class ApiConfig {
  static const String baseUrl1 = "https://qalbitech.techomia.xyz";
  static const String baseUrl = "https://qalbitech.techomia.xyz/api/v1";
  static const String imageUrl = "https://qalbitech.techomia.xyz/storage/";

  // Endpoints
  static String posts = "$baseUrl/posts";
  static String settings = "$baseUrl/settings";
  static String checkVersion = "$baseUrl/app-config/check-version";

  static String post(int id) => "$baseUrl/posts/$id";
  static String categories = "$baseUrl/categories";
  static String searchPosts(String query) => "$baseUrl/posts/search?q=$query";
  static String toggleLike(int postId) => "$baseUrl/posts/$postId/like";
  static String addView(int postId) => "$baseUrl/posts/$postId/view";

  static const String registerEndpoint = '$baseUrl/fcm/register';
}
