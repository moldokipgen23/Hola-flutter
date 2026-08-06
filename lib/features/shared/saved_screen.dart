import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/cards.dart';
import '../../models/models.dart';
import '../../services/api.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _loading = true;
  bool _loggedIn = false;
  List<Business> _businesses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final loggedIn = await api.hasToken();
    if (!mounted) return;
    if (!loggedIn) {
      setState(() {
        _loggedIn = false;
        _loading = false;
      });
      return;
    }
    setState(() => _loggedIn = true);
    try {
      final res = await api.get('/saved');
      final saved = res['saved'];
      final businesses = <Business>[];
      if (saved is List) {
        for (final item in saved) {
          if (item is Map<String, dynamic> && item['business'] is Map) {
            try {
              businesses.add(
                Business.fromJson(
                  Map<String, dynamic>.from(item['business'] as Map),
                ),
              );
            } catch (_) {}
          }
        }
      }
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR COLLECTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Saved places',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : !_loggedIn
                      ? _buildLoginPrompt()
                      : _businesses.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(18),
                              itemCount: _businesses.length,
                              itemBuilder: (context, i) =>
                                  _buildSavedCard(_businesses[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            size: 56,
            color: AppColors.muted,
          ),
          const SizedBox(height: 14),
          const Text(
            'Sign in to see your saved places',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/auth');
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 56, color: AppColors.muted),
          SizedBox(height: 14),
          Text(
            'No saved businesses',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap the heart on any business to save it here',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCard(Business b) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/business',
        arguments: {'slug': b.slug},
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 84,
                height: 84,
                child: b.photos.isNotEmpty
                    ? Image.network(
                        ApiClient.imageUrl(b.photos.first),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.soft,
                          child: const Icon(
                            Icons.store,
                            size: 30,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.soft,
                        child: const Icon(
                          Icons.store,
                          size: 30,
                          color: AppColors.muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${b.category?.name ?? ''}${b.distance != null ? ' · ${b.distance}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '★ ${b.averageRating > 0 ? b.averageRating.toStringAsFixed(1) : "New"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFb07b16),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
