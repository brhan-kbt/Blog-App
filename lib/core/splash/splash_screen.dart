import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:freshtips/core/services/connectivity_service.dart';
import 'package:freshtips/core/services/fcm_service.dart';
import 'package:freshtips/core/state/blog_store.dart';
import 'package:freshtips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _leafController;
  late AnimationController _growController;
  late Animation<double> _fade;
  late Animation<double> _slide;
  late Animation<double> _logoScale;

  // Brand palette
  static const Color _primary = Color(0xFF35D04F);
  static const Color _deep = Color(0xFF0F7A22);
  static const Color _soft = Color(0xFFE8FBEC);
  static const Color _lime = Color(0xFF9BE86B);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _growController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
    _leafController.dispose();
    _growController.dispose();
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
                  ? [const Color(0xFF04140A), const Color(0xFF0A3D18), _deep]
                  : [Colors.white, _soft, const Color(0xFFC8F4D2)],
            ),
          ),
          child: Stack(
            children: [
              // ── Big soft glow behind logo ──────────────────
              Positioned(
                top: MediaQuery.of(context).size.height * 0.16,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _growController,
                    builder: (context, _) {
                      final v = 0.9 + (_growController.value * 0.2);
                      return Container(
                        width: 320 * v,
                        height: 320 * v,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _primary.withOpacity(isDark ? 0.35 : 0.22),
                              _primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Floating leaf particles ─────────────────────
              ..._buildLeafParticles(isDark),

              // ── Organic blob top-left ────────────────────────
              Positioned(
                top: -100,
                left: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(200),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _primary.withOpacity(isDark ? 0.22 : 0.14),
                        _primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Organic blob bottom-right ────────────────────
              Positioned(
                bottom: -90,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(220),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _lime.withOpacity(0.0),
                        _primary.withOpacity(isDark ? 0.20 : 0.12),
                      ],
                    ),
                  ),
                ),
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
                      // Logo with rotating ring
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

                      const SizedBox(height: 44),

                      // Wordmark
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Fresh",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white : _deep,
                              ),
                            ),
                            TextSpan(
                              text: " Tips",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? _primary.withOpacity(0.95)
                                    : _primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Pill tagline with leaf icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isDark
                              ? _primary.withOpacity(0.18)
                              : _primary.withOpacity(0.10),
                          border: Border.all(
                            color: _primary.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 14,
                              color: isDark ? _lime : _primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "FRESH  •  DAILY  •  TIPS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.4,
                                color: isDark
                                    ? Colors.white.withOpacity(0.88)
                                    : _deep,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Growing seed loader
                      _buildSeedLoader(isDark),
                    ],
                  ),
                ),
              ),

              // ── Bottom brand footer ──────────────────────────
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [_primary, _lime],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "GROW  •  LEARN  •  SHARE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.6,
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

  // ── Logo with rotating dashed ring ───────────────────────
  Widget _buildLogo(bool isDark) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating dashed ring
          AnimatedBuilder(
            animation: _leafController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(170, 170),
                painter: _DashedRingPainter(
                  progress: _leafController.value,
                  color: _primary.withOpacity(isDark ? 0.55 : 0.40),
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
                  color: _primary.withOpacity(0.35),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: ClipOval(
              child: Image.asset(
                'assets/freshtips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Seed / sprout loader (growing bars) ──────────────────
  Widget _buildSeedLoader(bool isDark) {
    return AnimatedBuilder(
      animation: _growController,
      builder: (context, _) {
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              // Stagger growth
              final phase = (_growController.value + i * 0.15) % 1.0;
              final wave = phase < 0.5 ? (phase * 2) : (1 - (phase - 0.5) * 2);
              final height = 10.0 + (wave * 26.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _primary.withOpacity(isDark ? 0.85 : 0.75),
                      _lime.withOpacity(0.5 + wave * 0.5),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── Floating leaf particles ──────────────────────────────
  List<Widget> _buildLeafParticles(bool isDark) {
    return List.generate(6, (i) {
      final positions = [
        const Offset(0.10, 0.18),
        const Offset(0.85, 0.22),
        const Offset(0.15, 0.72),
        const Offset(0.80, 0.68),
        const Offset(0.50, 0.12),
        const Offset(0.30, 0.88),
      ];
      final pos = positions[i];
      final size = 12.0 + (i % 3) * 4;

      return Positioned(
        top: MediaQuery.of(context).size.height * pos.dy,
        left: MediaQuery.of(context).size.width * pos.dx,
        child: AnimatedBuilder(
          animation: _growController,
          builder: (context, _) {
            final t = (_growController.value + i * 0.18) % 1.0;
            final lift = (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Transform.translate(
              offset: Offset(0, -lift * 8),
              child: Transform.rotate(
                angle: lift * 0.6,
                child: Opacity(
                  opacity: 0.4 + lift * 0.5,
                  child: Icon(
                    Icons.eco_rounded,
                    size: size,
                    color: _primary.withOpacity(isDark ? 0.6 : 0.45),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Dashed rotating ring painter ────────────────────────────
class _DashedRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DashedRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const dashCount = 14;
    final circumference = 2 * 3.14159 * radius;
    final dashLength = circumference / (dashCount * 2.5);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * 3.14159 / dashCount) + progress * 6.28;
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
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
