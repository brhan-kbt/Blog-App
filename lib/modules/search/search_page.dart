import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qubee/widgets/shimmer_widgets.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/state/blog_store.dart';
import '../../models/post.dart';
import '../../widgets/post_tile.dart';
import '../../routes/app_routes.dart';
import '../post_detail/post_detail_page.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final store = Get.find<BlogStore>();
  final controller = TextEditingController();
  final _loading = false.obs;
  final _results = <Post>[].obs;
  Timer? _debounce;

  @override
  void dispose() {
    // save whatever is in the field if user didn't press "search"
    final t = controller.text.trim();
    if (t.isNotEmpty) {
      store.addRecentSearch(t);
    }

    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _loading.value = true;
      try {
        final results = await store.searchPosts(q);
        _results.assignAll(results);
      } finally {
        _loading.value = false;
      }
    });
  }

  void _submit(String q) {
    store.addRecentSearch(q);
    _runSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Get.back()),
        titleSpacing: 0,
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (q) {
            setState(() {}); // refresh suffixIcon visibility
            _runSearch(q);
          },
          onSubmitted: _submit,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search …',
            hintStyle: TextStyle(
              // muted hint
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(.5),
            ),
            isDense: true,
            // FLAT: no borders at all
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            // a touch of vertical padding so it breathes inside the AppBar
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 0,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: Theme.of(context).iconTheme.color?.withOpacity(.6),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      controller.clear();
                      _results.clear();
                      setState(() {}); // hide suffix immediately
                    },
                    icon: const Icon(Icons.clear, size: 20),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  )
                : null,
          ),
        ),
      ),
      body: Obx(() {
        final showRecents =
            !_loading.value &&
            controller.text.trim().isEmpty &&
            _results.isEmpty;

        if (_loading.value) {
          return const _ShimmerList();
        }

        if (showRecents) {
          if (store.recentSearches.isEmpty) {
            return const Center(child: Text('No recent searches'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: store.recentSearches.map((q) {
                  return InputChip(
                    label: Text(q),
                    onPressed: () {
                      controller.text = q;
                      controller.selection = TextSelection.collapsed(
                        offset: q.length,
                      );
                      store.addRecentSearch(q); // bump to top
                      _runSearch(q);
                      setState(() {}); // refresh suffix icon state
                    },
                    onDeleted: () => store.removeRecentSearch(q),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: store.clearRecentSearches,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear search history'),
              ),
            ],
          );
        }

        if (_results.isEmpty) {
          return const Center(child: Text('No results'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _results.length,
          itemBuilder: (c, i) {
            final p = _results[i];
            return PostTile(
              post: p,
              onTap: () => Get.to(() => PostDetailPage(post: p)),
              onMore: () => Get.toNamed(Routes.postDetail, arguments: p),
            );
          },
        );
      }),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        PostTileShimmer(),
        PostTileShimmer(),
        PostTileShimmer(),
        PostTileShimmer(),
        PostTileShimmer(),
      ],
    );
  }
}
