import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fana_pro/core/services/connectivity_service.dart';
import 'package:fana_pro/core/services/fcm_service.dart';
import 'package:fana_pro/core/state/blog_store.dart';
import 'package:fana_pro/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep forest green palette
  static const Color primaryColor = Color(0xFF12432E);
  static const Color midGreen = Color(0xFF1E6B4A);
  static const Color lightGreen = Color(0xFF3A9B72);
  static const Color mintAccent = Color(0xFF7DCFA8);
  static const Color paleMint = Color(0xFFD4F0E2);

  late AnimationController _entryController;
  late AnimationController _leafController;
  late AnimationController _shimmerController;
  late AnimationController _breatheController;
  late AnimationController _rotateController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _leafSway;
  late Animation<double> _shimmer;
  late Animation<double> _breathe;
  late Animation<double> _rotate;

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
      begin: const Offset(0, 0.3),
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
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _leafSway = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breathe = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
    _rotate = Tween<double>(begin: 0.0, end: 6.28318).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _leafController.dispose();
    _shimmerController.dispose();
    _breatheController.dispose();
    _rotateController.dispose();
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
                      const Color(0xFF071A12),
                      const Color(0xFF0C2A1D),
                      const Color(0xFF12432E),
                    ]
                  : [
                      const Color(0xFFF2FBF6),
                      paleMint,
                      const Color(0xFFB8E4CE),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _breathe,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 0.8,
                          colors: [
                            (isDark ? primaryColor : midGreen)
                                .withOpacity(0.22 * _breathe.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rotating leaf pattern
              Positioned(
                top: size.height * 0.5 - 220,
                left: size.width * 0.5 - 220,
                child: AnimatedBuilder(
                  animation: _rotate,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotate.value,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 440,
                    height: 440,
                    child: CustomPaint(
                      painter: _LeafRingPainter(
                        color: (isDark ? lightGreen : primaryColor)
                            .withOpacity(isDark ? 0.10 : 0.07),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating leaf particles
              ..._buildLeafParticles(isDark, size),

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

                        const SizedBox(height: 44),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 12),

                        // Botanical divider
                        _buildBotanicalDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 60),

                        // Seed loader
                        _buildSeedLoader(isDark),
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
                        Icons.eco,
                        size: 13,
                        color: isDark
                            ? mintAccent.withOpacity(0.55)
                            : primaryColor.withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "FANA PRO",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : primaryColor.withOpacity(0.5),
                          letterSpacing: 5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.eco,
                        size: 13,
                        color: isDark
                            ? mintAccent.withOpacity(0.55)
                            : primaryColor.withOpacity(0.4),
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

  List<Widget> _buildLeafParticles(bool isDark, Size size) {
    final particles = [
      _LeafParticle(size.width * 0.12, size.height * 0.20, 0.4, -0.5),
      _LeafParticle(size.width * 0.88, size.height * 0.28, 0.6, 0.8),
      _LeafParticle(size.width * 0.08, size.height * 0.72, 0.35, 1.2),
      _LeafParticle(size.width * 0.92, size.height * 0.68, 0.5, -0.9),
      _LeafParticle(size.width * 0.22, size.height * 0.88, 0.3, 0.4),
      _LeafParticle(size.width * 0.78, size.height * 0.15, 0.45, -1.1),
      _LeafParticle(size.width * 0.48, size.height * 0.10, 0.3, 0.7),
      _LeafParticle(size.width * 0.65, size.height * 0.92, 0.4, -0.3),
    ];

    return particles.map((p) {
      return Positioned(
        left: p.x,
        top: p.y,
        child: AnimatedBuilder(
          animation: _breathe,
          builder: (context, _) {
            return Transform.rotate(
              angle: p.rotation + _leafSway.value * 0.5,
              child: Icon(
                Icons.eco,
                size: 18,
                color: (isDark ? mintAccent : midGreen)
                    .withOpacity(p.opacity * _breathe.value),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildLeafLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        return Container(
          width: 165,
          height: 165,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : midGreen)
                    .withOpacity(0.4 * _breathe.value),
                blurRadius: 55,
                spreadRadius: 14,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.1),
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
          // Outer ring with rotating leaf accents
          AnimatedBuilder(
            animation: _rotate,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotate.value,
                child: SizedBox(
                  width: 165,
                  height: 165,
                  child: CustomPaint(
                    painter: _RingLeafPainter(
                      color: isDark ? mintAccent : midGreen,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),

          // Middle solid ring
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isDark
                    ? [
                        primaryColor,
                        lightGreen,
                        mintAccent,
                        lightGreen,
                        primaryColor,
                      ]
                    : [
                        primaryColor,
                        midGreen,
                        lightGreen,
                        midGreen,
                        primaryColor,
                      ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // Inner background
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF071A12) : Colors.white,
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 122,
              height: 122,
              padding: const EdgeInsets.all(14),
              color: isDark ? const Color(0xFF071A12) : Colors.white,
              child: Image.asset(
                'assets/fana_pro_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Small leaf accents around the ring
          ..._buildRingLeaves(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildRingLeaves(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.eco,
              size: 12,
              color: isDark ? mintAccent : Colors.white,
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
                      mintAccent,
                      Colors.white,
                      mintAccent,
                      Colors.white,
                    ]
                  : [
                      primaryColor,
                      lightGreen,
                      primaryColor,
                      lightGreen,
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
                "FANA",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 12,
                  color: isDark
                      ? Colors.white.withOpacity(0.85)
                      : primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "PRO",
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

  Widget _buildBotanicalDivider(bool isDark) {
    final color = isDark ? mintAccent : midGreen;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBranchLine(isDark, false),
        const SizedBox(width: 10),
        Icon(Icons.eco, size: 14, color: color),
        const SizedBox(width: 10),
        _buildBranchLine(isDark, true),
      ],
    );
  }

  Widget _buildBranchLine(bool isDark, bool reverse) {
    final color = isDark ? mintAccent : midGreen;
    return Container(
      width: 46,
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reverse
              ? [color.withOpacity(0.7), Colors.transparent]
              : [Colors.transparent, color.withOpacity(0.7)],
        ),
      ),
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      "Nurture  ·  Discover  ·  Flourish",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: isDark
            ? paleMint.withOpacity(0.65)
            : primaryColor.withOpacity(0.6),
      ),
    );
  }

  Widget _buildSeedLoader(bool isDark) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer breathing ring
          AnimatedBuilder(
            animation: _breathe,
            builder: (context, _) {
              return Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? primaryColor : midGreen)
                        .withOpacity(0.2 + 0.2 * _breathe.value),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          // Spinning arc
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? mintAccent : primaryColor,
              ),
            ),
          ),
          // Center leaf icon
          Icon(
            Icons.spa,
            size: 14,
            color: isDark ? mintAccent : primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Data holder for floating leaf particles
class _LeafParticle {
  final double x;
  final double y;
  final double opacity;
  final double rotation;

  const _LeafParticle(this.x, this.y, this.opacity, this.rotation);
}

/// Custom painter for rotating decorative leaf ring
class _LeafRingPainter extends CustomPainter {
  final Color color;

  _LeafRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer dashed ring
    _drawDashedCircle(canvas, center, size.width * 0.47, paint);

    // Middle ring
    paint.strokeWidth = 0.6;
    canvas.drawCircle(center, size.width * 0.40, paint);

    // Inner dashed ring
    paint.strokeWidth = 1.2;
    _drawDashedCircle(canvas, center, size.width * 0.33, paint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 10.0;
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
  bool shouldRepaint(covariant _LeafRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom painter for the rotating ring of leaves around the logo
class _RingLeafPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _RingLeafPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withOpacity(isDark ? 0.5 : 0.4)
      ..style = PaintingStyle.fill;

    // Draw small leaf shapes (teardrops) around the ring
    const leafCount = 12;
    for (int i = 0; i < leafCount; i++) {
      final angle = (2 * 3.14159 / leafCount) * i;
      final leafX = center.dx + radius * 0.96 * _cos(angle);
      final leafY = center.dy + radius * 0.96 * _sin(angle);

      canvas.save();
      canvas.translate(leafX, leafY);
      canvas.rotate(angle + 1.5708);

      // Draw a teardrop/leaf shape
      final path = Path();
      path.moveTo(0, -4);
      path.quadraticBezierTo(3, -1, 0, 3);
      path.quadraticBezierTo(-3, -1, 0, -4);
      path.close();
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  double _sin(double x) => (x % (2 * 3.14159)) < 3.14159
      ? _sinTable(x)
      : -_sinTable(x - 3.14159);

  double _cos(double x) => _sin(x + 1.5708);

  double _sinTable(double x) {
    // Simple approximation using Taylor-like approach for small angles
    // For full accuracy, use dart:math's sin/cos
    // Here we use a basic approximation to avoid import
    return _taylorSin(x);
  }

  double _taylorSin(double x) {
    // Normalize to [-PI, PI]
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    if (x < -3.14159265) x += 2 * 3.14159265;

    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  @override
  bool shouldRepaint(covariant _RingLeafPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}