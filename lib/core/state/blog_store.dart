import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:milki_tech/models/app_Setting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart';
import '../../models/category.dart';
import '../config/api_config.dart';

class BlogStore extends GetxController {
  final posts = <Post>[].obs;
  final categories = <Category>[].obs;
  final favorites = <int>{}.obs;
  final query = ''.obs;

  // loading states
  final isLoadingPosts = false.obs;
  final checkLoadingPosts = true.obs;
  final isLoadingCategories = false.obs;
  final isSearching = false.obs;
  final isLoadingSettings = false.obs;

  final settings = Rxn<AppSettings>();

  // recent searches (persisted)
  final recentSearches = <String>[].obs;
  static const _prefsKeyRecent = 'recent_searches';
  static const _prefsKeyFavorites = 'favorite_posts'; // ✅ new key

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _loadFavorites(); // ✅ load favorites

    fetchPosts();
    fetchCategories();
    loadSettings(); // load settings at startup
  }

  List<Post> get filtered =>
      posts.where((p) => p.matches(query.value)).toList();

  List<Post> byCategory(int catId) =>
      filtered.where((p) => p.category.id == catId).toList();

  List<Post> get favoritePosts =>
      filtered.where((p) => favorites.contains(p.id)).toList();

  Future<void> loadSettings() async {
    try {
      isLoadingSettings.value = true;
      settings.value = await fetchSettings();
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      isLoadingSettings.value = false;
    }
  }

  static Future<AppSettings> fetchSettings() async {
    final response = await http.get(Uri.parse(ApiConfig.settings));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AppSettings.fromJson(json);
    } else {
      throw Exception("Failed to load settings");
    }
  }

  void toggleFavorite(int id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    _saveFavorites(); // ✅ persist whenever updated
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList(_prefsKeyFavorites) ?? [];
    favorites.addAll(favList.map(int.parse)); // convert back to int
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyFavorites,
      favorites.map((id) => id.toString()).toList(),
    );
  }

  // ------------------- Recent searches -------------------
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.assignAll(prefs.getStringList(_prefsKeyRecent) ?? const []);
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyRecent, recentSearches);
  }

  Future<void> addRecentSearch(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    recentSearches.remove(t);
    recentSearches.insert(0, t);
    if (recentSearches.length > 10) recentSearches.removeLast();
    await _saveRecentSearches();
  }

  Future<void> removeRecentSearch(String q) async {
    recentSearches.remove(q);
    await _saveRecentSearches();
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    await _saveRecentSearches();
  }

  Future<Map<String, dynamic>> fetchPostWithSuggested(int id) async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.post(id)));

      if (resp.statusCode == 200) {
        final jsonBody = json.decode(resp.body);
        final data = jsonBody['data'];

        final post = Post.fromJson(Map<String, dynamic>.from(data['post']));
        final suggested = (data['suggested'] as List)
            .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        debugPrint("Post: ${Uri.parse(ApiConfig.post(id))}");
        return {'post': post, 'suggested': suggested};
      }
    } catch (e) {
      debugPrint("Error fetching post: $e");
    }
    return {'post': null, 'suggested': []};
  }

  // ------------------- Networking -------------------
  Future<void> fetchPosts() async {
    isLoadingPosts.value = true;
    try {
      final resp = await http.get(Uri.parse(ApiConfig.posts));
      debugPrint("Posts API response: ${resp.statusCode} ${resp.body}");

      if (resp.statusCode == 200) {
        final jsonBody = json.decode(resp.body);
        final List data =
            (jsonBody is Map &&
                jsonBody['data'] is Map &&
                jsonBody['data']['data'] is List)
            ? jsonBody['data']['data'] as List
            : (jsonBody is Map && jsonBody['data'] is List)
            ? jsonBody['data'] as List
            : (jsonBody is List ? jsonBody : const []);

        final parsed = data
            .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        posts.assignAll(parsed);
      } else {
        posts.clear();
      }
    } catch (e, st) {
      debugPrint("Error fetching posts: $e");
      debugPrintStack(stackTrace: st);
      posts.clear();
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final resp = await http.get(Uri.parse(ApiConfig.categories));
      if (resp.statusCode == 200) {
        final jsonBody = json.decode(resp.body);
        final List data = (jsonBody is Map && jsonBody['data'] is List)
            ? jsonBody['data'] as List
            : (jsonBody is List ? jsonBody : const []);

        final parsed = data
            .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        categories.assignAll(parsed);
      } else {
        categories.clear();
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      categories.clear();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> likePost(int postId) async {
    try {
      await http.post(Uri.parse(ApiConfig.toggleLike(postId)));
      toggleFavorite(postId);
    } catch (e) {
      debugPrint("Error liking post: $e");
    }
  }

  Future<void> addView(int postId) async {
    try {
      await http.post(Uri.parse(ApiConfig.addView(postId)));
    } catch (e) {
      debugPrint("Error adding view: $e");
    }
  }

  Future<List<Post>> searchPosts(String query) async {
    if (query.trim().isEmpty) return [];
    isSearching.value = true;

    try {
      final uri = Uri.parse(
        ApiConfig.searchPosts(query),
      ).replace(queryParameters: {'search': query.trim()});

      final resp = await http.get(uri);
      debugPrint("Search response: ${resp.body}");

      if (resp.statusCode == 200) {
        final jsonBody = json.decode(resp.body);
        final List data =
            (jsonBody is Map &&
                jsonBody['data'] is Map &&
                jsonBody['data']['data'] is List)
            ? jsonBody['data']['data'] as List
            : (jsonBody is Map && jsonBody['data'] is List)
            ? jsonBody['data'] as List
            : (jsonBody is List ? jsonBody : const []);

        final parsed =
            data
                .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return parsed;
      }
      return [];
    } catch (e, st) {
      debugPrint("Search error: $e");
      debugPrintStack(stackTrace: st);
      return [];
    } finally {
      isSearching.value = false;
    }
  }
}
