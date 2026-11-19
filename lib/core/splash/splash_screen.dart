import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mega_tips/core/services/connectivity_service.dart';
import 'package:mega_tips/core/services/fcm_service.dart';
import 'package:mega_tips/core/state/blog_store.dart';
import 'package:mega_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep royal blue palette
  static const Color primaryColor = Color(0xFF03559A);
  static const Color royalBlue = Color(0xFF0A6BBF);
  static const Color brightBlue = Color(0xFF1E8DE0);
  static const Color skyBlue = Color(0xFF6BBEF0);
  static const Color paleBlue = Color(0xFFC9E8FA);
  static const Color midnightBlue = Color(0xFF011F38);

  late AnimationController _entryController;
  late AnimationController _starController;
  late AnimationController _orbitController;
  late AnimationController _shimmerController;
  late AnimationController _twinkleController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _starTwinkle;
  late Animation<double> _orbit;
  late Animation<double> _shimmer;
  late Animation<double> _twinkle;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _scaleIn = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _starTwinkle = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
    _orbit = Tween<double>(
      begin: 0.0,
      end: 6.28318,
    ).animate(CurvedAnimation(parent: _orbitController, curve: Curves.linear));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _twinkle = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _twinkleController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _starController.dispose();
    _orbitController.dispose();
    _shimmerController.dispose();
    _twinkleController.dispose();
    super.dispose();
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

      await Future.delayed(const Duration(milliseconds: 500));

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
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final size = MediaQuery.of(context).size;

    return Obx(() {
      final isDark = themeService.isDark;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF000C18),
                      midnightBlue,
                      const Color(0xFF022A4A),
                    ]
                  : [
                      const Color(0xFFF0F8FE),
                      paleBlue,
                      const Color(0xFF9BD5F5),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Star field background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _starTwinkle,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _StarFieldPainter(
                        color: (isDark ? Colors.white : primaryColor)
                            .withOpacity(isDark ? 0.5 : 0.25),
                        twinkle: _starTwinkle.value,
                      ),
                    );
                  },
                ),
              ),

              // Ambient radial glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _twinkle,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 0.9,
                          colors: [
                            (isDark ? primaryColor : brightBlue).withOpacity(
                              0.28 * _twinkle.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rotating orbit rings with planets
              Positioned(
                top: size.height * 0.5 - 220,
                left: size.width * 0.5 - 220,
                child: AnimatedBuilder(
                  animation: _orbit,
                  builder: (context, child) {
                    return Transform.rotate(angle: _orbit.value, child: child);
                  },
                  child: SizedBox(
                    width: 440,
                    height: 440,
                    child: CustomPaint(
                      painter: _OrbitPlanetPainter(
                        color: (isDark ? skyBlue : primaryColor).withOpacity(
                          isDark ? 0.20 : 0.12,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating star particles
              ..._buildStarParticles(isDark, size),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Celestial logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildCelestialLogo(isDark),
                        ),

                        const SizedBox(height: 44),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 14),

                        // Star divider
                        _buildStarDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 60),

                        // Orbit loader
                        _buildOrbitLoader(isDark),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom branding
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 11,
                        color: isDark
                            ? skyBlue.withOpacity(0.5)
                            : primaryColor.withOpacity(0.45),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "MEGA TIPS",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : primaryColor.withOpacity(0.55),
                          letterSpacing: 5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_awesome,
                        size: 11,
                        color: isDark
                            ? skyBlue.withOpacity(0.5)
                            : primaryColor.withOpacity(0.45),
                      ),
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

  List<Widget> _buildStarParticles(bool isDark, Size size) {
    final particles = [
      _StarParticle(size.width * 0.08, size.height * 0.18, 3.0, 0.0),
      _StarParticle(size.width * 0.90, size.height * 0.25, 4.0, 1.2),
      _StarParticle(size.width * 0.05, size.height * 0.70, 2.5, 0.5),
      _StarParticle(size.width * 0.94, size.height * 0.65, 3.5, 1.8),
      _StarParticle(size.width * 0.20, size.height * 0.88, 2.0, 0.9),
      _StarParticle(size.width * 0.80, size.height * 0.12, 3.0, 2.2),
      _StarParticle(size.width * 0.45, size.height * 0.08, 2.5, 1.5),
      _StarParticle(size.width * 0.68, size.height * 0.94, 3.0, 0.3),
    ];

    return particles.map((p) {
      return Positioned(
        left: p.x - p.size / 2,
        top: p.y - p.size / 2,
        child: AnimatedBuilder(
          animation: _starController,
          builder: (context, _) {
            final twinkleValue =
                (0.3 + 0.7 * ((_starTwinkle.value + p.phase) % 1.0)).clamp(
                  0.0,
                  1.0,
                );
            return Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : primaryColor).withOpacity(
                  0.6 * twinkleValue,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? skyBlue : brightBlue).withOpacity(
                      0.6 * twinkleValue,
                    ),
                    blurRadius: p.size * 3,
                    spreadRadius: p.size,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildCelestialLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _twinkle,
      builder: (context, child) {
        return Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : brightBlue).withOpacity(
                  0.4 * _twinkle.value,
                ),
                blurRadius: 60,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer gradient ring
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isDark
                    ? [
                        primaryColor,
                        brightBlue,
                        skyBlue,
                        brightBlue,
                        primaryColor,
                      ]
                    : [
                        primaryColor,
                        royalBlue,
                        brightBlue,
                        royalBlue,
                        primaryColor,
                      ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // Middle ring
          Container(
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? midnightBlue : Colors.white,
            ),
          ),

          // Inner radial gradient
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [primaryColor.withOpacity(0.5), midnightBlue]
                    : [Colors.white, paleBlue],
              ),
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(14),
              color: isDark ? midnightBlue : Colors.white,
              child: Image.asset(
                'assets/mega_tips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Sparkle accents around the ring
          ..._buildSparkleAccents(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildSparkleAccents(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.star,
              size: 13,
              color: isDark ? skyBlue : Colors.white,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildShimmerTitle(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [Colors.white, skyBlue, Colors.white, skyBlue, Colors.white]
                  : [
                      primaryColor,
                      brightBlue,
                      primaryColor,
                      brightBlue,
                      primaryColor,
                    ],
              stops: [
                (_shimmer.value - 0.3).clamp(0.0, 1.0),
                (_shimmer.value).clamp(0.0, 1.0),
                (_shimmer.value + 0.3).clamp(0.0, 1.0),
                (_shimmer.value + 0.6).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Column(
            children: [
              Text(
                "MEGA",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 14,
                  color: isDark ? Colors.white.withOpacity(0.85) : primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "TIPS",
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 20,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarDivider(bool isDark) {
    final color = isDark ? skyBlue : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, color.withOpacity(0.6)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.star, size: 10, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Icon(Icons.auto_awesome, size: 14, color: color),
        const SizedBox(width: 6),
        Icon(Icons.star, size: 10, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.6), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      "Explore  ·  Learn  ·  Shine",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: isDark
            ? paleBlue.withOpacity(0.6)
            : primaryColor.withOpacity(0.6),
      ),
    );
  }

  Widget _buildOrbitLoader(bool isDark) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer twinkling ring
          AnimatedBuilder(
            animation: _twinkle,
            builder: (context, _) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? primaryColor : brightBlue).withOpacity(
                      0.15 + 0.2 * _twinkle.value,
                    ),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          // Spinning arc
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? skyBlue : primaryColor,
              ),
            ),
          ),
          // Center star
          Icon(Icons.star, size: 16, color: isDark ? skyBlue : primaryColor),
        ],
      ),
    );
  }
}

/// Data holder for star particles
class _StarParticle {
  final double x;
  final double y;
  final double size;
  final double phase;

  const _StarParticle(this.x, this.y, this.size, this.phase);
}

/// Painter for the twinkling star field background
class _StarFieldPainter extends CustomPainter {
  final Color color;
  final double twinkle;

  _StarFieldPainter({required this.color, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    // Generate deterministic star positions
    final random = _SimpleRandom(42);

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = 0.5 + random.nextDouble() * 1.5;

      // Each star twinkles at a slightly different phase
      final phase = random.nextDouble() * 3.14159 * 2;
      final starTwinkle =
          (0.3 +
                  0.7 *
                      ((twinkle * 3.14159 + phase) % (3.14159 * 2)) /
                      (3.14159 * 2))
              .clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(starTwinkle)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.twinkle != twinkle || oldDelegate.color != color;
}

/// Simple deterministic pseudo-random generator for stars
class _SimpleRandom {
  int _seed;
  _SimpleRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 9301 + 49297) % 233280;
    return _seed / 233280.0;
  }
}

/// Painter for the rotating orbit ring with planet dots
class _OrbitPlanetPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _OrbitPlanetPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer orbit ring
    canvas.drawCircle(center, size.width * 0.46, paint);

    // Middle dashed ring
    paint.strokeWidth = 0.7;
    _drawDashedCircle(canvas, center, size.width * 0.39, paint);

    // Inner faint ring
    paint.strokeWidth = 1.2;
    canvas.drawCircle(center, size.width * 0.32, paint);

    // Planet dots on outer ring
    const planetCount = 5;
    for (int i = 0; i < planetCount; i++) {
      final angle = (2 * 3.14159 / planetCount) * i;
      final planetX = center.dx + size.width * 0.46 * _cos(angle);
      final planetY = center.dy + size.width * 0.46 * _sin(angle);

      // Alternate planet sizes and styles
      if (i == 0) {
        // Larger glowing planet
        final glowPaint = Paint()
          ..color = color.withOpacity(isDark ? 0.5 : 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(planetX, planetY), 5.0, glowPaint);
      } else if (i % 2 == 0) {
        canvas.drawCircle(
          Offset(planetX, planetY),
          3.5,
          Paint()
            ..color = color.withOpacity(isDark ? 0.6 : 0.4)
            ..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawCircle(
          Offset(planetX, planetY),
          2.5,
          Paint()
            ..color = color.withOpacity(isDark ? 0.4 : 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 12.0;
    const gapLength = 16.0;
    final circumference = 2 * 3.14159 * radius;
    final totalSegments = circumference / (dashLength + gapLength);
    final anglePerSegment = 2 * 3.14159 / totalSegments;

    for (int i = 0; i < totalSegments; i++) {
      final startAngle = i * anglePerSegment;
      final endAngle = startAngle + anglePerSegment * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 1.5708);

  double _taylorSin(double x) {
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    if (x < -3.14159265) x += 2 * 3.14159265;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  @override
  bool shouldRepaint(covariant _OrbitPlanetPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
