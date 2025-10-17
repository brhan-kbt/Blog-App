import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abayjobs/core/config/api_config.dart';
import 'package:abayjobs/core/theme/app_palette.dart';
import 'package:abayjobs/models/category.dart';
import 'package:abayjobs/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import 'category_listing_page.dart';

class HorizontalCategory extends StatelessWidget {
  const HorizontalCategory({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Obx(() {
      if (store.isLoadingCategories.value) {
        // Show horizontal shimmer placeholders
        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const CategoryShimmer(),
          ),
        );
      }

      if (store.categories.isEmpty) {
        // Modern refresh UI when no data
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                "No categories found",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "Please check your connection or refresh.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => store.fetchCategories(),
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final q = store.query.value.trim().toLowerCase();
      final List<Category> cats = store.categories;
      final byQuery = q.isEmpty
          ? cats
          : cats.where((c) => c.name.toLowerCase().contains(q)).toList();

      return SizedBox(
        height: 70,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 12),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: byQuery.length,
          itemBuilder: (context, i) {
            final cat = byQuery[i];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Get.to(
                () => CategoryListingPage(catId: cat.id, title: cat.name),
                transition: Transition.cupertino,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Brightness.light == theme.brightness
                      ? Colors.white
                      : Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: palette.searchOutline, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      child: cat.image != null && cat.image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                "${ApiConfig.imageUrl}${cat.image!}",
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.folder_outlined,
                              size: 20,
                              color: Brightness.light == theme.brightness
                                  ? Colors.blueGrey
                                  : Colors.white70,
                            ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Brightness.light == theme.brightness
                            ? Colors.black87
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
