import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gold_tech/core/services/connectivity_service.dart';
import 'package:gold_tech/core/services/fcm_service.dart';
import 'package:gold_tech/core/state/blog_store.dart';
import 'package:gold_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Staggered animation sequence
    _backgroundController.forward();
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  // Keep your existing _initializeApp() and _checkForPendingNotification() methods exactly as they are
  Future<void> _initializeApp() async {
    try {
      // Check if we're already on home page (user navigated back)
      final currentRoute = Get.currentRoute;
      if (currentRoute == '/home') {
        debugPrint("🔥 Splash - Already on home page, skipping initialization");
        return;
      }

      // Check if FCM service indicates we should navigate to home
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

      // Initialize connectivity service
      Get.put(ConnectivityService(), permanent: true);

      // Check connectivity
      final connectivityService = Get.find<ConnectivityService>();
      await connectivityService.checkConnectivity();

      // Initialize blog store and fetch initial data
      final blogStore = Get.find<BlogStore>();

      // Only fetch data if connected
      if (connectivityService.isConnected) {
        await Future.wait([
          blogStore.fetchPosts(),
          blogStore.fetchCategories(),
        ]);
      }

      // Add minimum splash duration for better UX
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        // Check if there's a pending notification before navigating to home
        await _checkForPendingNotification();

        // Only navigate to home if no notification navigation occurred
        if (mounted) {
          // Check if FCM service has navigated from notification
          if (Get.isRegistered<FCMService>()) {
            final fcmService = Get.find<FCMService>();
            if (fcmService.hasNavigatedFromNotification) {
              debugPrint(
                "🔥 Splash - Notification navigation occurred, checking current route",
              );

              // Check if we're currently on a detail page
              if (fcmService.isOnDetailPage()) {
                debugPrint(
                  "🔥 Splash - Currently on detail page, skipping home navigation",
                );
                return;
              } else {
                debugPrint(
                  "🔥 Splash - Not on detail page, proceeding to home",
                );
                // Reset the notification flag since we're navigating to home
                fcmService.resetNotificationFlag();
              }
            }
          }

          debugPrint(
            "🔥 Splash - No notification navigation, proceeding to home",
          );

          // Only navigate to home if we're not already on a detail page
          if (Get.isRegistered<FCMService>()) {
            final fcmService = Get.find<FCMService>();
            if (fcmService.isOnDetailPage()) {
              debugPrint(
                "🔥 Splash - Currently on detail page, skipping home navigation",
              );
              return;
            }
          }

          // Use Get.offAllNamed to clear the navigation stack and go to home
          Get.offAllNamed('/home');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Still navigate to home even if there's an error
      if (mounted) {
        Get.offAllNamed('/home');
      }
    }
  }

  /// Check for pending notifications and handle them
  Future<void> _checkForPendingNotification() async {
    try {
      // Check if FCM service is available
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();

        // Check if there are pending notifications
        final hasPending = await fcmService.hasPendingNotifications();
        if (hasPending) {
          debugPrint("🔥 Splash - Found pending notifications, processing...");
          await fcmService.checkPendingNotifications();
          debugPrint("🔥 Splash - Pending notifications processed");
        } else {
          debugPrint("🔥 Splash - No pending notifications found");
        }
      } else {
        debugPrint("🔥 Splash - FCM service not available yet");
      }
    } catch (e) {
      debugPrint("❌ Error checking pending notifications in splash: $e");
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      final isDark = themeService.isDark;
      debugPrint(
        '🎨 Splash Screen - Theme Mode: ${themeService.mode.value}, IsDark: $isDark',
      );

      return Scaffold(
        body: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(
                      0xffed761c,
                    ).withOpacity(_backgroundAnimation.value),
                    const Color(
                      0xffff9441,
                    ).withOpacity(_backgroundAnimation.value),
                    const Color(
                      0xffff6221,
                    ).withOpacity(_backgroundAnimation.value),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Background Pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1 * _backgroundAnimation.value,
                      child: CustomPaint(painter: _SplashBackgroundPainter()),
                    ),
                  ),

                  // Content
                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

                        // Logo Section - Full Width
                        AnimatedBuilder(
                          animation: _logoAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoAnimation.value,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 60,
                                ),
                                child: Column(
                                  children: [
                                    // Logo Container
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(40),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3 * _logoAnimation.value,
                                            ),
                                            blurRadius: 30,
                                            offset: const Offset(0, 20),
                                            spreadRadius: 5,
                                          ),
                                          BoxShadow(
                                            color: Colors.white.withOpacity(
                                              0.2 * _logoAnimation.value,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, -10),
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFff6221,
                                            ).withOpacity(0.15),
                                            width: 3,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          child: Image.asset(
                                            'assets/gold_tech_logo.png',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFff6221,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            28,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.article_outlined,
                                                      size: 80,
                                                      color: const Color(
                                                        0xFFff6221,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // App Name with Slide Animation
                                    SlideTransition(
                                      position: _textSlideAnimation,
                                      child: FadeTransition(
                                        opacity: _textAnimation,
                                        child: Text(
                                          'Gold Tech',
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 42,
                                                fontFamily: 'Pacifico',
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                    offset: const Offset(0, 3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                                letterSpacing: 1.5,
                                              ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Tagline
                                    SlideTransition(
                                      position: _textSlideAnimation,
                                      child: FadeTransition(
                                        opacity: _textAnimation,
                                        child: Text(
                                          'Technology & Innovation',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 18,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    offset: const Offset(0, 2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const Spacer(flex: 2),

                        // Loading Section - Full Width
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              // Animated Loading Indicator
                              AnimatedBuilder(
                                animation: _textController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _textAnimation,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2 * _textAnimation.value,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: _backgroundController.value,
                                            strokeWidth: 4,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Colors.white),
                                            backgroundColor: Colors.white
                                                .withOpacity(0.3),
                                          ),
                                          Icon(
                                            Icons.rocket_launch_rounded,
                                            color: Colors.white,
                                            size: 24 * _textAnimation.value,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Loading Text
                              AnimatedBuilder(
                                animation: _textController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _textAnimation,
                                    child: Text(
                                      'Preparing Your Experience...',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.3,
                                                ),
                                                offset: const Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                            letterSpacing: 0.8,
                                          ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

// Custom background painter for geometric patterns
class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw geometric circles
    for (int i = 0; i < 8; i++) {
      final radius = (i + 1) * 40.0;
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint..color = Colors.white.withOpacity(0.05),
      );
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.8),
        radius,
        paint..color = Colors.white.withOpacity(0.05),
      );
    }

    // Draw diagonal lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 2;

    for (int i = 0; i < 10; i++) {
      final offset = i * 60.0;
      canvas.drawLine(Offset(offset, 0), Offset(0, offset), linePaint);
      canvas.drawLine(
        Offset(size.width - offset, size.height),
        Offset(size.width, size.height - offset),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
