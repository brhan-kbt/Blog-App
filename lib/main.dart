import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:milki_tech/core/theme/app_palette.dart';
import 'package:milki_tech/core/theme/theme_service.dart';
import 'package:milki_tech/core/services/connectivity_service.dart';
import 'package:milki_tech/core/services/performance_service.dart';
import 'package:milki_tech/routes/app_pages.dart';
import 'core/state/blog_store.dart';
import 'core/theme/app_theme.dart';
import 'modules/category/category_page.dart';
import 'modules/favorite/favorite_page.dart';
import 'modules/recent/recent_page.dart';
import 'widgets/search_header.dart';
import 'core/ads/ad_service.dart';
import 'widgets/banner_ad_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage first (required for theme service)
  await GetStorage.init();

  // Initialize theme service first to ensure proper theme loading
  await _initializeThemeService();

  // Initialize other services in parallel
  await Future.wait([
    _initializeBlogStore(),
    _initializeAds(),
    _initializePerformanceService(),
  ]);

  runApp(const MilkiApp());
}

Future<void> _initializeThemeService() async {
  final themeSvc = Get.put(ThemeService(), permanent: true);
  await themeSvc.init();

  // Small delay to ensure theme is properly applied
  await Future.delayed(const Duration(milliseconds: 100));

  debugPrint(
    "🎨 ThemeService - Initialization complete. Mode: ${themeSvc.mode.value}, IsDark: ${themeSvc.isDark}",
  );
}

Future<void> _initializeBlogStore() async {
  Get.put(BlogStore(), permanent: true);
}

Future<void> _initializeAds() async {
  try {
    await MobileAds.instance.initialize();
    await AdService.instance.initialize();
    AdService.instance.loadAppOpenAd();
  } catch (e) {
    debugPrint('Error initializing ads: $e');
    // Continue app initialization even if ads fail
  }
}

Future<void> _initializePerformanceService() async {
  Get.put(PerformanceService(), permanent: true);
}

class MilkiApp extends StatelessWidget {
  const MilkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSvc = Get.find<ThemeService>();

    return Obx(() {
      debugPrint(
        "🎨 MilkiApp - Building with theme mode: ${themeSvc.mode.value}",
      );
      debugPrint("🎨 MilkiApp - IsDark: ${themeSvc.isDark}");

      return GetMaterialApp(
        title: 'Milki Tech',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeSvc.mode.value,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      );
    });
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int index = 0;
  final store = Get.find<BlogStore>();
  final connectivityService = Get.find<ConnectivityService>();
  final titles = const ['Milki', 'Category', 'Favorite'];

  final box = GetStorage();

  // Lazy loading for pages
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize pages lazily
    pages = [const RecentPage(), const CategoryPage(), const FavoritePage()];

    _checkFirstLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     _checkNotificationStatus();
  //     // Show custom app resume ad dialog
  //     AdService.instance.showAppResumeAd(context);
  //   }
  // }
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdService.instance.showAppOpenAd();
    }
  }

  Future<void> _checkFirstLaunch() async {
    final isFirstLaunch = box.read("isFirstLaunch") ?? true;
    if (isFirstLaunch) {
      await _checkNotificationStatus();
      await box.write("isFirstLaunch", false);
    }
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final status = await Permission.notification.status;
      if (!mounted) return;
      if (status.isGranted) {
        debugPrint("✅ Notifications allowed");
      } else {
        debugPrint("❌ Notifications disabled");
      }
    } catch (e, st) {
      debugPrint("⚠️ Error checking notifications: $e\n$st");
    }
  }

  /// 🔹 Refresh depending on active tab
  Future<void> _onRefresh() async {
    // Check connectivity before refreshing
    if (!connectivityService.isConnected) {
      Get.snackbar(
        'No Internet',
        'Please check your internet connection',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      if (index == 0 || index == 2) {
        // Refresh posts for Recent or Favorite
        await store.fetchPosts();
      }
      if (index == 1) {
        // Refresh categories for Category page
        await store.fetchCategories();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choice = Random().nextInt(3); // 0 none, 1 interstitial, 2 rewarded

    print("Random choice: $choice");

    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Connectivity indicator
            Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: connectivityService.isConnected ? 0 : 30,
                child: connectivityService.isConnected
                    ? const SizedBox.shrink()
                    : Container(
                        width: double.infinity,
                        color: Colors.red,
                        child: const Center(
                          child: Text(
                            'No Internet Connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SearchHeader(
              title: "Search ... ",
              onChanged: (q) => store.query.value = q,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: pages[index],
              ),
            ),
            // Bottom banner ad on all pages (slightly smaller than inline)
            const SizedBox(height: 8),
            if (choice == 1 || choice == 2)
              const BannerAdWidget(size: AdSize(width: 370, height: 70)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: Brightness.light == theme.brightness
            ? const Color.fromARGB(255, 242, 242, 242)
            : const Color.fromARGB(255, 16, 16, 36),
        indicatorColor: palette.favoriteActive,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Recent',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Category',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
        ],
      ),
    );
  }
}
