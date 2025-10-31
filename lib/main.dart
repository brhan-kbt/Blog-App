import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ethio_tips/core/consent/consent_service.dart';
import 'package:ethio_tips/core/services/fcm_service.dart';
import 'package:ethio_tips/firebase_options.dart';
import 'package:ethio_tips/widgets/adabtiveBanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ethio_tips/core/theme/app_palette.dart';
import 'package:ethio_tips/core/theme/theme_service.dart';
import 'package:ethio_tips/core/services/connectivity_service.dart';
import 'package:ethio_tips/core/services/performance_service.dart';
import 'package:ethio_tips/core/services/version_check_service.dart';
import 'package:ethio_tips/core/services/version_check_controller.dart';
import 'package:ethio_tips/routes/app_pages.dart';
import 'core/state/blog_store.dart';
import 'core/theme/app_theme.dart';
import 'modules/category/category_page.dart';
import 'modules/favorite/favorite_page.dart';
import 'modules/recent/recent_page.dart';
import 'widgets/search_header.dart';
import 'core/ads/ad_service.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize GetStorage first (required for theme service)
  await GetStorage.init();

  // Initialize theme service first to ensure proper theme loading
  await _initializeThemeService();

  // Initialize other services in parallel
  // await Future.wait([
  //   _initializeBlogStore(),
  //   _initializeAds(),
  //   _initializePerformanceService(),
  //   _initializeVersionCheckService(),
  // ]);

  // Initialize only essential services for app startup
  await _initializeBlogStore();
  await _initializeConsentService();

  // Initialize other services in background to speed up startup
  _initializeBackgroundServices();

  runApp(const EthioTipsApp());
}

Future<void> _initializeThemeService() async {
  final themeSvc = Get.put(ThemeService(), permanent: true);
  await themeSvc.init();

  // Small delay to ensure theme is properly applied
  await Future.delayed(const Duration(milliseconds: 100));

  debugPrint(
    "🎨 ThemeService - Initialization complete. Mode: ${themeSvc.mode.value}, IsDark: ${themeSvc.isDark}",
  );
}

Future<void> _initializeBlogStore() async {
  Get.put(BlogStore(), permanent: true);
}

Future<void> _initializeConsentService() async {
  try {
    await ConsentService().initialize();
    debugPrint("✅ Consent service initialized successfully");
  } catch (e) {
    debugPrint("❌ Error initializing consent service: $e");
    // Continue app initialization even if consent service fails
  }
}

Future<void> _initializeAds() async {
  try {
    await MobileAds.instance.initialize();
    await AdService.instance.initialize();
    AdService.instance.loadAppOpenAd();
  } catch (e) {
    debugPrint('Error initializing ads: $e');
    // Continue app initialization even if ads fail
  }
}

Future<void> _initializePerformanceService() async {
  Get.put(PerformanceService(), permanent: true);
}

Future<void> _initializeVersionCheckService() async {
  Get.put(VersionCheckService(), permanent: true);
  Get.put(VersionCheckController(), permanent: true);
}

Future<void> _initializeFCMService() async {
  try {
    Get.put(FCMService(), permanent: true);
    await FCMService.instance.initialize();
    // Reset notification flag when app starts normally
    FCMService.instance.resetNotificationFlag();
    debugPrint("✅ FCM Service initialized successfully");
  } catch (e) {
    debugPrint("❌ Error initializing FCM Service: $e");
    // Continue app initialization even if FCM fails
  }
}

/// Initialize background services to speed up app startup
void _initializeBackgroundServices() {
  // Initialize performance and version check services in background
  Future.microtask(() async {
    try {
      await _initializePerformanceService();
      debugPrint("✅ Performance service initialized in background");
    } catch (e) {
      debugPrint("❌ Error initializing performance service: $e");
    }
  });

  Future.microtask(() async {
    try {
      await _initializeVersionCheckService();
      debugPrint("✅ Version check service initialized in background");
    } catch (e) {
      debugPrint("❌ Error initializing version check service: $e");
    }
  });

  // Initialize ads and FCM with longer delays to prevent blocking
  Future.delayed(const Duration(milliseconds: 1000), () async {
    try {
      await _initializeAds();
      debugPrint("✅ Ads initialized in background");
    } catch (e) {
      debugPrint("❌ Error initializing ads in background: $e");
    }
  });

  Future.delayed(const Duration(milliseconds: 1000), () async {
    try {
      await _initializeFCMService();
      debugPrint("✅ FCM Service initialized in background");
    } catch (e) {
      debugPrint("❌ Error initializing FCM in background: $e");
    }
  });
}

class EthioTipsApp extends StatelessWidget {
  const EthioTipsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSvc = Get.find<ThemeService>();

    return Obx(() {
      debugPrint(
        "🎨 EthioTipsApp - Building with theme mode: ${themeSvc.mode.value}",
      );
      debugPrint("🎨 EthioTipsApp - IsDark: ${themeSvc.isDark}");

      return GetMaterialApp(
        title: 'Ethio Tips',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeSvc.mode.value,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        navigatorObservers: [
          GetObserver((routing) {
            if (routing != null) {
              debugPrint(
                "🔥 Navigation - Route changed to: ${routing.current}",
              );
              _handleRouteChange(routing.current);
            }
          }),
        ],
      );
    });
  }

  void _handleRouteChange(String currentRoute) {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();

        // If we're on home page and notification flag is set, reset it
        if (currentRoute == '/home' &&
            fcmService.hasNavigatedFromNotification) {
          debugPrint(
            "🔥 App - Detected navigation to home, resetting notification flag",
          );
          fcmService.onBackFromDetailPage();

          debugPrint("🔥 App - User is on home page after back navigation");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error handling route change: $e");
    }
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int index = 0;
  final store = Get.find<BlogStore>();
  final connectivityService = Get.find<ConnectivityService>();
  final versionCheckService = Get.find<VersionCheckService>();
  final titles = const ['Home', 'Category', 'Favorite'];

  final box = GetStorage();

  // Lazy loading for pages
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize pages lazily
    pages = [const RecentPage(), const CategoryPage(), const FavoritePage()];

    _checkFirstLaunch();
    _checkForAppUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint(
          "📱 App resumed - checking notification status and showing ads",
        );
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        debugPrint("📱 App paused");
        break;
      case AppLifecycleState.inactive:
        debugPrint("📱 App inactive");
        break;
      case AppLifecycleState.detached:
        debugPrint("📱 App detached");
        break;
      case AppLifecycleState.hidden:
        debugPrint("📱 App hidden");
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for route changes to detect when user navigates back from detail page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForBackNavigation();
    });
  }

  void _checkForBackNavigation() {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        final currentRoute = Get.currentRoute;

        // If we're on home page and notification flag is set, reset it
        if (currentRoute == '/home' &&
            fcmService.hasNavigatedFromNotification) {
          debugPrint(
            "🔥 Shell - Detected back navigation to home, resetting notification flag",
          );
          fcmService.onBackFromDetailPage();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error checking for back navigation: $e");
    }
  }

  Future<void> _handleAppResume() async {
    try {
      // Check notification status when returning from settings
      await _checkNotificationStatus();

      // Check for pending notifications from background (but not if we're already on a detail page)
      try {
        final fcmService = Get.find<FCMService>();
        // Only check pending notifications if we haven't navigated from notification
        if (!fcmService.hasNavigatedFromNotification) {
          await fcmService.checkPendingNotifications();
        } else {
          debugPrint(
            "🔥 Shell - Skipping pending notification check (already navigated from notification)",
          );
        }
      } catch (e) {
        debugPrint("⚠️ Error checking pending notifications on resume: $e");
      }

      // Show app open ad with error handling
      try {
        await AdService.instance.showAppOpenAd();
      } catch (e) {
        debugPrint("⚠️ Error showing app open ad: $e");
      }
    } catch (e) {
      debugPrint("⚠️ Error handling app resume: $e");
    }
  }

  Future<void> _checkFirstLaunch() async {
    final isFirstLaunch = box.read("isFirstLaunch") ?? true;
    if (isFirstLaunch) {
      // await _requestNotificationPermission();
      // Delay notification permission request until after home page renders
      Future.delayed(const Duration(seconds: 3), () async {
        if (mounted) {
          await _requestNotificationPermission();
        }
      });
      await box.write("isFirstLaunch", false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!mounted) return;

      if (status.isGranted) {
        debugPrint("✅ Notifications already allowed");
        return;
      }

      if (status.isDenied) {
        debugPrint("📱 Requesting notification permission...");
        final result = await Permission.notification.request();
        if (!mounted) return;

        if (result.isGranted) {
          debugPrint("✅ Notification permission granted");
          // Initialize FCM after permission is granted
          try {
            await FCMService.instance.initialize();
          } catch (e) {
            debugPrint("❌ Error initializing FCM after permission: $e");
          }
          _showNotificationPermissionSnackbar(
            "Notifications enabled! You'll receive updates about new articles.",
          );
        } else if (result.isPermanentlyDenied) {
          debugPrint("❌ Notification permission permanently denied");
          _showNotificationPermissionSnackbar(
            "Notifications are disabled. You can enable them in Settings.",
          );
        } else {
          debugPrint("❌ Notification permission denied");
          _showNotificationPermissionSnackbar(
            "Notifications are disabled. You can enable them later in Settings.",
          );
        }
      } else if (status.isPermanentlyDenied) {
        debugPrint("❌ Notification permission permanently denied");
        _showNotificationPermissionSnackbar(
          "Notifications are disabled. You can enable them in Settings.",
        );
      }
    } catch (e, st) {
      debugPrint("⚠️ Error requesting notifications: $e\n$st");
    }
  }

  void _showNotificationPermissionSnackbar(String message) {
    if (!mounted) return;
    Get.snackbar(
      "Notification Settings",
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
      backgroundColor: Get.isDarkMode ? Colors.grey[800] : Colors.grey[100],
      colorText: Get.isDarkMode ? Colors.white : Colors.black,
    );
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final status = await Permission.notification.status;
      if (!mounted) return;
      if (status.isGranted) {
        debugPrint("✅ Notifications allowed");
      } else {
        debugPrint("❌ Notifications disabled");
      }
    } catch (e, st) {
      debugPrint("⚠️ Error checking notifications: $e\n$st");
    }
  }

  Future<void> _checkForAppUpdate() async {
    try {
      // Check connectivity first
      if (!connectivityService.isConnected) {
        debugPrint("📱 Skipping version check - no internet connection");
        return;
      }

      // Add a small delay to ensure the app is fully loaded
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final versionResponse = await versionCheckService.checkForUpdate();

      if (versionResponse != null && versionResponse.data.needsUpdate) {
        debugPrint("🔄 App update available - showing update dialog");

        // Show update dialog
        _showUpdateDialog(versionResponse.data);
      } else {
        debugPrint("✅ App is up to date");
      }
    } catch (e, st) {
      debugPrint("⚠️ Error checking for app update: $e\n$st");
      // Don't show error to user, just log it
    }
  }

  void _showUpdateDialog(versionData) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible:
          !versionData.forceUpdate, // Prevent dismissing if force update
      builder: (context) => UpdateDialog(versionData: versionData),
    );
  }

  /// 🔹 Refresh depending on active tab
  Future<void> _onRefresh() async {
    // Check connectivity before refreshing
    if (!connectivityService.isConnected) {
      Get.snackbar(
        'No Internet',
        'Please check your internet connection',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      if (index == 0 || index == 2) {
        // Refresh posts for Recent or Favorite
        await store.fetchPosts();
      }
      if (index == 1) {
        // Refresh categories for Category page
        await store.fetchCategories();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choice = Random().nextInt(3); // 0 none, 1 interstitial, 2 rewarded

    print("Random choice: $choice");

    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Connectivity indicator
            Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: connectivityService.isConnected ? 0 : 30,
                child: connectivityService.isConnected
                    ? const SizedBox.shrink()
                    : Container(
                        width: double.infinity,
                        color: Colors.red,
                        child: const Center(
                          child: Text(
                            'No Internet Connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SearchHeader(
              title: "Search ... ",
              onChanged: (q) => store.query.value = q,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: pages[index],
              ),
            ),
            // Bottom banner ad on all pages (slightly smaller than inline)
            // if (choice == 1 || choice == 2)
            const AdaptiveBannerAdWidget(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: Brightness.light == theme.brightness
            ? const Color.fromARGB(255, 242, 242, 242)
            : const Color.fromARGB(255, 16, 16, 36),
        indicatorColor: palette.favoriteActive,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.browse_gallery_outlined),
            selectedIcon: Icon(Icons.browse_gallery),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outlined),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
