import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';

class RideConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final String pickup;
  final String dropoff;
  final double? distanceKm;
  final double? fare;
  final String fareDisplay;
  final String vehicleType;
  final String vehicleName;
  final DateTime? scheduledAt;
  final String? businessName;
  final String? businessPhone;
  final String? businessWhatsApp;

  const RideConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.pickup,
    required this.dropoff,
    this.distanceKm,
    this.fare,
    required this.fareDisplay,
    required this.vehicleType,
    required this.vehicleName,
    this.scheduledAt,
    this.businessName,
    this.businessPhone,
    this.businessWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              _buildRequestAnimation(isDark),
              const SizedBox(height: AppSpacing.lg),
              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildBookingReference(isDark),
              ),
              const SizedBox(height: AppSpacing.xl),
              SlideInWidget(
                delay: const Duration(milliseconds: 300),
                child: _buildTripDetails(context, isDark),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (businessPhone != null || businessWhatsApp != null)
                SlideInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: _buildContactSection(isDark),
                ),
              if (businessPhone != null || businessWhatsApp != null)
                const SizedBox(height: AppSpacing.lg),
              SlideInWidget(
                delay: const Duration(milliseconds: 500),
                child: _buildStatusNotice(isDark),
              ),
              const SizedBox(height: AppSpacing.lg),
              SlideInWidget(
                delay: const Duration(milliseconds: 600),
                child: _buildActionButtons(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestAnimation(bool isDark) {
    return Column(
      children: [
        PulseAnimation(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.experienceTaxi.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.local_taxi_rounded,
                color: AppColors.experienceTaxi,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SuccessCheckmark(
          size: 48,
          color: AppColors.experienceTaxi,
          duration: AppAnimations.slow,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Request sent!',
          style: AppTypography.headlineMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Waiting for driver confirmation',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingReference(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.experienceTaxi.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.experienceTaxi.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 20,
            color: AppColors.experienceTaxi,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Ref: $bookingId',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.experienceTaxi,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(BuildContext context, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip details',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TripDetailRow(
            icon: Icons.circle,
            iconColor: AppColors.success,
            label: 'Pickup',
            value: pickup,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _TripDetailRow(
            icon: Icons.circle_outlined,
            iconColor: AppColors.error,
            label: 'Drop-off',
            value: dropoff,
            isDark: isDark,
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TripDetailRow(
              icon: Icons.straighten_rounded,
              iconColor: AppColors.textTertiary,
              label: 'Distance',
              value: '${distanceKm!.toStringAsFixed(1)} km',
              isDark: isDark,
            ),
          ],
          const Divider(height: AppSpacing.lg),
          _TripDetailRow(
            icon: Icons.directions_car_rounded,
            iconColor: AppColors.experienceTaxi,
            label: 'Vehicle',
            value: '$vehicleType · $vehicleName',
            isDark: isDark,
          ),
          if (scheduledAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TripDetailRow(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.primary,
              label: 'Scheduled',
              value:
                  '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year} at ${TimeOfDay.fromDateTime(scheduledAt!).format(context)}',
              isDark: isDark,
            ),
          ],
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated fare',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                fareDisplay,
                style: AppTypography.headlineSmall.copyWith(
                  color: fare != null
                      ? AppColors.experienceTaxi
                      : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName ?? 'Operator',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (businessPhone != null)
                Expanded(
                  child: AppButton(
                    label: 'Call',
                    onPressed: () {},
                    type: AppButtonType.outline,
                    leadingIcon: Icons.call_rounded,
                    isFullWidth: true,
                  ),
                ),
              if (businessPhone != null && businessWhatsApp != null)
                const SizedBox(width: AppSpacing.sm),
              if (businessWhatsApp != null)
                Expanded(
                  child: AppButton(
                    label: 'WhatsApp',
                    onPressed: () {},
                    type: AppButtonType.outline,
                    leadingIcon: Icons.chat_rounded,
                    isFullWidth: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your request is being processed. You will be notified once a driver accepts your ride.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        AppButton(
          label: 'Track ride',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Live tracking will be available once a driver is assigned',
                ),
              ),
            );
          },
          isFullWidth: true,
          leadingIcon: Icons.map_rounded,
          type: AppButtonType.outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Cancel ride',
          onPressed: () => _showCancelDialog(context, isDark),
          isFullWidth: true,
          type: AppButtonType.destructive,
          size: AppButtonSize.sm,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Done',
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          isFullWidth: true,
          type: AppButtonType.ghost,
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Cancel ride?',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this ride request? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          AppButton(
            label: 'Keep ride',
            onPressed: () => Navigator.pop(context),
            type: AppButtonType.ghost,
            size: AppButtonSize.sm,
          ),
          AppButton(
            label: 'Cancel',
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            type: AppButtonType.destructive,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

class _TripDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _TripDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
