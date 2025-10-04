import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jira_tips/core/ads/ad_service.dart';
import 'package:jira_tips/core/config/api_config.dart';
import 'package:jira_tips/core/services/fcm_service.dart';
import 'package:jira_tips/core/theme/app_palette.dart';
import 'package:jira_tips/widgets/adabtiveBanner.dart';
import 'package:jira_tips/widgets/banner_ad_widget.dart';
import 'package:jira_tips/widgets/post_detail_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';
import 'package:flutter_html/flutter_html.dart';
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

  void _handleBackNavigation() {
    // Check if we came from notification
    if (Get.isRegistered<FCMService>()) {
      final fcmService = Get.find<FCMService>();
      if (fcmService.hasNavigatedFromNotification) {
        debugPrint(
          "🔥 PostDetail - Back from notification, resetting flag and going back",
        );
        fcmService.onBackFromDetailPage();
        // Use normal back navigation instead of forcing home
        Get.back();
        return;
      }
    }
    // Normal back navigation
    Get.back();
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Scaffold(body: PostDetailShimmer());
    }

    if (post == null) {
      return const Scaffold(body: Center(child: Text("Post not found")));
    }

    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(post!.title),
        // Custom back button to ensure proper navigation
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we came from notification
            if (Get.isRegistered<FCMService>()) {
              final fcmService = Get.find<FCMService>();
              if (fcmService.hasNavigatedFromNotification) {
                debugPrint(
                  "🔥 PostDetail - AppBar back from notification, resetting flag and going back",
                );
                fcmService.onBackFromDetailPage();
                // Use normal back navigation instead of forcing home
                Get.back();
                return;
              }
            }
            // Normal back navigation
            Get.back();
          },
        ),
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
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
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
                      // i want a button Get it Now
                      const SizedBox(height: 8),
                      if (post!.link != null && post!.link!.isNotEmpty)
                        ElevatedButton.icon(
                          label: Text(
                            "Get it Now!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Brightness.light == theme.brightness
                                  ? Colors.white
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Brightness.light == theme.brightness
                                ? palette.primary
                                : palette.primary,
                            foregroundColor:
                                Brightness.light == theme.brightness
                                ? palette.primary
                                : palette.primary,

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

                      // const SizedBox(height: 16),
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
      bottomNavigationBar: const SafeArea(child: AdaptiveBannerAdWidget()),
    );
  }
}
