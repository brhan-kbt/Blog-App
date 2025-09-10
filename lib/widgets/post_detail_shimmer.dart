import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostDetailShimmer extends StatelessWidget {
  const PostDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Top image shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade500,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: EdgeInsets.all(16),
            height: 200,
            color: Colors.white,
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Meta shimmer (date + views)
              Row(
                children: [
                  Container(width: 16, height: 16, color: Colors.grey.shade300),
                  const SizedBox(width: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 14,
                      width: 120,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Body shimmer lines
              ...List.generate(
                10,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Container(height: 18, width: 100, color: Colors.grey.shade300),
            ],
          ),
        ),

        // Suggested shimmer items
        ...List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                children: [
                  Container(width: 96, height: 72, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(height: 14, width: 150, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
