import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design_system/components/gradient_shell.dart';
import '../../design_system/components/hero_card.dart';
import '../../design_system/components/category_grid.dart';
import '../../design_system/components/eiho_bottom_sheet.dart';
import '../../design_system/components/toast.dart';
import '../../models/models.dart';
import '../../models/launch_config.dart';
import '../../services/launch_control_service.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/search_service.dart';
import '../../services/api.dart';
import '../activity/my_orders_screen.dart';
import '../shared/saved_screen.dart';

class _Department {
  final String key;
  final String experienceKey;
  final String emoji;
  final String label;
  final List<Color> gradient;
  final Color soft;
  final String placeholder;
  final List<String> tabs;
  final List<String> hero;

  const _Department({
    required this.key,
    required this.experienceKey,
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.soft,
    required this.placeholder,
    required this.tabs,
    required this.hero,
  });
}

const _departments = [
  _Department(
    key: 'shopping',
    experienceKey: 'retail',
    emoji: '🛍️',
    label: 'Shopping',
    gradient: [Color(0xFF4D2CA8), Color(0xFF7C4DFF)],
    soft: Color(0xFFF2ECFF),
    placeholder: 'Search fashion, electronics, gifts...',
    tabs: ['All', 'Fashion', 'Electronics', 'Beauty', 'Home', 'Gifts'],
    hero: [
      'LOCAL SHOPPING',
      'Discover shops beyond groceries.',
      'Fashion, electronics, beauty, home and gifts—all local.',
      'Explore stores',
      '🛍️',
    ],
  ),
  _Department(
    key: 'grocery',
    experienceKey: 'retail',
    emoji: '🛒',
    label: 'Grocery',
    gradient: [Color(0xFF08753F), Color(0xFF11A75C)],
    soft: Color(0xFFEAF9F1),
    placeholder: 'Search milk, rice, snacks...',
    tabs: ['All', 'Fresh', 'Dairy', 'Snacks', 'Household'],
    hero: [
      '10–20 MIN DELIVERY',
      'Fresh groceries, fast.',
      'Daily essentials from trusted stores around Lamka.',
      'Shop now',
      '🥬',
    ],
  ),
  _Department(
    key: 'food',
    experienceKey: 'restaurant',
    emoji: '🍔',
    label: 'Food',
    gradient: [Color(0xFFB63F00), Color(0xFFFF6B00)],
    soft: Color(0xFFFFF2E8),
    placeholder: "Search for 'Biryani' or restaurants...",
    tabs: ['All', 'Top Rated', 'Fast Delivery', 'Veg', 'Offers'],
    hero: [
      'PAYDAY SPECIAL',
      'Big flavours. Local favourites.',
      'Order from restaurants and home kitchens nearby.',
      'Order food',
      '🍔',
    ],
  ),
  _Department(
    key: 'medicine',
    experienceKey: 'retail',
    emoji: '💊',
    label: 'Medicine',
    gradient: [Color(0xFF1451B8), Color(0xFF2677F3)],
    soft: Color(0xFFEBF3FF),
    placeholder: 'Search medicines, health products...',
    tabs: ['Medicines', 'Wellness', 'Baby Care', 'Personal Care', 'Devices'],
    hero: [
      'HEALTH ESSENTIALS',
      'Trusted pharmacy access.',
      'Request medicines from verified local pharmacies.',
      'Browse pharmacy',
      '💊',
    ],
  ),
];

class ShopScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;
  final LaunchConfig? launchConfig;
  const ShopScreen({super.key, this.onTabChange, this.launchConfig});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedDept = 0;
  int _selectedTab = 0;
  Category? _selectedCategory;

  bool _isLoading = false;
  String? _error;

  List<Category> _categories = [];
  List<Business> _allBusinesses = [];
  List<Business> _businesses = [];
  List<Product> _products = [];

  LaunchConfig get _launchConfig =>
      widget.launchConfig ?? LaunchControlService.instance.config;
  List<_Department> get _availableDepartments => _departments
      .where((department) => _launchConfig.experience(department.experienceKey))
      .toList();
  _Department get _dept => _availableDepartments.isEmpty
      ? _departments.first
      : _availableDepartments[_selectedDept.clamp(0, _availableDepartments.length - 1)];

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
        BusinessService.list(experience: _dept.experienceKey),
        CategoryService.getCategories(),
      ]);

      final businesses = results[0] as List<Business>;
      final categories = results[1] as List<Category>;

      // Fetch products for businesses that have catalog module
      final catalogBusinesses = businesses
          .where((b) => b.hasCatalogModule)
          .toList();
      final productResults = await Future.wait(
        catalogBusinesses.map((b) => BusinessService.products(b.slug)),
      );
      final allProducts = productResults.expand((p) => p).toList();

      if (mounted) {
        setState(() {
          _allBusinesses = businesses;
          _categories = categories;
          _products = allProducts;
          _isLoading = false;
        });
        _applyCategoryFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _categoryIcon(Category cat) {
    if (cat.icon != null && cat.icon!.isNotEmpty) {
      return cat.icon!;
    }
    switch (cat.slug) {
      case 'grocery':
        return '🛒';
      case 'food-restaurants':
        return '🍔';
      case 'pharmacy':
        return '💊';
      case 'shopping':
        return '🛍️';
      case 'hotels-lodges':
        return '🏨';
      case 'turf-sports':
        return '⚽';
      case 'salon-beauty':
        return '💇';
      case 'doctors-clinics':
        return '🏥';
      case 'gym-fitness':
        return '💪';
      case 'events-venues':
        return '🎉';
      case 'photography':
        return '📸';
      case 'education-classes':
        return '📚';
      default:
        return '📂';
    }
  }

  String _formatRating(double rating) {
    return '★ ${rating.toStringAsFixed(1)}';
  }

  String _storeMeta(Business b) {
    final parts = <String>[];
    if (b.locality != null && b.locality!.isNotEmpty) {
      parts.add(b.locality!);
    } else if (b.address != null && b.address!.isNotEmpty) {
      parts.add(b.address!);
    }
    if (b.distance != null && b.distance!.isNotEmpty) {
      parts.add('${b.distance}');
    }
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  String _storeBadge(Business b) {
    if (b.claimStatus == 'verified') return 'OPEN';
    if (b.claimStatus == 'claimed') return 'REQUEST';
    return 'VISIT';
  }

  void _applyCategoryFilter() {
    if (_selectedCategory == null) {
      setState(() => _businesses = _allBusinesses);
    } else {
      setState(() {
        _businesses = _allBusinesses
            .where((b) => b.category?.slug == _selectedCategory!.slug)
            .toList();
      });
    }
  }

  void _onCategoryTap(Category cat) {
    setState(() {
      if (_selectedCategory?.slug == cat.slug) {
        _selectedCategory = null;
      } else {
        _selectedCategory = cat;
      }
    });
    _applyCategoryFilter();
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
            _buildSubNav(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GradientShell(
      gradientColors: _dept.gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Home ›',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'New Lamka, Churachandpur, Manipur',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _openMenuSheet(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    color: Colors.black.withValues(alpha: 0.14),
                  ),
                  child: const Center(
                    child: Text(
                      '☰',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(_availableDepartments.length, (index) {
              final dept = _availableDepartments[index];
              final isActive = _selectedDept == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedDept != index) {
                      setState(() {
                        _selectedDept = index;
                        _selectedTab = 0;
                      });
                      _loadData();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isActive
                                ? dept.soft
                                : Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Center(
                            child: Text(
                              dept.emoji,
                              style: const TextStyle(fontSize: 25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          dept.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: isActive
                                ? dept.gradient[0]
                                : Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openSearchSheet(context),
                  child: Container(
                    height: 53,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dept.placeholder,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              GestureDetector(
                onTap: () =>
                    ToastHelper.show(context, 'Voice search coming soon'),
                child: Container(
                  width: 58,
                  height: 53,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎙️', style: TextStyle(fontSize: 23)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubNav() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _dept.tabs.length,
        itemBuilder: (context, index) {
          final isActive = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? _dept.soft : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _dept.tabs[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isActive ? _dept.gradient[0] : const Color(0xFF667085),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _dept.gradient[0]));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😢', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _dept.gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Retry',
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
        ),
      );
    }

    if (_businesses.isEmpty && _categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'No businesses found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back later for new ${_dept.label.toLowerCase()} options.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _dept.gradient[0],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeroCard(
            gradientColors: _dept.gradient,
            kicker: _dept.hero[0],
            title: _dept.hero[1],
            description: _dept.hero[2],
            ctaText: _dept.hero[3],
            artEmoji: _dept.hero[4],
          ),
          const SizedBox(height: 20),
          if (_categories.isNotEmpty) ...[
            _buildSectionHeader('Browse categories'),
            const SizedBox(height: 11),
            CategoryGrid(
              softColor: _dept.soft,
              categories: _categories
                  .map(
                    (cat) => CategoryItem(
                      emoji: _categoryIcon(cat),
                      label: cat.name,
                      onTap: () => _onCategoryTap(cat),
                    ),
                  )
                  .toList(),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    _applyCategoryFilter();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _dept.soft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _dept.gradient[0]),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14, color: _dept.gradient[0]),
                        const SizedBox(width: 5),
                        Text(
                          'Clear filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _dept.gradient[0],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
          if (_businesses.isNotEmpty) ...[
            _buildSectionHeader('Top rated near you'),
            const SizedBox(height: 11),
            _buildStoreCards(),
            const SizedBox(height: 20),
          ],
          if (_products.isNotEmpty) ...[
            _buildSectionHeader('Popular products'),
            const SizedBox(height: 11),
            _buildProductGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          'See all',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _dept.gradient[0],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCards() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _businesses.length,
        itemBuilder: (context, index) {
          final business = _businesses[index];
          final photoUrl = ApiClient.imageUrl(
            business.photos.isNotEmpty ? business.photos.first : null,
          );
          final badge = _storeBadge(business);
          final rating = _formatRating(business.averageRating);
          final meta = _storeMeta(business);
          final categoryName = business.category?.name ?? '';

          return GestureDetector(
            onTap: () {
              if (business.slug.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/business',
                  arguments: {'slug': business.slug},
                );
              }
            },
            child: Container(
              width: 245,
              margin: const EdgeInsets.only(right: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7EAF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_dept.soft, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (photoUrl.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        _dept.emoji,
                                        style: const TextStyle(fontSize: 55),
                                      ),
                                    ),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Text(
                              _dept.emoji,
                              style: const TextStyle(fontSize: 55),
                            ),
                          ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: badge == 'OPEN'
                                    ? const Color(0xFF0C8B4A)
                                    : const Color(0xFFB66B00),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB66B00),
                              ),
                            ),
                            if (categoryName.isNotEmpty) ...[
                              const SizedBox(width: 7),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                            if (meta.isNotEmpty) ...[
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  meta,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF667085),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final imageUrl = ApiClient.imageUrl(product.image);

        return GestureDetector(
          onTap: () => _openProductSheet(context, product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_dept.soft, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (imageUrl.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Center(
                                  child: Text(
                                    '📦',
                                    style: TextStyle(fontSize: 57),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Text('📦', style: TextStyle(fontSize: 57)),
                          ),
                        if (!product.isInStock)
                          Positioned(
                            left: 9,
                            top: 9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB66B00),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.displayPrice,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.displayPrice,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final businessSlug = product.business?.slug;
                              if (businessSlug != null &&
                                  businessSlug.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  '/retail/storefront',
                                  arguments: {'slug': businessSlug},
                                );
                              } else {
                                ToastHelper.show(
                                  context,
                                  'Store not available',
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _dept.soft,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: _dept.gradient[0]),
                              ),
                              child: Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: _dept.gradient[0],
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
      },
    );
  }

  void _openMenuSheet(BuildContext context) {
    EihoBottomSheet.show(
      context,
      Column(
        children: [
          const SheetHeader(title: 'Eiho One Shopping'),
          const SizedBox(height: 14),
          SheetListItem(
            emoji: '📦',
            title: 'My orders',
            subtitle: 'Track active orders',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          SheetListItem(
            emoji: '❤️',
            title: 'Saved stores',
            subtitle: 'Your favourites',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedScreen()),
              );
            },
          ),
          SheetListItem(
            emoji: '📍',
            title: 'Delivery address',
            subtitle: 'New Lamka',
            onTap: () {
              Navigator.pop(context);
              ToastHelper.show(context, 'Address management coming soon');
            },
          ),
          SheetListItem(
            emoji: '🎧',
            title: 'Help & support',
            subtitle: 'Contact Eiho One',
            onTap: () {
              Navigator.pop(context);
              launchUrl(Uri.parse('mailto:support@hola.ehlom.com'));
            },
          ),
        ],
      ),
    );
  }

  void _openProductSheet(BuildContext context, Product product) {
    final imageUrl = ApiClient.imageUrl(product.image);

    EihoBottomSheet.show(
      context,
      Column(
        children: [
          const SheetHeader(title: ''),
          const SizedBox(height: 14),
          Container(
            height: 205,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_dept.soft, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const Center(
                        child: Text('📦', style: TextStyle(fontSize: 90)),
                      ),
                    ),
                  )
                : const Center(
                    child: Text('📦', style: TextStyle(fontSize: 90)),
                  ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '♡',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              product.description!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SheetListItem(
            emoji: '🏪',
            title: product.business?.name ?? 'Local store',
            subtitle: 'Pickup or request delivery',
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ToastHelper.show(
                context,
                'Added to cart · ${product.displayPrice}',
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _dept.gradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Add to cart · ${product.displayPrice}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchSheet(BuildContext context) {
    List<Business> searchResults = [];
    bool searching = false;
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: _dept.placeholder,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    query = '';
                                    searchResults = [];
                                  });
                                },
                                child: const Icon(Icons.close),
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
                      onChanged: (value) async {
                        query = value.trim();
                        if (query.length < 2) {
                          setSheetState(() => searchResults = []);
                          return;
                        }
                        setSheetState(() => searching = true);
                        final results = await SearchService.instantSearch(
                          query,
                          experience: _dept.experienceKey,
                        );
                        if (context.mounted) {
                          setSheetState(() {
                            searchResults = results;
                            searching = false;
                          });
                        }
                      },
                    ),
                  ),
                  if (searching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  else if (searchResults.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final business = searchResults[index];
                          final photoUrl = ApiClient.imageUrl(
                            business.photos.isNotEmpty
                                ? business.photos.first
                                : null,
                          );
                          return ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _dept.soft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: photoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => Center(
                                          child: Text(
                                            _dept.emoji,
                                            style: const TextStyle(
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _dept.emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                            ),
                            title: Text(
                              business.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              business.category?.name ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF667085),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Color(0xFF667085),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              if (business.slug.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  '/business',
                                  arguments: {'slug': business.slug},
                                );
                              }
                            },
                          );
                        },
                      ),
                    )
                  else if (query.length >= 2 && searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                    )
                  else
                    ..._categories
                        .take(4)
                        .map(
                          (cat) => ListTile(
                            leading: Text(
                              _categoryIcon(cat),
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(cat.name),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _selectedCategory = cat);
                              _applyCategoryFilter();
                            },
                          ),
                        ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
