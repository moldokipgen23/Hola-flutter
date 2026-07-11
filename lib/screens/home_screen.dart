import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/safe_image.dart';
import 'business_detail_screen.dart';
import 'category_businesses_screen.dart';

Future<List<T>> _safeList<T>(
  Future<dynamic> call,
  List<T> Function(List<dynamic>) mapper,
) async {
  try {
    final res = await call;
    final list = res is List ? res : (res is Map ? _extractList(res) : <dynamic>[]);
    return mapper(list);
  } catch (_) {
    return <T>[];
  }
}

List<dynamic> _extractList(Map res) {
  for (final value in res.values) {
    if (value is List) return value;
    if (value is Map && value['data'] is List) return value['data'] as List;
  }
  return <dynamic>[];
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  const HomeScreen({super.key, this.onSearchTap});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];
  List<Business> featured = [];
  List<Business> trending = [];
  List<Business> newlyAdded = [];
  List<Product> popularProducts = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([
        _safeList(api.get('/categories'), (l) => l.map((c) => Category.fromJson(c)).toList()),
        _safeList(api.get('/businesses/featured'), (l) => l.map((b) => Business.fromJson(b)).toList()),
        _safeList(api.get('/businesses/trending'), (l) => l.map((b) => Business.fromJson(b)).toList()),
        _safeList(api.get('/businesses/new'), (l) => l.map((b) => Business.fromJson(b)).toList()),
        _safeList(api.get('/products/popular'), (l) => l.map((p) => Product.fromJson(p)).toList()),
      ]);
      if (mounted) {
        setState(() {
          categories = results[0] as List<Category>;
          featured = results[1] as List<Business>;
          trending = results[2] as List<Business>;
          newlyAdded = results[3] as List<Business>;
          popularProducts = results[4] as List<Product>;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; error = 'Failed to load data.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : error != null
                ? _buildError()
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Hero Header
                      SliverToBoxAdapter(child: _buildHeroHeader()),
                      // Category Icons
                      if (categories.isNotEmpty) SliverToBoxAdapter(child: _buildCategoryRow()),
                      // Featured Carousel
                      if (featured.isNotEmpty) SliverToBoxAdapter(child: _buildSection('Top Rated', featured, isCarousel: true)),
                      // Trending Grid
                      if (trending.isNotEmpty) SliverToBoxAdapter(child: _buildSection('Explore', trending, isCarousel: false)),
                      // Recently Added
                      if (newlyAdded.isNotEmpty) SliverToBoxAdapter(child: _buildSection('Recently Added', newlyAdded, isCarousel: true)),
                      // Stats
                      SliverToBoxAdapter(child: _buildStats()),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF), Color(0xFFF5F3FF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Discover Local Businesses',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              GestureDetector(
                onTap: widget.onSearchTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 22),
                      SizedBox(width: 12),
                      Text('Search restaurants, shops...', style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: categories.length.clamp(0, 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategoryBusinessesScreen(category: cat),
            )),
            child: Container(
              width: 72,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(child: Text(cat.icon ?? '🏪', style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Business> items, {required bool isCarousel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () {},
                child: const Text('See all', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (isCarousel)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length.clamp(0, 10),
              itemBuilder: (context, index) => _buildBusinessCardHorizontal(items[index]),
            ),
          )
        else
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length.clamp(0, 10),
              itemBuilder: (context, index) => _buildBusinessCardLarge(items[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessCardHorizontal(Business business) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(slug: business.slug),
      )),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: business.photos.isNotEmpty
                    ? SafeImage(path: business.photos.first, width: double.infinity, height: 110)
                    : Center(child: Text(business.category?.icon ?? '🏪', style: const TextStyle(fontSize: 36))),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(business.category?.name ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1),
                    const Spacer(),
                    Row(
                      children: [
                        if (business.averageRating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                          const SizedBox(width: 2),
                          Text('${business.averageRating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                        ],
                        if (business.locality != null) ...[
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(business.locality!, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCardLarge(Business business) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(slug: business.slug),
      )),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Container(
              height: 140,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: business.photos.isNotEmpty
                    ? SafeImage(path: business.photos.first, width: double.infinity, height: 140)
                    : Container(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        child: Center(child: Text(business.category?.icon ?? '🏪', style: const TextStyle(fontSize: 42))),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (business.averageRating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: AppTheme.success),
                              const SizedBox(width: 2),
                              Text('${business.averageRating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.success)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (business.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(business.category!.name, style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (business.locality != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 2),
                              Expanded(child: Text(business.locality!, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.accent],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${featured.length + trending.length + newlyAdded.length}+', 'Businesses'),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem('${categories.length}', 'Categories'),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
          _buildStatItem('4+', 'Areas'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }
}
