import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import 'buttons.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool isSelectable;
  final bool isSelected;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = AppRadius.md,
    this.shadows,
    this.onTap,
    this.isSelectable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final effectiveBackground =
        backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.surface);
    final effectiveBorderColor =
        borderColor ?? (isDark ? AppColors.darkOutline : AppColors.outline);

    Widget card = Container(
      margin: margin,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isSelected ? AppColors.primary : effectiveBorderColor,
          width: isSelected ? 2 : (borderWidth ?? 1),
        ),
        boxShadow:
            shadows ??
            (isSelected
                ? AppElevation.shadowLevel2(
                    AppColors.primary.withValues(alpha: 0.15),
                  )
                : null),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

class AppBusinessCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  const AppBusinessCard({
    super.key,
    required this.business,
    this.onTap,
    this.onPrimaryAction,
    this.primaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final primaryExperience =
        business['primary_experience'] as String? ?? 'directory';
    final readiness = business['readiness'] as Map<String, dynamic>?;
    final experienceReadiness =
        readiness?[primaryExperience] as Map<String, dynamic>?;
    final isReady = experienceReadiness?['ready'] == true;
    final availabilityMode =
        experienceReadiness?['availability_mode'] as String? ?? 'contact';
    final primaryAction = business['primary_action'] as Map<String, dynamic>?;

    final experienceColor = _getExperienceColor(primaryExperience);
    final experienceIcon = _getExperienceIcon(primaryExperience);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Image/Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child:
                      business['photos'] != null &&
                          (business['photos'] as List).isNotEmpty
                      ? Image.network(
                          business['photos'][0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholder(
                            experienceColor,
                            experienceIcon,
                          ),
                        )
                      : _buildPlaceholder(experienceColor, experienceIcon),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business['name'] ?? 'Unknown',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (business['average_rating'] != null &&
                            (business['average_rating'] as num) > 0)
                          _buildRating(
                            business['average_rating'],
                            business['review_count'] ?? 0,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _ExperienceChip(
                          label: _formatExperienceName(primaryExperience),
                          color: experienceColor,
                          icon: experienceIcon,
                        ),
                        if (!isReady)
                          _AvailabilityBadge(mode: availabilityMode),
                      ],
                    ),
                    if (business['address'] != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              business['address'],
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (onPrimaryAction != null || primaryAction != null) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                if (business['phone'] != null)
                  AppIconButton(
                    icon: Icons.call_outlined,
                    onPressed: () {},
                    type: AppButtonType.ghost,
                    size: AppButtonSize.sm,
                    tooltip: 'Call',
                  ),
                if (business['whatsapp'] != null)
                  AppIconButton(
                    icon: Icons.chat_outlined,
                    onPressed: () {},
                    type: AppButtonType.ghost,
                    size: AppButtonSize.sm,
                    tooltip: 'WhatsApp',
                  ),
                if (business['latitude'] != null)
                  AppIconButton(
                    icon: Icons.directions_outlined,
                    onPressed: () {},
                    type: AppButtonType.ghost,
                    size: AppButtonSize.sm,
                    tooltip: 'Directions',
                  ),
                const Spacer(),
                if (onPrimaryAction != null || primaryAction != null)
                  AppButton(
                    label:
                        primaryActionLabel ??
                        primaryAction?['label'] ??
                        'Action',
                    onPressed: onPrimaryAction,
                    type: isReady
                        ? AppButtonType.primary
                        : AppButtonType.outline,
                    size: AppButtonSize.sm,
                    leadingIcon: _getActionIcon(primaryExperience),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Color color, IconData icon) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(child: Icon(icon, color: color, size: 32)),
    );
  }

  Widget _buildRating(num rating, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.labelSmall.copyWith(color: AppColors.success),
          ),
          const SizedBox(width: 2),
          Text(
            '($count)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getExperienceColor(String experience) {
    switch (experience) {
      case 'restaurant':
        return AppColors.experienceRestaurant;
      case 'retail':
        return AppColors.experienceRetail;
      case 'appointment':
        return AppColors.experienceAppointment;
      case 'stay':
        return AppColors.experienceStay;
      case 'turf':
        return AppColors.experienceTurf;
      case 'taxi':
        return AppColors.experienceTaxi;
      case 'shared_transport':
        return AppColors.experienceSharedTransport;
      case 'vehicle_rental':
        return AppColors.experienceVehicleRental;
      case 'goods_transport':
        return AppColors.experienceGoodsTransport;
      case 'seat_event':
        return AppColors.experienceSeatEvent;
      default:
        return AppColors.primary;
    }
  }

  IconData _getExperienceIcon(String experience) {
    switch (experience) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'retail':
        return Icons.shopping_bag_rounded;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'stay':
        return Icons.hotel_rounded;
      case 'turf':
        return Icons.sports_soccer_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'shared_transport':
        return Icons.directions_bus_rounded;
      case 'vehicle_rental':
        return Icons.directions_car_rounded;
      case 'goods_transport':
        return Icons.local_shipping_rounded;
      case 'seat_event':
        return Icons.event_seat_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  String _formatExperienceName(String experience) {
    return experience
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  IconData _getActionIcon(String experience) {
    switch (experience) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'retail':
        return Icons.shopping_bag_rounded;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'stay':
        return Icons.hotel_rounded;
      case 'turf':
        return Icons.sports_soccer_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'shared_transport':
        return Icons.directions_bus_rounded;
      case 'vehicle_rental':
        return Icons.directions_car_rounded;
      case 'goods_transport':
        return Icons.local_shipping_rounded;
      case 'seat_event':
        return Icons.event_seat_rounded;
      default:
        return Icons.store_rounded;
    }
  }
}

class _ExperienceChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _ExperienceChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final String mode;

  const _AvailabilityBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (mode) {
      'live' => (AppColors.success, 'Live', Icons.circle),
      'request' => (AppColors.warning, 'Request', Icons.schedule_rounded),
      _ => (AppColors.textTertiary, 'Contact', Icons.contact_phone_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
