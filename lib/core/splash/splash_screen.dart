import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:milki_tech/core/services/connectivity_service.dart';
import 'package:milki_tech/core/state/blog_store.dart';
import 'package:milki_tech/core/theme/app_palette.dart';
import 'package:milki_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late Animation<double> _logoAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _loadingController.repeat();
  }

  Future<void> _initializeApp() async {
    try {
      // Ensure theme service is available (it should already be initialized in main.dart)
      final themeService = Get.find<ThemeService>();

      // Initialize connectivity service
      Get.put(ConnectivityService(), permanent: true);

      // Check connectivity
      final connectivityService = Get.find<ConnectivityService>();
      await connectivityService.checkConnectivity();

      // Initialize blog store and fetch initial data
      final blogStore = Get.find<BlogStore>();

      // Only fetch data if connected
      if (connectivityService.isConnected) {
        await Future.wait([
          blogStore.fetchPosts(),
          blogStore.fetchCategories(),
        ]);
      }

      // Add minimum splash duration for better UX
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Still navigate to home even if there's an error
      if (mounted) {
        Get.offAllNamed('/home');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      final isDark = themeService.isDark;
      debugPrint(
        '🎨 Splash Screen - Theme Mode: ${themeService.mode.value}, IsDark: $isDark',
      );

      return Scaffold(
        backgroundColor: isDark ? Colors.black87 : Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.black87, Colors.black87, Colors.black87]
                  : [Colors.white, Colors.white, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Logo
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/logo1.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.article_outlined,
                                  size: 60,
                                  color: const Color(0xFF04020F),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // App Name
                Text(
                  'Milki Tech',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 32,
                    fontFamily: 'Pacifico',
                    color: isDark
                        ? const Color.fromARGB(255, 217, 255, 237)
                        : const Color.fromARGB(221, 0, 44, 25),
                  ),
                ),

                const SizedBox(height: 8),

                // Text(
                //   'Your Tech Blog Companion',
                //   style: theme.textTheme.bodyMedium?.copyWith(
                //     color: Colors.white.withOpacity(0.8),
                //   ),
                // ),
                const Spacer(flex: 2),

                // Loading Indicator
                AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: _loadingAnimation.value,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    });
  }
}
