import 'package:intl/intl.dart';
import 'package:qubee/models/user_ref.dart';
import 'category.dart';

class Post {
  final int id;
  final String title;
  final String? subtitle;
  final String body;
  final String? image;
  final int views;
  final int likes;
  final DateTime createdAt;
  final Category category;
  final UserRef user;

  const Post({
    required this.id,
    required this.title,
    this.subtitle,
    required this.body,
    this.image,
    required this.views,
    required this.likes,
    required this.createdAt,
    required this.category,
    required this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      body: json['body'] ?? '',
      image: json['image'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      category: Category.fromJson(json['category'] ?? {}),
      user: UserRef.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'image': image,
      'views': views,
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
      'category': category.toJson(),
      'user': user.toJson(),
    };
  }

  String get prettyDate => DateFormat.yMMMMd().format(createdAt);

  String get viewsStr =>
      views >= 1000 ? "${(views / 1000).toStringAsFixed(1)}K" : "$views";

  bool matches(String q) {
    if (q.trim().isEmpty) return true;
    final s = q.toLowerCase();
    return title.toLowerCase().contains(s) ||
        (subtitle?.toLowerCase().contains(s) ?? false) ||
        body.toLowerCase().contains(s) ||
        category.name.toLowerCase().contains(s) ||
        user.name.toLowerCase().contains(s);
  }
}
