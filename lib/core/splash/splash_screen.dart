import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hagere_tips/core/services/connectivity_service.dart';
import 'package:hagere_tips/core/services/fcm_service.dart';
import 'package:hagere_tips/core/state/blog_store.dart';
import 'package:hagere_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Vibrant emerald palette
  static const Color primaryColor = Color(0xFF1EB979);
  static const Color brightEmerald = Color(0xFF2CD68E);
  static const Color softEmerald = Color(0xFF7EE8B8);
  static const Color paleEmerald = Color(0xFFD9F7E8);
  static const Color deepEmerald = Color(0xFF0A5C3C);
  static const Color forestGreen = Color(0xFF063D28);

  late AnimationController _entryController;
  late AnimationController _waveController;
  late AnimationController _breatheController;
  late AnimationController _shimmerController;
  late AnimationController _orbitController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _wave1;
  late Animation<double> _wave2;
  late Animation<double> _wave3;
  late Animation<double> _breathe;
  late Animation<double> _shimmer;
  late Animation<double> _orbit;

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
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _scaleIn = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _wave1 = Tween<double>(
      begin: 0.0,
      end: 6.28318,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));
    _wave2 = Tween<double>(
      begin: 3.14159,
      end: 9.42477,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));
    _wave3 = Tween<double>(
      begin: 1.5708,
      end: 7.85398,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breathe = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    _orbit = Tween<double>(
      begin: 0.0,
      end: 6.28318,
    ).animate(CurvedAnimation(parent: _orbitController, curve: Curves.linear));

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _waveController.dispose();
    _breatheController.dispose();
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
                      const Color(0xFF021A10),
                      const Color(0xFF063D28),
                      const Color(0xFF0A5C3C),
                    ]
                  : [
                      const Color(0xFFF0FDF7),
                      paleEmerald,
                      const Color(0xFFA8EFCE),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient radial glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _breathe,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 0.85,
                          colors: [
                            (isDark ? primaryColor : brightEmerald).withOpacity(
                              0.22 * _breathe.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Animated wave layers at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: size.height * 0.4,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WavePainter(
                        wave1: _wave1.value,
                        wave2: _wave2.value,
                        wave3: _wave3.value,
                        color1: (isDark ? primaryColor : brightEmerald)
                            .withOpacity(isDark ? 0.10 : 0.15),
                        color2: (isDark ? brightEmerald : softEmerald)
                            .withOpacity(isDark ? 0.07 : 0.12),
                        color3: (isDark ? softEmerald : paleEmerald)
                            .withOpacity(isDark ? 0.05 : 0.10),
                      ),
                    );
                  },
                ),
              ),

              // Rotating orbit ring with dots
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
                      painter: _OrbitDotPainter(
                        color: (isDark ? brightEmerald : primaryColor)
                            .withOpacity(isDark ? 0.15 : 0.10),
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating soft particles
              ..._buildSoftParticles(isDark, size),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Organic leaf-shaped logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildOrganicLogo(isDark),
                        ),

                        const SizedBox(height: 44),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 14),

                        // Organic divider
                        _buildOrganicDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 60),

                        // Breathing loader
                        _buildBreathingLoader(isDark),
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
                      _buildLeafIcon(isDark),
                      const SizedBox(width: 8),
                      Text(
                        "HAGERE TIPS",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : primaryColor.withOpacity(0.55),
                          letterSpacing: 5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildLeafIcon(isDark),
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

  Widget _buildLeafIcon(bool isDark) {
    return Transform.rotate(
      angle: 0.6,
      child: Icon(
        Icons.eco,
        size: 12,
        color: isDark
            ? softEmerald.withOpacity(0.5)
            : primaryColor.withOpacity(0.45),
      ),
    );
  }

  List<Widget> _buildSoftParticles(bool isDark, Size size) {
    final particles = [
      _SoftParticle(size.width * 0.10, size.height * 0.20, 6.0, 0.4),
      _SoftParticle(size.width * 0.88, size.height * 0.28, 8.0, 0.3),
      _SoftParticle(size.width * 0.06, size.height * 0.65, 5.0, 0.35),
      _SoftParticle(size.width * 0.92, size.height * 0.60, 7.0, 0.25),
      _SoftParticle(size.width * 0.22, size.height * 0.88, 4.5, 0.3),
      _SoftParticle(size.width * 0.80, size.height * 0.15, 5.5, 0.35),
      _SoftParticle(size.width * 0.48, size.height * 0.10, 4.0, 0.25),
      _SoftParticle(size.width * 0.68, size.height * 0.92, 6.0, 0.28),
    ];

    return particles.map((p) {
      return Positioned(
        left: p.x - p.size / 2,
        top: p.y - p.size / 2,
        child: AnimatedBuilder(
          animation: _breathe,
          builder: (context, _) {
            return Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? softEmerald : primaryColor).withOpacity(
                  p.opacity * _breathe.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? brightEmerald : softEmerald).withOpacity(
                      0.4 * _breathe.value,
                    ),
                    blurRadius: p.size * 2,
                    spreadRadius: p.size * 0.3,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildOrganicLogo(bool isDark) {
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
                color: (isDark ? primaryColor : brightEmerald).withOpacity(
                  0.4 * _breathe.value,
                ),
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
          // Outer organic ring (soft gradient)
          Container(
            width: 165,
            height: 165,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isDark
                    ? [
                        primaryColor,
                        brightEmerald,
                        softEmerald,
                        brightEmerald,
                        primaryColor,
                      ]
                    : [
                        deepEmerald,
                        primaryColor,
                        brightEmerald,
                        primaryColor,
                        deepEmerald,
                      ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // Middle ring
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? forestGreen : Colors.white,
            ),
          ),

          // Inner gradient ring
          Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [primaryColor.withOpacity(0.5), forestGreen]
                    : [Colors.white, paleEmerald],
              ),
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 124,
              height: 124,
              padding: const EdgeInsets.all(14),
              color: isDark ? forestGreen : Colors.white,
              child: Image.asset(
                'assets/hagere_tips_logo.png',
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
            padding: const EdgeInsets.only(top: 2),
            child: Transform.rotate(
              angle: 0.6,
              child: Icon(
                Icons.eco,
                size: 13,
                color: isDark ? softEmerald : Colors.white,
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
                      softEmerald,
                      Colors.white,
                      softEmerald,
                      Colors.white,
                    ]
                  : [
                      deepEmerald,
                      primaryColor,
                      deepEmerald,
                      primaryColor,
                      deepEmerald,
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
                "HAGERE",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 12,
                  color: isDark ? Colors.white.withOpacity(0.85) : deepEmerald,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "TIPS",
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 18,
                  color: isDark ? Colors.white : deepEmerald,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrganicDivider(bool isDark) {
    final color = isDark ? softEmerald : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, color.withOpacity(0.6)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 0.6,
          child: Icon(Icons.eco, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 1.2,
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
      "Explore  ·  Discover  ·  Thrive",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: isDark
            ? paleEmerald.withOpacity(0.6)
            : deepEmerald.withOpacity(0.6),
      ),
    );
  }

  Widget _buildBreathingLoader(bool isDark) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer breathing ring
          AnimatedBuilder(
            animation: _breathe,
            builder: (context, _) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? primaryColor : brightEmerald).withOpacity(
                      0.15 + 0.25 * _breathe.value,
                    ),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          // Spinning arc
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? brightEmerald : primaryColor,
              ),
            ),
          ),
          // Center leaf icon
          Transform.rotate(
            angle: 0.6,
            child: Icon(
              Icons.eco,
              size: 16,
              color: isDark ? softEmerald : primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data holder for floating soft particles
class _SoftParticle {
  final double x;
  final double y;
  final double size;
  final double opacity;

  const _SoftParticle(this.x, this.y, this.size, this.opacity);
}

/// Painter for animated wave layers at the bottom
class _WavePainter extends CustomPainter {
  final double wave1;
  final double wave2;
  final double wave3;
  final Color color1;
  final Color color2;
  final Color color3;

  _WavePainter({
    required this.wave1,
    required this.wave2,
    required this.wave3,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size, wave1, color1, 0.55);
    _drawWave(canvas, size, wave2, color2, 0.45);
    _drawWave(canvas, size, wave3, color3, 0.35);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double phase,
    Color color,
    double amplitudeFactor,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    final amplitude = size.height * 0.08 * amplitudeFactor;
    final frequency = 1.5;
    final baseHeight = size.height * (1 - amplitudeFactor * 0.3);

    for (double x = 0; x <= size.width; x += 2) {
      final y =
          baseHeight +
          amplitude * _sin(frequency * 2 * 3.14159 * x / size.width + phase);
      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  double _sin(double x) => _taylorSin(x);

  double _taylorSin(double x) {
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    if (x < -3.14159265) x += 2 * 3.14159265;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.wave1 != wave1 ||
      oldDelegate.wave2 != wave2 ||
      oldDelegate.wave3 != wave3;
}

/// Painter for the rotating orbit with dots
class _OrbitDotPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _OrbitDotPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer orbit ring
    canvas.drawCircle(center, size.width * 0.46, paint);

    // Inner dashed orbit
    paint.strokeWidth = 0.6;
    _drawDashedCircle(canvas, center, size.width * 0.38, paint);

    // Dots on outer orbit
    const dotCount = 6;
    final dotPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.5 : 0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * 3.14159 / dotCount) * i;
      final dotX = center.dx + size.width * 0.46 * _cos(angle);
      final dotY = center.dy + size.width * 0.46 * _sin(angle);

      // Alternate dot sizes for organic feel
      final dotSize = i.isEven ? 4.0 : 2.5;
      canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);
    }
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

  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 1.5708);

  double _taylorSin(double x) {
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    if (x < -3.14159265) x += 2 * 3.14159265;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  @override
  bool shouldRepaint(covariant _OrbitDotPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
