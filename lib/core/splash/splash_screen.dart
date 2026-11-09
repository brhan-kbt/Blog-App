import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selam_tips/core/services/connectivity_service.dart';
import 'package:selam_tips/core/services/fcm_service.dart';
import 'package:selam_tips/core/state/blog_store.dart';
import 'package:selam_tips/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Primary brand color
  static const Color primaryColor = Color(0xFF25736A);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Pulse animation for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scale animation for loader
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    _initApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0A1F1D),
                      const Color(0xFF122E2B),
                      const Color(0xFF1A3C38),
                    ]
                  : [
                      primaryColor,
                      const Color(0xFF2E8B80),
                      const Color(0xFF3DA89B),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -80,
                right: -80,
                child: _buildDecorativeCircle(
                  200,
                  isDark
                      ? primaryColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: _buildDecorativeCircle(
                  250,
                  isDark
                      ? primaryColor.withOpacity(0.1)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.15,
                left: -50,
                child: _buildDecorativeCircle(
                  120,
                  isDark
                      ? Colors.teal.withOpacity(0.08)
                      : Colors.white.withOpacity(0.05),
                ),
              ),

              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo
                        _buildAnimatedLogo(isDark),

                        const SizedBox(height: 40),

                        // App name with fade
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildAppName(isDark),
                        ),

                        const SizedBox(height: 12),

                        // Tagline
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildTagline(isDark),
                        ),

                        const SizedBox(height: 20),

                        // Decorative line
                        _buildDecorativeLine(isDark),

                        const SizedBox(height: 60),

                        // Custom loader
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildCustomLoader(isDark),
                        ),

                        const SizedBox(height: 24),

                        // Loading text
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            "Loading...",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.white.withOpacity(0.7),
                              letterSpacing: 3,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
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
                  opacity: _fadeAnimation,
                  child: Text(
                    "SELAM TIPS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey[700]
                          : Colors.white.withOpacity(0.35),
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    primaryColor.withOpacity(0.9),
                    const Color(0xFF1A3C38),
                  ]
                : [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                  ],
          ),
          boxShadow: [
            // Outer glow
            BoxShadow(
              color: isDark
                  ? primaryColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 10,
            ),
            // Inner shadow
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF0A1F1D) : Colors.white,
            child: Image.asset(
              'assets/selam_tips_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName(bool isDark) {
    return Column(
      children: [
        // "Selam" in lighter weight
        Text(
          "Selam",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
            color: isDark ? Colors.white70 : Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        // "Tips" in bold
        Text(
          "TIPS",
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
            color: isDark ? Colors.white : Colors.white,
            shadows: [
              Shadow(
                blurRadius: 20,
                color: isDark
                    ? primaryColor.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagline(bool isDark) {
    return Text(
      "Discover. Learn. Grow.",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        color: isDark
            ? Colors.teal[300]?.withOpacity(0.8)
            : Colors.white.withOpacity(0.75),
      ),
    );
  }

  Widget _buildDecorativeLine(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLineDot(isDark),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [primaryColor.withOpacity(0.3), primaryColor]
                  : [Colors.white.withOpacity(0.2), Colors.white],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        _buildLineDot(isDark),
      ],
    );
  }

  Widget _buildLineDot(bool isDark) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? primaryColor : Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildCustomLoader(bool isDark) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark
                    ? primaryColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          // Inner spinner
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? primaryColor : Colors.white,
              ),
            ),
          ),
          // Center dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? primaryColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}