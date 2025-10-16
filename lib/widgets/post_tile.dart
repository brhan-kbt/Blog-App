import 'package:flutter/material.dart';
import 'package:jira_tips/core/config/api_config.dart';
import 'package:jira_tips/widgets/post_options_sheet.dart';
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

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final descStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.25,
      fontSize: 13.5,
      color: theme.colorScheme.onSurface.withOpacity(.7),
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(.6),
    );
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      child: Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- ROW 1: text (L) + image (R)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Right thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: post.image != null && post.image!.isNotEmpty
                          ? Image.network(
                              "${ApiConfig.imageUrl}${post.image!}",
                              // post.image!,
                              width: 40, // ~pixel look from screenshot
                              height: 40, // 4:3-ish
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40, // ~pixel look from screenshot
                              height: 40, // 4:3-ish
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Title + description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),

                          const SizedBox(height: 3),
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Row(
                              children: [
                                if (post.companyName != null)
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: iconColor,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  post.companyName ?? '',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(.75),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    if (post.experienceLevel != null)
                                      Icon(
                                        Icons.work,
                                        size: 16,
                                        color: iconColor,
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      post.experienceLevel ?? '',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                //   required this.category,

                //   this.employmentType,

                // this.deadlineAt,

                // const SizedBox(height: 6),

                // Text(
                //   post.subtitle ?? '',
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                //   style: descStyle,
                // ),
                // const SizedBox(height: 10),

                // ---------- ROW 2: date (L) + more (R)
                Row(
                  children: [
                    if (post.deadlineAt != null ||
                        post.prettyDeadlineAt != 'N/A')
                      Icon(Icons.date_range, size: 16, color: iconColor),
                    if (post.deadlineAt != null ||
                        post.prettyDeadlineAt != 'N/A')
                      const SizedBox(width: 6),
                    if (post.deadlineAt != null ||
                        post.prettyDeadlineAt != 'N/A')
                      Text(
                        post.prettyDeadlineAt,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(.75),
                        ),
                      ),
                    Text(
                      post.postedAt != null ? " • ${post.category.name}" : '',
                      style: metaStyle,
                    ),

                    Text(
                      post.postedAt != null ? " • ${post.employmentType}" : '',
                      style: metaStyle,
                    ),
                    const Spacer(),

                    // IconButton(
                    //   onPressed:
                    //       onMore ?? () => showPostOptionsSheet(context, post),
                    //   icon: Icon(Icons.more_vert, color: iconColor),
                    //   padding: EdgeInsets.zero,
                    //   constraints: const BoxConstraints(
                    //     minWidth: 0,
                    //     minHeight: 0,
                    //   ),
                    //   visualDensity: VisualDensity.compact,
                    //   splashRadius: 18,
                    // ),
                    IconButton(
                      onPressed: onTap,
                      icon: Icon(Icons.open_in_new, color: iconColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
