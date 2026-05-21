import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qarotech/core/services/connectivity_service.dart';
import 'package:qarotech/core/services/fcm_service.dart';
import 'package:qarotech/core/state/blog_store.dart';
import 'package:qarotech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  late AnimationController _leafController;
  late List<Animation<double>> _leafAnimations;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initApp();
  }

  void _initAnimations() {
    // Main controller for overall timing
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    // Glow animation for logo
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Leaf particle animations
    _leafController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _leafAnimations = List.generate(6, (index) {
      final startDelay = index * 0.166;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _leafController,
          curve: Interval(startDelay, 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    // Progress animation for loading
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start main animation
    _mainController.forward();
    _progressController.forward();
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
    _glowController.dispose();
    _leafController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final primaryGreen = const Color(0xFF1B5E20);
    const darkGreen = Color(0xFF0D3B0F);
    const lightGreen = Color(0xFF2E7D32);
    const accentGreen = Color(0xFF4CAF50);
    const forestGreen = Color(0xFF228B22);
    const emeraldGreen = Color(0xFF50C878);

    return Obx(() {
      final isDark = themeService.isDark;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0A1A0A), darkGreen, primaryGreen]
                  : [
                      const Color(0xFFF0F7F0),
                      const Color(0xFFE8F5E9),
                      const Color(0xFFC8E6C9),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative leaf patterns
              ...List.generate(20, (index) {
                return Positioned(
                  left: (index * 53) % MediaQuery.of(context).size.width,
                  top: (index * 37) % MediaQuery.of(context).size.height,
                  child: AnimatedBuilder(
                    animation: _leafController,
                    builder: (context, child) {
                      final opacity = (index % 10) / 15;
                      return Transform.rotate(
                        angle: (index * 25) * math.pi / 180,
                        child: Icon(
                          Icons.eco,
                          color: lightGreen.withOpacity(opacity * 0.3),
                          size: 15 + (index % 10),
                        ),
                      );
                    },
                  ),
                );
              }),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with Growth Effect
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow rings
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 150 + (20 * _glowAnimation.value),
                                  height: 150 + (20 * _glowAnimation.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryGreen.withOpacity(
                                          0.3 * _glowAnimation.value,
                                        ),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Main logo container
                          // Container(
                          //   width: 130,
                          //   height: 130,
                          //   decoration: BoxDecoration(
                          //     shape: BoxShape.circle,
                          //     gradient: LinearGradient(
                          //       begin: Alignment.topLeft,
                          //       end: Alignment.bottomRight,
                          //       colors: [
                          //         forestGreen,
                          //         primaryGreen,
                          //         darkGreen,
                          //       ],
                          //     ),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: primaryGreen.withOpacity(0.6),
                          //         blurRadius: 30,
                          //         spreadRadius: 10,
                          //       ),
                          //     ],
                          //     border: Border.all(
                          //       color: accentGreen.withOpacity(0.5),
                          //       width: 2,
                          //     ),
                          //   ),
                          //   child: ClipOval(
                          //     child: Image.asset(
                          //       'assets/qarotech_logo.png',
                          //       fit: BoxFit.contain,
                          //       width: 80,
                          //       height: 80,
                          //     ),
                          //   ),
                          // ),

                            // Floating leaf particles around logo
                            ...List.generate(6, (index) {
                              final angle = (index * 60) * math.pi / 180;
                              return AnimatedBuilder(
                                animation: _leafAnimations[index],
                                builder: (context, child) {
                                  final progress = _leafAnimations[index].value;
                                  final distance =
                                      85 + (25 * (1 - progress).abs());
                                  final x = distance * math.cos(angle);
                                  final y = distance * math.sin(angle);

                                  return Positioned(
                                    left: 130 + x,
                                    top: 130 + y,
                                    child: Opacity(
                                      opacity: 0.3 + (0.7 * (1 - progress)),
                                      child: Transform.rotate(
                                        angle: progress * math.pi * 2,
                                        child: Icon(
                                          Icons.eco,
                                          color: emeraldGreen,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Animated Text with Nature Theme
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [primaryGreen, accentGreen, emeraldGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            "QARO TECH",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: primaryGreen.withOpacity(0.8),
                                  blurRadius: 15,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [lightGreen, accentGreen],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.eco, color: accentGreen, size: 18),
                            const SizedBox(width: 10),
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accentGreen, lightGreen],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Text(
                              "GROWING WITH INNOVATION",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                                color: isDark
                                    ? Colors.white70
                                    : primaryGreen.withOpacity(
                                        0.7 + (0.3 * _glowAnimation.value),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Nature-inspired Loading Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        children: [
                          // Animated growing bar (like a plant growing)
                          Container(
                            width: 150,
                            height: 3,
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [lightGreen, accentGreen],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentGreen,
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Animated leaves for loading indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGrowingLeaf(primaryGreen, 0),
                              const SizedBox(width: 8),
                              _buildGrowingLeaf(primaryGreen, 1),
                              const SizedBox(width: 8),
                              _buildGrowingLeaf(primaryGreen, 2),
                            ],
                          ),
                          const SizedBox(height: 15),

                          Text(
                            "CULTIVATING EXCELLENCE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: isDark
                                  ? Colors.white60
                                  : primaryGreen.withOpacity(0.7),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Percentage text
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              final percentage =
                                  (_progressAnimation.value * 100).toInt();
                              return Text(
                                "$percentage%",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: accentGreen,
                                  letterSpacing: 1,
                                ),
                              );
                            },
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

  Widget _buildGrowingLeaf(Color color, int index) {
    return AnimatedBuilder(
      animation: _leafController,
      builder: (context, child) {
        final delay = index * 0.33;
        final value = (_leafController.value + delay) % 1.0;
        final scale = 0.5 + (value * 0.8);
        final opacity = 0.3 + (value * 0.7);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5 * opacity),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
