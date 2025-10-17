import 'package:intl/intl.dart';
import 'package:abayjobs/models/user_ref.dart';
import 'category.dart';

class Post {
  final int id;
  final String title;
  final String? subtitle;
  final String body;
  final String? image;
  final String? link;
  final int views;
  final int likes;
  final bool isFeatured;
  final String? companyName;
  final String? companyWebsite;
  final String? location;
  final String? employmentType;
  final String? workplaceType;
  final String? experienceLevel;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final DateTime? postedAt;
  final DateTime? deadlineAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category category;
  final UserRef user;

  const Post({
    required this.id,
    required this.title,
    this.subtitle,
    required this.body,
    this.image,
    this.link,
    required this.views,
    required this.likes,
    required this.isFeatured,
    this.companyName,
    this.companyWebsite,
    this.location,
    this.employmentType,
    this.workplaceType,
    this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.postedAt,
    this.deadlineAt,
    required this.createdAt,
    required this.updatedAt,
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
      link: json['link'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      companyName: json['company_name'],
      companyWebsite: json['company_website'],
      location: json['location'],
      employmentType: json['employment_type'],
      workplaceType: json['workplace_type'],
      experienceLevel: json['experience_level'],
      salaryMin: json['salary_min'] != null
          ? double.tryParse(json['salary_min'].toString())
          : null,
      salaryMax: json['salary_max'] != null
          ? double.tryParse(json['salary_max'].toString())
          : null,
      salaryCurrency: json['salary_currency'],
      postedAt: json['posted_at'] != null && json['posted_at'] != ''
          ? DateTime.tryParse(json['posted_at'])
          : null,
      deadlineAt: json['deadline_at'] != null && json['deadline_at'] != ''
          ? DateTime.tryParse(json['deadline_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'link': link,
      'views': views,
      'likes': likes,
      'is_featured': isFeatured,
      'company_name': companyName,
      'company_website': companyWebsite,
      'location': location,
      'employment_type': employmentType,
      'workplace_type': workplaceType,
      'experience_level': experienceLevel,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'posted_at': postedAt?.toIso8601String(),
      'deadline_at': deadlineAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category.toJson(),
      'user': user.toJson(),
    };
  }

  // Helper getters
  String get prettyDate => DateFormat.yMMMMd().format(createdAt);

  String get prettyPostedAt =>
      postedAt != null ? DateFormat.yMMMMd().format(postedAt!) : 'N/A';
  String get prettyDeadlineAt {
    if (deadlineAt == null) return 'N/A';

    final now = DateTime.now();
    final difference = deadlineAt!.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} left';
    } else {
      return 'Less than a minute left';
    }
  }

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
