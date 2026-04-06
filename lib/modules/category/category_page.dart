import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_tips/core/config/api_config.dart';
import 'package:smart_tips/core/theme/app_palette.dart';
import 'package:smart_tips/models/category.dart';
import 'package:smart_tips/widgets/shimmer_widgets.dart';
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
      body: Obx(() {
        // Loading State
        if (store.isLoadingCategories.value) {
          return _buildLoadingState();
        }

        // Error/Empty State
        if (store.categories.isEmpty) {
          return _buildEmptyState(store, theme, palette);
        }

        // Filter categories based on search query
        final query = store.query.value.trim().toLowerCase();
        final filteredCategories = query.isEmpty
            ? store.categories
            : store.categories
                  .where((c) => c.name.toLowerCase().contains(query))
                  .toList();

        // No results after filtering
        if (filteredCategories.isEmpty) {
          return _buildNoResultsState(query, theme, palette);
        }

        return _buildCategoryGrid(filteredCategories, theme, palette);
      }),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (_, __) => const CategoryCardShimmer(),
    );
  }

  Widget _buildEmptyState(
    BlogStore store,
    ThemeData theme,
    AppPalette palette,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Categories Found",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "There was a problem loading categories.\nPlease check your connection and try again.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => store.fetchCategories(),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(
    String query,
    ThemeData theme,
    AppPalette palette,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No categories found",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No categories match \"$query\"",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                final store = Get.find<BlogStore>();
                store.query.value = '';
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Clear Search"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<Category> categories,
    ThemeData theme,
    AppPalette palette,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onTap: () => Get.to(
            () => CategoryListingPage(catId: category.id, title: category.name),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Image/Icon
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.primary?.withOpacity(0.1) ??
                          Colors.blueGrey.shade50,
                      palette.primary?.withOpacity(0.05) ??
                          Colors.blueGrey.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: category.image != null && category.image!.isNotEmpty
                      ? Image.network(
                          "${ApiConfig.imageUrl}${category.image!}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildIconPlaceholder(context, palette),
                        )
                      : _buildIconPlaceholder(context, palette),
                ),
              ),
              const SizedBox(height: 16),

              // Category Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(BuildContext context, AppPalette palette) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary?.withOpacity(0.2) ?? Colors.blueGrey.shade100,
            palette.primary?.withOpacity(0.1) ?? Colors.blueGrey.shade50,
          ],
        ),
      ),
      child: Icon(
        Icons.category_outlined,
        size: 44,
        color:
            palette.primary ??
            (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600),
      ),
    );
  }
}

// Shimmer loading state for category cards
class CategoryCardShimmer extends StatelessWidget {
  const CategoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image shimmer
          Container(
            height: 88,
            width: 88,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          // Name shimmer
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          // Count shimmer
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
