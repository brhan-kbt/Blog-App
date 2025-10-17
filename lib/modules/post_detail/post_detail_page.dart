import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abayjobs/core/ads/ad_service.dart';
import 'package:abayjobs/core/config/api_config.dart';
import 'package:abayjobs/core/services/fcm_service.dart';
import 'package:abayjobs/core/theme/app_palette.dart';
import 'package:abayjobs/widgets/adabtiveBanner.dart';
import 'package:abayjobs/widgets/banner_ad_widget.dart';
import 'package:abayjobs/widgets/post_detail_shimmer.dart';
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
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // image on left and title and company name on right
                if (post!.image != null && post!.image!.isNotEmpty)
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                      image: post!.image != null && post!.image!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                "${ApiConfig.imageUrl}${post!.image!}",
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),

                if (post!.image == null || post!.image!.isEmpty)
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      color: Colors.grey[300],
                    ),
                    child: Center(
                      // first letter of title
                      child: Text(
                        post!.title.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post!.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (post!.companyName != null &&
                            post!.companyName!.isNotEmpty)
                          Text(
                            post!.companyName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AspectRatio(
          //   aspectRatio: 16 / 9,
          //   child: post!.image != null && post!.image!.isNotEmpty
          //       ? Image.network(
          //           "${ApiConfig.imageUrl}${post!.image!}",
          //           fit: BoxFit.cover,
          //         )
          //       : Container(
          //           color: Colors.grey,
          //           child: const Center(child: Text('No Image')),
          //         ),
          // ),
          SizedBox(height: 16),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 1, // horizontal spacing between badges
                          runSpacing:
                              8, // vertical spacing if wrapped to next line
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Experience Level Badge
                            if ((post?.experienceLevel ?? '').isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getExperienceColorBg(
                                    context,
                                    post?.experienceLevel,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post?.experienceLevel ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _getExperienceColorText(
                                      context,
                                      post?.experienceLevel,
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(width: 12),
                            // Employment Type Badge
                            if (post?.employmentType != null &&
                                (post?.employmentType! ?? '').isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEmploymentColorBg(
                                    context,
                                    post?.employmentType,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post?.employmentType! ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _getEmploymentColorText(
                                      context,
                                      post?.employmentType,
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(width: 12),

                            // Deadline

                            // salary range
                            if (post?.salaryMin != null &&
                                post?.salaryMax != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${post!.salaryCurrency ?? ''} ${post!.salaryMin} - ${post!.salaryMax}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),

                            if (post?.deadlineAt != null ||
                                post?.prettyDeadlineAt != 'N/A')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post?.prettyDeadlineAt ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${post!.prettyDate}  • ${post!.viewsStr} views',
                          ),
                          // if (post?.deadlineAt != null ||
                          //     post?.prettyDeadlineAt != 'N/A')
                          //   Text(
                          //     '  • ${post?.prettyDeadlineAt}',
                          //     maxLines: 1,
                          //     overflow: TextOverflow.ellipsis,
                          //     style: TextStyle(
                          //       fontSize: 13.5,
                          //       color: Theme.of(context).colorScheme.secondary,
                          //     ),
                          //   ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Html(data: post!.body),
                      // i want a button Get it Now
                      const SizedBox(height: 8),
                      if (post!.link != null && post!.link!.isNotEmpty)
                        ElevatedButton.icon(
                          label: Text(
                            "Apply Now!",
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

Color getSeededAdaptiveCardColor(BuildContext context, String seed) {
  final random = Random();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Random hue between 0–360
  final hue = random.nextDouble() * 360;
  // Keep saturation moderate for pleasant colors
  final saturation = isDark
      ? 0.4 + random.nextDouble() * 0.3
      : 0.3 + random.nextDouble() * 0.4;
  // Lightness differs for dark/light mode
  final lightness = isDark
      ? 0.10 +
            random.nextDouble() *
                0.15 // dark mode: deeper tones
      : 0.85 + random.nextDouble() * 0.10; // light mode: pastel tones

  return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
}

Color getRandomSoftColor() {
  final random = Random();
  // Hue: 0–360, Saturation: 0.3–0.6 (moderate), Lightness: 0.8–0.9 (light)
  final hue = random.nextDouble() * 360;
  final saturation = 0.3 + random.nextDouble() * 0.3;
  final lightness = 0.8 + random.nextDouble() * 0.1;
  return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
}

Color _getExperienceColorBg(BuildContext context, String? level) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (level?.toLowerCase()) {
    case 'junior':
      return isDark
          ? Colors.greenAccent.withOpacity(.1)
          : Colors.green.withOpacity(.15);
    case 'intermediate':
    case 'mid':
      return isDark
          ? Colors.orangeAccent.withOpacity(.1)
          : Colors.orange.withOpacity(.15);
    case 'senior':
      return isDark
          ? Colors.redAccent.withOpacity(.1)
          : Colors.red.withOpacity(.15);
    case 'lead':
      return isDark
          ? Colors.purpleAccent.withOpacity(.1)
          : Colors.purple.withOpacity(.15);
    default:
      return isDark
          ? Colors.grey.withOpacity(.15)
          : Colors.grey.withOpacity(.1);
  }
}

Color _getExperienceColorText(BuildContext context, String? level) {
  switch (level?.toLowerCase()) {
    case 'junior':
      return Colors.green.shade700;
    case 'intermediate':
    case 'mid':
      return Colors.orange.shade700;
    case 'senior':
      return Colors.red.shade700;
    case 'lead':
      return Colors.purple.shade700;
    default:
      return Theme.of(context).colorScheme.onSurface.withOpacity(.7);
  }
}

Color _getEmploymentColorBg(BuildContext context, String? type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (type?.toLowerCase()) {
    case 'full time':
      return isDark
          ? Colors.blueAccent.withOpacity(.1)
          : Colors.blue.withOpacity(.15);
    case 'part time':
      return isDark
          ? Colors.tealAccent.withOpacity(.1)
          : Colors.teal.withOpacity(.15);
    case 'contract':
      return isDark
          ? Colors.deepPurpleAccent.withOpacity(.1)
          : Colors.deepPurple.withOpacity(.15);
    case 'internship':
      return isDark
          ? Colors.amberAccent.withOpacity(.1)
          : Colors.amber.withOpacity(.15);
    case 'temporary':
      return isDark
          ? Colors.pinkAccent.withOpacity(.1)
          : Colors.pink.withOpacity(.15);
    default:
      return isDark
          ? Colors.grey.withOpacity(.15)
          : Colors.grey.withOpacity(.1);
  }
}

Color _getEmploymentColorText(BuildContext context, String? type) {
  switch (type?.toLowerCase()) {
    case 'full time':
      return Colors.blue.shade700;
    case 'part time':
      return Colors.teal.shade700;
    case 'contract':
      return Colors.deepPurple.shade700;
    case 'internship':
      return Colors.amber.shade700;
    case 'temporary':
      return Colors.pink.shade700;
    default:
      return Theme.of(context).colorScheme.onSurface.withOpacity(.7);
  }
}
