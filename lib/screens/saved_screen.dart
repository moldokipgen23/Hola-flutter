import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/safe_image.dart';
import 'business_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Business> saved = [];
  bool loading = true;
  bool loggedIn = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final hasToken = await api.hasToken();
      if (!hasToken) {
        setState(() {
          loggedIn = false;
          loading = false;
        });
        return;
      }

      final result = await api.get('/saved');
      final savedList = result['saved'] as List;
      setState(() {
        saved = savedList.map((item) => Business.fromJson(item['business'])).toList();
        loggedIn = true;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loggedIn = false;
        loading = false;
        error = 'Failed to load saved businesses. Please try again.';
      });
    }
  }

  Future<void> _removeSaved(Business business) async {
    try {
      await api.post('/saved/toggle', body: {'business_id': business.id});
      setState(() {
        saved.removeWhere((b) => b.id == business.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : !loggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Login to see saved businesses', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : saved.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No saved businesses yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSaved,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: saved.length,
                        itemBuilder: (context, index) {
                          final business = saved[index];
                          return Dismissible(
                            key: Key(business.id.toString()),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: AppTheme.error,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _removeSaved(business),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => BusinessDetailScreen(slug: business.slug),
                              )),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SafeImage(path: business.photos.isNotEmpty ? business.photos.first : null),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(business.address ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
