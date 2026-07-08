import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import 'business_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Business> results = [];
  List<String> suggestions = [];
  bool loading = false;
  bool searched = false;

  void _search(String query) async {
    if (query.length < 2) return;
    setState(() => loading = true);

    try {
      final result = await api.get('/search', queryParams: {'q': query});
      setState(() {
        results = (result['businesses'] as List).map((b) => Business.fromJson(b)).toList();
        searched = true;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _loadSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => suggestions = []);
      return;
    }

    try {
      final result = await api.get('/search/suggestions', queryParams: {'q': query});
      setState(() {
        suggestions = List<String>.from(result['suggestions'] ?? []);
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search businesses...',
            border: InputBorder.none,
          ),
          onChanged: _loadSuggestions,
          onSubmitted: _search,
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_controller.text),
            child: const Text('Search', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
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
                          leading: const Icon(Icons.search, color: Colors.grey),
                          title: Text(suggestions[index]),
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
                  child: !searched
                      ? const Center(child: Text('Search for businesses'))
                      : results.isEmpty
                          ? const Center(child: Text('No results found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: results.length,
                              itemBuilder: (context, index) => _buildCard(results[index]),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(Business business) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(slug: business.slug),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('🏪', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(business.category?.name ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
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
