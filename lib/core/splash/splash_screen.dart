import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zena_tips/core/services/connectivity_service.dart';
import 'package:zena_tips/core/services/fcm_service.dart';
import 'package:zena_tips/core/state/blog_store.dart';
import 'package:zena_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deep emerald forest palette
  static const Color primaryColor = Color(0xFF0C3322);
  static const Color brightEmerald = Color(0xFF1F6B47);
  static const Color softEmerald = Color(0xFF6FB894);
  static const Color paleEmerald = Color(0xFFE4F4EC);
  static const Color deepEmerald = Color(0xFF061D14);
  static const Color darkForest = Color(0xFF020D08);

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late AnimationController _dotController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _pulse;
  late Animation<double> _breathe;
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

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _breathe = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
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
    _breatheController.dispose();
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
                      const Color(0xFF000604),
                      darkForest,
                      const Color(0xFF0A2A1C),
                    ]
                  : [
                      const Color(0xFFF4FBF7),
                      paleEmerald,
                      const Color(0xFFB8DDC8),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Soft organic breathing glow in background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _breathe,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 0.85,
                          colors: [
                            (isDark ? brightEmerald : softEmerald).withOpacity(
                              0.18 * _breathe.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Minimal concentric arc accents
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5 - 180,
                left: MediaQuery.of(context).size.width * 0.5 - 180,
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: CustomPaint(
                    painter: _ConcentricArcPainter(
                      color: (isDark ? brightEmerald : primaryColor)
                          .withOpacity(isDark ? 0.08 : 0.05),
                    ),
                  ),
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
                        // Minimal logo with soft glow
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 11,
                        color: isDark
                            ? softEmerald.withOpacity(0.4)
                            : deepEmerald.withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ZENA TIPS",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.25)
                              : deepEmerald.withOpacity(0.45),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.spa_outlined,
                        size: 11,
                        color: isDark
                            ? softEmerald.withOpacity(0.4)
                            : deepEmerald.withOpacity(0.4),
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
      _Leaf(size.width * 0.10, size.height * 0.22, 14.0, 0.0),
      _Leaf(size.width * 0.88, size.height * 0.30, 16.0, 0.5),
      _Leaf(size.width * 0.06, size.height * 0.72, 12.0, 1.0),
      _Leaf(size.width * 0.92, size.height * 0.68, 15.0, 1.5),
      _Leaf(size.width * 0.25, size.height * 0.85, 11.0, 0.8),
      _Leaf(size.width * 0.75, size.height * 0.15, 13.0, 1.2),
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
              angle: p.phase * 0.5,
              child: Icon(
                Icons.spa,
                size: p.size,
                color: (isDark ? softEmerald : primaryColor).withOpacity(
                  0.35 * value,
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
                color: (isDark ? primaryColor : deepEmerald).withOpacity(
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
                colors: [primaryColor, brightEmerald],
              ),
            ),
          ),

          // Inner circle
          Container(
            width: 122,
            height: 122,
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
                'assets/zena_tips_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Small leaf accents at cardinal points
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
              color: isDark ? softEmerald : Colors.white,
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
            color: isDark ? Colors.white.withOpacity(0.85) : deepEmerald,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "TIPS",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: 20,
            color: isDark ? Colors.white : deepEmerald,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalDivider(bool isDark) {
    final color = isDark ? softEmerald : primaryColor;
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
        color: isDark
            ? paleEmerald.withOpacity(0.6)
            : deepEmerald.withOpacity(0.6),
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
                    color: (isDark ? primaryColor : deepEmerald).withOpacity(
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
                isDark ? softEmerald : primaryColor,
              ),
            ),
          ),
          // Center leaf icon
          Icon(Icons.spa, size: 14, color: isDark ? softEmerald : primaryColor),
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

  const _Leaf(this.x, this.y, this.size, this.phase);
}

/// Painter for minimal concentric arc accents
class _ConcentricArcPainter extends CustomPainter {
  final Color color;

  _ConcentricArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Three subtle arcs at different radii and angles
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.46),
      0.3,
      1.4,
      false,
      paint,
    );
    paint.strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.38),
      2.0,
      1.8,
      false,
      paint,
    );
    paint.strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.30),
      4.5,
      1.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConcentricArcPainter oldDelegate) =>
      oldDelegate.color != color;
}
