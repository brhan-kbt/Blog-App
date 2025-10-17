import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abayjobs/models/post.dart';
import 'package:abayjobs/widgets/adabtiveBanner.dart';
import 'package:abayjobs/widgets/hero_card.dart';
import 'package:abayjobs/widgets/post_options_sheet.dart';
import 'package:abayjobs/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import '../../widgets/post_tile.dart';
import '../post_detail/post_detail_page.dart';
import '../../widgets/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CategoryListingPage extends StatelessWidget {
  final int catId;
  final String title;
  const CategoryListingPage({
    super.key,
    required this.catId,
    required this.title,
  });

  void _openPost(Post post, BlogStore store) {
    store.addView(post.id); // ✅ increment views on backend
    Get.to(() => PostDetailPage(postId: post.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Obx(() {
        if (store.isLoadingPosts.value) {
          return ListView(
            children: const [
              // HeroCardShimmer(),
              PostTileShimmer(),
              PostTileShimmer(),
              PostTileShimmer(),
              PostTileShimmer(),
              PostTileShimmer(),
            ],
          );
        }

        final list = store.byCategory(catId)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ...List.generate(list.length, (index) {
              final p = list[index];
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
      }),
      bottomNavigationBar: const SafeArea(child: AdaptiveBannerAdWidget()),
    );
  }
}
