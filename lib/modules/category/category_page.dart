import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kelotech/core/config/api_config.dart';
import 'package:kelotech/core/theme/app_palette.dart';
import 'package:kelotech/models/category.dart';
import 'package:kelotech/widgets/shimmer_widgets.dart';
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

    return Scaffold(
      backgroundColor: palette.cardBg,
      body: CustomScrollView(
        slivers: [
          // Content
          Obx(() {
            if (store.isLoadingCategories.value) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ModernCategoryShimmer(),
                    childCount: 6,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                ),
              );
            }

            if (store.categories.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(store, theme, palette),
              );
            }

            final query = store.query.value.trim().toLowerCase();
            final filteredCategories = query.isEmpty
                ? store.categories
                : store.categories
                      .where((c) => c.name.toLowerCase().contains(query))
                      .toList();

            if (filteredCategories.isEmpty) {
              return SliverFillRemaining(
                child: _buildNoResultsState(query, theme, palette),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = filteredCategories[index];
                  return ModernCategoryCard(
                    category: category,
                    index: index,
                    onTap: () => Get.to(
                      () => CategoryListingPage(
                        catId: category.id,
                        title: category.name,
                      ),
                    ),
                  );
                }, childCount: filteredCategories.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, BlogStore store) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search categories...",
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: palette.primary?.withOpacity(0.3),
                ),
                onChanged: (value) {
                  store.query.value = value;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BlogStore store,
    ThemeData theme,
    AppPalette palette,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  palette.primary?.withOpacity(0.1) ?? Colors.grey.shade100,
                  palette.primary?.withOpacity(0.05) ?? Colors.grey.shade50,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_rounded,
              size: 60,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Categories Found",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We couldn't find any categories.\nPlease check your connection.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.primary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => store.fetchCategories(),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(
    String query,
    ThemeData theme,
    AppPalette palette,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  palette.primary?.withOpacity(0.1) ?? Colors.grey.shade100,
                  palette.primary?.withOpacity(0.05) ?? Colors.grey.shade50,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Results Found",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No categories match \"$query\"",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.primary),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () {
              final store = Get.find<BlogStore>();
              store.query.value = '';
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.primary,
              side: BorderSide(color: palette.primary ?? Colors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text("Clear Search"),
          ),
        ],
      ),
    );
  }
}

// Modern Category Card
class ModernCategoryCard extends StatelessWidget {
  final Category category;
  final int index;
  final VoidCallback onTap;

  const ModernCategoryCard({
    super.key,
    required this.category,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Image/Icon with modern styling
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.primary?.withOpacity(0.15) ?? Colors.blue.shade50,
                      palette.primary?.withOpacity(0.05) ?? Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: category.image != null && category.image!.isNotEmpty
                      ? Image.network(
                          "${ApiConfig.imageUrl}${category.image!}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildModernPlaceholder(context, palette),
                        )
                      : _buildModernPlaceholder(context, palette),
                ),
              ),

              const SizedBox(height: 20),

              // Category Name with modern typography
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Post count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPlaceholder(BuildContext context, AppPalette palette) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary?.withOpacity(0.3) ?? Colors.blue.shade200,
            palette.primary?.withOpacity(0.1) ?? Colors.blue.shade100,
          ],
        ),
      ),
      child: Icon(Icons.category_rounded, size: 50, color: palette.primary),
    );
  }
}

// Modern Shimmer Loading
class ModernCategoryShimmer extends StatelessWidget {
  const ModernCategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image shimmer
          ShimmerWidget.circular(
            width: 90,
            height: 90,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: 20),
          // Name shimmer
          ShimmerWidget.rectangular(width: 100, height: 16, borderRadius: 8),
          const SizedBox(height: 12),
          // Count shimmer
          ShimmerWidget.rectangular(width: 70, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

// Shimmer Widget Helper
class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder,
  }) : borderRadius = 0;

  const ShimmerWidget.rectangular({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  }) : shapeBorder = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        shape:
            shapeBorder ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
      ),
    );
  }
}
