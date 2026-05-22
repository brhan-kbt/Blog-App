import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sheger_tech/core/state/blog_store.dart';
import 'package:sheger_tech/models/category.dart';
import 'package:sheger_tech/modules/category/category_listing_page.dart';

class CategoryTitleList extends StatelessWidget {
  const CategoryTitleList({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<BlogStore>();

    return Obx(() {
      if (store.isLoadingCategories.value) {
        // Shimmer-like placeholders
        return SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 90,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      }

      if (store.categories.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "No categories available",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        );
      }

      final List<Category> cats = store.categories;

      return SizedBox(
        height: 42,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final cat = cats[index];
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Get.to(
                () => CategoryListingPage(catId: cat.id, title: cat.name),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xff32a1af).withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff195158),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
