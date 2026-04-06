import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:risatech/core/config/api_config.dart';
import 'package:risatech/core/theme/app_palette.dart';
import 'package:risatech/models/category.dart';
import 'package:risatech/widgets/shimmer_widgets.dart';
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
      // 🔄 Loading State
      if (store.isLoadingCategories.value) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 120,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (_, __) => const CategoryShimmer(),
        );
      }

      // ❌ Empty/Error State (Modern)
      if (store.categories.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => store.fetchCategories(),
          child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No categories found",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Pull down to refresh",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: store.fetchCategories,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // 🔍 Filter
      final q = store.query.value.trim().toLowerCase();
      final List<Category> cats = store.categories;
      final filtered = q.isEmpty
          ? cats
          : cats.where((c) => c.name.toLowerCase().contains(q)).toList();

      return RefreshIndicator(
        onRefresh: () => store.fetchCategories(),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          itemCount: filtered.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 120,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (_, i) {
            final cat = filtered[i];

            return _CategoryCard(
              category: cat,
              palette: palette,
              onTap: () => Get.to(
                () => CategoryListingPage(catId: cat.id, title: cat.name),
              ),
            );
          },
        ),
      );
    });
  }
}

// 🔥 Extracted modern card widget
class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final AppPalette palette;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼 Icon container
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: category.image != null && category.image!.isNotEmpty
                      ? Image.network(
                          "${ApiConfig.imageUrl}${category.image!}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.folder_outlined),
                        )
                      : Icon(
                          Icons.folder_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // 📝 Name
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
