import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:addis_tips/core/services/connectivity_service.dart';
import 'package:addis_tips/core/services/fcm_service.dart';
import 'package:addis_tips/core/state/blog_store.dart';
import 'package:addis_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Primary brand color - warm gold
  static const Color primaryColor = Color(0xFF9D720B);
  static const Color lightGold = Color(0xFFD4A73A);
  static const Color darkGold = Color(0xFF6B4E08);
  static const Color creamGold = Color(0xFFF5E6C8);

  late AnimationController _entryController;
  late AnimationController _shimmerController;
  late AnimationController _orbitController;
  late AnimationController _glowController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _shimmer;
  late Animation<double> _orbit;
  late Animation<double> _glow;

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
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _scaleIn = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _orbit = Tween<double>(
      begin: 0.0,
      end: 6.28318,
    ).animate(CurvedAnimation(parent: _orbitController, curve: Curves.linear));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    _orbitController.dispose();
    _glowController.dispose();
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
                      const Color(0xFF1A1206),
                      const Color(0xFF2A1E0A),
                      const Color(0xFF3D2B0F),
                    ]
                  : [
                      creamGold,
                      const Color(0xFFE8D5A8),
                      const Color(0xFFD4BE8A),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Soft radial glow in the center
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 0.75,
                          colors: [
                            (isDark ? primaryColor : lightGold).withOpacity(
                              0.18 * _glow.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rotating orbit rings around the logo
              Positioned(
                top: size.height * 0.5 - 200,
                left: size.width * 0.5 - 200,
                child: AnimatedBuilder(
                  animation: _orbit,
                  builder: (context, child) {
                    return Transform.rotate(angle: _orbit.value, child: child);
                  },
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: CustomPaint(
                      painter: _OrbitPainter(
                        color: (isDark ? primaryColor : darkGold).withOpacity(
                          isDark ? 0.12 : 0.10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating gold particles
              ..._buildParticles(isDark, size),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emblem-style logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildEmblemLogo(isDark),
                        ),

                        const SizedBox(height: 44),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 14),

                        // Divider with diamond
                        _buildOrnamentalDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 64),

                        // Ring loader
                        _buildRingLoader(isDark),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom branding with icon
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
                        size: 12,
                        color: isDark
                            ? primaryColor.withOpacity(0.6)
                            : darkGold.withOpacity(0.45),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ADDIS TIPS",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : darkGold.withOpacity(0.5),
                          letterSpacing: 5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: isDark
                            ? primaryColor.withOpacity(0.6)
                            : darkGold.withOpacity(0.45),
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

  List<Widget> _buildParticles(bool isDark, Size size) {
    final particles = [
      _Particle(size.width * 0.15, size.height * 0.22, 3.0, 0.35),
      _Particle(size.width * 0.85, size.height * 0.30, 4.0, 0.25),
      _Particle(size.width * 0.10, size.height * 0.70, 2.5, 0.30),
      _Particle(size.width * 0.90, size.height * 0.65, 3.5, 0.20),
      _Particle(size.width * 0.25, size.height * 0.85, 2.0, 0.25),
      _Particle(size.width * 0.75, size.height * 0.18, 3.0, 0.30),
      _Particle(size.width * 0.50, size.height * 0.12, 2.5, 0.20),
      _Particle(size.width * 0.60, size.height * 0.90, 3.0, 0.22),
    ];

    return particles.map((p) {
      return Positioned(
        left: p.x,
        top: p.y,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) {
            return Container(
              width: p.radius * 2,
              height: p.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? lightGold : darkGold).withOpacity(
                  p.opacity * _glow.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? lightGold : darkGold).withOpacity(
                      p.opacity * 0.5 * _glow.value,
                    ),
                    blurRadius: p.radius * 3,
                    spreadRadius: p.radius,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildEmblemLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : lightGold).withOpacity(
                  0.35 * _glow.value,
                ),
                blurRadius: 50,
                spreadRadius: 12,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isDark
                    ? [
                        primaryColor,
                        lightGold,
                        darkGold,
                        lightGold,
                        primaryColor,
                      ]
                    : [darkGold, lightGold, creamGold, lightGold, darkGold],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // Middle ring
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1A1206) : creamGold,
            ),
          ),

          // Inner gradient ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [primaryColor.withOpacity(0.6), const Color(0xFF1A1206)]
                    : [Colors.white, creamGold],
              ),
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 118,
              height: 118,
              padding: const EdgeInsets.all(12),
              color: isDark ? const Color(0xFF1A1206) : Colors.white,
              child: Image.asset(
                'assets/addis_tips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Small diamond accents on the ring
          ..._buildDiamondAccents(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildDiamondAccents(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? lightGold : Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? lightGold : darkGold).withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
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
                      lightGold,
                      Colors.white,
                      lightGold,
                      Colors.white,
                    ]
                  : [darkGold, lightGold, darkGold, lightGold, darkGold],
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
                "ADDIS",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 10,
                  color: isDark ? Colors.white.withOpacity(0.85) : darkGold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "TIPS",
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 16,
                  color: isDark ? Colors.white : darkGold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrnamentalDivider(bool isDark) {
    final color = isDark ? lightGold : darkGold;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, color.withOpacity(0.6)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 1.5,
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
      "Discover  ·  Learn  ·  Grow",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: isDark
            ? creamGold.withOpacity(0.65)
            : darkGold.withOpacity(0.65),
      ),
    );
  }

  Widget _buildRingLoader(bool isDark) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                (isDark ? primaryColor : darkGold).withOpacity(0.25),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? lightGold : primaryColor,
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? lightGold : primaryColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small data holder for floating particles
class _Particle {
  final double x;
  final double y;
  final double radius;
  final double opacity;

  const _Particle(this.x, this.y, this.radius, this.opacity);
}

/// Custom painter for the rotating orbit rings
class _OrbitPainter extends CustomPainter {
  final Color color;

  _OrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer dashed ring
    _drawDashedCircle(canvas, center, size.width * 0.46, paint);

    // Middle ring with subtle stroke
    paint.strokeWidth = 0.6;
    canvas.drawCircle(center, size.width * 0.38, paint);

    // Inner ring
    paint.strokeWidth = 1.2;
    _drawDashedCircle(canvas, center, size.width * 0.30, paint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 8.0;
    const gapLength = 12.0;
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
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}
