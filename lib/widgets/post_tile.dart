import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jara_tech/core/config/api_config.dart';
import 'package:jara_tech/widgets/post_options_sheet.dart';
import '../core/theme/app_palette.dart';
import '../models/post.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const PostTile({super.key, required this.post, this.onTap, this.onMore});

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  late AnimationController _likeController;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() => isLiked = !isLiked);
    _likeController
      ..forward(from: 0.8)
      ..reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        const Shadow(
          color: Colors.black54,
          offset: Offset(0, 1),
          blurRadius: 4,
        ),
      ],
    );
    final descStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withOpacity(0.9),
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(.7),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card with image, overlay, like, and more
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    /// Background Image
                    widget.post.image != null && widget.post.image!.isNotEmpty
                        ? Image.network(
                            "${ApiConfig.imageUrl}${widget.post.image!}",
                            width: double.infinity,
                            height: 230,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 230,
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),

                    /// Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// Floating glass card with title + subtitle
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Title + Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.post.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleStyle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.post.subtitle ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: descStyle,
                                      ),
                                    ],
                                  ),
                                ),

                                /// More button
                                IconButton(
                                  onPressed:
                                      widget.onMore ??
                                      () => showPostOptionsSheet(
                                        context,
                                        widget.post,
                                      ),
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  splashRadius: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Animated Like button
                    Positioned(
                      top: 14,
                      right: 14,
                      child: ScaleTransition(
                        scale: _likeController,
                        child: GestureDetector(
                          onTap: _toggleLike,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 20,
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.redAccent : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Meta row below the card
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(.6),
                ),
                const SizedBox(width: 6),
                Text(widget.post.prettyDate, style: metaStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
