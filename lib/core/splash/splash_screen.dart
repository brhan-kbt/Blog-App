import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ormitech/core/services/connectivity_service.dart';
import 'package:ormitech/core/services/fcm_service.dart';
import 'package:ormitech/core/state/blog_store.dart';
import 'package:ormitech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _fade;
  late Animation<double> _slide;
  late Animation<double> _pulse;

  // Brand palette
  static const Color _primary = Color(0xFF5735E8);
  static const Color _deep = Color(0xFF2A1670);
  static const Color _soft = Color(0xFFEDE9FF);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulse = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0B0620),
                      _deep,
                      _primary,
                    ]
                  : [
                      Colors.white,
                      _soft,
                      const Color(0xFFD9D2FF),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // ── Large soft glow behind logo ──────────────────
              Positioned(
                top: MediaQuery.of(context).size.height * 0.20,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Container(
                        width: 320 * _pulse.value,
                        height: 320 * _pulse.value,
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

              // ── Top-left diagonal accent bar ─────────────────
              Positioned(
                top: -60,
                left: -40,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          _primary.withOpacity(0.35),
                          _primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom-right accent bar ──────────────────────
              Positioned(
                bottom: -40,
                right: -60,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    width: 240,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          _primary.withOpacity(0.0),
                          _primary.withOpacity(0.35),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Small floating dots ──────────────────────────
              Positioned(
                top: 140,
                left: 60,
                child: _dot(6, isDark),
              ),
              Positioned(
                top: 220,
                right: 70,
                child: _dot(4, isDark),
              ),
              Positioned(
                bottom: 200,
                left: 80,
                child: _dot(5, isDark),
              ),
              Positioned(
                bottom: 140,
                right: 50,
                child: _dot(8, isDark),
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
                      // Hexagon-style logo frame
                      _buildHexLogo(isDark),

                      const SizedBox(height: 44),

                      // App name — "Ormi" bold + "Tech" light
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Ormi",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white : _deep,
                              ),
                            ),
                            TextSpan(
                              text: " Tech",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                                color: isDark
                                    ? _primary.withOpacity(0.9)
                                    : _primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pill-shaped tagline badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isDark
                              ? _primary.withOpacity(0.20)
                              : _primary.withOpacity(0.10),
                          border: Border.all(
                            color: _primary.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "INNOVATE  •  BUILD  •  GROW",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                            color: isDark
                                ? Colors.white.withOpacity(0.85)
                                : _primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 90),

                      // Custom three-bar loader
                      _buildBarLoader(isDark),
                    ],
                  ),
                ),
              ),

              // ── Bottom version text ──────────────────────────
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Text(
                  "v1.0.0",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: isDark
                        ? Colors.white.withOpacity(0.35)
                        : Colors.black.withOpacity(0.30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Hexagon logo frame ─────────────────────────────────
  Widget _buildHexLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: Border.all(
              color: _primary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35 * _pulse.value),
                blurRadius: 30,
                spreadRadius: 3,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        );
      },
      child: ClipOval(
        child: Image.asset(
          'assets/ormitech_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ── Three-bar animated loader ──────────────────────────
  Widget _buildBarLoader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            // Stagger the bars
            final t = (_pulseController.value + i * 0.25) % 1.0;
            final scale = 0.5 + (0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 5,
              height: 24 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _primary.withOpacity(isDark ? 0.9 : 0.75),
              ),
            );
          },
        );
      }),
    );
  }

  // ── Small floating dot ─────────────────────────────────
  Widget _dot(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primary.withOpacity(isDark ? 0.5 : 0.35),
      ),
    );
  }
}