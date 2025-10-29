import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habesha_tech/core/config/api_config.dart';
import 'package:habesha_tech/core/theme/app_palette.dart';
import 'package:habesha_tech/models/category.dart';
import 'package:habesha_tech/widgets/shimmer_widgets.dart';
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
        mainAxisExtent: 180,
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
            // Ethiopian pattern decorative element
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.searchOutline.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.incomplete_circle_rounded,
                size: 60,
                color: palette.searchOutline,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Tewunt Alewgnm",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.searchOutline,
                fontFamily: "Roboto",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Sorry, we couldn't load the categories.",
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
                    ? Colors.green.shade800
                    : Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: isDark
                    ? Colors.green.withOpacity(0.3)
                    : Colors.green.withOpacity(0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Try Again",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
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
            size: 80,
            color: palette.searchOutline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No categories found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
        mainAxisExtent: 150,
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
    // Generate consistent color based on category name
    final cardColor = _getCategoryColor(category.name, isDark);
    final textColor = _getTextColor(cardColor);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Get.to(
        () => CategoryListingPage(catId: category.id, title: category.name),
        transition: Transition.cupertinoDialog,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.9),
              cardColor.withOpacity(0.7),
              cardColor.withOpacity(0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Ethiopian pattern background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: _EthiopianPatternCardPainter(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon/Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: category.image != null && category.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              "${ApiConfig.imageUrl}${category.image!}",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackIcon(category.name),
                            ),
                          )
                        : _buildFallbackIcon(category.name),
                  ),

                  const Spacer(),

                  // Category Name
                  Text(
                    category.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Decorative Ethiopian element
                  Container(
                    width: 24,
                    height: 2,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            // Hover overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(String categoryName) {
    return Center(
      child: Icon(
        _getCategoryIcon(categoryName),
        size: 28,
        color: Colors.white.withOpacity(0.9),
      ),
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

  // Ethiopian-inspired color palette
  static final _lightCategoryColors = [
    const Color(0xFFD4AF37), // Gold
    const Color(0xFF2E8B57), // Green
    const Color(0xFFDC143C), // Crimson
    const Color(0xFF4169E1), // Royal Blue
    const Color(0xFF8B4513), // Saddle Brown
    const Color(0xFF2F4F4F), // Dark Slate Gray
    const Color(0xFF8B008B), // Dark Magenta
    const Color(0xFFCD853F), // Peru
  ];

  static final _darkCategoryColors = [
    const Color(0xFFB8860B), // Dark Goldenrod
    const Color(0xFF228B22), // Forest Green
    const Color(0xFFB22222), // Fire Brick
    const Color(0xFF1E90FF), // Dodger Blue
    const Color(0xFFA0522D), // Sienna
    const Color(0xFF708090), // Slate Gray
    const Color(0xFF9932CC), // Dark Orchid
    const Color(0xFFD2691E), // Chocolate
  ];
}

// Ethiopian pattern painter for card backgrounds
class _EthiopianPatternCardPainter extends CustomPainter {
  final Color color;

  const _EthiopianPatternCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const patternSize = 30.0;
    final rows = (size.height / patternSize).ceil();
    final columns = (size.width / patternSize).ceil();

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        final x = i * patternSize;
        final y = j * patternSize;

        // Draw simplified Ethiopian cross pattern
        final path = Path();
        path.moveTo(x + patternSize / 2, y);
        path.lineTo(x + patternSize, y + patternSize / 2);
        path.lineTo(x + patternSize / 2, y + patternSize);
        path.lineTo(x, y + patternSize / 2);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
