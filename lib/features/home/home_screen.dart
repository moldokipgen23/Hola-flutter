import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final ValueChanged<int>? onTabChange;

  const HomeScreen({super.key, this.onSearchTap, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(isDark),
            SliverToBoxAdapter(child: _buildServiceLauncher(isDark)),
            SliverToBoxAdapter(child: _buildNearbySection(isDark)),
            SliverToBoxAdapter(child: _buildRecentActivity(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkSurface, AppColors.darkSurfaceVariant]
                  : [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xxl),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Center(
                      child: Text(
                        'H',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Eiho One',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _LocationChip(),
                  const SizedBox(width: AppSpacing.sm),
                  AppIconButton(
                    icon: Icons.notifications_outlined,
                    onPressed: () {},
                    type: AppButtonType.ghost,
                    size: AppButtonSize.sm,
                    customColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: widget.onSearchTap,
                child: AppSearchField(
                  controller: TextEditingController(),
                  hint: 'Search food, shops, rides, stays...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceLauncher(bool isDark) {
    final items = [
      (Icons.restaurant_rounded, 'Food', AppColors.experienceRestaurant),
      (Icons.shopping_bag_rounded, 'Shopping', AppColors.experienceRetail),
      (Icons.local_taxi_rounded, 'Taxi', AppColors.experienceTaxi),
      (
        Icons.directions_bus_rounded,
        'Transport',
        AppColors.experienceSharedTransport,
      ),
      (Icons.sports_soccer_rounded, 'Turf', AppColors.experienceTurf),
      (Icons.hotel_rounded, 'Hotels', AppColors.experienceStay),
      (
        Icons.calendar_month_rounded,
        'Appointments',
        AppColors.experienceAppointment,
      ),
      (Icons.store_rounded, 'All', AppColors.primary),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInWidget(
            child: Text(
              'What do you need?',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.85,
            children: List.generate(items.length, (index) {
              final (icon, label, color) = items[index];
              return SlideInWidget(
                delay: Duration(milliseconds: index * 60),
                beginOffset: const Offset(0, 0.3),
                child: RippleEffect(
                  onTap: () => widget.onTabChange?.call(1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: _ServiceLauncherItem(
                    icon: icon,
                    label: label,
                    color: color,
                    onTap: () => widget.onTabChange?.call(1),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySection(bool isDark) {
    final businesses = [
      ('https://picsum.photos/seed/biz0/300/200', 'Tasty Bites', 'restaurant'),
      ('https://picsum.photos/seed/biz1/300/200', 'City Mart', 'retail'),
      ('https://picsum.photos/seed/biz2/300/200', 'Quick Ride', 'taxi'),
      ('https://picsum.photos/seed/biz3/300/200', 'Grand Stay', 'stay'),
      ('https://picsum.photos/seed/biz4/300/200', 'Fit Turf', 'turf'),
      ('https://picsum.photos/seed/biz5/300/200', 'Style Salon', 'appointment'),
      ('https://picsum.photos/seed/biz6/300/200', 'MediCare', 'appointment'),
      ('https://picsum.photos/seed/biz7/300/200', 'Event Hub', 'seat_event'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeInWidget(
                child: Text(
                  'Nearby',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: TextButton.icon(
                  onPressed: () => widget.onTabChange?.call(1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View all'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final (imageUrl, name, experience) = businesses[index];
                return SlideInWidget(
                  delay: Duration(milliseconds: 120 + index * 80),
                  beginOffset: const Offset(0.2, 0),
                  direction: Axis.horizontal,
                  child: _NearbyBusinessCard(
                    imageUrl: imageUrl,
                    name: name,
                    experience: experience,
                    distance: '${(index + 1) * 0.5} km',
                    rating: 4.0 + (index * 0.1),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeInWidget(
                child: Text(
                  'Recent Activity',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: TextButton(
                  onPressed: () => widget.onTabChange?.call(2),
                  child: const Text('View all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredAnimationList(
            staggerDelay: const Duration(milliseconds: 80),
            beginOffset: const Offset(0, 0.15),
            children: [
              RippleEffect(
                onTap: () {},
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _ActivityItem(
                  icon: Icons.local_taxi_rounded,
                  iconColor: AppColors.experienceTaxi,
                  title: 'Ride to Airport',
                  subtitle: 'Confirmed • ₹450 • Today 10:30 AM',
                  onTap: () {},
                ),
              ),
              RippleEffect(
                onTap: () {},
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _ActivityItem(
                  icon: Icons.restaurant_rounded,
                  iconColor: AppColors.experienceRestaurant,
                  title: 'Order from Tasty Bites',
                  subtitle: 'Preparing • ₹320 • 15 mins ago',
                  onTap: () {},
                ),
              ),
              RippleEffect(
                onTap: () {},
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _ActivityItem(
                  icon: Icons.sports_soccer_rounded,
                  iconColor: AppColors.experienceTurf,
                  title: 'Turf Booking - 7v7',
                  subtitle: 'Pending confirmation • ₹800 • Tomorrow 6 PM',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Lamka, Churachandpur',
            style: AppTypography.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ServiceLauncherItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceLauncherItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NearbyBusinessCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String experience;
  final String distance;
  final double rating;
  final VoidCallback onTap;

  const _NearbyBusinessCard({
    required this.imageUrl,
    required this.name,
    required this.experience,
    required this.distance,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final experienceColor = _getExperienceColor(experience);
    final experienceIcon = _getExperienceIcon(experience);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: AppSpacing.md),
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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 160,
                        height: 100,
                        color: experienceColor.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            experienceIcon,
                            color: experienceColor,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 10,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: experienceColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          _formatExperienceName(experience),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 10,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          distance,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
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
      ),
    );
  }

  Color _getExperienceColor(String exp) {
    switch (exp) {
      case 'restaurant':
        return AppColors.experienceRestaurant;
      case 'retail':
        return AppColors.experienceRetail;
      case 'taxi':
        return AppColors.experienceTaxi;
      case 'stay':
        return AppColors.experienceStay;
      case 'turf':
        return AppColors.experienceTurf;
      case 'appointment':
        return AppColors.experienceAppointment;
      case 'seat_event':
        return AppColors.experienceSeatEvent;
      default:
        return AppColors.primary;
    }
  }

  IconData _getExperienceIcon(String exp) {
    switch (exp) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'retail':
        return Icons.shopping_bag_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'stay':
        return Icons.hotel_rounded;
      case 'turf':
        return Icons.sports_soccer_rounded;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'seat_event':
        return Icons.event_seat_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  String _formatExperienceName(String exp) {
    return exp
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
