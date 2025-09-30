import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jara_tech/core/config/api_config.dart';
import 'package:jara_tech/core/theme/app_palette.dart';
import 'package:jara_tech/models/category.dart';
import 'package:jara_tech/widgets/shimmer_widgets.dart';
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
          padding: const EdgeInsets.all(20),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (_, __) => const CategoryShimmer(),
        );
      }

      if (store.categories.isEmpty) {
        /// Redesigned error state
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 72,
                color: theme.colorScheme.error.withOpacity(.7),
              ),
              const SizedBox(height: 12),
              Text(
                "No categories found",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Check your connection or refresh again.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => store.fetchCategories(),
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
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

      return GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: byQuery.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 130,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemBuilder: (c, i) {
          final cat = byQuery[i];
          return _CategoryCard(cat: cat, palette: palette);
        },
      );
    });
  }
}

class _CategoryCard extends StatefulWidget {
  final Category cat;
  final AppPalette palette;

  const _CategoryCard({required this.cat, required this.palette});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) => _scaleController.forward(),
      onTapCancel: () => _scaleController.forward(),
      onTap: () => Get.to(
        () => CategoryListingPage(catId: widget.cat.id, title: widget.cat.name),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 400),
      ),
      child: ScaleTransition(
        scale: _scaleController,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                /// Background (image or placeholder)
                widget.cat.image != null && widget.cat.image!.isNotEmpty
                    ? Image.network(
                        "${ApiConfig.imageUrl}${widget.cat.image!}",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.brightness == Brightness.light
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                        child: const Center(
                          child: Icon(
                            Icons.folder_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                /// Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// Title
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    widget.cat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
