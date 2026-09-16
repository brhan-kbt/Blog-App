import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ethiopro/core/services/connectivity_service.dart';
import 'package:ethiopro/core/services/fcm_service.dart';
import 'package:ethiopro/core/state/blog_store.dart';
import 'package:ethiopro/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  // Primary brand color
  static const Color _primary = Color(0xFF1C25AD);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _initApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    try {
      // Avoid duplicate navigation
      if (Get.currentRoute == '/home') return;

      // FCM check
      if (Get.isRegistered<FCMService>()) {
        final fcm = Get.find<FCMService>();
        if (fcm.hasNavigatedFromNotification) {
          Get.offAllNamed('/home');
          return;
        }
      }

      // Services
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

      // Check notifications
      await _handleNotifications();

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Prevent override if already navigated
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
                  ? [const Color(0xFF0A0E3D), const Color(0xFF141A6E), _primary]
                  : [
                      Colors.white,
                      const Color(0xFFEEF0FF),
                      const Color(0xFFDDE1FF),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Top-right accent circle
              Positioned(
                top: -110,
                right: -110,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary.withOpacity(isDark ? 0.25 : 0.08),
                  ),
                ),
              ),

              // Bottom-left accent circle
              Positioned(
                bottom: -90,
                left: -90,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary.withOpacity(isDark ? 0.20 : 0.06),
                  ),
                ),
              ),

              // Main content
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(scale: _scale, child: child),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container with brand-colored ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white,
                          border: Border.all(color: _primary, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.30),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/ethiopro_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // App name
                      Text(
                        "Ethio Pro",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: isDark ? Colors.white : _primary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Brand-colored divider
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _primary,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Subtitle
                      Text(
                        "Powered by Innovation",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.55),
                        ),
                      ),

                      const SizedBox(height: 70),

                      // Loading indicator
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _primary.withOpacity(isDark ? 0.95 : 0.85),
                          ),
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : _primary.withOpacity(0.12),
                        ),
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
}
