import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abayjobs/modules/category/horizontalCategory.dart';
import 'package:abayjobs/widgets/adabtiveBanner.dart';
import 'package:abayjobs/widgets/featured_post_tile.dart';
import 'package:abayjobs/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/post_options_sheet.dart';
import '../post_detail/post_detail_page.dart';

class RecentPage extends StatelessWidget {
  const RecentPage({super.key});

  void _openPost(Post post, BlogStore store) {
    store.addView(post.id);
    Get.to(() => PostDetailPage(postId: post.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    return Obx(() {
      final list = [...store.filtered]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 🔄 Loading shimmer
      if (store.isLoadingPosts.value && list.isEmpty) {
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

      // ❌ Empty State with refresh button
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No jobs found right now."),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => store.fetchPosts(),
                icon: const Icon(Icons.refresh),
                label: const Text("Reload Jobs"),
              ),
            ],
          ),
        );
      }

      // ✅ Main content with infinite scroll
      return RefreshIndicator(
        onRefresh: () async => await store.fetchPosts(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            // ✅ Infinite scroll trigger
            if (!store.isLoadingMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 100 &&
                store.canLoadMore) {
              store.currentPage++;
              store.fetchPosts(loadMore: true);
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount:
                list.length +
                (store.canLoadMore ? 1 : 0) +
                (store.featuredPosts.isNotEmpty ? 3 : 2),
            itemBuilder: (context, index) {
              // 🏆 Featured jobs section
              if (store.featuredPosts.isNotEmpty && index == 0) {
                return SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.featuredPosts.length,
                    padding: const EdgeInsets.only(left: 16),
                    itemBuilder: (context, fIndex) {
                      final featured = store.featuredPosts[fIndex];
                      return FeaturedPostTile(
                        post: featured,
                        onTap: () => _openPost(featured, store),
                      );
                    },
                  ),
                );
              }

              // 🏷️ Categories section
              if (store.featuredPosts.isNotEmpty && index == 1) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: HorizontalCategory(),
                );
              }

              // 🧾 Title before job list
              if (store.featuredPosts.isNotEmpty && index == 2) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    "Recent Jobs",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              // 🧱 Job posts list
              final adjustedIndex =
                  index -
                  (store.featuredPosts.isNotEmpty
                      ? 3
                      : 0); // adjust index offset
              if (adjustedIndex < 0 || adjustedIndex >= list.length) {
                // 🔄 Loader at the bottom
                if (store.canLoadMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }

              final p = list[adjustedIndex];
              final widgets = <Widget>[
                PostTile(
                  post: p,
                  onTap: () => _openPost(p, store),
                  onMore: () => showPostOptionsSheet(context, p),
                ),
              ];

              // 💰 Insert banner ads every 3 posts
              if ((adjustedIndex + 1) % 3 == 0) {
                widgets.add(const AdaptiveBannerAdWidget());
              }

              return Column(children: widgets);
            },
          ),
        ),
      );
    });
  }
}
