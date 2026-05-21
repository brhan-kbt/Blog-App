import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:superpro/core/services/connectivity_service.dart';
import 'package:superpro/core/services/fcm_service.dart';
import 'package:superpro/core/state/blog_store.dart';
import 'package:superpro/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scalePulseAnimation;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  late AnimationController _ringController;
  late List<Animation<double>> _ringAnimations;

  late AnimationController _textGlowController;
  late Animation<double> _textGlowAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initApp();
  }

  void _initAnimations() {
    // Main controller for overall timing
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeIn));

    _scalePulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    // Wave animation for decorative effect
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Ring expanding animations
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _ringAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ringController,
          curve: Interval(index * 0.3, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    // Text glow animation
    _textGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _textGlowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textGlowController, curve: Curves.easeInOut),
    );

    // Start main animation
    _mainController.forward();
  }

  Future<void> _initApp() async {
    try {
      if (Get.currentRoute == '/home') return;

      if (Get.isRegistered<FCMService>()) {
        final fcm = Get.find<FCMService>();
        if (fcm.hasNavigatedFromNotification) {
          Get.offAllNamed('/home');
          return;
        }
      }

      Get.put(ConnectivityService(), permanent: true);
      final connectivity = Get.find<ConnectivityService>();
      await connectivity.checkConnectivity();

      final blogStore = Get.find<BlogStore>();

      if (connectivity.isConnected) {
        await Future.wait([
          blogStore.fetchPosts(),
          blogStore.fetchCategories(),
        ]);
      }

      await _handleNotifications();
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      if (Get.isRegistered<FCMService>()) {
        final fcm = Get.find<FCMService>();
        if (fcm.isOnDetailPage()) return;
      }

      Get.offAllNamed('/home');
    } catch (e) {
      debugPrint("Splash Error: $e");
      if (mounted) Get.offAllNamed('/home');
    }
  }

  Future<void> _handleNotifications() async {
    if (!Get.isRegistered<FCMService>()) return;
    final fcm = Get.find<FCMService>();
    if (await fcm.hasPendingNotifications()) {
      await fcm.checkPendingNotifications();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _ringController.dispose();
    _textGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final primaryColor = const Color(0xFF145663);
    final secondaryColor = const Color(0xFF1A7A8C);
    final accentColor = const Color(0xFF2D9CAB);

    return Obx(() {
      final isDark = themeService.isDark;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0A1A1F),
                      primaryColor,
                      const Color(0xFF0D2F38),
                    ]
                  : [
                      const Color(0xFFE8F4F6),
                      const Color(0xFFD1E8ED),
                      const Color(0xFFB8DBE3),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Animated Wave Background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: WavePainter(
                        progress: _waveAnimation.value,
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),

              // Expanding Rings behind logo
              Center(
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          width: 100 + (200 * _ringAnimations[index].value),
                          height: 100 + (200 * _ringAnimations[index].value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(
                                0.3 * (1 - _ringAnimations[index].value),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    // Logo with pulse animation
                    // FadeTransition(
                    //   opacity: _fadeInAnimation,
                    //   child: ScaleTransition(
                    //     scale: _scalePulseAnimation,
                    //     child: Container(
                    //       width: 140,
                    //       height: 140,
                    //       decoration: BoxDecoration(
                    //         shape: BoxShape.circle,
                    //         gradient: LinearGradient(
                    //           begin: Alignment.topLeft,
                    //           end: Alignment.bottomRight,
                    //           colors: [
                    //             primaryColor,
                    //             secondaryColor,
                    //             accentColor,
                    //           ],
                    //         ),
                    //         boxShadow: [
                    //           BoxShadow(
                    //             color: primaryColor.withOpacity(0.6),
                    //             blurRadius: 40,
                    //             spreadRadius: 15,
                    //           ),
                    //         ],
                    //       ),
                    //       child: ClipOval(
                    //         child: Image.asset(
                    //           'assets/superpro_logo.png',
                    //           fit: BoxFit.contain,
                    //           width: 85,
                    //           height: 85,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 50),

                    // Animated Text with Glow
                    AnimatedBuilder(
                      animation: _textGlowAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  primaryColor,
                                  accentColor,
                                  secondaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                "SUPER PRO",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 6,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: primaryColor.withOpacity(
                                        0.5 * _textGlowAnimation.value,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              width: 60,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, accentColor],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "EXCELLENCE IN EVERY DETAIL",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                                color: isDark
                                    ? Colors.white60
                                    : primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(),

                    // Modern Loading Indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        children: [
                          // Circular progress indicator
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                              strokeWidth: 3,
                              backgroundColor: primaryColor.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "INITIALIZING",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                              color: isDark
                                  ? Colors.white38
                                  : primaryColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Custom Wave Painter for background effect
class WavePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isDark;

  WavePainter({
    required this.progress,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(isDark ? 0.1 : 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      final y =
          size.height *
          (0.7 +
              (0.1 * (progress * 2) * math.sin(i / size.width)) +
              (0.05 * (progress * 2) * math.cos(i / size.width)));
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
