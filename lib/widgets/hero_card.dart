import 'package:flutter/material.dart';
import 'package:smart_tips/core/config/api_config.dart';
import 'package:smart_tips/widgets/post_options_sheet.dart';
import '../core/theme/app_palette.dart';
import '../models/post.dart';

class HeroCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const HeroCard({super.key, required this.post, this.onTap, this.onMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    // Refined typography styles
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.3,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.45,
      color: theme.colorScheme.onSurface.withOpacity(0.75),
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.6),
    );
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        color: palette.cardBg,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Section with Image & Menu ---
              Stack(
                children: [
                  // Image with improved aspect ratio and rounded corners
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // Slightly taller for hero feel
                      child: post.image != null && post.image!.isNotEmpty
                          ? Image.network(
                              "${ApiConfig.imageUrl}${post.image!}",
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  // Menu button positioned in top-right corner
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => onMore != null
                            ? onMore!()
                            : showPostOptionsSheet(context, post),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        splashRadius: 18,
                      ),
                    ),
                  ),
                ],
              ),

              // --- Content Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle / Description
                    // if (post.subtitle != null && post.subtitle!.isNotEmpty)
                    //   Text(
                    //     post.subtitle!,
                    //     maxLines: 3,
                    //     overflow: TextOverflow.ellipsis,
                    //     style: subtitleStyle,
                    //   ),
                    // const SizedBox(height: 12),

                    // --- Author & Metadata Row ---
                    // Row(
                    //   children: [
                    //     // Author Avatar (placeholder)
                    //     CircleAvatar(
                    //       radius: 14,
                    //       backgroundColor:
                    //           palette.primary?.withOpacity(0.2) ??
                    //           Colors.grey.shade300,
                    //       child: Text(
                    //         'ST',
                    //         style: TextStyle(
                    //           fontSize: 12,
                    //           fontWeight: FontWeight.w600,
                    //           color: palette.primary ?? Colors.grey.shade700,
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 10),
                    //     // Author name and date
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(
                    //             'Smart Tips',
                    //             style: theme.textTheme.bodySmall?.copyWith(
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //             maxLines: 1,
                    //             overflow: TextOverflow.ellipsis,
                    //           ),
                    //           const SizedBox(height: 2),
                    //           Row(
                    //             children: [
                    //               Icon(
                    //                 Icons.access_time,
                    //                 size: 12,
                    //                 color: iconColor,
                    //               ),
                    //               const SizedBox(width: 4),
                    //               Text(post.prettyDate, style: metaStyle),
                    //             ],
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //     // Bookmark Icon (for future functionality)
                    //     // IconButton(
                    //     //   onPressed: () {
                    //     //     ScaffoldMessenger.of(context).showSnackBar(
                    //     //       const SnackBar(
                    //     //         content: Text('Save feature coming soon'),
                    //     //         duration: Duration(seconds: 1),
                    //     //       ),
                    //     //     );
                    //     //   },
                    //     //   icon: Icon(
                    //     //     Icons.bookmark_outline,
                    //     //     color: iconColor,
                    //     //     size: 22,
                    //     //   ),
                    //     //   padding: EdgeInsets.zero,
                    //     //   constraints: const BoxConstraints(
                    //     //     minWidth: 32,
                    //     //     minHeight: 32,
                    //     //   ),
                    //     //   splashRadius: 20,
                    //     // ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
