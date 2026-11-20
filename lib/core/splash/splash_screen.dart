import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selam_tech/core/services/connectivity_service.dart';
import 'package:selam_tech/core/services/fcm_service.dart';
import 'package:selam_tech/core/state/blog_store.dart';
import 'package:selam_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Bright sky blue palette
  static const Color primaryColor = Color(0xFF13B1E8);
  static const Color brightBlue = Color(0xFF3FC4F2);
  static const Color softBlue = Color(0xFF8DDCF5);
  static const Color paleBlue = Color(0xFFDCF4FC);
  static const Color deepBlue = Color(0xFF0A7296);
  static const Color abyssBlue = Color(0xFF063A4D);

  late AnimationController _entryController;
  late AnimationController _beamController;
  late AnimationController _cloudController;
  late AnimationController _shimmerController;
  late AnimationController _breatheController;
  late AnimationController _floatController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _beamSweep;
  late Animation<double> _cloudDrift;
  late Animation<double> _shimmer;
  late Animation<double> _breathe;
  late Animation<double> _float;

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

    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _beamSweep = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _beamController, curve: Curves.easeInOut),
    );

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    )..repeat();
    _cloudDrift = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cloudController, curve: Curves.linear));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breathe = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _beamController.dispose();
    _cloudController.dispose();
    _shimmerController.dispose();
    _breatheController.dispose();
    _floatController.dispose();
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
                      abyssBlue,
                      const Color(0xFF0A4B62),
                    ]
                  : [
                      const Color(0xFFF2FCFF),
                      paleBlue,
                      const Color(0xFFB4E9F9),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Drifting cloud shapes
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _cloudController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CloudPainter(
                        progress: _cloudDrift.value,
                        color: (isDark ? brightBlue : Colors.white).withOpacity(
                          isDark ? 0.06 : 0.35,
                        ),
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),

              // Light beams sweeping across
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _beamController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _BeamPainter(
                        sweep: _beamSweep.value,
                        color: (isDark ? brightBlue : Colors.white).withOpacity(
                          isDark ? 0.08 : 0.25,
                        ),
                      ),
                    );
                  },
                ),
              ),

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
                            (isDark ? primaryColor : brightBlue).withOpacity(
                              0.2 * _breathe.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Floating glass panels (decorative)
              ..._buildGlassPanels(isDark, size),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glass-card logo
                        ScaleTransition(
                          scale: _scaleIn,
                          child: _buildGlassLogo(isDark),
                        ),

                        const SizedBox(height: 48),

                        // Shimmering title
                        _buildShimmerTitle(isDark),

                        const SizedBox(height: 14),

                        // Airy divider
                        _buildAiryDivider(isDark),

                        const SizedBox(height: 14),

                        // Tagline
                        _buildTagline(isDark),

                        const SizedBox(height: 62),

                        // Glass loader
                        _buildGlassLoader(isDark),
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
                        Icons.cloud_outlined,
                        size: 12,
                        color: isDark
                            ? softBlue.withOpacity(0.5)
                            : primaryColor.withOpacity(0.45),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SELAM TECH",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : primaryColor.withOpacity(0.55),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.cloud_outlined,
                        size: 12,
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

  List<Widget> _buildGlassPanels(bool isDark, Size size) {
    return [
      Positioned(
        top: size.height * 0.12,
        left: size.width * 0.06,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _float.value * 0.5),
              child: _glassPanel(40, isDark, 0.6),
            );
          },
        ),
      ),
      Positioned(
        top: size.height * 0.28,
        right: size.width * 0.04,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, -_float.value * 0.4),
              child: _glassPanel(55, isDark, 0.8),
            );
          },
        ),
      ),
      Positioned(
        bottom: size.height * 0.22,
        left: size.width * 0.08,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _float.value * 0.6),
              child: _glassPanel(30, isDark, 0.5),
            );
          },
        ),
      ),
      Positioned(
        bottom: size.height * 0.30,
        right: size.width * 0.10,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, -_float.value * 0.7),
              child: _glassPanel(45, isDark, 0.7),
            );
          },
        ),
      ),
    ];
  }

  Widget _glassPanel(double size, bool isDark, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? brightBlue : Colors.white).withOpacity(
              opacity * (isDark ? 0.08 : 0.35),
            ),
            (isDark ? primaryColor : softBlue).withOpacity(
              opacity * (isDark ? 0.03 : 0.15),
            ),
          ],
        ),
        border: Border.all(
          color: (isDark ? brightBlue : Colors.white).withOpacity(
            opacity * (isDark ? 0.15 : 0.6),
          ),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? brightBlue : primaryColor).withOpacity(
              0.08 * opacity,
            ),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        return Container(
          width: 172,
          height: 172,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? primaryColor : brightBlue).withOpacity(
                  0.4 * _breathe.value,
                ),
                blurRadius: 60,
                spreadRadius: 18,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
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
          // Outer glass ring
          Container(
            width: 172,
            height: 172,
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

          // Middle glass ring
          Container(
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? abyssBlue : Colors.white.withOpacity(0.95),
            ),
          ),

          // Inner radial gradient (glass highlight)
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: isDark
                    ? [
                        softBlue.withOpacity(0.2),
                        primaryColor.withOpacity(0.4),
                        abyssBlue,
                      ]
                    : [Colors.white, paleBlue, softBlue.withOpacity(0.5)],
                stops: const [0.0, 0.5, 1.0],
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
                'assets/selam_tech_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Glass highlight arc
          Positioned(
            top: 12,
            left: 30,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.15 : 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Small cloud accents at cardinal points
          ..._buildCloudAccents(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildCloudAccents(bool isDark) {
    final angles = [0.0, 1.5708, 3.14159, 4.71239];
    return angles.map((angle) {
      return Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Icon(
              Icons.cloud,
              size: 13,
              color: isDark ? softBlue.withOpacity(0.8) : Colors.white,
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
                "SELAM",
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
                  letterSpacing: 22,
                  color: isDark ? Colors.white : deepBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiryDivider(bool isDark) {
    final color = isDark ? softBlue : primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, color.withOpacity(0.6)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.cloud_outlined, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Icon(Icons.cloud, size: 16, color: color),
        const SizedBox(width: 6),
        Icon(Icons.cloud_outlined, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 10),
        Container(
          width: 30,
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
      "Soar  ·  Discover  ·  Connect",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: isDark ? paleBlue.withOpacity(0.6) : deepBlue.withOpacity(0.6),
      ),
    );
  }

  Widget _buildGlassLoader(bool isDark) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer breathing glass ring
          AnimatedBuilder(
            animation: _breathe,
            builder: (context, _) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? primaryColor : brightBlue).withOpacity(
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
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? softBlue : primaryColor,
              ),
            ),
          ),
          // Center cloud icon
          Icon(Icons.cloud, size: 16, color: isDark ? softBlue : primaryColor),
        ],
      ),
    );
  }
}

/// Painter for drifting cloud shapes
class _CloudPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _CloudPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a few large soft cloud clusters that drift
    _drawCloud(
      canvas,
      Offset(size.width * ((progress * 0.5) % 1.5 - 0.25), size.height * 0.15),
      size.width * 0.35,
      paint,
    );
    _drawCloud(
      canvas,
      Offset(
        size.width * ((progress * 0.4 + 0.5) % 1.4 - 0.2),
        size.height * 0.40,
      ),
      size.width * 0.28,
      paint,
    );
    _drawCloud(
      canvas,
      Offset(
        size.width * ((progress * 0.6 + 0.2) % 1.3 - 0.15),
        size.height * 0.65,
      ),
      size.width * 0.42,
      paint,
    );
    _drawCloud(
      canvas,
      Offset(
        size.width * ((progress * 0.3 + 0.7) % 1.2 - 0.1),
        size.height * 0.85,
      ),
      size.width * 0.30,
      paint,
    );
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
    // Draw a cluster of overlapping circles to form a cloud
    final height = width * 0.35;
    final radius = width * 0.25;

    canvas.drawCircle(
      Offset(center.dx - width * 0.2, center.dy),
      radius * 0.9,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.05, center.dy - height * 0.3),
      radius * 1.1,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.25, center.dy),
      radius * 0.85,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx - width * 0.05, center.dy + height * 0.2),
      radius * 0.75,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Painter for light beams sweeping across
class _BeamPainter extends CustomPainter {
  final double sweep;
  final Color color;

  _BeamPainter({required this.sweep, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw diagonal light beams
    for (int i = 0; i < 3; i++) {
      final offset = (sweep + i * 0.4) % 3.0 - 1.0;
      final startX = size.width * (offset - 0.5);
      final endX = size.width * (offset + 0.2);

      final path = Path()
        ..moveTo(startX, 0)
        ..lineTo(endX, 0)
        ..lineTo(endX - size.width * 0.6, size.height)
        ..lineTo(startX - size.width * 0.6, size.height)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.color != color;
}
