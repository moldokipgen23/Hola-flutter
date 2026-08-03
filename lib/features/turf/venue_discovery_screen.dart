import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../widgets/safe_image.dart';
import 'venue_detail_screen.dart';

class VenueDiscoveryScreen extends StatefulWidget {
  const VenueDiscoveryScreen({super.key});

  @override
  State<VenueDiscoveryScreen> createState() => _VenueDiscoveryScreenState();
}

class _VenueDiscoveryScreenState extends State<VenueDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedSport = 'all';
  bool _showMap = false;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _venues = [];
  Timer? _debounce;

  static const List<Map<String, dynamic>> _sportFilters = [
    {'label': 'All', 'icon': Icons.sports_rounded, 'value': 'all'},
    {
      'label': 'Football',
      'icon': Icons.sports_soccer_rounded,
      'value': 'football',
    },
    {
      'label': 'Cricket',
      'icon': Icons.sports_cricket_rounded,
      'value': 'cricket',
    },
    {'label': 'Tennis', 'icon': Icons.sports_tennis_rounded, 'value': 'tennis'},
    {
      'label': 'Badminton',
      'icon': Icons.sports_tennis_rounded,
      'value': 'badminton',
    },
    {
      'label': 'Basketball',
      'icon': Icons.sports_basketball_rounded,
      'value': 'basketball',
    },
    {
      'label': 'Volleyball',
      'icon': Icons.sports_volleyball_rounded,
      'value': 'volleyball',
    },
    {
      'label': 'Pickleball',
      'icon': Icons.sports_handball_rounded,
      'value': 'pickleball',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _loadVenues();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
      _loadVenues();
    });
  }

  Future<void> _loadVenues() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, String>{
        'experience': 'turf',
        'page': _currentPage.toString(),
        'per_page': '20',
      };
      if (_selectedSport != 'all') {
        queryParams['sport'] = _selectedSport;
      }
      if (_searchController.text.isNotEmpty) {
        queryParams['q'] = _searchController.text.trim();
      }

      final response = await api.get('/businesses', queryParams: queryParams);
      final paginated = response['businesses'] as Map<String, dynamic>;
      final data = (paginated['data'] as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        if (_currentPage == 1) _venues.clear();
        _venues.addAll(data);
        _currentPage++;
        _hasMore = _currentPage <= (paginated['last_page'] as int? ?? 1);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setSport(String sport) {
    if (_selectedSport == sport) return;
    setState(() {
      _selectedSport = sport;
      _currentPage = 1;
      _hasMore = true;
    });
    _loadVenues();
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
            _buildSportFilters(isDark),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return FadeInWidget(
      child: Container(
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
        child: Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _searchController,
                hint: 'Search sports, venues...',
                onChanged: _onSearchChanged,
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
      ),
    );
  }

  Widget _buildSportFilters(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _sportFilters.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final sport = _sportFilters[index];
            return _SportFilterChip(
              label: sport['label'] as String,
              icon: sport['icon'] as IconData,
              selected: _selectedSport == sport['value'],
              onTap: () => _setSport(sport['value'] as String),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_venues.isEmpty && _isLoading) return _buildShimmer(isDark);
    if (_venues.isEmpty) return _buildEmptyState(isDark);
    if (_showMap) return _buildMapView(isDark);

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        _hasMore = true;
        await _loadVenues();
      },
      color: AppColors.experienceTurf,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _venues.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _venues.length) {
            return _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.experienceTurf,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return SlideInWidget(
            delay: Duration(milliseconds: 60 * (index % 10)),
            child: RippleEffect(
              onTap: () => _navigateToDetail(_venues[index]),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _VenueCard(venue: _venues[index]),
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
              Icons.sports_soccer_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No venues found',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different sport or location',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _selectedSport = 'all';
                  _searchController.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                _loadVenues();
              },
              type: AppButtonType.outline,
              size: AppButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    return FadeInWidget(
      child: Container(
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
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> venue) {
    final slug = venue['slug'] as String?;
    if (slug == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VenueDetailScreen(slug: slug)));
  }
}

class _SportFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SportFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final color = AppColors.experienceTurf;

    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : color),
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
      selectedColor: color,
      backgroundColor: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      side: BorderSide(
        color: selected
            ? color
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

class _VenueCard extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final photos = venue['photos'] as List<dynamic>? ?? [];
    final name = venue['name'] as String? ?? 'Unknown Venue';
    final rating = venue['average_rating'] != null
        ? (venue['average_rating'] as num).toDouble()
        : 0.0;
    final reviewCount = venue['review_count'] as int? ?? 0;
    final distance = venue['distance']?.toString();
    final priceRange = venue['price_range'] as int?;
    final availableSlots = venue['available_slots'] as List<dynamic>?;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: photos.isNotEmpty
                      ? SafeImage(
                          path: photos[0].toString(),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.experienceTurf.withValues(
                            alpha: 0.1,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sports_soccer_rounded,
                              size: 48,
                              color: AppColors.experienceTurf,
                            ),
                          ),
                        ),
                ),
              ),
              if (rating > 0)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    if (distance != null) ...[
                      Icon(
                        Icons.near_me_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (reviewCount > 0) ...[
                      Icon(
                        Icons.reviews_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$reviewCount reviews',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (priceRange != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '₹' * priceRange,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.experienceTurf,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (availableSlots != null && availableSlots.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: availableSlots.take(3).map((slot) {
                      final time = slot['time'] as String? ?? '';
                      final spotsLeft = slot['spots_left'] as int? ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: spotsLeft > 3
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '$time ($spotsLeft left)',
                          style: AppTypography.labelSmall.copyWith(
                            color: spotsLeft > 3
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
