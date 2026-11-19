import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiya_tech/core/services/connectivity_service.dart';
import 'package:kiya_tech/core/services/fcm_service.dart';
import 'package:kiya_tech/core/state/blog_store.dart';
import 'package:kiya_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Ocean blue palette
  static const Color primaryColor = Color(0xFF118FAF);
  static const Color brightBlue = Color(0xFF1DB0D6);
  static const Color softBlue = Color(0xFF6DD3EB);
  static const Color paleBlue = Color(0xFFD1F2FA);
  static const Color deepBlue = Color(0xFF0A5A6E);
  static const Color abyssBlue = Color(0xFF052F3A);

  late AnimationController _entryController;
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _shimmerController;
  late AnimationController _swirlController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _wave1;
  late Animation<double> _wave2;
  late Animation<double> _wave3;
  late Animation<double> _bubbleRise;
  late Animation<double> _shimmer;
  late Animation<double> _swirl;

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
      duration: const Duration(milliseconds: 6000),
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

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _bubbleRise = Tween<double>(
      begin: 1.0,
      end: -0.2,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.linear));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _swirlController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();
    _swirl = Tween<double>(
      begin: 0.0,
      end: 6.28318,
    ).animate(CurvedAnimation(parent: _swirlController, curve: Curves.linear));

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _waveController.dispose();
    _bubbleController.dispose();
    _shimmerController.dispose();
    _swirlController.dispose();
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
                      const Color(0xFF021419),
                      const Color(0xFF052F3A),
                      const Color(0xFF0A5A6E),
                    ]
                  : [
                      const Color(0xFFF0FBFD),
                      paleBlue,
                      const Color(0xFFA8E4F2),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient radial glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.25),
                          radius: 0.9,
                          colors: [
                            (isDark ? primaryColor : brightBlue).withOpacity(
                              isDark ? 0.25 : 0.15,
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
                height: size.height * 0.45,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OceanWavePainter(
                        wave1: _wave1.value,
                        wave2: _wave2.value,
                        wave3: _wave3.value,
                        color1: (isDark ? primaryColor : brightBlue)
                            .withOpacity(isDark ? 0.12 : 0.18),
                        color2: (isDark ? brightBlue : softBlue).withOpacity(
                          isDark ? 0.08 : 0.14,
                        ),
                        color3: (isDark ? softBlue : paleBlue).withOpacity(
                          isDark ? 0.06 : 0.10,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rising bubbles
              ..._buildBubbles(isDark, size),

              // Rotating swirl ring
              Positioned(
                top: size.height * 0.5 - 205,
                left: size.width * 0.5 - 205,
                child: AnimatedBuilder(
                  animation: _swirl,
                  builder: (context, child) {
                    return Transform.rotate(angle: _swirl.value, child: child);
                  },
                  child: SizedBox(
                    width: 410,
                    height: 410,
                    child: CustomPaint(
                      painter: _SwirlRingPainter(
                        color: (isDark ? brightBlue : primaryColor).withOpacity(
                          isDark ? 0.18 : 0.12,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Droplet-shaped logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildDropletLogo(isDark),
                        ),

                        const SizedBox(height: 44),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 14),

                        // Wave divider
                        _buildWaveDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 60),

                        // Ripple loader
                        _buildRippleLoader(isDark),
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
                        Icons.water_drop,
                        size: 11,
                        color: isDark
                            ? softBlue.withOpacity(0.5)
                            : primaryColor.withOpacity(0.45),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "KIYA TECH",
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
                      Icon(
                        Icons.water_drop,
                        size: 11,
                        color: isDark
                            ? softBlue.withOpacity(0.5)
                            : primaryColor.withOpacity(0.45),
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

  List<Widget> _buildBubbles(bool isDark, Size size) {
    final bubbles = [
      _Bubble(size.width * 0.12, 0.9, 6.0, 0.0),
      _Bubble(size.width * 0.88, 0.85, 8.0, 1.2),
      _Bubble(size.width * 0.25, 0.92, 4.0, 0.6),
      _Bubble(size.width * 0.72, 0.88, 5.0, 2.0),
      _Bubble(size.width * 0.45, 0.95, 3.5, 1.8),
      _Bubble(size.width * 0.60, 0.90, 6.5, 0.9),
    ];

    return bubbles.map((b) {
      return AnimatedBuilder(
        animation: _bubbleController,
        builder: (context, _) {
          final progress = (_bubbleRise.value + b.offset) % 1.0;
          final y = b.startY * size.height * progress;
          final opacity = progress < 0.8
              ? (1.0 - progress / 0.8).clamp(0.0, 1.0)
              : 0.0;

          return Positioned(
            left: b.x,
            top: size.height * 0.85 - y,
            child: Container(
              width: b.size,
              height: b.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? softBlue : primaryColor).withOpacity(
                    0.4 * opacity,
                  ),
                  width: 1.2,
                ),
                color: (isDark ? brightBlue : softBlue).withOpacity(
                  0.08 * opacity,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildDropletLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : brightBlue).withOpacity(0.4),
                blurRadius: 55,
                spreadRadius: 14,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
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
          // Outer gradient ring
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isDark
                    ? [
                        primaryColor,
                        brightBlue,
                        softBlue,
                        brightBlue,
                        primaryColor,
                      ]
                    : [
                        deepBlue,
                        primaryColor,
                        brightBlue,
                        primaryColor,
                        deepBlue,
                      ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // Middle ring
          Container(
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? abyssBlue : Colors.white,
            ),
          ),

          // Inner gradient
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [primaryColor.withOpacity(0.5), abyssBlue]
                    : [Colors.white, paleBlue],
              ),
            ),
          ),

          // Logo image
          ClipOval(
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(14),
              color: isDark ? abyssBlue : Colors.white,
              child: Image.asset(
                'assets/kiya_tech_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Small water drop accents around the ring
          ..._buildDropletAccents(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildDropletAccents(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.water_drop,
              size: 13,
              color: isDark ? softBlue : Colors.white,
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
                      softBlue,
                      Colors.white,
                      softBlue,
                      Colors.white,
                    ]
                  : [deepBlue, primaryColor, deepBlue, primaryColor, deepBlue],
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
                "KIYA",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 14,
                  color: isDark ? Colors.white.withOpacity(0.85) : deepBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "TECH",
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 18,
                  color: isDark ? Colors.white : deepBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveDivider(bool isDark) {
    final color = isDark ? softBlue : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, color.withOpacity(0.6)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.water_drop, size: 13, color: color),
        const SizedBox(width: 8),
        Icon(Icons.water_drop, size: 9, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Icon(Icons.water_drop, size: 13, color: color),
        const SizedBox(width: 8),
        Container(
          width: 36,
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
      "Flow  ·  Create  ·  Innovate",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: isDark ? paleBlue.withOpacity(0.6) : deepBlue.withOpacity(0.6),
      ),
    );
  }

  Widget _buildRippleLoader(bool isDark) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripple ring
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? primaryColor : brightBlue).withOpacity(
                      0.15 + 0.15 * _wave1.value / 6.28318,
                    ),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          // Spinning arc
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? brightBlue : primaryColor,
              ),
            ),
          ),
          // Center water drop icon
          Icon(
            Icons.water_drop,
            size: 16,
            color: isDark ? softBlue : primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Data holder for rising bubbles
class _Bubble {
  final double x;
  final double startY;
  final double size;
  final double offset;

  const _Bubble(this.x, this.startY, this.size, this.offset);
}

/// Painter for animated ocean wave layers
class _OceanWavePainter extends CustomPainter {
  final double wave1;
  final double wave2;
  final double wave3;
  final Color color1;
  final Color color2;
  final Color color3;

  _OceanWavePainter({
    required this.wave1,
    required this.wave2,
    required this.wave3,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size, wave1, color1, 0.55, 1.2);
    _drawWave(canvas, size, wave2, color2, 0.45, 1.8);
    _drawWave(canvas, size, wave3, color3, 0.35, 1.5);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double phase,
    Color color,
    double amplitudeFactor,
    double frequency,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    final amplitude = size.height * 0.12 * amplitudeFactor;
    final baseHeight = size.height * (1 - amplitudeFactor * 0.4);

    for (double x = 0; x <= size.width; x += 2) {
      final y =
          baseHeight +
          amplitude * _sin(frequency * 2 * 3.14159 * x / size.width + phase);
      path.lineTo(x, y);
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
  bool shouldRepaint(covariant _OceanWavePainter oldDelegate) =>
      oldDelegate.wave1 != wave1 ||
      oldDelegate.wave2 != wave2 ||
      oldDelegate.wave3 != wave3;
}

/// Painter for the rotating swirl ring
class _SwirlRingPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _SwirlRingPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer swirl ring
    canvas.drawCircle(center, size.width * 0.46, paint);

    // Middle dashed ring
    paint.strokeWidth = 0.7;
    _drawDashedCircle(canvas, center, size.width * 0.39, paint);

    // Inner faint ring
    paint.strokeWidth = 1.2;
    canvas.drawCircle(center, size.width * 0.32, paint);

    // Small dots on outer ring
    const dotCount = 8;
    final dotPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.6 : 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * 3.14159 / dotCount) * i;
      final dotX = center.dx + size.width * 0.46 * _cos(angle);
      final dotY = center.dy + size.width * 0.46 * _sin(angle);

      // Alternate dots and small circles
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(dotX, dotY), 3.5, dotPaint);
      } else {
        canvas.drawCircle(
          Offset(dotX, dotY),
          2.5,
          Paint()
            ..color = color.withOpacity(isDark ? 0.4 : 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 12.0;
    const gapLength = 16.0;
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
  bool shouldRepaint(covariant _SwirlRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
