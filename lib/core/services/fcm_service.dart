import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:qarotech/core/config/api_config.dart';
import 'package:qarotech/core/config/fcm_config.dart';
import 'package:qarotech/firebase_options.dart';
import 'package:qarotech/modules/category/category_listing_page.dart';
import 'package:qarotech/modules/post_detail/post_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM Service for handling push notifications
class FCMService extends GetxService {
  static FCMService get instance => Get.find<FCMService>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final RxString _fcmToken = ''.obs;
  final RxBool _isInitialized = false.obs;
  final RxBool _isNavigating = false.obs;
  final RxBool _hasNavigatedFromNotification = false.obs;

  String get fcmToken => _fcmToken.value;
  bool get isInitialized => _isInitialized.value;
  bool get isNavigating => _isNavigating.value;
  bool get hasNavigatedFromNotification => _hasNavigatedFromNotification.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Don't initialize FCM in onInit to prevent blocking
    // FCM will be initialized separately in main.dart
  }

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      debugPrint("🔥 FCM Service - Initializing...");

      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Initialize local notifications with timeout
      await _initializeLocalNotifications().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("⚠️ FCM Service - Local notifications init timeout");
        },
      );

      // Request permission and get token with timeout
      await _requestPermissionAndGetToken().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("⚠️ FCM Service - Permission request timeout");
        },
      );

      // Set up message handlers
      _setupMessageHandlers();

      // Check for pending notifications from background (but only if not already navigated)
      if (!_hasNavigatedFromNotification.value) {
        await checkPendingNotifications();
      } else {
        debugPrint(
          "🔥 FCM - Skipping pending notification check (already navigated from notification)",
        );
      }

      _isInitialized.value = true;
      debugPrint("✅ FCM Service - Initialization complete");
    } catch (e, stackTrace) {
      debugPrint("❌ FCM Service - Initialization failed: $e");
      debugPrint("Stack trace: $stackTrace");
      _isInitialized.value = false;
      // Don't rethrow - let app continue without FCM
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 🔴 Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      FCMConfig.defaultNotificationChannel,
      FCMConfig.defaultNotificationChannelName,
      description: FCMConfig.defaultNotificationChannelDescription,
      importance: Importance.max, // 🔥 Heads-up notification
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);

    debugPrint("✅ FCM - Notification channel created");
  }

  /// Request FCM permission and get token
  Future<void> _requestPermissionAndGetToken() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint("🔥 FCM Permission status: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          _fcmToken.value = token;
          debugPrint("🔥 FCM Token: $token");

          // Register token with backend
          await _registerTokenWithBackend(token);

          // Save token locally
          await _saveTokenLocally(token);
        }
      } else {
        debugPrint("❌ FCM Permission denied");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error requesting FCM permission: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification tap when app is terminated
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessage(message);
      }
    });
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint("🔥 FCM - Foreground message received: ${message.messageId}");
    debugPrint("Title: ${message.notification?.title}");
    debugPrint("Body: ${message.notification?.body}");

    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Handle background messages (when app is in background or terminated)
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint("🔥 FCM - Background message received: ${message.messageId}");
    debugPrint("Title: ${message.notification?.title}");
    debugPrint("Body: ${message.notification?.body}");

    // Handle navigation or other actions based on message data
    if (message.data.isNotEmpty) {
      _handleMessageData(message.data);
    }
  }

  /// Handle message data for navigation
  void _handleMessageData(Map<String, dynamic> data) {
    try {
      debugPrint("🔥 FCM - _handleMessageData called with data: $data");
      debugPrint("🔥 FCM - Data keys: ${data.keys.toList()}");

      bool hasValidNavigation = false;

      // Navigate to specific post if postId is provided
      if (data.containsKey('postId') || data.containsKey('post_id')) {
        final postId = data['postId'] ?? data['post_id'];
        if (postId != null && postId.toString().trim().isNotEmpty) {
          debugPrint(
            "🔥 FCM - Found postId: $postId (type: ${postId.runtimeType})",
          );
          debugPrint("🔥 FCM - Navigating to post: $postId");
          _navigateToPost(postId);
          hasValidNavigation = true;
        } else {
          debugPrint("🔥 FCM - Empty or null postId found");
        }
      }

      // Navigate to category if categoryId is provided
      if (data.containsKey('categoryId') || data.containsKey('category_id')) {
        final categoryId = data['categoryId'] ?? data['category_id'];
        if (categoryId != null && categoryId.toString().trim().isNotEmpty) {
          debugPrint("🔥 FCM - Found categoryId: $categoryId");
          debugPrint("🔥 FCM - Navigating to category: $categoryId");
          _navigateToCategory(categoryId);
          hasValidNavigation = true;
        } else {
          debugPrint("🔥 FCM - Empty or null categoryId found");
        }
      }

      // If no valid navigation data found, redirect to home
      if (!hasValidNavigation) {
        debugPrint(
          "🔥 FCM - No valid navigation data found, redirecting to home",
        );
        _handleNavigationError("No valid navigation data in notification");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error handling message data: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      _handleNavigationError("Error processing notification data: $e");
    }
  }

  /// Navigate to post detail page
  void _navigateToPost(dynamic postId) {
    try {
      debugPrint(
        "🔥 FCM - _navigateToPost called with: $postId (type: ${postId.runtimeType})",
      );

      // Check if we're already on a detail page
      if (isOnDetailPage()) {
        debugPrint("🔥 FCM - Already on detail page, skipping navigation");
        return;
      }

      // Set navigation flags to prevent splash screen from overriding
      _isNavigating.value = true;
      _hasNavigatedFromNotification.value = true;

      // Convert postId to int if it's a string
      int id;
      try {
        if (postId is String) {
          id = int.parse(postId);
          debugPrint("🔥 FCM - Converted string postId to int: $id");
        } else if (postId is int) {
          id = postId;
          debugPrint("🔥 FCM - PostId is already int: $id");
        } else {
          debugPrint("❌ Invalid postId type: ${postId.runtimeType}");
          _handleNavigationError("Invalid postId type: ${postId.runtimeType}");
          return;
        }

        // Validate postId
        if (id <= 0) {
          debugPrint("❌ Invalid postId: $id (must be positive)");
          _handleNavigationError("Invalid postId: $id");
          return;
        }
      } catch (e) {
        debugPrint("❌ Error parsing postId: $e");
        _handleNavigationError("Error parsing postId: $e");
        return;
      }

      debugPrint("🔥 FCM - Opening post with ID: $id");

      // Always navigate through home first for better stability
      final currentRoute = Get.currentRoute;
      debugPrint("🔥 FCM - Current route before navigation: $currentRoute");

      if (currentRoute == '/splash') {
        debugPrint(
          "🔥 FCM - Coming from splash screen, navigating to home first",
        );
        // Navigate to home first, then to detail page
        Get.offAllNamed('/home');

        // Wait for home to load, then navigate to detail
        Future.delayed(const Duration(milliseconds: 800), () {
          _navigateToPostDetail(id);
        });
      } else {
        debugPrint(
          "🔥 FCM - App is running, navigating to home first for stability",
        );
        // Navigate to home first, then to detail page for consistency
        Get.offAllNamed('/home');

        // Wait for home to load, then navigate to detail
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToPostDetail(id);
        });
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error navigating to post: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      _handleNavigationError("Error navigating to post: $e");
    }
  }

  /// Navigate to post detail with error handling
  void _navigateToPostDetail(int id) {
    try {
      // Ensure we're on home page before navigating to detail
      final currentRoute = Get.currentRoute;
      if (currentRoute != '/home') {
        debugPrint("🔥 FCM - Not on home page, navigating to home first");
        Get.offAllNamed('/home');
        Future.delayed(const Duration(milliseconds: 300), () {
          _navigateToPostDetail(id);
        });
        return;
      }

      debugPrint(
        "🔥 FCM - Attempting navigation to PostDetailPage with ID: $id",
      );
      Get.to(() => PostDetailPage(postId: id));
      debugPrint("✅ FCM - Successfully navigated to post: $id");

      // Reset navigation flag after successful navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigating.value = false;
      });
    } catch (e, stackTrace) {
      debugPrint("❌ Error in Get.to navigation: $e");
      debugPrint("❌ Navigation stack trace: $stackTrace");
      _handleNavigationError("Error navigating to post detail: $e");
    }
  }

  /// Navigate to category page
  void _navigateToCategory(dynamic categoryId) {
    try {
      debugPrint(
        "🔥 FCM - _navigateToCategory called with: $categoryId (type: ${categoryId.runtimeType})",
      );

      // Check if we're already on a detail page
      if (isOnDetailPage()) {
        debugPrint("🔥 FCM - Already on category page, skipping navigation");
        return;
      }

      // Set navigation flags to prevent splash screen from overriding
      _isNavigating.value = true;
      _hasNavigatedFromNotification.value = true;

      // Convert categoryId to int if it's a string
      int id;
      try {
        if (categoryId is String) {
          id = int.parse(categoryId);
          debugPrint("🔥 FCM - Converted string categoryId to int: $id");
        } else if (categoryId is int) {
          id = categoryId;
          debugPrint("🔥 FCM - CategoryId is already int: $id");
        } else {
          debugPrint("❌ Invalid categoryId type: ${categoryId.runtimeType}");
          _handleNavigationError(
            "Invalid categoryId type: ${categoryId.runtimeType}",
          );
          return;
        }

        // Validate categoryId
        if (id <= 0) {
          debugPrint("❌ Invalid categoryId: $id (must be positive)");
          _handleNavigationError("Invalid categoryId: $id");
          return;
        }
      } catch (e) {
        debugPrint("❌ Error parsing categoryId: $e");
        _handleNavigationError("Error parsing categoryId: $e");
        return;
      }

      debugPrint("🔥 FCM - Opening category with ID: $id");

      // Always navigate through home first for better stability
      final currentRoute = Get.currentRoute;
      debugPrint("🔥 FCM - Current route before navigation: $currentRoute");

      if (currentRoute == '/splash') {
        debugPrint(
          "🔥 FCM - Coming from splash screen, navigating to home first",
        );
        // Navigate to home first, then to category page
        Get.offAllNamed('/home');

        // Wait for home to load, then navigate to category
        Future.delayed(const Duration(milliseconds: 800), () {
          _navigateToCategoryDetail(id);
        });
      } else {
        debugPrint(
          "🔥 FCM - App is running, navigating to home first for stability",
        );
        // Navigate to home first, then to category page for consistency
        Get.offAllNamed('/home');

        // Wait for home to load, then navigate to category
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToCategoryDetail(id);
        });
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error navigating to category: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      _handleNavigationError("Error navigating to category: $e");
    }
  }

  /// Navigate to category detail with error handling
  void _navigateToCategoryDetail(int id) {
    try {
      // Ensure we're on home page before navigating to detail
      final currentRoute = Get.currentRoute;
      if (currentRoute != '/home') {
        debugPrint("🔥 FCM - Not on home page, navigating to home first");
        Get.offAllNamed('/home');
        Future.delayed(const Duration(milliseconds: 300), () {
          _navigateToCategoryDetail(id);
        });
        return;
      }

      debugPrint(
        "🔥 FCM - Attempting navigation to CategoryListingPage with ID: $id",
      );
      Get.to(() => CategoryListingPage(catId: id, title: 'Tech Trends'));
      debugPrint("✅ FCM - Successfully navigated to category: $id");

      // Reset navigation flag after successful navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigating.value = false;
      });
    } catch (e, stackTrace) {
      debugPrint("❌ Error in Get.to navigation: $e");
      debugPrint("❌ Navigation stack trace: $stackTrace");
      _handleNavigationError("Error navigating to category detail: $e");
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            FCMConfig.defaultNotificationChannel,
            FCMConfig.defaultNotificationChannelName,
            channelDescription: FCMConfig.defaultNotificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint("❌ Error showing local notification: $e");
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("🔥 FCM - Notification tapped: ${response.payload}");
    debugPrint("🔥 FCM - Response actionId: ${response.actionId}");
    debugPrint("🔥 FCM - Response input: ${response.input}");

    try {
      if (response.payload != null && response.payload!.isNotEmpty) {
        debugPrint("🔥 FCM - Processing payload: ${response.payload}");

        // Parse the payload data
        final payload = jsonDecode(response.payload!);
        debugPrint("🔥 FCM - Parsed payload: $payload");
        debugPrint("🔥 FCM - Payload keys: ${payload.keys.toList()}");

        // Try snake_case first, then camelCase fallback
        final postId = payload['post_id'] ?? payload['postId'];
        final categoryId = payload['category_id'] ?? payload['categoryId'];

        debugPrint("🔥 FCM - Post ID: $postId (type: ${postId?.runtimeType})");
        debugPrint(
          "🔥 FCM - Category ID: $categoryId (type: ${categoryId?.runtimeType})",
        );

        if (postId != null) {
          // Navigate to post detail page
          debugPrint("🔥 FCM - Navigating to post: $postId");
          _navigateToPost(postId);
        } else if (categoryId != null) {
          // Navigate to category page
          debugPrint("🔥 FCM - Navigating to category: $categoryId");
          _navigateToCategory(categoryId);
        } else {
          debugPrint("🔥 FCM - No valid navigation data in payload");
          debugPrint("🔥 FCM - Available keys: ${payload.keys.toList()}");
        }
      } else {
        debugPrint("🔥 FCM - Empty payload, no navigation");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error handling notification tap: $e");
      debugPrint("❌ Stack trace: $stackTrace");
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final String backendUrl = ApiConfig.registerEndpoint;
      debugPrint("🔥 FCM - Registering token with backend: $backendUrl");
      // prev toke
      final prevToken = await getStoredToken();

      final data = {
        'token': token,
        'prevToken': prevToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      };
      debugPrint("🔥 FCM - Previous token: $prevToken");
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      debugPrint("🔥 FCM - Registering token response: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ FCM Token registered with backend");
      } else {
        debugPrint("❌ Failed to register FCM token: ${response}");
      }
    } catch (e) {
      debugPrint("❌ Error registering FCM token with backend: $e");
    }
  }

  /// Save token locally
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint("✅ FCM Token saved locally");
    } catch (e) {
      debugPrint("❌ Error saving FCM token locally: $e");
    }
  }

  /// Get stored token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint("❌ Error getting stored FCM token: $e");
      return null;
    }
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token != _fcmToken.value) {
        _fcmToken.value = token;
        await _registerTokenWithBackend(token);
        await _saveTokenLocally(token);
        debugPrint("✅ FCM Token refreshed");
      }
    } catch (e) {
      debugPrint("❌ Error refreshing FCM token: $e");
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint("✅ Subscribed to topic: $topic");
    } catch (e) {
      debugPrint("❌ Error subscribing to topic $topic: $e");
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint("✅ Unsubscribed from topic: $topic");
    } catch (e) {
      debugPrint("❌ Error unsubscribing from topic $topic: $e");
    }
  }

  /// Test navigation method for debugging
  void testNavigation(int postId) {
    debugPrint("🔥 FCM - Testing navigation to post: $postId");
    _navigateToPost(postId);
  }

  /// Test notification handling with sample data
  void testNotificationHandling() {
    debugPrint("🔥 FCM - Testing notification handling with sample data");
    final testData = {'postId': '123'};
    _handleMessageData(testData);
  }

  /// Simulate notification from closed app state
  void simulateNotificationFromClosedApp() {
    debugPrint("🔥 FCM - Simulating notification from closed app");
    final testData = {'postId': '456'};
    _handleMessageData(testData);
  }

  /// Check if there are pending notifications without processing them
  Future<bool> hasPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString('pending_notification');
      return pendingData != null && pendingData.isNotEmpty;
    } catch (e) {
      debugPrint("❌ Error checking for pending notifications: $e");
      return false;
    }
  }

  /// Reset notification navigation flag (call when app starts normally)
  void resetNotificationFlag() {
    _hasNavigatedFromNotification.value = false;
    debugPrint("🔥 FCM - Reset notification navigation flag");
  }

  /// Handle when user navigates back from detail page
  void onBackFromDetailPage() {
    debugPrint("🔥 FCM - User navigated back from detail page");
    _hasNavigatedFromNotification.value = false;
    _isNavigating.value = false;
    // Don't automatically navigate - let the user control back navigation
  }

  /// Navigate to home page safely
  void navigateToHome() {
    try {
      debugPrint("🔥 FCM - Navigating to home page");
      Get.offAllNamed('/home');
    } catch (e) {
      debugPrint("❌ Error navigating to home: $e");
    }
  }

  /// Handle navigation errors by redirecting to Recent Page
  void _handleNavigationError(String error) {
    try {
      debugPrint("🔥 FCM - Handling navigation error: $error");

      // Reset navigation flags
      _isNavigating.value = false;
      _hasNavigatedFromNotification.value = false;

      // Navigate to home page (Recent Page)
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          debugPrint("🔥 FCM - Redirecting to Recent Page due to error");
          Get.offAllNamed('/home');

          // Show error message to user
          Get.snackbar(
            "Navigation Error",
            "Unable to open the requested content. Redirecting to Recent Page.",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
          );
        } catch (e) {
          debugPrint("❌ Error redirecting to home: $e");
        }
      });
    } catch (e) {
      debugPrint("❌ Error in _handleNavigationError: $e");
    }
  }

  /// Check if we're already on a detail page
  bool isOnDetailPage() {
    try {
      final currentRoute = Get.currentRoute;
      debugPrint("🔥 FCM - Current route: $currentRoute");
      return currentRoute.contains('/post_detail') ||
          currentRoute.contains('PostDetailPage');
    } catch (e) {
      debugPrint("❌ Error checking current route: $e");
      return false;
    }
  }

  /// Clear pending notification data
  Future<void> _clearPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_notification');
      debugPrint("🔥 FCM - Cleared pending notification data");
    } catch (e) {
      debugPrint("❌ Error clearing pending notification: $e");
    }
  }

  /// Check for pending notifications from background
  Future<void> checkPendingNotifications() async {
    try {
      debugPrint("🔥 FCM - Checking for pending notifications...");
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString('pending_notification');

      if (pendingData != null && pendingData.isNotEmpty) {
        debugPrint("🔥 FCM - Found pending notification data: $pendingData");

        // Clear the pending notification
        await prefs.remove('pending_notification');

        // Parse and handle the data
        final notificationInfo =
            jsonDecode(pendingData) as Map<String, dynamic>;
        debugPrint("🔥 FCM - Parsed notification info: $notificationInfo");

        final data = notificationInfo['data'] as Map<String, dynamic>;
        debugPrint("🔥 FCM - Processing pending notification with data: $data");
        debugPrint("🔥 FCM - Data keys: ${data.keys.toList()}");

        // Check if we're coming from splash screen (app was closed)
        final currentRoute = Get.currentRoute;
        debugPrint(
          "🔥 FCM - Current route when processing pending notification: $currentRoute",
        );

        if (currentRoute == '/splash') {
          debugPrint(
            "🔥 FCM - Coming from splash screen, will navigate to home first",
          );
          // The navigation will be handled in _navigateToPost with proper flow
        }

        // Add delay to ensure app is fully loaded before navigating
        Future.delayed(const Duration(milliseconds: 2000), () {
          debugPrint("🔥 FCM - Delayed execution - calling _handleMessageData");
          _handleMessageData(data);

          // Clear the pending notification after processing to prevent re-processing
          _clearPendingNotification();
        });
      } else {
        debugPrint("🔥 FCM - No pending notifications found");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error checking pending notifications: $e");
      debugPrint("❌ Stack trace: $stackTrace");
    }
  }
}

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🔥 FCM - Background handler: ${message.messageId}");
  debugPrint("🔥 FCM - Background message data: ${message.data}");

  // Initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Store the message data for later processing when app opens
  if (message.data.isNotEmpty) {
    final prefs = await SharedPreferences.getInstance();
    final notificationData = {
      'data': message.data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'messageId': message.messageId,
    };
    await prefs.setString('pending_notification', jsonEncode(notificationData));
    debugPrint("🔥 FCM - Stored pending notification data: ${message.data}");
  }
}
