import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:milki_tech/core/theme/app_palette.dart';
import 'package:share_plus/share_plus.dart';
import '../core/state/blog_store.dart';
import '../models/post.dart';

Future<void> showPostOptionsSheet(BuildContext context, Post post) async {
  final store = Get.find<BlogStore>();
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  final bool isFav = store.favorites.contains(post.id);

  final theme = Theme.of(context);
  final palette = theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: false,
    showDragHandle: true,
    // Use themed colors instead of hard-coded white
    backgroundColor: palette.cardBg,
    barrierColor: Colors.black.withOpacity(0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Text(
                    'More options',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    splashRadius: 22,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

            // Favorite
            _ActionTile(
              icon: isFav ? Icons.favorite : Icons.favorite_border,
              iconColor: isFav ? Colors.red : cs.onSurfaceVariant,
              label: isFav ? 'Remove from favorites' : 'Add to favorites',
              onTap: () {
                HapticFeedback.selectionClick();
                store.toggleFavorite(post.id);
                Navigator.pop(ctx);
                Get.snackbar(
                  'Favorites',
                  isFav ? 'Removed from favorites' : 'Added to favorites',
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(12),
                );
              },
            ),

            // Share
            _ActionTile(
              icon: Icons.share,
              iconColor: cs.onSurfaceVariant,
              label: 'Share to friends',
              onTap: () async {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx);
                final text =
                    '${post.title}\n${post.subtitle}\n\nRead more in Milki Tech.';
                await Share.share(text);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}
