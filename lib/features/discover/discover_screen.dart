import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/city_service.dart';
import '../explore/explore_screen.dart';
import '../search/search_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isLoading = true;
  String? _error;
  List<Business> _businesses = [];
  List<CityRef> _cities = [];
  int? _selectedCityId;
  double? _lat;
  double? _lng;
  bool _usingGps = false;
  List<DiscoverCategory> _rail = [];
  final String _selectedCategory = 'all';
  String _pinQuery = '';
  List<Map<String, dynamic>> _pinResults = [];

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
    final citiesFuture = CityService.getCities();
    final railFuture = _loadRail();
    try {
      final results = await Future.wait([citiesFuture, railFuture]);
      if (!mounted) return;
      final cities = results[0] as List<CityRef>;
      setState(() {
        _cities = cities;
        _rail = results[1] as List<DiscoverCategory>;
        if (_selectedCityId == null) {
          final lamka = cities
              .where((c) => c.slug == 'lamka-churachandpur')
              .firstOrNull;
          _selectedCityId = lamka?.id;
        }
      });
      await _loadBusinesses();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load businesses';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<DiscoverCategory>> _loadRail() async {
    try {
      final server = await CategoryService.getCategories();
      if (server.isNotEmpty) {
        final rail = <DiscoverCategory>[
          const DiscoverCategory('all', 'All', '✨'),
          ...server.map(
            (c) => DiscoverCategory(c.slug, c.name, c.displayEmoji),
          ),
        ];
        return rail;
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
        cityId: _usingGps ? null : _selectedCityId,
        latitude: _usingGps ? _lat : null,
        longitude: _usingGps ? _lng : null,
        radius: _usingGps ? 30 : null,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        perPage: 20,
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
          _error = 'Failed to load businesses';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadBusinesses();
  }

  Future<void> _useMyLocation() async {
    if (_usingGps && _lat != null && _lng != null) {
      Navigator.pop(context);
      _loadBusinesses();
      return;
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission needed for "near me"'),
            ),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _usingGps = true;
        _selectedCityId = null;
      });
      _loadBusinesses();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect your location')),
        );
      }
    }
  }

  Future<void> _selectPincode(Map<String, dynamic> pin) async {
    Navigator.pop(context);
    final district = (pin['district']?.toString() ?? '').toLowerCase();
    final state = (pin['state']?.toString() ?? '').toLowerCase();
    CityRef? match;
    for (final c in _cities) {
      final cDistrict = (c.district ?? '').toLowerCase();
      final cState = (c.state ?? '').toLowerCase();
      if (cDistrict.isNotEmpty &&
          cDistrict == district &&
          (state.isEmpty || cState == state)) {
        match = c;
        break;
      }
    }
    setState(() {
      _usingGps = false;
      _lat = null;
      _lng = null;
      _selectedCityId = match?.id;
    });
    if (match != null) {
      _loadBusinesses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No city found for that pincode yet')),
      );
    }
  }

  void _selectCity(CityRef city) {
    setState(() {
      _usingGps = false;
      _lat = null;
      _lng = null;
      _selectedCityId = city.id;
      if (_selectedCityId == 0) _selectedCityId = null;
    });
    _loadBusinesses();
  }

  void _openExplore([String? category]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreScreen(
          initialCategory: category,
          initialCityId: _usingGps ? null : _selectedCityId,
        ),
      ),
    );
  }

  void _selectCategory(String slug) {
    if (slug == 'all') {
      _openExplore();
      return;
    }
    _openExplore(slug);
  }

  CityRef? get _selectedCity {
    for (final c in _cities) {
      if (c.id == _selectedCityId) return c;
    }
    return null;
  }

  /// Launch cities surfaced in the location picker (popular + home market).
  static const List<String> _popularCitySlugs = [
    'lamka-churachandpur',
    'imphal',
    'guwahati',
    'shillong',
    'aizawl',
    'delhi',
    'mumbai',
    'bengaluru',
    'kolkata',
    'hyderabad',
  ];

  List<CityRef> get _pickerCities {
    if (_cities.isEmpty) return const [];
    final curated = _cities
        .where((c) => c.slug != null && _popularCitySlugs.contains(c.slug))
        .toList();
    return curated.isEmpty ? _cities : curated;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _cityName =>
      _usingGps ? 'Near me' : (_selectedCity?.name ?? 'Lamka');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? _buildSkeleton()
            : _error != null
            ? _buildError()
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _onRefresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildGreeting(),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 18),
                    _buildHero(),
                    const SizedBox(height: 22),
                    _buildCategoriesSection(),
                    const SizedBox(height: 22),
                    _buildTrendingSection(),
                    const SizedBox(height: 22),
                    _buildRecommendedSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _openCityPicker,
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _cityName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            children: [
              TextSpan(text: '$_greeting, '),
              const TextSpan(
                text: 'Moldo',
                style: TextStyle(color: AppColors.gold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Discover and book the best around $_cityName.',
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
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
              child: Text(
                'Search "Football turf"',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
            Container(
              width: 37,
              height: 37,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141846).withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SMART DISCOVERY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find it. Trust it.\nBook it.',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.03,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Discover verified local businesses\nand reserve in a few taps.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _openExplore(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Explore Now',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            GestureDetector(
              onTap: () => _openExplore(),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _rail.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cat = _rail[i];
              final active = cat.slug == _selectedCategory;
              return GestureDetector(
                onTap: () => _selectCategory(cat.slug),
                child: SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F143C,
                                    ).withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat.emoji,
                            style: TextStyle(
                              fontSize: 22,
                              color: active ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: active
                              ? AppColors.primary
                              : const Color(0xFF44495f),
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    if (_businesses.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trending Near You',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            GestureDetector(
              onTap: () => _openExplore(),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 216,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _businesses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _buildTrendingCard(_businesses[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(Business b) {
    final photoUrl = b.photos.isNotEmpty
        ? ApiClient.imageUrl(b.photos.first)
        : '';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/business',
        arguments: {'slug': b.slug},
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1437).withValues(alpha: 0.13),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl.isNotEmpty)
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.soft,
                  child: const Icon(
                    Icons.store,
                    size: 40,
                    color: AppColors.muted,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.soft,
                child: const Icon(
                  Icons.store,
                  size: 40,
                  color: AppColors.muted,
                ),
              ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0x05081C00), const Color(0xEC05081C)],
                    stops: const [0.03, 0.62],
                  ),
                ),
              ),
            ),
            // Top tag + heart
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _getTag(b),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom info
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${b.category?.name ?? ""}\n★ ${b.averageRating > 0 ? b.averageRating.toStringAsFixed(1) : "New"} ${b.reviewCount > 0 ? "(${b.reviewCount})" : ""} · ${b.distance ?? ""}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFeceefa),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          b.canBookNow ? b.bookCtaLabel : 'View',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (b.canBookNow)
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/business',
                            arguments: {'slug': b.slug},
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                              ),
                            ),
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

  String _getTag(Business b) {
    if (b.canBookNow) return 'Book now';
    if (b.averageRating >= 4.5) return 'Top rated';
    return 'Popular';
  }

  Widget _buildRecommendedSection() {
    if (_businesses.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended For You',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Based on your preferences',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
            GestureDetector(
              onTap: _onRefresh,
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._businesses.take(3).map((b) => _buildRecommendedCard(b)),
      ],
    );
  }

  Widget _buildRecommendedCard(Business b) {
    final photoUrl = b.photos.isNotEmpty
        ? ApiClient.imageUrl(b.photos.first)
        : '';
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
            // Image
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
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.description ?? b.category?.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '★ ${b.averageRating > 0 ? b.averageRating.toStringAsFixed(1) : "New"} · ${b.distance ?? ""}',
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

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
      children: [
        const SizedBox(height: 48),
        Container(
          height: 27,
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.line),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.soft,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
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
            onTap: _loadBusinesses,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  Future<void> _searchPincode(String q, StateSetter setSheetState) async {
    if (q.trim().length < 3) {
      setSheetState(() {
        _pinQuery = q;
        _pinResults = [];
      });
      return;
    }
    try {
      final res = await api.get(
        '/pincodes/search',
        queryParams: {'q': q.trim()},
      );
      final data = res['data'];
      setSheetState(() {
        _pinQuery = q;
        _pinResults = data is List
            ? data
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : [];
      });
    } catch (_) {
      setSheetState(() {
        _pinQuery = q;
        _pinResults = [];
      });
    }
  }

  void _openCityPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your city',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'See businesses near you',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                // Use my current location
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                  child: GestureDetector(
                    onTap: _useMyLocation,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3E6F1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Use my current location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pincode search
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                  child: TextField(
                    onChanged: (q) => _searchPincode(q, setSheetState),
                    decoration: InputDecoration(
                      hintText: 'Search by pincode (e.g. 795128)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (_pinResults.isNotEmpty)
                  ..._pinResults.map(
                    (pin) => GestureDetector(
                      onTap: () => _selectPincode(pin),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pin['pincode']} · ${pin['locality']}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${pin['district']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_pinQuery.isNotEmpty && _pinResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
                    child: Text(
                      'No pincode found',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                // City list header
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'OR CHOOSE A CITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.05,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                if (_pickerCities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No cities available',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: _pickerCities
                          .map(
                            (city) => GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _selectCity(city);
                              },
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  10,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.line),
                                  borderRadius: BorderRadius.circular(16),
                                  color: _selectedCityId == city.id
                                      ? const Color(0xFFF2f3fa)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          city.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (city.state != null)
                                          Text(
                                            city.state!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (_selectedCityId == city.id)
                                      const Text(
                                        '✓',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
