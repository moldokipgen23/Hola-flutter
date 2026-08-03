import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/components/hero_card.dart';
import '../../design_system/components/toast.dart';
import '../../models/models.dart';
import '../../services/business_service.dart';
import '../../services/search_service.dart';
import '../../services/api.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isLoading = true;
  String? _error;
  List<Business> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        BusinessService.featured(),
        BusinessService.list(perPage: 20),
      ]);
      if (mounted) {
        setState(() {
          _businesses = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load businesses';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  String _workingHoursStatus(Map<String, dynamic>? hours) {
    if (hours == null || hours.isEmpty) return 'Hours unavailable';
    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final today = dayNames[now.weekday - 1];
    final todayHours = hours[today];
    if (todayHours == null) return 'Closed today';
    if (todayHours is Map) {
      final open = todayHours['open']?.toString();
      final close = todayHours['close']?.toString();
      if (open != null && close != null) return 'Open $open – $close';
    }
    if (todayHours is String) return 'Open today';
    return 'Hours available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Businesses, people and places',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ToastHelper.show(context, 'Filters coming soon'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('⚙️', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _openSearchSheet(context),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EAF0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Search businesses, places, services...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE99A2F),
          strokeWidth: 2.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😢', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE99A2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFE99A2F),
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HeroCard(
            gradientColors: [Color(0xFF954F09), Color(0xFFE99A2F)],
            kicker: 'EXPLORE LAMKA',
            title: 'Everything local, easy to find.',
            description:
                'Discover verified businesses, professionals and institutions.',
            ctaText: '',
            artEmoji: '📍',
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick discover',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 11),
          _buildQuickGrid(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended near you',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'Map',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (_businesses.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(_businesses.length, (i) {
              final b = _businesses[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRecommendedItem(b),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No businesses found nearby',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters or check back later.',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 11,
      crossAxisSpacing: 11,
      childAspectRatio: 1.6,
      children: [
        _buildQuickCard(
          '🏥',
          'Hospitals',
          'Clinics and emergency',
          'healthcare',
        ),
        _buildQuickCard('🏫', 'Schools', 'Nearby institutions', 'education'),
        _buildQuickCard('⛪', 'Churches', 'Community listings', 'religious'),
        _buildQuickCard('🏛️', 'Government', 'Public services', 'government'),
      ],
    );
  }

  Widget _buildQuickCard(
    String emoji,
    String title,
    String subtitle,
    String categorySlug,
  ) {
    return GestureDetector(
      onTap: () => _openCategorySheet(context, title, categorySlug),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedItem(Business b) {
    final photoUrl = b.photos.isNotEmpty
        ? ApiClient.imageUrl(b.photos.first)
        : '';
    final categoryName = b.category?.name ?? 'Business';
    final hoursStatus = _workingHoursStatus(b.workingHours);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/business',
        arguments: {'slug': b.slug},
      ),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Row(
          children: [
            Container(
              width: 67,
              height: 67,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2FF),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text('🏪', style: TextStyle(fontSize: 29)),
                      ),
                    )
                  : const Center(
                      child: Text('🏪', style: TextStyle(fontSize: 29)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$categoryName · $hoursStatus',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('›', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  void _openCategorySheet(
    BuildContext context,
    String title,
    String categorySlug,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(title: title, categorySlug: categorySlug),
    );
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SearchSheet(),
    );
  }
}

// ──────────────────────────── Category Bottom Sheet ────────────────────────────

class _CategorySheet extends StatefulWidget {
  final String title;
  final String categorySlug;

  const _CategorySheet({required this.title, required this.categorySlug});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  bool _loading = true;
  List<Business> _results = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = await BusinessService.list(
        category: widget.categorySlug,
        perPage: 30,
      );
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E6EC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE99A2F),
                        strokeWidth: 2,
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No ${widget.title.toLowerCase()} found',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final b = _results[i];
                        final photoUrl = b.photos.isNotEmpty
                            ? ApiClient.imageUrl(b.photos.first)
                            : '';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Text(
                                        '🏪',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      '🏪',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                          ),
                          title: Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            b.category?.name ?? 'Business',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF667085),
                            ),
                          ),
                          trailing: const Text(
                            '›',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/business',
                              arguments: {'slug': b.slug},
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Search Bottom Sheet ──────────────────────────────

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<Business> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _controller.text.trim();
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String query) async {
    try {
      final found = await SearchService.instantSearch(query);
      if (mounted) {
        setState(() {
          _results = found;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E6EC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search businesses, places, services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(
                  color: Color(0xFFE99A2F),
                  strokeWidth: 2,
                ),
              )
            else if (_controller.text.trim().length >= 2 && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text(
                      'No results for "${_controller.text.trim()}"',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final b = _results[i];
                    final photoUrl = b.photos.isNotEmpty
                        ? ApiClient.imageUrl(b.photos.first)
                        : '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text(
                                    '🏪',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  '🏪',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                      ),
                      title: Text(
                        b.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        b.category?.name ?? 'Business',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF667085),
                        ),
                      ),
                      trailing: const Text(
                        '›',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/business',
                          arguments: {'slug': b.slug},
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
