import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/safe_image.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/animations.dart';
import '../../features/shared/business_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// `/search` returns `{"sections": [{"type": "businesses", "items": [...]}]}`.
  /// Tolerate both that shape and a legacy top-level `businesses` array.
  static List<Business> parseSearchResults(dynamic result) {
    if (result is! Map<String, dynamic>) return const [];
    final parsed = <Business>[];

    final sections = result['sections'];
    if (sections is List) {
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        if (section['type'] != 'businesses') continue;
        final items = section['items'];
        if (items is! List) continue;
        for (final item in items) {
          if (item is! Map<String, dynamic>) continue;
          try {
            parsed.add(Business.fromJson(item));
          } catch (_) {
            // Skip a single malformed result instead of failing the whole search.
          }
        }
      }
    }

    final legacy = result['businesses'];
    if (legacy is List && parsed.isEmpty) {
      for (final item in legacy) {
        if (item is! Map<String, dynamic>) continue;
        try {
          parsed.add(Business.fromJson(item));
        } catch (_) {}
      }
    }

    return parsed;
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Business> results = [];
  List<String> suggestions = [];
  bool loading = false;
  bool searched = false;
  String? error;

  void _search(String query) async {
    if (query.trim().length < 2) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await api.get('/search', queryParams: {'q': query.trim()});
      final parsed = SearchScreen.parseSearchResults(result);
      setState(() {
        results = parsed;
        searched = true;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Search failed. Please try again.';
      });
    }
  }

  void _loadSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() => suggestions = []);
      return;
    }

    try {
      final result = await api.get(
        '/search/suggestions',
        queryParams: {'q': query.trim()},
      );
      setState(() {
        suggestions = List<String>.from(result['suggestions'] ?? []);
      });
    } catch (e) {
      // Suggestions are optional, silently ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: null,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search restaurants, shops...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _loadSuggestions,
            onSubmitted: _search,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_controller.text),
            child: const Text(
              'Search',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                if (suggestions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.trending_up_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          title: Text(
                            suggestions[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            _controller.text = suggestions[index];
                            _search(suggestions[index]);
                            setState(() => suggestions = []);
                          },
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                error!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _search(_controller.text),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : !searched
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 64,
                                color: Colors.grey[200],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Search for businesses',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey[200],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: results.length,
                          itemBuilder: (context, index) =>
                              _buildCard(results[index], index),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(Business business, int index) {
    final catColor = CategoryIcons.getColor(business.category?.name);
    return FadeInSlide(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 60),
      child: ScaleOnTap(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(slug: business.slug),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: business.photos.isNotEmpty
                      ? SafeImage(
                          path: business.photos.first,
                          width: 80,
                          height: 80,
                        )
                      : Container(
                          color: catColor.withValues(alpha: 0.08),
                          child: Icon(
                            CategoryIcons.getIcon(business.category?.name),
                            color: catColor,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CategoryIcons.getIcon(
                                    business.category?.name,
                                  ),
                                  size: 10,
                                  color: catColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  business.category?.name ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: catColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (business.averageRating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${business.averageRating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (business.locality != null) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                business.locality!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
