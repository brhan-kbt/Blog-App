import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kana_tech/core/services/connectivity_service.dart';
import 'package:kana_tech/core/services/fcm_service.dart';
import 'package:kana_tech/core/state/blog_store.dart';
import 'package:kana_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  // Orange color palette based on #e1632e
  final Color deepSpace = const Color(0xFF1A0F0A);
  final Color cosmicOrange = const Color(0xFF2A1A10);
  final Color neonOrange = const Color(0xFFE1632E);
  final Color electricRed = const Color(0xFFF6422E);
  final Color amberGlow = const Color(0xFFFFA000);
  final Color starWhite = const Color(0xFFFFF0E0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _logoController.forward();
    await _textController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      final currentRoute = Get.currentRoute;
      if (currentRoute == '/home') {
        debugPrint("🔥 Splash - Already on home page, skipping initialization");
        return;
      }

      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        if (fcmService.hasNavigatedFromNotification) {
          debugPrint(
            "🔥 Splash - FCM indicates navigation to home, skipping splash",
          );
          Get.offAllNamed('/home');
          return;
        }
      }

      Get.put(ConnectivityService(), permanent: true);
      final connectivityService = Get.find<ConnectivityService>();
      await connectivityService.checkConnectivity();

      final blogStore = Get.find<BlogStore>();
      if (connectivityService.isConnected) {
        await Future.wait([
          blogStore.fetchPosts(),
          blogStore.fetchCategories(),
        ]);
      }

      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        await _checkForPendingNotification();

        if (mounted) {
          if (Get.isRegistered<FCMService>()) {
            final fcmService = Get.find<FCMService>();
            if (fcmService.hasNavigatedFromNotification) {
              if (fcmService.isOnDetailPage()) {
                return;
              } else {
                fcmService.resetNotificationFlag();
              }
            }
          }

          if (Get.isRegistered<FCMService>()) {
            final fcmService = Get.find<FCMService>();
            if (fcmService.isOnDetailPage()) {
              return;
            }
          }

          Get.offAllNamed('/home');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) {
        Get.offAllNamed('/home');
      }
    }
  }

  Future<void> _checkForPendingNotification() async {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        final hasPending = await fcmService.hasPendingNotifications();
        if (hasPending) {
          await fcmService.checkPendingNotifications();
        }
      }
    } catch (e) {
      debugPrint("❌ Error checking pending notifications in splash: $e");
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  // Simple logo with safe animations
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [neonOrange, electricRed],
                stops: const [0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: neonOrange.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.rocket_launch, color: starWhite, size: 50),
          ),
        );
      },
    );
  }

  // Simple loading indicator
  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        final progress = _loadingController.value;
        final dotCount = (progress * 4).floor() % 4;
        final dots = '.' * (dotCount + 1);

        return Column(
          children: [
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: deepSpace.withOpacity(0.6),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 200 * progress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [amberGlow, neonOrange, electricRed],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading$dots",
              style: TextStyle(
                color: starWhite.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 179, 52, 9),
              Color.fromARGB(255, 104, 30, 6),
              const Color.fromARGB(255, 189, 56, 12),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              _buildLogo(),

              const SizedBox(height: 40),

              // App Name
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _textAnimation.value) * 20),
                      child: Column(
                        children: [
                          Text(
                            "KANA TECH",
                            style: TextStyle(
                              fontSize: min(screenWidth * 0.1, 42),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: starWhite,
                              fontFamily: "Orbitron",
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: neonOrange.withOpacity(0.8),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Text(
                          //   "WHERE TRADITION MEETS INNOVATION",
                          //   style: TextStyle(
                          //     color: starWhite.withOpacity(0.7),
                          //     fontSize: min(screenWidth * 0.035, 14),
                          //     letterSpacing: 1.5,
                          //     fontWeight: FontWeight.w300,
                          //   ),
                          //   textAlign: TextAlign.center,
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              // Loading indicator
              _buildLoadingIndicator(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
