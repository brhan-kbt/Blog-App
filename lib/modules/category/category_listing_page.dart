import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qubee/models/post.dart';
import 'package:qubee/widgets/hero_card.dart';
import 'package:qubee/widgets/post_options_sheet.dart';
import 'package:qubee/widgets/shimmer_widgets.dart';
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
              HeroCardShimmer(),
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
          return const Center(child: Text('No posts'));
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
                widgets.add(const BannerAdWidget(size: AdSize.largeBanner));
              }
              return Column(children: widgets);
            }),
          ],
        );
      }),
      bottomNavigationBar: const SafeArea(
        child: BannerAdWidget(size: AdSize(width: 370, height: 100)),
      ),
    );
  }
}
