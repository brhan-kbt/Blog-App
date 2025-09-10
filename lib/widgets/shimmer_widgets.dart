import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder for the big HeroCard
class HeroCardShimmer extends StatelessWidget {
  const HeroCardShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            // Title line
            Container(
              height: 16,
              width: 220,
              color: Colors.white,
            ),
            const SizedBox(height: 6),
            // Subtitle lines
            Container(
              height: 14,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            // Meta row
            Container(
              height: 12,
              width: 100,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for PostTile list items
class PostTileShimmer extends StatelessWidget {
  const PostTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 200, color: Colors.white),
                  const SizedBox(height: 14),
                  Container(height: 12, width: 120, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 96,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Category grid items
class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 14, width: 60, color: Colors.white),
        ],
      ),
    );
  }
}
