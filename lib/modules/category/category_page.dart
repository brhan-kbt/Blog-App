import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sheger_tech/core/config/api_config.dart';
import 'package:sheger_tech/core/theme/theme_service.dart';
import 'package:sheger_tech/models/category.dart';
import 'package:sheger_tech/widgets/shimmer_widgets.dart';
import '../../core/state/blog_store.dart';
import 'category_listing_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    return Obx(() {
      if (store.isLoadingCategories.value) {
        return _buildShimmerGrid();
      }

      if (store.categories.isEmpty) {
        return _buildErrorState(store);
      }

      final query = store.query.value.trim().toLowerCase();
      final filteredCategories = query.isEmpty
          ? store.categories
          : store.categories
                .where((cat) => cat.name.toLowerCase().contains(query))
                .toList();

      if (filteredCategories.isEmpty) {
        return _buildNoResultsState();
      }

      return _buildCategoryGrid(filteredCategories);
    });
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 120,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => const CategoryShimmer(),
    );
  }

  Widget _buildErrorState(BlogStore store) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Failed to load categories",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please check your connection and try again",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => store.fetchCategories(),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No categories found",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try different search terms",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 120,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, context);
      },
    );
  }

  Widget _buildCategoryCard(Category category, context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Brightness.light == theme.brightness
          ? Colors.white
          : Color(0xFF143d5f).withOpacity(0.6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(
          () => CategoryListingPage(catId: category.id, title: category.name),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Image/Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF143d5f).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          "${ApiConfig.imageUrl}${category.image!}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                        ),
                      )
                    : _buildFallbackIcon(),
              ),

              const SizedBox(height: 12),

              // Category Name
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return const Icon(Icons.category, size: 24, color: Colors.blue);
  }
}
