import 'package:flutter/material.dart';
import 'package:abayjobs/core/config/api_config.dart';
import 'package:abayjobs/models/post.dart';
import 'package:abayjobs/core/theme/app_palette.dart';

class FeaturedPostTile extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const FeaturedPostTile({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        theme.extension<AppPalette>() ?? AppPalette.fromTheme(theme);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Container(
                  color: _getRandomColorBgShadow().withOpacity(0.5),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Favorite Icon
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star_border,
                    size: 20,
                    color: Colors.yellow,
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags Row
                    Row(
                      children: [
                        if (post.experienceLevel != null &&
                            post.experienceLevel!.isNotEmpty)
                          _buildTag(
                            post.experienceLevel!,
                            bg: _getExperienceColorBg(post.experienceLevel),
                            text: _getExperienceColorText(post.experienceLevel),
                          ),
                        if (post.employmentType != null &&
                            post.employmentType!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _buildTag(
                              post.employmentType!,
                              bg: _getEmploymentColorBg(post.employmentType),
                              text: _getEmploymentColorText(
                                post.employmentType,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Company
                    if (post.companyName != null)
                      Text(
                        post.companyName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, {required Color bg, required Color text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getExperienceColorBg(String? level) {
    switch (level?.toLowerCase()) {
      case 'junior':
        return Colors.green;
      case 'mid':
      case 'intermediate':
        return Colors.orange;
      case 'senior':
        return Colors.red;
      case 'lead':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getExperienceColorText(String? level) => Colors.white;

  Color _getEmploymentColorBg(String? type) {
    switch (type?.toLowerCase()) {
      case 'full time':
        return Colors.blue;
      case 'part time':
        return Colors.teal;
      case 'contract':
        return Colors.deepPurple;
      case 'internship':
        return Colors.amber;
      case 'temporary':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Color _getEmploymentColorText(String? type) => Colors.white;
}

Color _getRandomColorBgShadow() {
  return Colors.primaries[DateTime.now().millisecondsSinceEpoch %
      Colors.primaries.length];
}
