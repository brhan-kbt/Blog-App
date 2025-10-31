import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ethio_tips/core/config/api_config.dart';
import 'package:ethio_tips/core/theme/app_palette.dart';
import 'package:ethio_tips/models/category.dart';
import 'package:ethio_tips/widgets/shimmer_widgets.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (store.isLoadingCategories.value) {
        return _buildShimmerGrid();
      }

      if (store.categories.isEmpty) {
        return _buildErrorState(store, palette, isDark);
      }

      final query = store.query.value.trim().toLowerCase();
      final categories = store.categories;
      final filteredCategories = query.isEmpty
          ? categories
          : categories
                .where((cat) => cat.name.toLowerCase().contains(query))
                .toList();

      if (filteredCategories.isEmpty) {
        return _buildNoResultsState(palette, isDark);
      }

      return _buildCategoryGrid(filteredCategories, palette, isDark, theme);
    });
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 120,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, __) => const CategoryShimmer(),
    );
  }

  Widget _buildErrorState(BlogStore store, AppPalette palette, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: palette.searchOutline.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              "Unable to Load Categories",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.searchOutline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection and try again",
              style: TextStyle(
                fontSize: 14,
                color: palette.searchOutline.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => store.fetchCategories(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.blue.shade800
                    : Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(AppPalette palette, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: palette.searchOutline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No categories found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.searchOutline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try different search terms",
            style: TextStyle(color: palette.searchOutline.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<Category> categories,
    AppPalette palette,
    bool isDark,
    ThemeData theme,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 120,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, palette, isDark, theme);
      },
    );
  }

  Widget _buildCategoryCard(
    Category category,
    AppPalette palette,
    bool isDark,
    ThemeData theme,
  ) {
    final cardColor = _getCategoryColor(category.name, isDark);
    final textColor = _getTextColor(cardColor);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(
          () => CategoryListingPage(catId: category.id, title: category.name),
          transition: Transition.cupertinoDialog,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon and category name in a row
                Row(
                  children: [
                    // Category Icon/Image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          category.image != null && category.image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                "${ApiConfig.imageUrl}${category.image!}",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildFallbackIcon(
                                      category.name,
                                      textColor,
                                    ),
                              ),
                            )
                          : _buildFallbackIcon(category.name, textColor),
                    ),
                    const SizedBox(width: 12),

                    // Category Name
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Simple divider
                Container(
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(String categoryName, Color iconColor) {
    return Center(
      child: Icon(_getCategoryIcon(categoryName), size: 20, color: iconColor),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('tech') || name.contains('software')) {
      return Icons.code_rounded;
    } else if (name.contains('design') || name.contains('creative')) {
      return Icons.design_services_rounded;
    } else if (name.contains('business') || name.contains('startup')) {
      return Icons.business_center_rounded;
    } else if (name.contains('mobile') || name.contains('app')) {
      return Icons.phone_iphone_rounded;
    } else if (name.contains('web') || name.contains('development')) {
      return Icons.web_rounded;
    } else if (name.contains('ai') || name.contains('artificial')) {
      return Icons.smart_toy_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String categoryName, bool isDark) {
    // Generate consistent color based on category name hash
    final hash = categoryName.hashCode;
    final colors = isDark ? _darkCategoryColors : _lightCategoryColors;
    return colors[hash % colors.length];
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate luminance to determine text color
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Simple, clean color palette
  static final _lightCategoryColors = [
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFF3E5F5), // Light Purple
    const Color(0xFFE8F5E8), // Light Green
    const Color(0xFFFFF3E0), // Light Orange
    const Color(0xFFFCE4EC), // Light Pink
    const Color(0xFFE0F2F1), // Light Teal
    const Color(0xFFFFF8E1), // Light Yellow
    const Color(0xFFE8EAF6), // Light Indigo
  ];

  static final _darkCategoryColors = [
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF8E24AA), // Purple
    const Color(0xFF43A047), // Green
    const Color(0xFFFB8C00), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFF00ACC1), // Teal
    const Color(0xFFFDD835), // Yellow
    const Color(0xFF3949AB), // Indigo
  ];
}
