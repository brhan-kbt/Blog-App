import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:milki_tech/core/config/api_config.dart';
import 'package:milki_tech/widgets/post_detail_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:milki_tech/core/ads/ad_service.dart';
import 'package:milki_tech/widgets/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final store = Get.find<BlogStore>();

  Post? post;
  List<Post> suggested = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPost();
    // Randomly show interstitial or rewarded (or none) on open
    AdService.instance.showRandomOpenAd();
  }

  Future<void> _fetchPost() async {
    final result = await store.fetchPostWithSuggested(widget.postId);
    setState(() {
      post = result['post'];
      suggested = result['suggested'];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: PostDetailShimmer());
    }

    if (post == null) {
      return const Scaffold(body: Center(child: Text("Post not found")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        // back button
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Get.to(() => const RecentPage()),
        // ),
        actions: [
          IconButton(
            onPressed: () => store.toggleFavorite(post!.id),
            icon: Obx(
              () => Icon(
                store.favorites.contains(post!.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
            ),
          ),

          IconButton(
            onPressed: () => {
              setState(() {
                loading = true;
              }),
              _fetchPost(),
            },
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: post!.image != null && post!.image!.isNotEmpty
                ? Image.network(
                    "${ApiConfig.imageUrl}${post!.image!}",
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey,
                    child: const Center(child: Text('No Image')),
                  ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        post!.title,
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
                          Text('${post!.prettyDate} • ${post!.viewsStr} views'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Html(data: post!.body),
                      // i want a button Get it Here
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        label: const Text(
                          "Get it Here",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Brightness.light == Theme.of(context).brightness
                              ? Colors.black
                              : Colors.white,
                          foregroundColor:
                              Brightness.light == Theme.of(context).brightness
                              ? Colors.white
                              : Colors.black,

                          minimumSize: const Size(double.infinity, 50),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          // WHEN CLICKED REDIRECT TO LINK

                          debugPrint(post!.link!);
                          final uri = Uri.parse(post!.link!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Large banner below the button
                const BannerAdWidget(size: AdSize(width: 380, height: 280)),
                const SizedBox(height: 24),

                if (suggested.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text(
                      'Suggested',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...suggested.map(
            (p) => PostTile(
              post: p,
              onTap: () {
                print("Post tapped: ${p.id}");
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => PostDetailPage(postId: p.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: BannerAdWidget(size: AdSize(width: 370, height: 70)),
      ),
    );
  }
}
