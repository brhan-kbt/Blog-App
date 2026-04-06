import 'package:flutter/material.dart';
import 'package:smart_tips/core/config/api_config.dart';
import 'package:smart_tips/widgets/post_options_sheet.dart';
import '../core/theme/app_palette.dart';
import '../models/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const PostTile({super.key, required this.post, this.onTap, this.onMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    // Refined typography with better hierarchy
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 1.35,
      letterSpacing: -0.3,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.4,
      fontSize: 13,
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: theme.colorScheme.onSurface.withOpacity(0.6),
    );
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 0, // Flat card with subtle border instead
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- ROW 1: Thumbnail + Text Content (Left-aligned thumbnail) ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left thumbnail - consistent with modern card designs
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: post.image != null && post.image!.isNotEmpty
                            ? Image.network(
                                "${ApiConfig.imageUrl}${post.image!}",
                                width: 105,
                                height: 105,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // Title + metadata (expanded to fill remaining space)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title with improved spacing
                            Text(
                              post.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            const SizedBox(height: 8),

                            // Author & Date row
                            Row(
                              children: [
                                // Small author avatar
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      palette.primary?.withOpacity(0.15) ??
                                      theme.colorScheme.primary.withOpacity(
                                        0.15,
                                      ),
                                  child: Text(
                                    'ST',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          palette.primary ??
                                          theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Author name and date combined
                                Expanded(
                                  child: Text(
                                    '${'Smart Tips'} • ${post.prettyDate}',
                                    style: metaStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Read time indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_calculateReadTime(post.subtitle ?? post.title)} min read',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),

                                // Save/Bookmark button

                                // More options button
                                IconButton(
                                  onPressed:
                                      onMore ??
                                      () => showPostOptionsSheet(context, post),
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    size: 20,
                                    color: iconColor,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ---------- ROW 3: Engagement & Actions ----------
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to calculate approximate read time
  int _calculateReadTime(String content) {
    // Average reading speed: 200 words per minute
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return minutes.clamp(1, 10); // Between 1-10 minutes
  }
}
