import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abay_tips/core/config/api_config.dart';
import 'package:abay_tips/core/theme/app_palette.dart';
import 'package:abay_tips/models/category.dart';
import 'package:abay_tips/modules/category/category_listing_page.dart';
import 'package:abay_tips/widgets/adabtiveBanner.dart';
import 'package:abay_tips/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/post_options_sheet.dart';
import '../post_detail/post_detail_page.dart';
import '../../widgets/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RecentPage extends StatelessWidget {
  const RecentPage({super.key});

  void _openPost(Post post, BlogStore store) {
    store.addView(post.id); // ✅ increment views on backend
    Get.to(() => PostDetailPage(postId: post.id));
  }

  void _openCategory(Category category) {
    Get.to(() => CategoryListingPage(catId: category.id, title: category.name));
  }

  Widget _buildCategoryChip(Category category, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openCategory(category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category.image != null && category.image!.isNotEmpty)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(
                        "${ApiConfig.imageUrl}${category.image!}",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                category.name,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> categories, ThemeData theme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 0, bottom: 16, left: 8, right: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryChip(category, theme);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Obx(() {
      final list = [...store.filtered]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (store.isLoadingPosts.value) {
        return ListView(
          children: const [
            HeroCardShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
          ],
        );
      }

      if (list.isEmpty) {
        // i want a way to refresh the posts here
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Sorry, something went wrong."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  store.fetchPosts();
                },
                child: const Text("Refresh"),
              ),
            ],
          ),
        );
      }

      final top = list.first;
      final rest = list.length > 1 ? list.sublist(1) : const <Post>[];

      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          HeroCard(
            post: top,
            onTap: () => _openPost(top, store),
            onMore: () => showPostOptionsSheet(context, top),
          ),

          // list of categories
          if (store.categories.isNotEmpty)
            _buildCategoriesSection(store.categories, theme),

          ...List.generate(rest.length, (index) {
            final p = rest[index];
            final widgets = <Widget>[
              PostTile(
                post: p,
                onTap: () => _openPost(p, store),
                onMore: () => showPostOptionsSheet(context, p),
              ),
            ];

            if ((index + 1) % 3 == 0) {
              widgets.add(const AdaptiveBannerAdWidget());
            }
            return Column(children: widgets);
          }),
        ],
      );
    });
  }
}
