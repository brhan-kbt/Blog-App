import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../core/theme/app_palette.dart';

class SearchHeader extends StatelessWidget {
  final String title;
  final ValueChanged<String> onChanged;
  const SearchHeader({super.key, required this.title, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Material(
        color: palette.searchBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.toNamed(Routes.search),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.searchOutline, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: palette.searchIcon),
                const SizedBox(width: 8),
                Expanded(
                  child: IgnorePointer(
                    ignoring: true,
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: title,
                        hintStyle: TextStyle(
                          color: palette.searchIcon.withOpacity(.8),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Get.toNamed(Routes.settings),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.settings_outlined,
                      color: palette.searchIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
