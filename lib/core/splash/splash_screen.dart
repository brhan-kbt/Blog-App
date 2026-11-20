import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zena_tech/core/services/connectivity_service.dart';
import 'package:zena_tech/core/services/fcm_service.dart';
import 'package:zena_tech/core/state/blog_store.dart';
import 'package:zena_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep navy palette
  static const Color primaryColor = Color(0xFF073B82);
  static const Color brightBlue = Color(0xFF1E5DB8);
  static const Color softBlue = Color(0xFF7BA6E0);
  static const Color paleBlue = Color(0xFFE3ECF9);
  static const Color deepNavy = Color(0xFF042455);
  static const Color darkNavy = Color(0xFF01112B);

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _dotController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _pulse;
  late Animation<double> _rotate;
  late Animation<double> _dotPulse;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _scaleIn = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    _rotate = Tween<double>(
      begin: 0.0,
      end: 6.28318,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _dotPulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dotController, curve: Curves.easeInOut));

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _dotController.dispose();
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

    return Obx(() {
      final isDark = themeService.isDark;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF00060F), darkNavy, const Color(0xFF0A2A5E)]
                  : [
                      const Color(0xFFF3F7FE),
                      paleBlue,
                      const Color(0xFFB8CCEC),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Rotating dashed circle (subtle geometric accent)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5 - 200,
                left: MediaQuery.of(context).size.width * 0.5 - 200,
                child: AnimatedBuilder(
                  animation: _rotate,
                  builder: (context, child) {
                    return Transform.rotate(angle: _rotate.value, child: child);
                  },
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: CustomPaint(
                      painter: _GeometricRingPainter(
                        color: (isDark ? brightBlue : primaryColor).withOpacity(
                          isDark ? 0.10 : 0.06,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating small dots
              ..._buildFloatingDots(isDark),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minimal geometric logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildMinimalLogo(isDark),
                        ),

                        const SizedBox(height: 48),

                        // Clean title
                        _buildCleanTitle(isDark),

                        const SizedBox(height: 16),

                        // Minimal divider
                        _buildMinimalDivider(isDark),

                        const SizedBox(height: 16),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 70),

                        // Minimal loader
                        _buildMinimalLoader(isDark),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom branding
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Text(
                    "ZENA TECH",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.white.withOpacity(0.25)
                          : deepNavy.withOpacity(0.45),
                      letterSpacing: 6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildFloatingDots(bool isDark) {
    final size = MediaQuery.of(context).size;
    final dots = [
      _Dot(size.width * 0.12, size.height * 0.22, 4.0, 0.0),
      _Dot(size.width * 0.88, size.height * 0.30, 5.0, 0.3),
      _Dot(size.width * 0.08, size.height * 0.72, 3.0, 0.6),
      _Dot(size.width * 0.92, size.height * 0.68, 4.0, 0.9),
      _Dot(size.width * 0.25, size.height * 0.85, 3.0, 0.2),
      _Dot(size.width * 0.75, size.height * 0.15, 3.5, 0.5),
    ];

    return dots.map((d) {
      return Positioned(
        left: d.x - d.size / 2,
        top: d.y - d.size / 2,
        child: AnimatedBuilder(
          animation: _dotController,
          builder: (context, _) {
            final value = (0.3 + 0.7 * ((_dotPulse.value + d.phase) % 1.0))
                .clamp(0.0, 1.0);
            return Container(
              width: d.size,
              height: d.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? softBlue : primaryColor).withOpacity(
                  0.5 * value,
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildMinimalLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : deepNavy).withOpacity(
                  0.28 * _pulse.value,
                ),
                blurRadius: 50,
                spreadRadius: 12,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer solid ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? primaryColor.withOpacity(0.15) : Colors.white,
            ),
          ),

          // Gradient ring
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, brightBlue],
              ),
            ),
          ),

          // Inner white circle
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? darkNavy : Colors.white,
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(12),
              color: isDark ? darkNavy : Colors.white,
              child: Image.asset(
                'assets/zena_tech_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Corner accents (small triangles)
          ..._buildCornerAccents(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildCornerAccents(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: CustomPaint(
              size: const Size(10, 10),
              painter: _TriangleAccentPainter(
                color: isDark ? softBlue : Colors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCleanTitle(bool isDark) {
    return Column(
      children: [
        Text(
          "ZENA",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 14,
            color: isDark ? Colors.white.withOpacity(0.85) : deepNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "TECH",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: 18,
            color: isDark ? Colors.white : deepNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalDivider(bool isDark) {
    final color = isDark ? softBlue : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 1, color: color.withOpacity(0.35)),
        const SizedBox(width: 10),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 36, height: 1, color: color.withOpacity(0.35)),
      ],
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      "Discover  ·  Learn  ·  Grow",
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        color: isDark ? paleBlue.withOpacity(0.6) : deepNavy.withOpacity(0.6),
      ),
    );
  }

  Widget _buildMinimalLoader(bool isDark) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Breathing ring
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? primaryColor : deepNavy).withOpacity(
                      0.15 + 0.2 * _pulse.value,
                    ),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          // Spinning arc
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? softBlue : primaryColor,
              ),
            ),
          ),
          // Center square
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? softBlue : primaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data holder for floating dots
class _Dot {
  final double x;
  final double y;
  final double size;
  final double phase;

  const _Dot(this.x, this.y, this.size, this.phase);
}

/// Painter for the rotating dashed geometric ring
class _GeometricRingPainter extends CustomPainter {
  final Color color;

  _GeometricRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawDashedCircle(canvas, center, size.width * 0.46, paint);
    paint.strokeWidth = 0.7;
    canvas.drawCircle(center, size.width * 0.38, paint);
    paint.strokeWidth = 1.0;
    _drawDashedCircle(canvas, center, size.width * 0.30, paint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 10.0;
    const gapLength = 18.0;
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
  bool shouldRepaint(covariant _GeometricRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Painter for small triangle corner accents
class _TriangleAccentPainter extends CustomPainter {
  final Color color;

  _TriangleAccentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleAccentPainter oldDelegate) =>
      oldDelegate.color != color;
}
