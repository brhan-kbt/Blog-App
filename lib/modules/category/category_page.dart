import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kana_tech/core/config/api_config.dart';
import 'package:kana_tech/core/state/blog_store.dart';
import 'category_listing_page.dart';
import '../../models/category.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (store.isLoadingCategories.value) {
        return _buildLoadingGrid();
      }

      if (store.categories.isEmpty) {
        return _buildEmptyState(isDark);
      }

      final query = store.query.value.trim().toLowerCase();
      final categories = store.categories;
      final filteredCategories = query.isEmpty
          ? categories
          : categories
                .where((cat) => cat.name.toLowerCase().contains(query))
                .toList();

      if (filteredCategories.isEmpty) {
        return _buildNoResultsState(isDark);
      }

      return _buildCategoryGrid(filteredCategories, colorScheme);
    });
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 140,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_rounded,
            size: 80,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(height: 16),
          Text(
            "No Categories",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Categories will appear here once added.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(height: 16),
          Text(
            "No Results Found",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search terms.",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<Category> categories,
    ColorScheme colorScheme,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 140,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, colorScheme);
      },
    );
  }

  Widget _buildCategoryCard(Category category, ColorScheme colorScheme) {
    final textColor = colorScheme.onSurface;
    final bgColor = colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.to(
        () => CategoryListingPage(catId: category.id, title: category.name),
        transition: Transition.cupertinoDialog,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: category.image != null && category.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "${ApiConfig.imageUrl}${category.image!}",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.category_rounded, color: textColor),
                      ),
                    )
                  : Icon(Icons.category_rounded, color: colorScheme.primary),
            ),
            const Spacer(),
            Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
