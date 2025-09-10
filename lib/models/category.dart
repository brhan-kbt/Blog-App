class Category {
  final int id;
  final String slug;
  final String name;
  final String? image;
  final int? parentId;

  const Category({
    required this.id,
    required this.slug,
    required this.name,
    this.image,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'image': image,
      'parent_id': parentId,
    };
  }
}

