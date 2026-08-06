import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/city_service.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;
  final int? initialCityId;

  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialCityId,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _isLoading = true;
  String? _error;
  List<Business> _businesses = [];
  List<CityRef> _cities = [];
  int? _selectedCityId;
  String _selectedChip = 'all';
  final TextEditingController _searchController = TextEditingController();
  List<DiscoverCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _categories = await _loadCategories();
      _cities = await CityService.getCities();
      if (_cities.isNotEmpty) {
        _selectedCityId = widget.initialCityId ?? _cities.first.id;
      }
      if (widget.initialCategory != null) {
        _selectedChip = widget.initialCategory!;
      }
      await _loadBusinesses();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<DiscoverCategory>> _loadCategories() async {
    try {
      final server = await CategoryService.getCategories();
      if (server.isNotEmpty) {
        return <DiscoverCategory>[
          const DiscoverCategory('all', 'All', '✨'),
          ...server.map((c) => DiscoverCategory(c.slug, c.name, c.icon ?? '🏪')),
        ];
      }
    } catch (_) {}
    return kDiscoverCategories;
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await BusinessService.list(
        cityId: _selectedCityId,
        category: _selectedChip == 'all' ? null : _selectedChip,
        perPage: 30,
      );
      if (mounted) {
        setState(() {
          _businesses = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _isLoading = false;
        });
      }
    }
  }

  String get _cityName {
    for (final c in _cities) {
      if (c.id == _selectedCityId) return c.name;
    }
    return 'Lamka';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            _buildChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISCOVER',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Nearby in $_cityName',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.14,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F143C).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            const Icon(Icons.search, color: Color(0xFF81869a), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search businesses or services',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final active = cat.slug == _selectedChip;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedChip = cat.slug);
              _loadBusinesses();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.line,
                ),
              ),
              child: Text(
                cat.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: 5,
        itemBuilder: (_, _) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
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
            Text(_error!),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadBusinesses,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_businesses.isEmpty) {
      return const Center(
        child: Text(
          'No businesses found',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _loadBusinesses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
        itemCount: _businesses.length,
        itemBuilder: (context, i) => _buildBusinessCard(_businesses[i]),
      ),
    );
  }

  Widget _buildBusinessCard(Business b) {
    final photoUrl =
        b.photos.isNotEmpty ? ApiClient.imageUrl(b.photos.first) : '';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/business',
        arguments: {'slug': b.slug},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1437).withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.soft,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl.isNotEmpty
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : const Icon(Icons.store, size: 36, color: AppColors.muted),
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
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${b.category?.name ?? ""} · ${b.distance ?? ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '★ ${b.averageRating > 0 ? b.averageRating.toStringAsFixed(1) : "New"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFb07b16),
                        ),
                      ),
                      Text(
                        b.canBookNow ? b.bookCtaLabel : 'View',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
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
}
