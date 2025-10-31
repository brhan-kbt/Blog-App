import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nile_tech/core/config/api_config.dart';
import 'package:nile_tech/core/theme/app_palette.dart';
import 'package:nile_tech/models/category.dart';
import 'package:nile_tech/widgets/shimmer_widgets.dart';
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
        mainAxisExtent: 200,
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
            // Modern geometric error icon
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2D2D6D), const Color(0xFF1B1B45)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C6CD3).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6C6CD3),
                        width: 3,
                      ),
                    ),
                  ),
                  // Inner cross
                  Icon(
                    Icons.close_rounded,
                    size: 50,
                    color: const Color(0xFF6C6CD3),
                    shadows: [
                      Shadow(
                        blurRadius: 15,
                        color: const Color(0xFF6C6CD3).withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Connection Issue",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE0E0FF),
                fontFamily: "Roboto",
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Unable to load categories. Please check your connection and try again.",
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFFE0E0FF).withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => store.fetchCategories(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C6CD3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF6C6CD3).withOpacity(0.4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 22),
                  SizedBox(width: 12),
                  Text(
                    "Retry Connection",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D6D).withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4A4A9C), width: 2),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: const Color(0xFF6C6CD3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Categories Found",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0FF),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Try adjusting your search terms",
            style: TextStyle(
              color: const Color(0xFFE0E0FF).withOpacity(0.7),
              fontSize: 16,
            ),
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
        return _buildCategoryCard(category, palette, isDark, theme, index);
      },
    );
  }

  Widget _buildCategoryCard(
    Category category,
    AppPalette palette,
    bool isDark,
    ThemeData theme,
    int index,
  ) {
    final cardColors = _getCategoryGradient(category.name, index);
    final textColor = const Color(0xFFE0E0FF);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Get.to(
        () => CategoryListingPage(catId: category.id, title: category.name),
        transition: Transition.cupertinoDialog,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardColors,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColors.last.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _ModernPatternPainter(
                    baseColor: cardColors.first.withOpacity(0.1),
                    accentColor: cardColors.last.withOpacity(0.2),
                  ),
                ),
              ),
            ),

            // Floating particles
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _FloatingParticlesPainter(
                    color: textColor.withOpacity(0.1),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon Container
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: category.image != null && category.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              "${ApiConfig.imageUrl}${category.image!}",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackIcon(category.name, textColor),
                            ),
                          )
                        : _buildFallbackIcon(category.name, textColor),
                  ),

                  const Spacer(),

                  // Category Name
                  Text(
                    category.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Progress indicator line
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Hover overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top right decorative element
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(String categoryName, Color color) {
    return Center(
      child: Icon(_getCategoryIcon(categoryName), size: 32, color: color),
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
    } else if (name.contains('data') || name.contains('analytics')) {
      return Icons.analytics_rounded;
    } else if (name.contains('cloud') || name.contains('server')) {
      return Icons.cloud_rounded;
    } else if (name.contains('security') || name.contains('cyber')) {
      return Icons.security_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  List<Color> _getCategoryGradient(String categoryName, int index) {
    final hash = categoryName.hashCode + index;
    final gradients = _categoryGradients;
    return gradients[hash % gradients.length];
  }

  // Modern gradient combinations based on #1b1b45
  static final _categoryGradients = [
    // Blue to Purple
    [const Color(0xFF2D2D6D), const Color(0xFF4A4A9C), const Color(0xFF6C6CD3)],
    // Deep Blue to Teal
    [const Color(0xFF1B1B45), const Color(0xFF2A4A5F), const Color(0xFF3A8DA8)],
    // Purple to Pink
    [const Color(0xFF3A2D6D), const Color(0xFF5A4A9C), const Color(0xFF8C6CD3)],
    // Navy to Blue
    [const Color(0xFF151538), const Color(0xFF2D2D6D), const Color(0xFF4A4A9C)],
    // Dark Purple to Light Purple
    [const Color(0xFF2A1B45), const Color(0xFF4A2D6D), const Color(0xFF6C4A9C)],
    // Blue to Green
    [const Color(0xFF1B2D45), const Color(0xFF2A5F5A), const Color(0xFF3AA8A8)],
    // Deep Navy to Violet
    [const Color(0xFF0F0F2D), const Color(0xFF2D1B45), const Color(0xFF4A2D6D)],
    // Blue Gray to Light Blue
    [const Color(0xFF2A3A45), const Color(0xFF3A5F6D), const Color(0xFF4A8CA8)],
  ];
}

// Modern geometric pattern painter
class _ModernPatternPainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;

  const _ModernPatternPainter({
    required this.baseColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const patternSize = 40.0;
    final rows = (size.height / patternSize).ceil();
    final columns = (size.width / patternSize).ceil();

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        final x = i * patternSize;
        final y = j * patternSize;

        // Draw modern geometric patterns
        if ((i + j) % 2 == 0) {
          // Circles
          canvas.drawCircle(
            Offset(x + patternSize / 2, y + patternSize / 2),
            patternSize / 8,
            basePaint..style = PaintingStyle.stroke,
          );
        } else {
          // Triangles
          final path = Path()
            ..moveTo(x + patternSize / 2, y)
            ..lineTo(x + patternSize, y + patternSize)
            ..lineTo(x, y + patternSize)
            ..close();
          canvas.drawPath(path, accentPaint);
        }

        // Connecting lines
        if (i < columns - 1) {
          canvas.drawLine(
            Offset(x + patternSize, y + patternSize / 2),
            Offset(x + patternSize * 1.5, y + patternSize / 2),
            basePaint,
          );
        }

        if (j < rows - 1) {
          canvas.drawLine(
            Offset(x + patternSize / 2, y + patternSize),
            Offset(x + patternSize / 2, y + patternSize * 1.5),
            basePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Floating particles painter
class _FloatingParticlesPainter extends CustomPainter {
  final Color color;

  const _FloatingParticlesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final particleCount = 8;
    final random = Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
