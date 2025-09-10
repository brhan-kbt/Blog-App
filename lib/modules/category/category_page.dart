import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qubee/core/theme/app_palette.dart';
import 'package:qubee/models/category.dart';
import 'package:qubee/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import 'category_listing_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Obx(() {
      if (store.isLoadingCategories.value) {
        return GridView.builder(
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 120,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
          ),
          itemBuilder: (_, __) => const CategoryShimmer(),
        );
      }

      if (store.categories.isEmpty) {
        return const Center(child: Text("No categories available"));
      }
      final q = store.query.value.trim().toLowerCase();
      final List<Category> cats = store.categories;
      final byQuery = q.isEmpty
          ? cats
          : cats.where((c) => c.name.toLowerCase().contains(q)).toList();

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        itemCount: byQuery.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 120,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemBuilder: (c, i) {
          final cat = byQuery[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.to(
              () => CategoryListingPage(catId: cat.id, title: cat.name),
            ),
            child: Column(
              children: [
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: Brightness.light == theme.brightness
                        ? Colors.white
                        : Colors.black,
                    border: Border.all(color: palette.searchOutline, width: 1),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: cat.image != null && cat.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(cat.image!, fit: BoxFit.cover),
                        )
                      : Icon(
                          Icons.folder_outlined,
                          size: 36,
                          color:
                              Brightness.light == Theme.of(context).brightness
                              ? Colors.blueGrey
                              : Colors.white,
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  cat.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
