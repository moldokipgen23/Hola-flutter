import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../services/api.dart';

class BookingLookupScreen extends StatefulWidget {
  const BookingLookupScreen({super.key});

  @override
  State<BookingLookupScreen> createState() => _BookingLookupScreenState();
}

class _BookingLookupScreenState extends State<BookingLookupScreen> {
  final _phoneController = TextEditingController();
  final _referenceController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _booking;

  @override
  void dispose() {
    _phoneController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_phoneController.text.isEmpty || _referenceController.text.isEmpty) {
      setState(() => _error = 'Enter both phone number and booking reference.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _booking = null;
    });

    try {
      final response = await api.get('/bookings/lookup', queryParams: {
        'phone': _phoneController.text.trim(),
        'client_reference': _referenceController.text.trim(),
      });

      final data = response is Map ? response : {};
      final booking = data['booking'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (booking == null) {
            _error = 'No booking found for this phone and reference.';
          } else {
            _booking = booking;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final msg = e.toString().replaceFirst('Exception: ', '');
          if (msg.contains('404') || msg.contains('No booking found')) {
            _error = 'No booking found for this phone and reference.';
          } else {
            _error = msg;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Find my booking',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.experienceAppointment.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.experienceAppointment),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Enter your phone number and booking reference to find your reservation without logging in.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              hint: 'Phone number',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _referenceController,
              prefixIcon: Icons.confirmation_number_outlined,
              hint: 'Booking reference',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Find booking',
              onPressed: _isLoading ? null : _lookup,
              isFullWidth: true,
              isLoading: _isLoading,
              leadingIcon: Icons.search_rounded,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_booking != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildBookingResult(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingResult(bool isDark) {
    final b = _booking!;
    final business = b['business'] as Map<String, dynamic>?;
    final service = b['service'] as Map<String, dynamic>?;
    final status = b['status'] ?? 'unknown';
    final ref = b['client_reference'] ?? '';
    final date = b['booking_date'] ?? b['check_in_date'] ?? '';
    final startTime = b['start_time'] ?? '';
    final price = b['total_price'];
    final type = b['booking_type'] ?? '';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'confirmed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
      case 'completed':
        statusColor = AppColors.experienceSharedTransport;
        statusIcon = Icons.task_alt_rounded;
      default:
        statusColor = AppColors.textTertiary;
        statusIcon = Icons.help_outline;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status.toString().toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (type.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.experienceAppointment.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    type,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.experienceAppointment,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (business != null)
            Text(
              business['name'] ?? '',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          if (service != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              service['name'] ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
          const Divider(height: AppSpacing.md),
          if (ref.isNotEmpty)
            _InfoRow(label: 'Reference', value: ref, isDark: isDark),
          if (date.isNotEmpty)
            _InfoRow(label: 'Date', value: date, isDark: isDark),
          if (startTime.isNotEmpty)
            _InfoRow(label: 'Time', value: startTime, isDark: isDark),
          if (price != null)
            _InfoRow(
              label: 'Total',
              value: '₹${(price as num).toInt()}',
              isDark: isDark,
              valueColor: AppColors.experienceAppointment,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
