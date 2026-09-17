import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:melatech/core/services/connectivity_service.dart';
import 'package:melatech/core/services/fcm_service.dart';
import 'package:melatech/core/state/blog_store.dart';
import 'package:melatech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _orbitController;
  late Animation<double> _fade;
  late Animation<double> _slide;
  late Animation<double> _logoScale;

  // Brand palette
  static const Color _primary = Color(0xFF0054F0);
  static const Color _deep = Color(0xFF002266);
  static const Color _soft = Color(0xFFE6EEFF);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
                  ? [const Color(0xFF000A24), _deep, _primary]
                  : [Colors.white, _soft, const Color(0xFFC7D8FF)],
            ),
          ),
          child: Stack(
            children: [
              // ── Concentric orbit rings around logo area ─────
              Positioned(
                top: MediaQuery.of(context).size.height * 0.13,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 340,
                    height: 340,
                    child: AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _OrbitPainter(
                            progress: _orbitController.value,
                            color: _primary.withOpacity(isDark ? 0.28 : 0.18),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Corner chevron accents ──────────────────────
              Positioned(top: 90, left: 30, child: _chevron(isDark, 0)),
              Positioned(top: 160, right: 40, child: _chevron(isDark, 1)),
              Positioned(bottom: 200, left: 55, child: _chevron(isDark, 2)),

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
                      // Logo with brand ring
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

                      // Wordmark with accent underline
                      Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Mela",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2,
                                    color: isDark ? Colors.white : _deep,
                                  ),
                                ),
                                TextSpan(
                                  text: "Tech",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: isDark
                                        ? _primary.withOpacity(0.95)
                                        : _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Triple-bar accent underline
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _underlineBar(28, _primary),
                              const SizedBox(width: 4),
                              _underlineBar(18, _primary.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              _underlineBar(10, _primary.withOpacity(0.3)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Tagline
                      Text(
                        "SMART SOLUTIONS, SIMPLIFIED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                          color: isDark
                              ? Colors.white.withOpacity(0.55)
                              : Colors.black.withOpacity(0.45),
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Custom wave loader
                      _buildWaveLoader(isDark),
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
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: _primary.withOpacity(isDark ? 0.6 : 0.4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "MELA  •  TECH",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
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

  // ── Logo container ───────────────────────────────────────
  Widget _buildLogo(bool isDark) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        border: Border.all(color: _primary.withOpacity(0.55), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: ClipOval(
        child: Image.asset('assets/melatech_logo.png', fit: BoxFit.contain),
      ),
    );
  }

  // ── Triple bar underline ─────────────────────────────────
  Widget _underlineBar(double width, Color color) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: color,
      ),
    );
  }

  // ── Chevron accent (corner V shape) ──────────────────────
  Widget _chevron(bool isDark, int index) {
    final opacity = isDark ? 0.35 : 0.22;
    return Transform.rotate(
      angle: index.isEven ? 0.6 : -0.6,
      child: Icon(
        Icons.chevron_right_rounded,
        size: 22 + (index * 4),
        color: _primary.withOpacity(opacity),
      ),
    );
  }

  // ── Animated wave loader ─────────────────────────────────
  Widget _buildWaveLoader(bool isDark) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final phase = (_orbitController.value + i * 0.12) % 1.0;
            final wave = phase < 0.5 ? (phase * 2) : (1 - (phase - 0.5) * 2);
            final height = 8.0 + (wave * 16.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _primary.withOpacity(
                  (isDark ? 0.5 : 0.4) + (wave * 0.5),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Custom painter for concentric orbit rings ───────────────
class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer ring (dashed)
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final outerRadius = size.width / 2;
    _drawDashedCircle(canvas, center, outerRadius, outerPaint, 20);

    // Middle ring (solid thin, rotated)
    final midPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius * 0.80),
      progress * 6.28,
      4.0,
      false,
      midPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius * 0.80),
      progress * 6.28 + 3.14,
      2.5,
      false,
      midPaint,
    );

    // Inner ring (dotted)
    final innerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawDashedCircle(
      canvas,
      center,
      outerRadius * 0.62,
      innerPaint,
      12,
      offset: progress * 6.28,
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    int dashCount, {
    double offset = 0,
  }) {
    final circumference = 2 * 3.14159 * radius;
    final dashLength = circumference / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * 3.14159 / dashCount) + offset;
      final sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
