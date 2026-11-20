import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yene_tips/core/services/connectivity_service.dart';
import 'package:yene_tips/core/services/fcm_service.dart';
import 'package:yene_tips/core/state/blog_store.dart';
import 'package:yene_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep forest green palette
  static const Color primaryColor = Color(0xFF2B553C);
  static const Color brightGreen = Color(0xFF4A7A5B);
  static const Color softGreen = Color(0xFF8FB89C);
  static const Color paleGreen = Color(0xFFE8F3EC);
  static const Color deepGreen = Color(0xFF1A3325);
  static const Color darkForest = Color(0xFF0D1A12);

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _leafController;
  late AnimationController _dotController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _pulse;
  late Animation<double> _leafSway;
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

    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _leafSway = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.easeInOut),
    );

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
    _leafController.dispose();
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
                  ? [
                      const Color(0xFF06120B),
                      darkForest,
                      const Color(0xFF163323),
                    ]
                  : [
                      const Color(0xFFF6FBF8),
                      paleGreen,
                      const Color(0xFFBFDDC8),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Soft organic curved arcs in background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _leafController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OrganicArcPainter(
                        sway: _leafSway.value,
                        color: (isDark ? brightGreen : primaryColor)
                            .withOpacity(isDark ? 0.08 : 0.05),
                      ),
                    );
                  },
                ),
              ),

              // Floating leaf particles
              ..._buildLeafParticles(isDark),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Leaf-framed logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildLeafLogo(isDark),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 11,
                        color: isDark
                            ? softGreen.withOpacity(0.4)
                            : deepGreen.withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "YENE TIPS",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.25)
                              : deepGreen.withOpacity(0.45),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.spa_outlined,
                        size: 11,
                        color: isDark
                            ? softGreen.withOpacity(0.4)
                            : deepGreen.withOpacity(0.4),
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

  List<Widget> _buildLeafParticles(bool isDark) {
    final size = MediaQuery.of(context).size;
    final particles = [
      _Leaf(size.width * 0.10, size.height * 0.22, 14.0, 0.0, 0.4),
      _Leaf(size.width * 0.88, size.height * 0.30, 16.0, 1.5, -0.6),
      _Leaf(size.width * 0.06, size.height * 0.72, 12.0, 0.8, 0.9),
      _Leaf(size.width * 0.92, size.height * 0.68, 15.0, 2.2, -0.4),
      _Leaf(size.width * 0.25, size.height * 0.85, 11.0, 1.1, 0.5),
      _Leaf(size.width * 0.75, size.height * 0.15, 13.0, 0.5, -0.8),
    ];

    return particles.map((p) {
      return Positioned(
        left: p.x,
        top: p.y,
        child: AnimatedBuilder(
          animation: _dotController,
          builder: (context, _) {
            final value = (0.3 + 0.7 * ((_dotPulse.value + p.phase) % 1.0))
                .clamp(0.0, 1.0);
            return Transform.rotate(
              angle: p.rotation + _leafSway.value * 0.6,
              child: Icon(
                Icons.spa,
                size: p.size,
                color: (isDark ? softGreen : primaryColor).withOpacity(
                  0.4 * value,
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildLeafLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 152,
          height: 152,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : deepGreen).withOpacity(
                  0.28 * _pulse.value,
                ),
                blurRadius: 48,
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
          // Outer ring
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? primaryColor.withOpacity(0.15) : Colors.white,
            ),
          ),

          // Gradient ring
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, brightGreen],
              ),
            ),
          ),

          // Inner circle
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? darkForest : Colors.white,
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(12),
              color: isDark ? darkForest : Colors.white,
              child: Image.asset(
                'assets/yene_tips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Small leaf accents
          ..._buildLogoLeafAccents(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildLogoLeafAccents(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.spa,
              size: 12,
              color: isDark ? softGreen : Colors.white,
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
          "YENE",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 14,
            color: isDark ? Colors.white.withOpacity(0.85) : deepGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "TIPS",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: 20,
            color: isDark ? Colors.white : deepGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalDivider(bool isDark) {
    final color = isDark ? softGreen : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 1, color: color.withOpacity(0.35)),
        const SizedBox(width: 10),
        Icon(Icons.spa, size: 12, color: color.withOpacity(0.7)),
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
        color: isDark ? paleGreen.withOpacity(0.6) : deepGreen.withOpacity(0.6),
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
                    color: (isDark ? primaryColor : deepGreen).withOpacity(
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
                isDark ? softGreen : primaryColor,
              ),
            ),
          ),
          // Center leaf icon
          Icon(Icons.spa, size: 14, color: isDark ? softGreen : primaryColor),
        ],
      ),
    );
  }
}

/// Data holder for floating leaf particles
class _Leaf {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double rotation;

  const _Leaf(this.x, this.y, this.size, this.phase, this.rotation);
}

/// Painter for the soft organic arcs in background
class _OrganicArcPainter extends CustomPainter {
  final double sway;
  final Color color;

  _OrganicArcPainter({required this.sway, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Top-left large arc
    final rect1 = Rect.fromCircle(
      center: Offset(size.width * 0.1 + sway * 10, size.height * 0.15),
      radius: size.width * 0.55,
    );
    canvas.drawArc(rect1, 0.2, 1.2, false, paint);

    // Bottom-right large arc
    paint.strokeWidth = 1.2;
    final rect2 = Rect.fromCircle(
      center: Offset(size.width * 0.9 + sway * 8, size.height * 0.85),
      radius: size.width * 0.45,
    );
    canvas.drawArc(rect2, 3.3, 1.4, false, paint);

    // Small accent arc
    paint.strokeWidth = 0.8;
    final rect3 = Rect.fromCircle(
      center: Offset(size.width * 0.5 + sway * 6, size.height * 0.5),
      radius: size.width * 0.38,
    );
    canvas.drawArc(rect3, 1.5, 0.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OrganicArcPainter oldDelegate) =>
      oldDelegate.sway != sway || oldDelegate.color != color;
}
