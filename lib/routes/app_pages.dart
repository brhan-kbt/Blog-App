import 'package:get/get.dart';
import '../modules/recent/recent_page.dart';
import '../modules/category/category_page.dart';
import '../modules/favorite/favorite_page.dart';
import '../modules/post_detail/post_detail_page.dart';
import '../modules/search/search_page.dart';
import '../modules/settings/settings_page.dart';
import '../models/post.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = Routes.shell;

  static final routes = [
    GetPage(name: Routes.shell, page: () => const RecentPage()),
    GetPage(name: Routes.recent, page: () => const RecentPage()),
    GetPage(name: Routes.category, page: () => const CategoryPage()),
    GetPage(name: Routes.favorite, page: () => const FavoritePage()),

    GetPage(
      name: Routes.postDetail,
      page: () {
        final post = Get.arguments as Post;
        return PostDetailPage(post: post);
      },
    ),

    // NEW
    GetPage(name: Routes.search, page: () => const SearchPage()),
    GetPage(name: Routes.settings, page: () => const SettingsPage()),
  ];
}
