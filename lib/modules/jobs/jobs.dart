import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abayjobs/widgets/adabtiveBanner.dart';
import 'package:abayjobs/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/post_options_sheet.dart';
import '../post_detail/post_detail_page.dart';

class JobsListPage extends StatelessWidget {
  const JobsListPage({super.key});

  void _openPost(Post post, BlogStore store) {
    store.addView(post.id); // ✅ increment views on backend
    Get.to(() => PostDetailPage(postId: post.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    return Obx(() {
      final list = [...store.filtered]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (store.isLoadingPosts.value) {
        return ListView(
          children: const [
            // HeroCardShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
            PostTileShimmer(),
          ],
        );
      }

      if (list.isEmpty) {
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

      return RefreshIndicator(
        onRefresh: () async {
          await store.fetchPosts();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
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
            itemCount: list.length + (store.canLoadMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == list.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final p = list[index];
              return Column(
                children: [
                  PostTile(
                    post: p,
                    onTap: () => _openPost(p, store),
                    onMore: () => showPostOptionsSheet(context, p),
                  ),
                  if ((index + 1) % 3 == 0) const AdaptiveBannerAdWidget(),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}
