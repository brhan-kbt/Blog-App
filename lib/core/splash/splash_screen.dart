import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habesha_tech/core/services/connectivity_service.dart';
import 'package:habesha_tech/core/services/fcm_service.dart';
import 'package:habesha_tech/core/state/blog_store.dart';
import 'package:habesha_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _patternController;
  late AnimationController _textRevealController;
  late AnimationController _ethiopianSymbolController;
  late Animation<double> _patternAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _symbolAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Full width pattern animation
    _patternController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _patternAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _patternController,
      curve: Curves.easeInOut,
    ));

    // Text reveal animation
    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _textRevealController,
      curve: Curves.easeOutCubic,
    ));

    // Ethiopian symbol animation
    _ethiopianSymbolController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _symbolAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _ethiopianSymbolController,
      curve: Curves.elasticOut,
    ));

    // Start sequenced animations
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _ethiopianSymbolController.forward();
    await _textRevealController.forward();
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

      await Future.delayed(const Duration(milliseconds: 2500));

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
    _patternController.dispose();
    _textRevealController.dispose();
    _ethiopianSymbolController.dispose();
    super.dispose();
  }

  // Full-width Ethiopian Pattern
  Widget _buildFullWidthPattern() {
    return AnimatedBuilder(
      animation: _patternAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _patternAnimation.value * 30),
          child: SizedBox(
            width: double.infinity,
            height: 150,
            child: CustomPaint(
              painter: _FullWidthEthiopianPatternPainter(),
            ),
          ),
        );
      },
    );
  }

  // Full-width Tech Circuit Background
  Widget _buildFullWidthTechCircuit() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _FullWidthTechCircuitPainter(),
      ),
    );
  }

  // Ethiopian Symbol with full-width context
  Widget _buildEthiopianSymbol() {
    return AnimatedBuilder(
      animation: _symbolAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _symbolAnimation.value,
          child: Transform.rotate(
            angle: _symbolAnimation.value * 2 * 3.14159,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _EthiopianCrossPainter(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Obx(() {
        final isDark = themeService.isDark;
        return Stack(
          children: [
            // Full-width background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xff0a1a1c),
                          const Color(0xff0d2a2d),
                          const Color(0xff123437),
                          const Color(0xff0a1f21),
                        ]
                      : [
                          const Color(0xff195158),
                          const Color(0xff32a1af),
                          const Color(0xff1a5d66),
                          const Color(0xff0d2a2d),
                        ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Full-width tech circuit background
            _buildFullWidthTechCircuit(),

            // Full-width top pattern
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFullWidthPattern(),
            ),

            // Full-width bottom pattern (rotated)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Transform.rotate(
                angle: 3.14159, // 180 degrees
                child: _buildFullWidthPattern(),
              ),
            ),

            // Side patterns for complete immersion
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: 1.5708, // 90 degrees
                child: SizedBox(
                  width: 150,
                  child: _buildFullWidthPattern(),
                ),
              ),
            ),

            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: -1.5708, // -90 degrees
                child: SizedBox(
                  width: 150,
                  child: _buildFullWidthPattern(),
                ),
              ),
            ),

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

                    // Central symbol with full-width context
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer tech ring that spans more width
                        AnimatedBuilder(
                          animation: _patternController,
                          builder: (context, child) {
                            return Container(
                              width: screenWidth * 0.4,
                              height: screenWidth * 0.4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.4),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircularProgressIndicator(
                                value: _patternController.value,
                                strokeWidth: 2,
                                color: Colors.amber,
                                backgroundColor: Colors.transparent,
                              ),
                            );
                          },
                        ),

                        // Ethiopian symbol
                        _buildEthiopianSymbol(),

                        // Tech dots around the symbol - full circle
                        ...List.generate(12, (index) {
                          final angle = (index / 12) * 2 * 3.14159;
                          final distance = screenWidth * 0.18;
                          return Positioned(
                            left: distance * cos(angle) + screenWidth * 0.5 - 50,
                            top: distance * sin(angle) + screenWidth * 0.2,
                            child: AnimatedBuilder(
                              animation: _patternController,
                              builder: (context, child) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index % 3 == 0 
                                      ? Colors.green 
                                      : index % 3 == 1 
                                        ? Colors.amber 
                                        : Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (index % 3 == 0 
                                          ? Colors.green 
                                          : index % 3 == 1 
                                            ? Colors.amber 
                                            : Colors.red).withOpacity(0.7),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // App Name with full-width emphasis
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
                                    "HABESHA TECH",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.08,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                      color: Colors.white,
                                      fontFamily: "Roboto",
                                      shadows: [
                                        Shadow(
                                          blurRadius: 15,
                                          color: Colors.amber.withOpacity(0.6),
                                        ),
                                        Shadow(
                                          blurRadius: 30,
                                          color: Colors.green.withOpacity(0.4),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedBuilder(
                                animation: _textAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _textAnimation.value,
                                    child: Text(
                                      "Where Innovation Meets Heritage",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: screenWidth * 0.035,
                                        letterSpacing: 2,
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

                    // Full-width loading bar
                    Container(
                      width: screenWidth * 0.6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.white.withOpacity(0.2),
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
                          // Animated progress - full width movement
                          AnimatedBuilder(
                            animation: _patternController,
                            builder: (context, child) {
                              return Container(
                                width: screenWidth * 0.6 * _patternController.value,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.amber,
                                      Colors.red,
                                      Colors.green,
                                    ],
                                    stops: [0.0, 0.4, 0.7, 1.0],
                                    tileMode: TileMode.mirror,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 10,
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

                    // Loading text
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// Full-width Ethiopian Pattern Painter
class _FullWidthEthiopianPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const patternSize = 50.0;
    final columns = (size.width / patternSize).ceil();
    final rows = (size.height / patternSize).ceil();

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        final x = i * patternSize;
        final y = j * patternSize;

        // Draw interconnected Ethiopian cross pattern
        final path = Path();
        
        // Main cross
        path.moveTo(x + patternSize / 2, y);
        path.lineTo(x + patternSize, y + patternSize / 2);
        path.lineTo(x + patternSize / 2, y + patternSize);
        path.lineTo(x, y + patternSize / 2);
        path.close();

        // Inner decorative elements
        path.moveTo(x + patternSize / 4, y + patternSize / 4);
        path.lineTo(x + patternSize * 3 / 4, y + patternSize / 4);
        path.lineTo(x + patternSize * 3 / 4, y + patternSize * 3 / 4);
        path.lineTo(x + patternSize / 4, y + patternSize * 3 / 4);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Full-width Tech Circuit Painter
class _FullWidthTechCircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final circuitSize = 80.0;
    final columns = (size.width / circuitSize).ceil();
    final rows = (size.height / circuitSize).ceil();

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        final x = i * circuitSize;
        final y = j * circuitSize;

        // Draw interconnected circuit lines
        if (i < columns - 1) {
          canvas.drawLine(
            Offset(x + circuitSize, y + circuitSize / 2),
            Offset(x + circuitSize * 1.5, y + circuitSize / 2),
            paint,
          );
        }

        if (j < rows - 1) {
          canvas.drawLine(
            Offset(x + circuitSize / 2, y + circuitSize),
            Offset(x + circuitSize / 2, y + circuitSize * 1.5),
            paint,
          );
        }

        // Circuit nodes
        canvas.drawCircle(
          Offset(x + circuitSize / 2, y + circuitSize / 2),
          2,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Ethiopian Cross Painter (unchanged)
class _EthiopianCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    const crossSize = 40.0;

    // Draw elaborate Ethiopian cross
    final path = Path();
    
    // Main cross arms
    path.moveTo(center.dx, center.dy - crossSize / 2);
    path.lineTo(center.dx + crossSize / 3, center.dy - crossSize / 6);
    path.lineTo(center.dx + crossSize / 2, center.dy);
    path.lineTo(center.dx + crossSize / 3, center.dy + crossSize / 6);
    path.lineTo(center.dx, center.dy + crossSize / 2);
    path.lineTo(center.dx - crossSize / 3, center.dy + crossSize / 6);
    path.lineTo(center.dx - crossSize / 2, center.dy);
    path.lineTo(center.dx - crossSize / 3, center.dy - crossSize / 6);
    path.close();

    canvas.drawPath(path, paint);

    // Inner decorative circle
    canvas.drawCircle(center, crossSize / 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}