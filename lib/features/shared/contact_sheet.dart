import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../models/models.dart';

class ContactSheet extends StatelessWidget {
  final Business business;

  const ContactSheet({super.key, required this.business});

  static void show(BuildContext context, Business business) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ContactSheet(business: business),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _call() {
    if (business.phone != null) {
      _launchUrl('tel:${business.phone}');
    }
  }

  void _whatsapp() {
    if (business.whatsapp != null) {
      _launchUrl('https://wa.me/${business.whatsapp}');
    }
  }

  void _directions() {
    if (business.lat != null && business.lng != null) {
      _launchUrl(
        'https://www.google.com/maps/dir/?api=1&destination=${business.lat},${business.lng}',
      );
    }
  }

  void _share() {
    _launchUrl('https://hola.ehlom.com/business/${business.slug}');
  }

  bool _isOpenNow(String hours) {
    try {
      final parts = hours.split('-');
      if (parts.length != 2) return false;
      final open = parts[0].trim();
      final close = parts[1].trim();
      final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
      final openParts = open.split(':');
      final closeParts = close.split(':');
      final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      return nowMinutes >= openMin && nowMinutes < closeMin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dayName = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][now.weekday - 1];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (business.workingHours != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildWorkingHours(business.workingHours, dayName, isDark),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (business.phone != null)
                        Expanded(
                          child: AppButton(
                            label: 'Call',
                            onPressed: _call,
                            leadingIcon: Icons.call_rounded,
                            type: AppButtonType.primary,
                            size: AppButtonSize.sm,
                            isFullWidth: true,
                          ),
                        ),
                      if (business.phone != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (business.whatsapp != null)
                        Expanded(
                          child: AppButton(
                            label: 'WhatsApp',
                            onPressed: _whatsapp,
                            leadingIcon: Icons.chat_rounded,
                            type: AppButtonType.ghost,
                            size: AppButtonSize.sm,
                            isFullWidth: true,
                          ),
                        ),
                      if (business.whatsapp != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (business.lat != null)
                        Expanded(
                          child: AppButton(
                            label: 'Directions',
                            onPressed: _directions,
                            leadingIcon: Icons.directions_outlined,
                            type: AppButtonType.ghost,
                            size: AppButtonSize.sm,
                            isFullWidth: true,
                          ),
                        ),
                      if (business.lat != null)
                        const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        label: 'Share',
                        onPressed: _share,
                        leadingIcon: Icons.share_outlined,
                        type: AppButtonType.ghost,
                        size: AppButtonSize.sm,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHours(
    Map<String, dynamic>? hours,
    String today,
    bool isDark,
  ) {
    final todayHours = hours?[today]?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            if (todayHours != null) ...[
              Text(
                'Today: $todayHours',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _isOpenNow(todayHours)
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  _isOpenNow(todayHours) ? 'Open' : 'Closed',
                  style: AppTypography.labelSmall.copyWith(
                    color: _isOpenNow(todayHours)
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else
              Text(
                'Hours not available',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
