import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/state/blog_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_tile.dart';
import '../post_detail/post_detail_page.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    return Obx(() {
      final list = store.favoritePosts;
      if (list.isEmpty) {
        return const EmptyState(
          icon: Icons.favorite,
          title: 'Whoops!',
          message:
              "Your favorite list is empty because you didn't add any news in the favorite menu.",
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: list.length,
        itemBuilder: (c, i) => PostTile(
          post: list[i],
          onTap: () => Get.to(() => PostDetailPage(postId: list[i].id)),
        ),
      );
    });
  }
}
