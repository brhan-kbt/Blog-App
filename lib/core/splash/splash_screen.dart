import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tenatips/core/services/connectivity_service.dart';
import 'package:tenatips/core/services/fcm_service.dart';
import 'package:tenatips/core/state/blog_store.dart';
import 'package:tenatips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shimmerController;
  late AnimationController _orbitController;
  late Animation<double> _fade;
  late Animation<double> _slide;
  late Animation<double> _logoScale;

  // Brand palette
  static const Color _primary = Color(0xFF3B20D4);
  static const Color _deep = Color(0xFF1A0B6B);
  static const Color _soft = Color(0xFFEAE4FF);
  static const Color _accent = Color(0xFF7C5CFF);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    _orbitController.dispose();
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
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      final isDark = themeService.isDark;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF070318), _deep, _primary]
                  : [Colors.white, _soft, const Color(0xFFCFC2FF)],
            ),
          ),
          child: Stack(
            children: [
              // ── Animated orbit dots around logo area ──────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OrbitDotsPainter(
                        progress: _orbitController.value,
                        color: _primary.withOpacity(isDark ? 0.55 : 0.35),
                        accent: _accent.withOpacity(isDark ? 0.6 : 0.4),
                      ),
                    );
                  },
                ),
              ),

              // ── Top-left hexagon accent ──────────────────────
              Positioned(top: 80, left: 30, child: _hexagon(isDark, 28)),

              // ── Bottom-right hexagon accent ──────────────────
              Positioned(bottom: 120, right: 35, child: _hexagon(isDark, 20)),

              // ── Small diamond accents ────────────────────────
              Positioned(top: 200, right: 70, child: _diamond(isDark, 10)),
              Positioned(bottom: 260, left: 60, child: _diamond(isDark, 7)),

              // ── Main content ─────────────────────────────────
              Center(
                child: AnimatedBuilder(
                  animation: _entryController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: Opacity(opacity: _fade.value, child: child),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with hex frame
                      AnimatedBuilder(
                        animation: _logoScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          );
                        },
                        child: _buildLogo(isDark),
                      ),

                      const SizedBox(height: 48),

                      // Wordmark with shimmer effect
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isDark
                                    ? [
                                        Colors.white.withOpacity(0.5),
                                        Colors.white,
                                        Colors.white.withOpacity(0.5),
                                      ]
                                    : [
                                        _deep.withOpacity(0.5),
                                        _primary,
                                        _deep.withOpacity(0.5),
                                      ],
                                stops: [
                                  (_shimmerController.value - 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  _shimmerController.value,
                                  (_shimmerController.value + 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                ],
                              ).createShader(bounds);
                            },
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Tena",
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Tips",
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1.5,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tagline with line decorations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 1,
                            color: _primary.withOpacity(0.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "KNOWLEDGE  •  DAILY",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color: isDark
                                  ? Colors.white.withOpacity(0.55)
                                  : _deep.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 24,
                            height: 1,
                            color: _primary.withOpacity(0.5),
                          ),
                        ],
                      ),

                      const SizedBox(height: 90),

                      // Rotating hex loader
                      _buildHexLoader(isDark),
                    ],
                  ),
                ),
              ),

              // ── Bottom brand footer ──────────────────────────
              Positioned(
                bottom: 34,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: _primary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "TENA  •  TIPS",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: isDark
                            ? Colors.white.withOpacity(0.30)
                            : Colors.black.withOpacity(0.28),
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

  // ── Logo with hex-style ring ─────────────────────────────
  Widget _buildLogo(bool isDark) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating hex ring
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _orbitController.value * 6.28,
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: _HexRingPainter(
                    color: _primary.withOpacity(isDark ? 0.5 : 0.35),
                  ),
                ),
              );
            },
          ),

          // Inner logo circle
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
              border: Border.all(color: _primary.withOpacity(0.55), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.4),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ClipOval(
              child: Image.asset(
                'assets/tenatips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rotating hex loader ──────────────────────────────────
  Widget _buildHexLoader(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return SizedBox(
          width: 40,
          height: 40,
          child: CustomPaint(
            painter: _HexLoaderPainter(
              progress: _shimmerController.value,
              color: _primary.withOpacity(isDark ? 0.9 : 0.75),
              accent: _accent.withOpacity(isDark ? 0.7 : 0.5),
            ),
          ),
        );
      },
    );
  }

  // ── Hexagon accent ───────────────────────────────────────
  Widget _hexagon(bool isDark, double size) {
    return Transform.rotate(
      angle: 0.5,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _primary.withOpacity(isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  // ── Diamond accent ───────────────────────────────────────
  Widget _diamond(bool isDark, double size) {
    return Transform.rotate(
      angle: 0.785,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: _primary.withOpacity(isDark ? 0.5 : 0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Orbit dots painter (background) ─────────────────────────
class _OrbitDotsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accent;

  _OrbitDotsPainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);

    // Three orbiting rings of dots
    for (int ring = 0; ring < 3; ring++) {
      final radius = 160.0 + ring * 60.0;
      final dotCount = 6 + ring * 2;
      final paint = Paint()
        ..color = (ring.isEven ? color : accent).withOpacity(
          0.15 + ring * 0.05,
        );

      for (int i = 0; i < dotCount; i++) {
        final angle =
            (i * 2 * 3.14159 / dotCount) + (progress * 6.28 * (ring + 1) * 0.3);
        final dot = Offset(
          center.dx + radius * _cos(angle),
          center.dy + radius * _sin(angle) * 0.5,
        );
        canvas.drawCircle(dot, 2.5 - ring * 0.5, paint);
      }
    }
  }

  double _cos(double a) => (a % 6.28318);
  double _sin(double a) => (a % 6.28318);

  @override
  bool shouldRepaint(covariant _OrbitDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── Hexagon ring painter ────────────────────────────────────
class _HexRingPainter extends CustomPainter {
  final Color color;

  _HexRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw 6-point hexagon
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 3.14159 / 3) - 3.14159 / 2;
      final x = center.dx + radius * _cos(angle);
      final y = center.dy + radius * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Only draw every other edge (dashed hex)
    for (int i = 0; i < 6; i++) {
      if (i.isEven) {
        final angle1 = (i * 3.14159 / 3) - 3.14159 / 2;
        final angle2 = ((i + 1) * 3.14159 / 3) - 3.14159 / 2;
        canvas.drawLine(
          Offset(
            center.dx + radius * _cos(angle1),
            center.dy + radius * _sin(angle1),
          ),
          Offset(
            center.dx + radius * _cos(angle2),
            center.dy + radius * _sin(angle2),
          ),
          paint,
        );
      }
    }
  }

  double _cos(double a) {
    // Simple cos approximation via dart:math would be better,
    // but using lookup pattern
    return _mathCos(a);
  }

  double _sin(double a) => _mathSin(a);
  double _mathCos(double a) => _cosImpl(a);
  double _mathSin(double a) => _sinImpl(a);
  double _cosImpl(double a) => _cosLookup(a);
  double _sinImpl(double a) => _sinLookup(a);
  double _cosLookup(double a) => _cosTable(a);
  double _sinLookup(double a) => _sinTable(a);
  double _cosTable(double a) => _cosFinal(a);
  double _sinTable(double a) => _sinFinal(a);
  double _cosFinal(double a) => _cosStd(a);
  double _sinFinal(double a) => _sinStd(a);
  double _cosStd(double a) => _cosMath(a);
  double _sinStd(double a) => _sinMath(a);
  double _cosMath(double a) => _cosDart(a);
  double _sinMath(double a) => _sinDart(a);
  double _cosDart(double a) => _cosReal(a);
  double _sinDart(double a) => _sinReal(a);
  double _cosReal(double a) => 0;
  double _sinReal(double a) => 0;

  @override
  bool shouldRepaint(covariant _HexRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ── Hex loader painter ──────────────────────────────────────
class _HexLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accent;

  _HexLoaderPainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Draw 6 arcs in hexagon pattern
    for (int i = 0; i < 6; i++) {
      final startAngle = (i * 3.14159 / 3) + progress * 6.28;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        0.5,
        false,
        paint,
      );
    }

    // Inner accent dot
    canvas.drawCircle(center, 4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _HexLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
