import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingConfirmationScreen({super.key, required this.bookingData});

  String get _bookingReference {
    return bookingData['id']?.toString() ??
        bookingData['booking_number']?.toString() ??
        '';
  }

  String get _status {
    return bookingData['status']?.toString() ?? 'pending';
  }

  bool get _isRequestMode => _status == 'pending';

  String get _serviceName {
    final service = bookingData['service'];
    if (service is Map) return service['name']?.toString() ?? '';
    return bookingData['service_name']?.toString() ?? '';
  }

  String get _staffName {
    final staff = bookingData['staff'];
    if (staff is Map) return staff['name']?.toString() ?? '';
    return bookingData['staff_name']?.toString() ?? '';
  }

  String get _bookingDate {
    final date = bookingData['booking_date']?.toString();
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[d.month]} ${d.day}, ${d.year}';
    } catch (_) {
      return date;
    }
  }

  String get _startTime {
    final time = bookingData['start_time']?.toString();
    if (time == null) return '';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mStr = m > 0 ? ':${m.toString().padLeft(2, '0')}' : '';
    return '$h12$mStr $period';
  }

  String get _businessName {
    final business = bookingData['business'];
    if (business is Map) return business['name']?.toString() ?? '';
    return bookingData['business_name']?.toString() ?? '';
  }

  String get _customerPhone => bookingData['customer_phone']?.toString() ?? '';
  String get _customerName => bookingData['customer_name']?.toString() ?? '';
  String get _notes => bookingData['notes']?.toString() ?? '';

  void _callVendor(BuildContext context) {
    if (_customerPhone.isNotEmpty) {
      // In production, use url_launcher to make a phone call
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Calling vendor...')));
    }
  }

  void _whatsappVendor(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening WhatsApp...')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            _buildSuccessIcon(isDark),
            const SizedBox(height: AppSpacing.lg),
            _buildTitle(isDark),
            const SizedBox(height: AppSpacing.sm),
            _buildSubtitle(isDark),
            const SizedBox(height: AppSpacing.lg),
            if (_bookingReference.isNotEmpty) ...[
              SlideInWidget(
                delay: const Duration(milliseconds: 400),
                child: _buildReferenceCard(isDark),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            SlideInWidget(
              delay: const Duration(milliseconds: 450),
              child: _buildDetailsCard(isDark),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isRequestMode)
              SlideInWidget(
                delay: const Duration(milliseconds: 480),
                child: _buildAwaitingConfirmationBanner(isDark),
              ),
            if (_isRequestMode) const SizedBox(height: AppSpacing.md),
            SlideInWidget(
              delay: const Duration(milliseconds: 500),
              child: _buildVendorContactSection(context, isDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            SlideInWidget(
              delay: const Duration(milliseconds: 550),
              child: AppButton(
                label: 'View in Activity',
                leadingIcon: Icons.receipt_long_rounded,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                type: AppButtonType.outline,
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SlideInWidget(
              delay: const Duration(milliseconds: 600),
              child: AppButton(
                label: 'Back to Home',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(bool isDark) {
    return const Center(child: SuccessCheckmark());
  }

  Widget _buildTitle(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Center(
        child: Text(
          _isRequestMode ? 'Booking Request Sent!' : 'Booking Confirmed!',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Center(
        child: Text(
          _isRequestMode
              ? 'Your booking request has been sent. You will receive confirmation shortly.'
              : 'Your booking has been confirmed. See you there!',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildReferenceCard(bool isDark) {
    return AppCard(
      backgroundColor: AppColors.experienceAppointment.withValues(alpha: 0.08),
      borderColor: AppColors.experienceAppointment.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 20,
            color: AppColors.experienceAppointment,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Booking #$_bookingReference',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.experienceAppointment,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_serviceName.isNotEmpty)
            _buildDetailRow(
              isDark,
              icon: Icons.medical_services_outlined,
              label: 'Service',
              value: _serviceName,
            ),
          if (_staffName.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.person_outline_rounded,
              label: 'Staff',
              value: _staffName,
            ),
          ],
          if (_bookingDate.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: _bookingDate,
            ),
          ],
          if (_startTime.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: _startTime,
            ),
          ],
          if (_businessName.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.store_outlined,
              label: 'Venue',
              value: _businessName,
            ),
          ],
          if (_customerName.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.person_outline,
              label: 'Name',
              value: _customerName,
            ),
          ],
          if (_customerPhone.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _customerPhone,
            ),
          ],
          if (_notes.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: _notes,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.experienceAppointment),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingConfirmationBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Awaiting Confirmation',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'The business will confirm your booking shortly. You will be notified once confirmed.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorContactSection(BuildContext context, bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Venue',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Call',
                  leadingIcon: Icons.call_rounded,
                  onPressed: () => _callVendor(context),
                  type: AppButtonType.outline,
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'WhatsApp',
                  leadingIcon: Icons.chat_rounded,
                  onPressed: () => _whatsappVendor(context),
                  type: AppButtonType.outline,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
