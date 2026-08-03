import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'route_selection_screen.dart';

class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Business> _operators = [];
  final List<Map<String, dynamic>> _recentDestinations = [
    {
      'name': 'Home',
      'address': 'Lamka, Churachandpur',
      'icon': Icons.home_rounded,
    },
    {
      'name': 'Work',
      'address': 'Imphal City Centre',
      'icon': Icons.work_rounded,
    },
    {
      'name': 'Airport',
      'address': 'Bir Tikendrajit Intl Airport',
      'icon': Icons.flight_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await api.get(
        '/businesses',
        queryParams: {'experience': 'taxi'},
      );
      final data = response is Map
          ? response['data'] ?? response['businesses'] ?? []
          : [];
      final operators = (data as List)
          .map((e) => Business.fromJson(e))
          .toList();
      if (mounted) {
        setState(() {
          _operators = operators;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildMapPlaceholder(isDark),
            SliverToBoxAdapter(child: _buildSearchBar(isDark)),
            SliverToBoxAdapter(child: _buildQuickActions(isDark)),
            SliverToBoxAdapter(child: _buildRecentDestinations(isDark)),
            SliverToBoxAdapter(child: _buildNearbyOperators(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 48,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Map view',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: AppSpacing.md,
              right: AppSpacing.md,
              child: AppIconButton(
                icon: Icons.my_location_rounded,
                onPressed: () {},
                type: AppButtonType.outline,
                tooltip: 'Current location',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RouteSelectionScreen()),
          );
        },
        child: AppTextField(
          controller: _searchController,
          prefixIcon: Icons.search_rounded,
          hint: 'Where to?',
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          _QuickActionChip(
            icon: Icons.home_rounded,
            label: 'Home',
            isDark: isDark,
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickActionChip(
            icon: Icons.work_rounded,
            label: 'Work',
            isDark: isDark,
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickActionChip(
            icon: Icons.history_rounded,
            label: 'Recent',
            isDark: isDark,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDestinations(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Recent destinations',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _recentDestinations.length,
              itemBuilder: (context, index) {
                final dest = _recentDestinations[index];
                return _RecentDestinationCard(
                  name: dest['name'],
                  address: dest['address'],
                  icon: dest['icon'],
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteSelectionScreen(
                          initialDropoff: dest['address'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyOperators(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby taxi operators',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                if (_operators.isNotEmpty)
                  Text(
                    '${_operators.length} found',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isLoading)
            const SizedBox(
              height: 160,
              child: Center(child: BusinessCardSkeleton()),
            )
          else if (_error != null)
            SizedBox(
              height: 140,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Retry',
                      onPressed: _loadOperators,
                      type: AppButtonType.outline,
                      size: AppButtonSize.sm,
                    ),
                  ],
                ),
              ),
            )
          else if (_operators.isEmpty)
            SizedBox(
              height: 140,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_taxi_rounded,
                      size: 40,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No taxi operators nearby',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _operators.length,
                itemBuilder: (context, index) => SlideInWidget(
                  duration: AppAnimations.medium,
                  delay: Duration(milliseconds: 80 * index),
                  beginOffset: const Offset(0.3, 0),
                  child: _OperatorCard(
                    business: _operators[index],
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RouteSelectionScreen(business: _operators[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.experienceTaxi),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentDestinationCard extends StatelessWidget {
  final String name;
  final String address;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentDestinationCard({
    required this.name,
    required this.address,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RippleEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.experienceTaxi.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.experienceTaxi),
            ),
            const Spacer(),
            Text(
              name,
              style: AppTypography.labelMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              address,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorCard extends StatelessWidget {
  final Business business;
  final bool isDark;
  final VoidCallback onTap;

  const _OperatorCard({
    required this.business,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleTypes = business.vehicles.map((v) => v.type).toSet().toList();
    final typeLabels = vehicleTypes
        .map((t) {
          switch (t) {
            case 'car':
              return 'Sedan';
            case 'auto':
              return 'Auto';
            case 'suv':
              return 'SUV';
            case 'bike':
              return 'Bike';
            default:
              return t[0].toUpperCase() + t.substring(1);
          }
        })
        .join(', ');

    return RippleEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.experienceTaxi.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: business.photos.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.network(
                            ApiClient.imageUrl(business.photos.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.local_taxi_rounded,
                              color: AppColors.experienceTaxi,
                              size: 22,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.local_taxi_rounded,
                          color: AppColors.experienceTaxi,
                          size: 22,
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    business.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (business.averageRating > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    business.averageRating.toStringAsFixed(1),
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${business.reviewCount})',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            const Spacer(),
            if (typeLabels.isNotEmpty)
              Text(
                typeLabels,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              '${business.vehicles.length} vehicles',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
