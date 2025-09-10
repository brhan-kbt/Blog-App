class ApiConfig {
  static const String baseUrl = "https://ekub.birhanu.et/api/v1";

  // Endpoints
  static String posts = "$baseUrl/posts";
  static String categories = "$baseUrl/categories";
  static String searchPosts(String query) => "$baseUrl/posts/search?q=$query";
  static String toggleLike(int postId) => "$baseUrl/posts/$postId/like";
  static String addView(int postId) => "$baseUrl/posts/$postId/view";
}
