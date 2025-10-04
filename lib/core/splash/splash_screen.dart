import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rivo_tech/core/services/connectivity_service.dart';
import 'package:rivo_tech/core/services/fcm_service.dart';
import 'package:rivo_tech/core/state/blog_store.dart';
import 'package:rivo_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _waveController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _particleAnimation;
  late Animation<double> _waveAnimation;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    // Wave animation
    _waveAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Start animations in sequence
    _particleController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _textController.forward();
    });
    _loadingController.repeat(reverse: true);
  }

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
      await Future.delayed(const Duration(milliseconds: 2500));

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
    _particleController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Obx(() {
      final isDark = themeService.isDark;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // Full width background gradient
              Container(
                width: screenWidth,
                height: screenHeight,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: isDark
                        ? [
                            const Color(0xFF1a0b02),
                            const Color(0xFF4a1d0a),
                            const Color(0xFF8b2d0f),
                            const Color(0xFFac4114),
                            const Color(0xFF6b2304),
                          ]
                        : [
                            const Color(0xFFff6b35),
                            const Color(0xFFff784e),
                            const Color(0xFFff8f59),
                            const Color(0xFFffa270),
                            const Color(0xFFffb58c),
                          ],
                    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                  ),
                ),
              ),

              // Animated wave effect at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(screenWidth, 120),
                      painter: _WavePainter(
                        animationValue: _waveAnimation.value,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),

              // Full width particle system
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _FullWidthParticlePainter(
                        animationValue: _particleAnimation.value,
                        isDark: isDark,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                    );
                  },
                ),
              ),

              // Main content
              SafeArea(
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Animated Logo with floating effect - scaled for full width
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform(
                            transform: Matrix4.identity()
                              ..scale(_logoScale.value)
                              ..rotateZ(_logoRotation.value),
                            alignment: Alignment.center,
                            child: Container(
                              width: screenWidth * 0.35,
                              height: screenWidth * 0.35,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Color(0xFFffeae0)],
                                ),
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.05,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 20),
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, -10),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.035,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.035,
                                  ),
                                  child: Image.asset(
                                    'assets/rivo_tech_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(
                                                0xFFff6221,
                                              ).withOpacity(0.1),
                                              const Color(
                                                0xFFff784e,
                                              ).withOpacity(0.2),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.035,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.bolt,
                                          size: screenWidth * 0.15,
                                          color: const Color(0xFFff6221),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Animated App Name - responsive text size
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: SlideTransition(
                              position: _textSlide,
                              child: Column(
                                children: [
                                  Text(
                                    'RIVO',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.12,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'TECHNOLOGY',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'Inter',
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 6,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const Spacer(flex: 2),

                      // Modern Loading Indicator - responsive size
                      Column(
                        children: [
                          AnimatedBuilder(
                            animation: _loadingController,
                            builder: (context, child) {
                              return Container(
                                width: screenWidth * 0.15,
                                height: screenWidth * 0.15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: _ArcLoadingPainter(
                                    progress: _loadingController.value,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          AnimatedBuilder(
                            animation: _loadingController,
                            builder: (context, child) {
                              return Text(
                                _getLoadingText(_loadingController.value),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.08),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _getLoadingText(double progress) {
    if (progress < 0.33) return 'Initializing...';
    if (progress < 0.66) return 'Loading Content...';
    return 'Almost Ready...';
  }
}

class _FullWidthParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  final double screenWidth;
  final double screenHeight;

  _FullWidthParticlePainter({
    required this.animationValue,
    required this.isDark,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final particleCount = 25;
    final time = animationValue * 2 * 3.14159;

    for (int i = 0; i < particleCount; i++) {
      final angle = 2 * 3.14159 * i / particleCount + time;
      final radius = screenWidth * 0.4;
      final x = screenWidth / 2 + radius * cos(angle);
      final y = screenHeight / 2 + radius * sin(angle);
      final particleSize = 3 + sin(angle + time) * 2;

      // Create particles across the entire width
      final randomX = x + sin(time + i) * screenWidth * 0.1;
      final randomY = y + cos(time + i) * screenHeight * 0.1;

      canvas.drawCircle(
        Offset(randomX, randomY),
        particleSize,
        paint..color = Colors.white.withOpacity(0.15 + sin(angle + time) * 0.1),
      );
    }

    // Additional floating particles in corners
    for (int i = 0; i < 10; i++) {
      final cornerX = screenWidth * (0.1 + 0.8 * (i % 2));
      final cornerY = screenHeight * (0.1 + 0.8 * (i ~/ 2));
      final cornerSize = 2 + sin(time + i) * 1.5;

      canvas.drawCircle(
        Offset(cornerX, cornerY),
        cornerSize,
        paint..color = Colors.white.withOpacity(0.1 + sin(time + i) * 0.05),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullWidthParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        isDark != oldDelegate.isDark ||
        screenWidth != oldDelegate.screenWidth ||
        screenHeight != oldDelegate.screenHeight;
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _WavePainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // Create wave effect
    for (double i = 0; i <= size.width; i += 10) {
      final y =
          size.height * 0.7 +
          sin((i / size.width) * 4 * 3.14159 + animationValue * 2 * 3.14159) *
              size.height *
              0.3;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        isDark != oldDelegate.isDark;
  }
}

class _ArcLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcLoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background circle
    canvas.drawCircle(center, radius, paint..color = color.withOpacity(0.2));

    // Progress arc
    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      paint,
    );

    // Pulsing dot at the end of the arc
    final dotAngle = -3.14159 / 2 + sweepAngle;
    final dotX = center.dx + radius * cos(dotAngle);
    final dotY = center.dy + radius * sin(dotAngle);

    canvas.drawCircle(Offset(dotX, dotY), 4, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ArcLoadingPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
