class ApiConfig {
  static const String baseUrl1 = "https://shegertech.birhanu.et";
  static const String baseUrl = "https://shegertech.birhanu.et/api/v1";
  static const String imageUrl = "https://shegertech.birhanu.et/storage/";

  // Endpoints
  static String posts = "$baseUrl/posts";
  static String settings = "$baseUrl/settings";
  static String appConfig = "$baseUrl/app-config";
  static String checkVersion = "$baseUrl/app-config/check-version";

  static String post(int id) => "$baseUrl/posts/$id";
  static String categories = "$baseUrl/categories";
  static String searchPosts(String query) => "$baseUrl/posts/search?q=$query";
  static String toggleLike(int postId) => "$baseUrl/posts/$postId/like";
  static String addView(int postId) => "$baseUrl/posts/$postId/view";

  static const String registerEndpoint = '$baseUrl/fcm/register';
}
