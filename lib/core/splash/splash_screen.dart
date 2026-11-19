import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selam_pro/core/services/connectivity_service.dart';
import 'package:selam_pro/core/services/fcm_service.dart';
import 'package:selam_pro/core/state/blog_store.dart';
import 'package:selam_pro/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep teal palette with warm lantern glow
  static const Color primaryColor = Color(0xFF04888F);
  static const Color brightTeal = Color(0xFF06B0B9);
  static const Color softTeal = Color(0xFF6FD4DB);
  static const Color paleTeal = Color(0xFFD4F3F5);
  static const Color deepTeal = Color(0xFF025A5F);
  static const Color abyssTeal = Color(0xFF012E31);
  static const Color warmGlow = Color(0xFFFFE9B8);

  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _rayController;
  late AnimationController _shimmerController;
  late AnimationController _driftController;
  late AnimationController _sparkleController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _glow;
  late Animation<double> _rayRotation;
  late Animation<double> _shimmer;
  late Animation<double> _drift;
  late Animation<double> _sparkle;

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
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
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

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _rayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();
    _rayRotation = Tween<double>(begin: 0.0, end: 6.28318).animate(
      CurvedAnimation(parent: _rayController, curve: Curves.linear),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _drift = Tween<double>(begin: 0.0, end: 6.28318).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.linear),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _sparkle = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _rayController.dispose();
    _shimmerController.dispose();
    _driftController.dispose();
    _sparkleController.dispose();
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
                      const Color(0xFF001416),
                      abyssTeal,
                      const Color(0xFF024347),
                    ]
                  : [
                      const Color(0xFFF2FCFD),
                      paleTeal,
                      const Color(0xFFA8E4E9),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Warm inner glow (lantern effect)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 0.75,
                          colors: [
                            (isDark ? warmGlow : brightTeal)
                                .withOpacity(0.18 * _glow.value),
                            (isDark ? primaryColor : brightTeal)
                                .withOpacity(0.08 * _glow.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rotating light rays behind logo
              Positioned(
                top: size.height * 0.5 - 250,
                left: size.width * 0.5 - 250,
                child: AnimatedBuilder(
                  animation: _rayRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rayRotation.value,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 500,
                    height: 500,
                    child: CustomPaint(
                      painter: _LightRayPainter(
                        color: (isDark ? warmGlow : softTeal)
                            .withOpacity(isDark ? 0.06 : 0.08),
                      ),
                    ),
                  ),
                ),
              ),

              // Drifting concentric arcs
              Positioned(
                top: size.height * 0.5 - 230,
                left: size.width * 0.5 - 230,
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) {
                    return SizedBox(
                      width: 460,
                      height: 460,
                      child: CustomPaint(
                        painter: _DriftArcPainter(
                          progress: _drift.value,
                          color: (isDark ? softTeal : primaryColor)
                              .withOpacity(isDark ? 0.14 : 0.08),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Floating sparkle particles
              ..._buildSparkleParticles(isDark, size),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lantern-style logo with glow
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildLanternLogo(isDark),
                        ),

                        const SizedBox(height: 48),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 14),

                        // Ornamental divider
                        _buildOrnamentalDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 62),

                        // Lantern loader
                        _buildLanternLoader(isDark),
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
                        Icons.nights_stay,
                        size: 11,
                        color: isDark
                            ? softTeal.withOpacity(0.5)
                            : primaryColor.withOpacity(0.45),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SELAM PRO",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : primaryColor.withOpacity(0.55),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.nights_stay,
                        size: 11,
                        color: isDark
                            ? softTeal.withOpacity(0.5)
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

  List<Widget> _buildSparkleParticles(bool isDark, Size size) {
    final particles = [
      _Sparkle(size.width * 0.10, size.height * 0.18, 3.0, 0.0),
      _Sparkle(size.width * 0.88, size.height * 0.26, 4.0, 1.2),
      _Sparkle(size.width * 0.06, size.height * 0.68, 2.5, 0.5),
      _Sparkle(size.width * 0.93, size.height * 0.62, 3.5, 1.8),
      _Sparkle(size.width * 0.22, size.height * 0.88, 2.0, 0.9),
      _Sparkle(size.width * 0.78, size.height * 0.12, 3.0, 2.2),
      _Sparkle(size.width * 0.46, size.height * 0.08, 2.5, 1.5),
      _Sparkle(size.width * 0.66, size.height * 0.94, 3.0, 0.3),
    ];

    return particles.map((p) {
      return Positioned(
        left: p.x - p.size / 2,
        top: p.y - p.size / 2,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, _) {
            final sparkleValue =
                (0.3 + 0.7 * ((_sparkle.value + p.phase) % 1.0)).clamp(0.0, 1.0);
            return Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? warmGlow : primaryColor)
                    .withOpacity(0.7 * sparkleValue),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? warmGlow : brightTeal)
                        .withOpacity(0.6 * sparkleValue),
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

  Widget _buildLanternLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          width: 172,
          height: 172,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Warm inner glow
              BoxShadow(
                color: (isDark ? warmGlow : brightTeal)
                    .withOpacity(0.45 * _glow.value),
                blurRadius: 60,
                spreadRadius: 18,
              ),
              // Cool outer shadow
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
          // Outer glow ring with warm gradient
          Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isDark
                    ? [
                        primaryColor,
                        warmGlow,
                        brightTeal,
                        warmGlow,
                        primaryColor,
                      ]
                    : [
                        deepTeal,
                        primaryColor,
                        brightTeal,
                        primaryColor,
                        deepTeal,
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
              color: isDark ? abyssTeal : Colors.white,
            ),
          ),

          // Inner radial gradient (warm light)
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        warmGlow.withOpacity(0.25),
                        primaryColor.withOpacity(0.4),
                        abyssTeal,
                      ]
                    : [
                        Colors.white,
                        paleTeal,
                      ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(14),
              color: isDark ? abyssTeal : Colors.white,
              child: Image.asset(
                'assets/selam_pro_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Ornamental accents at cardinal points
          ..._buildLanternOrnaments(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildLanternOrnaments(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: CustomPaint(
              size: const Size(14, 14),
              painter: _DiamondOrnamentPainter(
                color: isDark ? warmGlow : Colors.white,
                glowColor: isDark ? warmGlow : brightTeal,
              ),
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
                  ? [
                      Colors.white,
                      warmGlow,
                      Colors.white,
                      softTeal,
                      Colors.white,
                    ]
                  : [
                      deepTeal,
                      primaryColor,
                      deepTeal,
                      primaryColor,
                      deepTeal,
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
                "SELAM",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.85)
                      : deepTeal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "PRO",
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 24,
                  color: isDark ? Colors.white : deepTeal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrnamentalDivider(bool isDark) {
    final color = isDark ? warmGlow : primaryColor;
    final accentColor = isDark ? softTeal : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, accentColor.withOpacity(0.6)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor.withOpacity(0.6), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      "Illuminate  ·  Discover  ·  Rise",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: isDark
            ? paleTeal.withOpacity(0.6)
            : deepTeal.withOpacity(0.6),
      ),
    );
  }

  Widget _buildLanternLoader(bool isDark) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing ring
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? warmGlow : brightTeal)
                        .withOpacity(0.15 + 0.25 * _glow.value),
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
                isDark ? softTeal : primaryColor,
              ),
            ),
          ),
          // Center diamond
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: isDark ? warmGlow : primaryColor,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? warmGlow : brightTeal)
                        .withOpacity(0.7),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data holder for sparkle particles
class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double phase;

  const _Sparkle(this.x, this.y, this.size, this.phase);
}

/// Painter for rotating light rays behind the logo
class _LightRayPainter extends CustomPainter {
  final Color color;

  _LightRayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const rayCount = 16;
    for (int i = 0; i < rayCount; i++) {
      final angle = (2 * 3.14159 / rayCount) * i;
      final rayLength = size.width * 0.48;
      final rayWidth = 0.05;

      final path = Path();
      path.moveTo(
        center.dx + size.width * 0.18 * _cos(angle - rayWidth),
        center.dy + size.width * 0.18 * _sin(angle - rayWidth),
      );
      path.lineTo(
        center.dx + rayLength * _cos(angle),
        center.dy + rayLength * _sin(angle),
      );
      path.lineTo(
        center.dx + size.width * 0.18 * _cos(angle + rayWidth),
        center.dy + size.width * 0.18 * _sin(angle + rayWidth),
      );
      path.close();

      canvas.drawPath(path, paint);
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
  bool shouldRepaint(covariant _LightRayPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Painter for drifting concentric arcs
class _DriftArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DriftArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Three rotating arc segments at different radii
    for (int i = 0; i < 3; i++) {
      final baseRadius = size.width * (0.28 + i * 0.09);
      final opacity = 0.6 - i * 0.15;
      paint.color = color.withOpacity(opacity);

      final startAngle = progress + i * 1.5;
      final sweepAngle = 1.2 + i * 0.4;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: baseRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Outer dashed ring
    paint.strokeWidth = 0.6;
    paint.color = color.withOpacity(0.3);
    _drawDashedCircle(canvas, center, size.width * 0.44, paint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 6.0;
    const gapLength = 14.0;
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

  @override
  bool shouldRepaint(covariant _DriftArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Painter for diamond ornaments at the ring edges
class _DiamondOrnamentPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  _DiamondOrnamentPainter({required this.color, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 4, glowPaint);

    // Diamond shape
    final path = Path()
      ..moveTo(center.dx, center.dy - 5)
      ..lineTo(center.dx + 4, center.dy)
      ..lineTo(center.dx, center.dy + 5)
      ..lineTo(center.dx - 4, center.dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondOrnamentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glowColor != glowColor;
}