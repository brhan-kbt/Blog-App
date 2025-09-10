import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';

class PostDetailPage extends StatelessWidget {
  final Post post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final store = Get.find<BlogStore>();
    final suggested = store
        .byCategory(post.category.id)
        .where((p) => p.id != post.id)
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          IconButton(
            onPressed: () => store.toggleFavorite(post.id),
            icon: Obx(
              () => Icon(
                store.favorites.contains(post.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: post.image != null && post.image!.isNotEmpty
                ? Image.network(post.image!, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey,
                    child: const Center(
                      child: Text(
                        'No Image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${post.prettyDate}  •  ${post.viewsStr} views',
                      style: TextStyle(
                        color: Brightness.light == theme.brightness
                            ? Colors.black54
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(post.body, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 24),
                const Text(
                  'Suggested',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
          ),
          ...suggested.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PostTile(
                post: p,
                onTap: () => Get.to(() => PostDetailPage(post: p)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
