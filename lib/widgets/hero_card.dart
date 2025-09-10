import 'package:flutter/material.dart';
import 'package:qubee/widgets/post_options_sheet.dart';
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

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.35,
      color: theme.colorScheme.onSurface.withOpacity(.7),
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(.6),
    );
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top image
              AspectRatio(
                aspectRatio: 16 / 7,
                child: post.image != null && post.image!.isNotEmpty
                    ? Image.network(post.image!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),

              // Description (subtitle fallback to body or empty string)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  post.subtitle ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle,
                ),
              ),

              // Date + trailing menu
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 2,
                  bottom: 6,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: iconColor),
                    const SizedBox(width: 6),
                    Text(post.prettyDate, style: metaStyle),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          onMore != null ? onMore!() : showPostOptionsSheet(context, post),
                      icon: Icon(Icons.more_vert, color: iconColor),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
