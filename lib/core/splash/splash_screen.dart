import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:siket_tips/core/services/connectivity_service.dart';
import 'package:siket_tips/core/services/fcm_service.dart';
import 'package:siket_tips/core/state/blog_store.dart';
import 'package:siket_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep maroon palette
  static const Color primaryColor = Color(0xFF8E1A34);
  static const Color brightMaroon = Color(0xFFB22B4A);
  static const Color softMaroon = Color(0xFFD97388);
  static const Color paleMaroon = Color(0xFFF9E5EA);
  static const Color deepMaroon = Color(0xFF5C0F21);
  static const Color darkRose = Color(0xFF2E0710);

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
                  ? [const Color(0xFF14050A), darkRose, const Color(0xFF4A0C1A)]
                  : [
                      const Color(0xFFFFF6F8),
                      paleMaroon,
                      const Color(0xFFF0C2CE),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Rotating dashed circle (subtle heritage seal)
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
                      painter: _SealRingPainter(
                        color: (isDark ? brightMaroon : primaryColor)
                            .withOpacity(isDark ? 0.10 : 0.07),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating small diamonds
              ..._buildFloatingDiamonds(isDark),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Seal-style logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildSealLogo(isDark),
                        ),

                        const SizedBox(height: 48),

                        // Elegant title
                        _buildElegantTitle(isDark),

                        const SizedBox(height: 16),

                        // Ornamental divider
                        _buildOrnamentalDivider(isDark),

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
                    "SIKET TIPS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.white.withOpacity(0.25)
                          : deepMaroon.withOpacity(0.45),
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

  List<Widget> _buildFloatingDiamonds(bool isDark) {
    final size = MediaQuery.of(context).size;
    final diamonds = [
      _Diamond(size.width * 0.12, size.height * 0.22, 5.0, 0.0),
      _Diamond(size.width * 0.88, size.height * 0.30, 6.0, 0.3),
      _Diamond(size.width * 0.08, size.height * 0.72, 4.0, 0.6),
      _Diamond(size.width * 0.92, size.height * 0.68, 5.0, 0.9),
      _Diamond(size.width * 0.25, size.height * 0.85, 4.0, 0.2),
      _Diamond(size.width * 0.75, size.height * 0.15, 4.5, 0.5),
    ];

    return diamonds.map((d) {
      return Positioned(
        left: d.x - d.size / 2,
        top: d.y - d.size / 2,
        child: AnimatedBuilder(
          animation: _dotController,
          builder: (context, _) {
            final value = (0.3 + 0.7 * ((_dotPulse.value + d.phase) % 1.0))
                .clamp(0.0, 1.0);
            return Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: d.size,
                height: d.size,
                decoration: BoxDecoration(
                  color: (isDark ? softMaroon : primaryColor).withOpacity(
                    0.5 * value,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildSealLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : deepMaroon).withOpacity(
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
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? primaryColor.withOpacity(0.15) : Colors.white,
            ),
          ),

          // Gradient ring
          Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, brightMaroon],
              ),
            ),
          ),

          // Inner white circle
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? darkRose : Colors.white,
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(12),
              color: isDark ? darkRose : Colors.white,
              child: Image.asset(
                'assets/siket_tips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Diamond ornaments at cardinal points
          ..._buildSealOrnaments(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildSealOrnaments(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? softMaroon : Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildElegantTitle(bool isDark) {
    return Column(
      children: [
        Text(
          "SIKET",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 14,
            color: isDark ? Colors.white.withOpacity(0.85) : deepMaroon,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "TIPS",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: 20,
            color: isDark ? Colors.white : deepMaroon,
          ),
        ),
      ],
    );
  }

  Widget _buildOrnamentalDivider(bool isDark) {
    final color = isDark ? softMaroon : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 1, color: color.withOpacity(0.35)),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
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
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(0.5),
            ),
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
        color: isDark
            ? paleMaroon.withOpacity(0.6)
            : deepMaroon.withOpacity(0.6),
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
                    color: (isDark ? primaryColor : deepMaroon).withOpacity(
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
                isDark ? softMaroon : primaryColor,
              ),
            ),
          ),
          // Center diamond
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isDark ? softMaroon : primaryColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data holder for floating diamonds
class _Diamond {
  final double x;
  final double y;
  final double size;
  final double phase;

  const _Diamond(this.x, this.y, this.size, this.phase);
}

/// Painter for rotating dashed seal ring background
class _SealRingPainter extends CustomPainter {
  final Color color;

  _SealRingPainter({required this.color});

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
  bool shouldRepaint(covariant _SealRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
