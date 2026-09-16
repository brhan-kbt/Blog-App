import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:totalpro/core/services/connectivity_service.dart';
import 'package:totalpro/core/services/fcm_service.dart';
import 'package:totalpro/core/state/blog_store.dart';
import 'package:totalpro/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Red primary palette
  static const Color _primaryRed = Color(0xFFE53935);
  static const Color _darkRed = Color(0xFFB71C1C);
  static const Color _lightRed = Color(0xFFFFEBEE);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    _initApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1A0A0A),
                      const Color(0xFF2D0F0F),
                      const Color(0xFF4A1515),
                    ]
                  : [Colors.white, _lightRed, const Color(0xFFFFCDD2)],
            ),
          ),
          child: Stack(
            children: [
              // Top-right diagonal accent shape
              Positioned(
                top: -120,
                right: -80,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                _primaryRed.withOpacity(0.15),
                                _darkRed.withOpacity(0.05),
                              ]
                            : [
                                _primaryRed.withOpacity(0.12),
                                _primaryRed.withOpacity(0.03),
                              ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom-left circle accent
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryRed.withOpacity(isDark ? 0.15 : 0.10),
                        _primaryRed.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Small floating red dots
              Positioned(
                top: 120,
                left: 40,
                child: _buildFloatingDot(8, isDark),
              ),
              Positioned(
                top: 200,
                right: 50,
                child: _buildFloatingDot(5, isDark),
              ),
              Positioned(
                bottom: 180,
                right: 80,
                child: _buildFloatingDot(6, isDark),
              ),

              // Main content
              Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container with red ring
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF2D0F0F)
                              : Colors.white,
                          border: Border.all(color: _primaryRed, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.35),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _primaryRed.withOpacity(0.1),
                                  _darkRed.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/totalpro_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // App name
                      Text(
                        "Total Pro",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: isDark ? Colors.white : _darkRed,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Red divider line
                      Container(
                        width: 50,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [_primaryRed, _darkRed],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        "Powered by Innovation",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Loading indicator
                      _buildLoadingIndicator(isDark),
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

  Widget _buildFloatingDot(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primaryRed.withOpacity(isDark ? 0.4 : 0.3),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          _primaryRed.withOpacity(isDark ? 0.9 : 0.8),
        ),
        backgroundColor: isDark ? Colors.white.withOpacity(0.1) : _lightRed,
      ),
    );
  }
}
