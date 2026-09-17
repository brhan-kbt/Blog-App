import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tenatech/core/services/connectivity_service.dart';
import 'package:tenatech/core/services/fcm_service.dart';
import 'package:tenatech/core/state/blog_store.dart';
import 'package:tenatech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _fade;
  late Animation<double> _slide;
  late Animation<double> _logoScale;

  // Brand palette
  static const Color _primary = Color(0xFF0066E6);
  static const Color _deep = Color(0xFF002B66);
  static const Color _soft = Color(0xFFE5F0FF);
  static const Color _cyan = Color(0xFF35B7FF);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

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
    _scanController.dispose();
    _pulseController.dispose();
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
                  ? [const Color(0xFF020A1A), _deep, _primary]
                  : [Colors.white, _soft, const Color(0xFFBFDBFF)],
            ),
          ),
          child: Stack(
            children: [
              // ── Animated grid background ────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _GridPainter(
                        color: _primary.withOpacity(isDark ? 0.10 : 0.06),
                      ),
                    );
                  },
                ),
              ),

              // ── Horizontal scan line sweeping down ──────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ScanLinePainter(
                        progress: _scanController.value,
                        color: _cyan.withOpacity(isDark ? 0.35 : 0.25),
                      ),
                    );
                  },
                ),
              ),

              // ── Big pulse glow behind logo ──────────────────
              Positioned(
                top: MediaQuery.of(context).size.height * 0.16,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final v = 0.9 + (_pulseController.value * 0.2);
                      return Container(
                        width: 300 * v,
                        height: 300 * v,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _primary.withOpacity(isDark ? 0.30 : 0.20),
                              _primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Corner brackets (tech frame) ────────────────
              Positioned(
                top: 50,
                left: 30,
                child: _cornerBracket(isDark, false, false),
              ),
              Positioned(
                top: 50,
                right: 30,
                child: _cornerBracket(isDark, true, false),
              ),
              Positioned(
                bottom: 50,
                left: 30,
                child: _cornerBracket(isDark, false, true),
              ),
              Positioned(
                bottom: 50,
                right: 30,
                child: _cornerBracket(isDark, true, true),
              ),

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
                      // Logo with rotating arcs
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

                      const SizedBox(height: 46),

                      // Tech wordmark
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Tena",
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white : _deep,
                              ),
                            ),
                            TextSpan(
                              text: "Tech",
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? _cyan.withOpacity(0.95)
                                    : _primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tech-flavored tagline with monospace vibe
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isDark
                              ? _primary.withOpacity(0.15)
                              : _primary.withOpacity(0.08),
                          border: Border.all(
                            color: _primary.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _cyan,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "BUILD  •  CONNECT  •  SCALE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.4,
                                color: isDark
                                    ? Colors.white.withOpacity(0.88)
                                    : _deep,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 84),

                      // Segmented tech loader
                      _buildTechLoader(isDark),
                    ],
                  ),
                ),
              ),

              // ── Bottom system status footer ──────────────────
              Positioned(
                bottom: 34,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statusDot(_cyan),
                        const SizedBox(width: 6),
                        _statusDot(_primary.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        _statusDot(_primary.withOpacity(0.4)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "SYSTEM  INITIALIZING",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: isDark
                            ? Colors.white.withOpacity(0.32)
                            : Colors.black.withOpacity(0.30),
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

  // ── Logo with rotating tech arcs ─────────────────────────
  Widget _buildLogo(bool isDark) {
    return SizedBox(
      width: 175,
      height: 175,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating arcs
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(175, 175),
                painter: _ArcRingPainter(
                  progress: _scanController.value,
                  color: _primary.withOpacity(isDark ? 0.55 : 0.40),
                  accent: _cyan.withOpacity(isDark ? 0.6 : 0.45),
                ),
              );
            },
          ),

          // Logo circle
          Container(
            width: 134,
            height: 134,
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
            padding: const EdgeInsets.all(15),
            child: ClipOval(
              child: Image.asset(
                'assets/tenatech_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented tech loader ────────────────────────────────
  Widget _buildTechLoader(bool isDark) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final phase = (_scanController.value + i * 0.08) % 1.0;
              final active = phase < 0.5;
              final intensity = active ? (1 - phase * 2) : ((phase - 0.5) * 2);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: 12 + (intensity * 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _primary.withOpacity(
                        (isDark ? 0.5 : 0.4) + (1 - intensity) * 0.2,
                      ),
                      _cyan.withOpacity(0.3 + intensity * 0.7),
                    ],
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: _cyan.withOpacity(0.35 * intensity),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── Corner bracket (tech frame corner) ───────────────────
  Widget _cornerBracket(bool isDark, bool isRight, bool isBottom) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _CornerBracketPainter(
        color: _primary.withOpacity(isDark ? 0.45 : 0.30),
        isRight: isRight,
        isBottom: isBottom,
      ),
    );
  }

  // ── Status dot ───────────────────────────────────────────
  Widget _statusDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Grid background painter ─────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ── Horizontal scan line painter ────────────────────────────
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Main line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.0), color, color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2));

    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), linePaint);

    // Soft glow band
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.15),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, y - 40, size.width, 80), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ── Rotating arcs painter ───────────────────────────────────
class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accent;

  _ArcRingPainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Outer ring arcs
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 4 arcs rotating
    for (int i = 0; i < 4; i++) {
      final startAngle = (i * 1.5708) + (progress * 6.28);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        0.55,
        false,
        outerPaint,
      );
    }

    // Inner accent arcs (counter-rotating)
    final innerPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final startAngle = (i * 0.785) - (progress * 6.28);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 12),
        startAngle,
        0.25,
        false,
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── Corner bracket painter ──────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool isRight;
  final bool isBottom;

  _CornerBracketPainter({
    required this.color,
    required this.isRight,
    required this.isBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final x = isRight ? size.width : 0.0;
    final y = isBottom ? size.height : 0.0;
    final xEnd = isRight ? 0.0 : size.width;
    final yEnd = isBottom ? 0.0 : size.height;

    path.moveTo(x, y + (isBottom ? -size.height * 0.6 : size.height * 0.6));
    path.lineTo(x, y);
    path.lineTo(xEnd + (isRight ? size.width * 0.6 : -size.width * 0.6), y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
