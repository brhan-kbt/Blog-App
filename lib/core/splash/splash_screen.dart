import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nile_tech/core/services/connectivity_service.dart';
import 'package:nile_tech/core/services/fcm_service.dart';
import 'package:nile_tech/core/state/blog_store.dart';
import 'package:nile_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  // Color palette based on #1b1b45
  final Color primaryColor = const Color(0xFF1B1B45);
  final Color secondaryColor = const Color(0xFF2D2D6D);
  final Color accentColor = const Color(0xFF4A4A9C);
  final Color highlightColor = const Color(0xFF6C6CD3);
  final Color textColor = const Color(0xFFE0E0FF);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start sequenced animations
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _logoController.forward();
    await _textController.forward();
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

      await Future.delayed(const Duration(milliseconds: 3000));

      if (mounted) {
        await _checkForPendingNotification();

        if (mounted) {
          if (Get.isRegistered<FCMService>()) {
            final fcmService = Get.find<FCMService>();
            if (fcmService.hasNavigatedFromNotification) {
              debugPrint(
                "🔥 Splash - Notification navigation occurred, checking current route",
              );

              if (fcmService.isOnDetailPage()) {
                debugPrint(
                  "🔥 Splash - Currently on detail page, skipping home navigation",
                );
                return;
              } else {
                debugPrint(
                  "🔥 Splash - Not on detail page, proceeding to home",
                );
                fcmService.resetNotificationFlag();
              }
            }
          }

          debugPrint(
            "🔥 Splash - No notification navigation, proceeding to home",
          );

          if (Get.isRegistered<FCMService>()) {
            final fcmService = Get.find<FCMService>();
            if (fcmService.isOnDetailPage()) {
              debugPrint(
                "🔥 Splash - Currently on detail page, skipping home navigation",
              );
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
    _waveController.dispose();
    _particleController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Animated background waves
  Widget _buildAnimatedWaves() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _waveAnimation.value * 20),
          child: CustomPaint(
            painter: _WavePatternPainter(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              accentColor: accentColor,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  // Floating tech particles
  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            animationValue: _particleAnimation.value,
            highlightColor: highlightColor,
            accentColor: accentColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // Modern geometric logo
  Widget _buildModernLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Transform.rotate(
            angle: _logoAnimation.value * 2 * pi,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accentColor, primaryColor],
                  stops: const [0.7, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: highlightColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _GeometricLogoPainter(
                  primaryColor: textColor,
                  highlightColor: highlightColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              secondaryColor,
              const Color(0xFF151538),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background waves
            _buildAnimatedWaves(),

            // Floating particles
            _buildFloatingParticles(),

            // Main content
            SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Modern logo with orbiting elements
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Orbiting dots
                        ...List.generate(8, (index) {
                          final angle = (index / 8) * 2 * pi +
                              _particleAnimation.value * 2 * pi;
                          final distance = 60.0;
                          return Positioned(
                            left: distance * cos(angle) + screenWidth * 0.5 - 60,
                            top: distance * sin(angle) + screenHeight * 0.3,
                            child: AnimatedBuilder(
                              animation: _particleController,
                              builder: (context, child) {
                                final scale = 0.5 +
                                    0.5 *
                                        sin(_particleAnimation.value * 2 * pi +
                                            index * 0.5);
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index % 3 == 0
                                          ? highlightColor
                                          : index % 3 == 1
                                              ? accentColor
                                              : textColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (index % 3 == 0
                                                  ? highlightColor
                                                  : index % 3 == 1
                                                      ? accentColor
                                                      : textColor)
                                              .withOpacity(0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        // Main logo
                        _buildModernLogo(),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // App Name with modern typography
                    AnimatedBuilder(
                      animation: _textAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.center,
                                  widthFactor: _textAnimation.value,
                                  child: Text(
                                    "NILE TECH",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.09,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                      color: textColor,
                                      fontFamily: "Roboto",
                                      shadows: [
                                        Shadow(
                                          blurRadius: 20,
                                          color: highlightColor.withOpacity(0.6),
                                        ),
                                        Shadow(
                                          blurRadius: 40,
                                          color: accentColor.withOpacity(0.4),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedBuilder(
                                animation: _textAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _textAnimation.value,
                                    child: Text(
                                      "Innovation ∙ Heritage ∙ Future",
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.8),
                                        fontSize: screenWidth * 0.035,
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w300,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Modern loading indicator
                    Container(
                      width: screenWidth * 0.7,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: primaryColor.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Animated progress
                          AnimatedBuilder(
                            animation: _particleController,
                            builder: (context, child) {
                              return Container(
                                width: screenWidth *
                                    0.7 *
                                    (_particleAnimation.value * 0.3 + 0.7),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      highlightColor,
                                      accentColor,
                                      highlightColor,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    tileMode: TileMode.mirror,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: highlightColor.withOpacity(0.6),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Loading text with dots animation
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        final dots = '.' *
                            ((_particleAnimation.value * 3).floor() % 4);
                        return Text(
                          "Loading$dots",
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wave Pattern Painter
class _WavePatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  _WavePatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = accentColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = secondaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const waveCount = 8;
    final waveSpacing = size.height / waveCount;

    for (int i = 0; i < waveCount; i++) {
      final y = i * waveSpacing;
      final path = Path();

      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 10) {
        final waveHeight = sin(x * 0.02 + i * 0.5) * 8;
        path.lineTo(x, y + waveHeight);
      }

      canvas.drawPath(path, wavePaint);
    }

    // Draw some geometric shapes in background
    final shapePaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = Random(i).nextDouble() * size.width;
      final y = Random(i + 100).nextDouble() * size.height;
      final sizeShape = Random(i + 200).nextDouble() * 30 + 10;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), sizeShape / 2, shapePaint);
      } else if (i % 3 == 1) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: sizeShape, height: sizeShape),
          shapePaint,
        );
      } else {
        final path = Path()
          ..moveTo(x, y - sizeShape / 2)
          ..lineTo(x + sizeShape / 2, y + sizeShape / 2)
          ..lineTo(x - sizeShape / 2, y + sizeShape / 2)
          ..close();
        canvas.drawPath(path, shapePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle Painter
class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color highlightColor;
  final Color accentColor;

  _ParticlePainter({
    required this.animationValue,
    required this.highlightColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    final particleCount = 15;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animationValue + i / particleCount) % 1.0;
      final x = progress * size.width;
      final y = sin(progress * 2 * pi) * 50 + size.height * 0.3;

      final particleSize = 2 + sin(progress * 4 * pi) * 2;
      final opacity = 0.3 + sin(progress * 2 * pi) * 0.3;

      particlePaint.color = (i % 2 == 0 ? highlightColor : accentColor)
          .withOpacity(opacity);

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Geometric Logo Painter
class _GeometricLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color highlightColor;

  _GeometricLogoPainter({
    required this.primaryColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final basePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = highlightColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Main hexagon
    final hexagonPath = Path();
    const hexagonRadius = 30.0;
    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6;
      final x = center.dx + hexagonRadius * cos(angle);
      final y = center.dy + hexagonRadius * sin(angle);
      if (i == 0) {
        hexagonPath.moveTo(x, y);
      } else {
        hexagonPath.lineTo(x, y);
      }
    }
    hexagonPath.close();

    canvas.drawPath(hexagonPath, fillPaint);
    canvas.drawPath(hexagonPath, basePaint);

    // Inner circles
    canvas.drawCircle(center, 15, basePaint..strokeWidth = 2);
    canvas.drawCircle(center, 8, basePaint..strokeWidth = 1);

    // Tech lines
    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6;
      final innerX = center.dx + 15 * cos(angle);
      final innerY = center.dy + 15 * sin(angle);
      final outerX = center.dx + hexagonRadius * cos(angle);
      final outerY = center.dy + hexagonRadius * sin(angle);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        basePaint..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}