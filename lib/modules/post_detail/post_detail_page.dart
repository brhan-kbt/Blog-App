import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appletips/core/ads/ad_service.dart';
import 'package:appletips/core/config/api_config.dart';
import 'package:appletips/core/services/fcm_service.dart';
import 'package:appletips/core/theme/app_palette.dart';
import 'package:appletips/widgets/adabtiveBanner.dart';
import 'package:appletips/widgets/banner_ad_widget.dart';
import 'package:appletips/widgets/post_detail_shimmer.dart';
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

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  final store = Get.find<BlogStore>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  Post? post;
  List<Post> suggested = [];
  bool loading = true;
  bool get policy => store.adpExist.value;
  bool _isFavorite = false;
  ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _fetchPost();
    // AdService.instance.showRandomOpenAd();
    if (!policy) {
      AdService.instance.showRandomOpenAd();
    }
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 500 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
      _fabAnimationController.forward();
    } else if (_scrollController.offset <= 500 && _showBackToTop) {
      setState(() => _showBackToTop = false);
      _fabAnimationController.reverse();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBackNavigation() {
    if (Get.isRegistered<FCMService>()) {
      final fcmService = Get.find<FCMService>();
      if (fcmService.hasNavigatedFromNotification) {
        debugPrint(
          "🔥 PostDetail - Back from notification, resetting flag and going back",
        );
        fcmService.onBackFromDetailPage();
        Get.back();
        return;
      }
    }
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
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBackNavigation();
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Scaffold(body: PostDetailShimmer());
    }

    if (post == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Post not found",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(theme, palette),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostContent(theme, palette),
                    if (!policy)
                      const BannerAdWidget(
                        size: AdSize(width: 380, height: 280),
                      ),
                    const SizedBox(height: 24),
                    if (suggested.isNotEmpty) _buildSuggestedHeader(),
                  ],
                ),
              ),
              if (suggested.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostTile(
                      post: suggested[index],
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                PostDetailPage(postId: suggested[index].id),
                          ),
                        );
                      },
                    ),
                    childCount: suggested.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          if (_showBackToTop) _buildBackToTopFAB(theme),
          _buildBottomAd(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, AppPalette palette) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      floating: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBackNavigation,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Obx(
            () => IconButton(
              icon: Icon(
                store.favorites.contains(post!.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: store.favorites.contains(post!.id)
                    ? Colors.red
                    : Colors.white,
              ),
              onPressed: () => store.toggleFavorite(post!.id),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => loading = true);
              _fetchPost();
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (post!.image != null && post!.image!.isNotEmpty)
              Image.network(
                "${ApiConfig.imageUrl}${post!.image!}",
                fit: BoxFit.cover,
                height: 100,
              )
            else
              Container(
                color: palette.primary.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    Icons.article,
                    size: 80,
                    color: palette.primary.withOpacity(0.3),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ],
        ),
        // title: Text(
        //   post!.title,
        //   style: const TextStyle(
        //     fontSize: 18,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.white,
        //   ),
        //   overflow: TextOverflow.ellipsis,
        // ),
        centerTitle: true,
        expandedTitleScale: 1.5,
      ),
    );
  }

  Widget _buildPostContent(ThemeData theme, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            post!.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Metadata
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post!.category.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                post!.prettyDate,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                post!.viewsStr,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Author info
          // Row(
          //   children: [
          //     CircleAvatar(
          //       radius: 20,
          //       backgroundColor: palette.primary.withOpacity(0.1),
          //       child: Text(
          //         post!.user.name[0].toUpperCase(),
          //         style: TextStyle(
          //           color: palette.primary,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             post!.user.name,
          //             style: const TextStyle(
          //               fontWeight: FontWeight.w600,
          //               fontSize: 14,
          //             ),
          //           ),
          //           Text(
          //             "Author",
          //             style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),

          // Divider
          Divider(color: Colors.grey[200], thickness: 1),
          // const SizedBox(height: 24),

          // Post Body
          Html(
            data: post!.body,
            style: {
              "body": Style(
                fontSize: FontSize(16.0),
                lineHeight: LineHeight(1.6),
                color: theme.textTheme.bodyLarge?.color,
              ),
              "h1": Style(
                fontSize: FontSize(24.0),
                fontWeight: FontWeight.bold,
              ),
              "h2": Style(
                fontSize: FontSize(20.0),
                fontWeight: FontWeight.bold,
              ),
              "h3": Style(
                fontSize: FontSize(18.0),
                fontWeight: FontWeight.bold,
              ),
              "p": Style(margin: Margins.only(bottom: 12)),
              "img": Style(
                width: Width(double.infinity),
                // height: Height.auto(),
              ),
            },
          ),
          const SizedBox(height: 24),

          // CTA Button
          if (post!.link != null && post!.link!.isNotEmpty)
            _buildCTAButton(theme, palette),
        ],
      ),
    );
  }

  Widget _buildCTAButton(ThemeData theme, AppPalette palette) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          debugPrint(post!.link!);
          final uri = Uri.parse(post!.link!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_cart, size: 20),
            SizedBox(width: 12),
            Text(
              "Get it Now!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).extension<AppPalette>()!.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'You May Also Like',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToTopFAB(ThemeData theme) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _scrollToTop,
          mini: true,
          backgroundColor: theme.extension<AppPalette>()!.primary,
          child: const Icon(Icons.arrow_upward, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBottomAd() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: const SafeArea(child: AdaptiveBannerAdWidget()),
    );
  }
}
