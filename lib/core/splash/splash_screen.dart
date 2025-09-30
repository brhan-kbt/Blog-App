import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jara_tech/core/services/connectivity_service.dart';
import 'package:jara_tech/core/services/fcm_service.dart';
import 'package:jara_tech/core/state/blog_store.dart';
import 'package:jara_tech/core/theme/theme_service.dart';
import 'dart:ui'; // 👈 Needed for ImageFilter

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
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

      await Future.delayed(const Duration(milliseconds: 1500));

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
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final isDark = themeService.isDark;

    return Scaffold(
      body: Stack(
        children: [
          /// Animated Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xff0f2027),
                        const Color(0xff203a43),
                        const Color(0xff2c5364),
                      ]
                    : [
                        const Color(0xff1d976c),
                        const Color(0xff93f9b9),
                        const Color(0xff1d976c),
                      ],
              ),
            ),
          ),

          /// Floating Particles
          // Positioned.fill(child: CustomPaint(painter: _ParticlePainter())),
          Positioned.fill(child: AnimatedParticles()),

          /// Glassmorphism Center Card
          Center(
            child: FadeTransition(
              opacity: _logoController,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _logoController,
                  curve: Curves.elasticOut,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          "assets/jara_tech_logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// App Name + Tagline + Loader
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FadeTransition(
                opacity: _textController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Jara Tech",
                      style: TextStyle(
                        fontFamily: "Pacifico",
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tech Updates • Insights",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 30),

                    /// Custom Loading Bar
                    Container(
                      width: 180,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _textController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Particle Painter for floating dots
// class _ParticlePainter extends CustomPainter {
//   final Random _random = Random();
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white.withOpacity(0.3); // brighter
//     for (int i = 0; i < 80; i++) {
//       final dx = _random.nextDouble() * size.width;
//       final dy = _random.nextDouble() * size.height;
//       canvas.drawCircle(Offset(dx, dy), _random.nextDouble() * 4 + 2, paint); // larger
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

class AnimatedParticles extends StatefulWidget {
  const AnimatedParticles({super.key});

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<_Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles
    particles = List.generate(
      40,
      (_) => _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        dx: (_random.nextDouble() - 0.5) * 0.002,
        dy: (_random.nextDouble() - 0.5) * 0.002,
        size: _random.nextDouble() * 3 + 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(particles),
          child: Container(),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Particle {
  double x, y, dx, dy, size;
  _Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    for (var p in particles) {
      final dx = (p.x * size.width);
      final dy = (p.y * size.height);

      // update position
      p.x += p.dx;
      p.y += p.dy;

      // wrap around
      if (p.x < 0) p.x = 1;
      if (p.x > 1) p.x = 0;
      if (p.y < 0) p.y = 1;
      if (p.y > 1) p.y = 0;

      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
