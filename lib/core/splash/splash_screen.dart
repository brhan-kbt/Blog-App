import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:milki_tech/core/services/connectivity_service.dart';
import 'package:milki_tech/core/state/blog_store.dart';
import 'package:milki_tech/core/theme/theme_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoPulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Logo pulsing glow
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  Future<void> _initializeApp() async {
    try {
      Get.put(ConnectivityService(), permanent: true);
      final connectivityService = Get.find<ConnectivityService>();
      await connectivityService.checkConnectivity();

      final blogStore = Get.find<BlogStore>();
      if (connectivityService.isConnected) {
        await Future.wait([
          blogStore.fetchPosts(),
          blogStore.fetchCategories(),
        ]);
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) Get.offAllNamed('/home');
    } catch (e) {
      debugPrint("Init error: $e");
      if (mounted) Get.offAllNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoPulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Scaffold(
      body: Obx(() {
        final isDark = themeService.isDark;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: isDark
                  ? [
                      const Color(0xff0d2a2d),
                      const Color(0xff32a1af),
                      const Color(0xff123437),
                    ]
                  : [
                      const Color.fromARGB(255, 16, 51, 55),
                      const Color(0xff32a1af),
                      const Color(0xff195158),
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo with glowing pulse
                AnimatedBuilder(
                  animation: _logoPulseController,
                  builder: (context, child) {
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(
                              0.5 * _logoPulseController.value + 0.3,
                            ),
                            Color.fromARGB(255, 11, 36, 39).withOpacity(0.8),
                          ],
                          radius: 0.8,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/milki_tech_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.memory_rounded,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // App Name with shimmer effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.white70, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    "Milki Tech",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                      fontFamily: "Pacifico",
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Custom Loading Bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Container(
                      width: 180,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.white,
                                Color.fromARGB(255, 22, 70, 77),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  "Loading...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        );
      }),
    );
  }
}
