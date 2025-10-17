import 'dart:math';

import 'package:flutter/material.dart';
import 'package:abayjobs/core/config/api_config.dart';
import 'package:abayjobs/widgets/post_options_sheet.dart';
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
        color: getSeededAdaptiveCardColor(
          context,
          post.id.toString(),
        ).withOpacity(.5),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Right thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: post.image != null && post.image!.isNotEmpty
                          ? Image.network(
                              "${ApiConfig.imageUrl}${post.image!}",
                              // post.image!,
                              width: 50, // ~pixel look from screenshot
                              height: 50, // 4:3-ish
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 50, // ~pixel look from screenshot
                              height: 50, // 4:3-ish
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),

                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Experience Level Badge
                              if (post.experienceLevel != null &&
                                  post.experienceLevel!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getExperienceColorBg(
                                      context,
                                      post.experienceLevel,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    post.experienceLevel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: _getExperienceColorText(
                                        context,
                                        post.experienceLevel,
                                      ),
                                    ),
                                  ),
                                ),

                              // Employment Type Badge
                              if (post.employmentType != null &&
                                  post.employmentType!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEmploymentColorBg(
                                      context,
                                      post.employmentType,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    post.employmentType!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: _getEmploymentColorText(
                                        context,
                                        post.employmentType,
                                      ),
                                    ),
                                  ),
                                ),

                              // Deadline
                              if (post.deadlineAt != null ||
                                  post.prettyDeadlineAt != 'N/A')
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
                                    post.prettyDeadlineAt,
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
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    .1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post.companyName ?? '',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(.75),
                                  ),
                                ),
                              ),
                              Spacer(),

                              InkWell(
                                onTap:
                                    onMore ??
                                    () {
                                      showPostOptionsSheet(context, post);
                                    },
                                child: Icon(
                                  Icons.more_vert_outlined,
                                  size: 16,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
