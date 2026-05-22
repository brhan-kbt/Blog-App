// give me a code that list categories in a horizontal list view with a card for each category
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sheger_tech/core/state/blog_store.dart';
import 'package:sheger_tech/models/category.dart';
import 'package:sheger_tech/widgets/shimmer_widgets.dart';
import '../core/theme/app_palette.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryListCard extends StatelessWidget {
  const CategoryListCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blogStore = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black,
    );

    return Obx(
      () => blogStore.categories.isEmpty
          ? const ShimmerCategoryListCard()
          : ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: blogStore.categories.length,
              itemBuilder: (context, index) {
                final category = blogStore.categories[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.chipBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(category.name, style: textStyle),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ShimmerCategoryListCard
class ShimmerCategoryListCard extends StatelessWidget {
  const ShimmerCategoryListCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
