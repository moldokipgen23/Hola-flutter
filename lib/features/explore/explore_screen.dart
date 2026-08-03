import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedExperience = 'all';
  String _selectedCategory = 'all';
  bool _showMap = false;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _loadBusinesses();
    }
  }

  Future<void> _loadBusinesses() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'per_page': '20',
      };
      if (_selectedExperience != 'all') {
        queryParams['experience'] = _selectedExperience;
      }
      if (_selectedCategory != 'all') {
        queryParams['category'] = _selectedCategory;
      }
      if (_searchController.text.isNotEmpty) {
        queryParams['q'] = _searchController.text.trim();
      }

      final response = await api.get('/businesses', queryParams: queryParams);
      final paginated = response['businesses'] as Map<String, dynamic>;
      final data = (paginated['data'] as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        if (_currentPage == 1) _businesses.clear();
        _businesses.addAll(data);
        _currentPage++;
        _hasMore = _currentPage <= (paginated['last_page'] as int);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    _loadBusinesses();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildFilters(isDark),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Search businesses...',
                  onChanged: _onSearchChanged,
                  showFilter: true,
                  onFilterTap: _showFilterSheet,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: _showMap ? Icons.list_rounded : Icons.map_outlined,
                onPressed: () => setState(() => _showMap = !_showMap),
                type: AppButtonType.outline,
                size: AppButtonSize.sm,
                tooltip: _showMap ? 'List view' : 'Map view',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          RippleEffect(
            onTap: () => _setExperience('all'),
            child: _FilterChip(
              label: 'All',
              icon: Icons.apps_rounded,
              selected: _selectedExperience == 'all',
              onTap: () => _setExperience('all'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RippleEffect(
            onTap: () => _setExperience('restaurant'),
            child: _FilterChip(
              label: 'Food',
              icon: Icons.restaurant_rounded,
              color: AppColors.experienceRestaurant,
              selected: _selectedExperience == 'restaurant',
              onTap: () => _setExperience('restaurant'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RippleEffect(
            onTap: () => _setExperience('retail'),
            child: _FilterChip(
              label: 'Shopping',
              icon: Icons.shopping_bag_rounded,
              color: AppColors.experienceRetail,
              selected: _selectedExperience == 'retail',
              onTap: () => _setExperience('retail'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RippleEffect(
            onTap: () => _setExperience('taxi'),
            child: _FilterChip(
              label: 'Taxi',
              icon: Icons.local_taxi_rounded,
              color: AppColors.experienceTaxi,
              selected: _selectedExperience == 'taxi',
              onTap: () => _setExperience('taxi'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RippleEffect(
            onTap: () => _setExperience('stay'),
            child: _FilterChip(
              label: 'Hotels',
              icon: Icons.hotel_rounded,
              color: AppColors.experienceStay,
              selected: _selectedExperience == 'stay',
              onTap: () => _setExperience('stay'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RippleEffect(
            onTap: () => _setExperience('turf'),
            child: _FilterChip(
              label: 'Turf',
              icon: Icons.sports_soccer_rounded,
              color: AppColors.experienceTurf,
              selected: _selectedExperience == 'turf',
              onTap: () => _setExperience('turf'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RippleEffect(
            onTap: () => _setExperience('appointment'),
            child: _FilterChip(
              label: 'Appointments',
              icon: Icons.calendar_month_rounded,
              color: AppColors.experienceAppointment,
              selected: _selectedExperience == 'appointment',
              onTap: () => _setExperience('appointment'),
            ),
          ),
        ],
      ),
    );
  }

  void _setExperience(String exp) {
    if (_selectedExperience == exp) return;
    setState(() {
      _selectedExperience = exp;
      _currentPage = 1;
      _hasMore = true;
    });
    _loadBusinesses();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        onCategoryChanged: (cat) {
          setState(() {
            _selectedCategory = cat;
            _currentPage = 1;
            _hasMore = true;
          });
          _loadBusinesses();
        },
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_businesses.isEmpty && _isLoading) {
      return _buildShimmer(isDark);
    }

    if (_businesses.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _showMap ? _buildMapView(isDark) : _buildListView(isDark),
    );
  }

  Widget _buildListView(bool isDark) {
    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: () async {
        _currentPage = 1;
        _hasMore = true;
        await _loadBusinesses();
      },
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _businesses.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _businesses.length) {
            return _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return SlideInWidget(
            delay: Duration(milliseconds: index * 60),
            beginOffset: const Offset(0, 0.15),
            child: AppBusinessCard(
              business: _businesses[index],
              onTap: () => _navigateToDetail(_businesses[index]),
              onPrimaryAction: () => _handlePrimaryAction(_businesses[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      itemBuilder: (_, _) => const BusinessCardSkeleton(),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeInWidget(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No businesses found',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try adjusting your filters or search',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    return Container(
      key: const ValueKey('map'),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Map view coming soon',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> business) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${business['name']} detail screen coming soon')),
    );
  }

  void _handlePrimaryAction(Map<String, dynamic> business) {
    final primaryExperience =
        business['primary_experience'] as String? ?? 'directory';
    final readiness = business['readiness'] as Map<String, dynamic>?;
    final expReadiness = readiness?[primaryExperience] as Map<String, dynamic>?;
    final isReady = expReadiness?['ready'] == true;

    if (!isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contact the business directly'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$primaryExperience flow coming soon')),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final effectiveColor = color ?? AppColors.primary;

    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : effectiveColor),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: selected
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        fontWeight: FontWeight.w600,
      ),
      selectedColor: effectiveColor,
      backgroundColor: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      side: BorderSide(
        color: selected
            ? effectiveColor
            : (isDark ? AppColors.darkOutline : AppColors.outline),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      showCheckmark: false,
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final categories = [
      'all',
      'restaurant',
      'retail',
      'services',
      'health',
      'education',
      'automotive',
    ];

    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOutline : AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Filter by Category',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: RadioGroup<String>(
              groupValue: selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  onCategoryChanged(value);
                  Navigator.pop(context);
                }
              },
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (_, index) {
                  final cat = categories[index];
                  return RadioListTile<String>(
                    title: Text(
                      cat == 'all'
                          ? 'All Categories'
                          : cat[0].toUpperCase() + cat.substring(1),
                      style: AppTypography.bodyMedium,
                    ),
                    value: cat,
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
