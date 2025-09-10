import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:qubee/core/theme/app_palette.dart';
import 'package:qubee/core/theme/theme_service.dart';
import 'package:qubee/routes/app_pages.dart';
import 'core/state/blog_store.dart';
import 'core/theme/app_theme.dart';
import 'modules/category/category_page.dart';
import 'modules/favorite/favorite_page.dart';
import 'modules/recent/recent_page.dart';
import 'widgets/search_header.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  final themeSvc = Get.put(ThemeService(), permanent: true);
  await themeSvc.init();

  Get.put(BlogStore(), permanent: true);

  runApp(const QubeeApp());
}

class QubeeApp extends StatelessWidget {
  const QubeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSvc = Get.find<ThemeService>();

    return Obx(
      () => GetMaterialApp(
        title: 'Qubee',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeSvc.mode.value,
        home: const Shell(),
        getPages: AppPages.routes,
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int index = 0;
  final pages = const [RecentPage(), CategoryPage(), FavoritePage()];
  final titles = const ['Qubee', 'Category', 'Favorite'];

  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 👈 listen for app resume
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationStatus(); // 👈 re-check permission safely
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

      if (!mounted) return; // 👈 avoid crash on disposed widget

      if (status.isGranted) {
        debugPrint("✅ Notifications allowed");
      } else {
        debugPrint("❌ Notifications disabled");
        // Don't call setState here unless you really need UI update
        // Instead show safe feedback like:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text("Notifications are disabled.")),
          // );
        });
      }
    } catch (e, st) {
      debugPrint("⚠️ Error checking notifications: $e\n$st");
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            SearchHeader(
              title: "Search ... ",
              onChanged: (q) => store.query.value = q,
            ),
            const SizedBox(height: 8),
            Expanded(child: pages[index]),
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
