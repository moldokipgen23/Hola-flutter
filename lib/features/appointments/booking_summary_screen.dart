import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'booking_confirmation_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  final int businessId;
  final String businessSlug;
  final Service? service;
  final String? staffId;
  final String? staffName;
  final DateTime selectedDate;
  final String selectedTime;

  const BookingSummaryScreen({
    super.key,
    required this.businessId,
    required this.businessSlug,
    this.service,
    this.staffId,
    this.staffName,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requestsController = TextEditingController();
  bool _submitting = false;

  String get _formattedDate {
    final d = widget.selectedDate;
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
  }

  String get _formattedTime {
    final parts = widget.selectedTime.split(':');
    if (parts.length < 2) return widget.selectedTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mStr = m > 0 ? ':${m.toString().padLeft(2, '0')}' : '';
    return '$h12$mStr $period';
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final body = <String, dynamic>{
        'service_id': widget.service?.id,
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'booking_date': widget.selectedDate.toIso8601String().split('T')[0],
        'start_time': widget.selectedTime,
        'payment_method': 'cash',
      };

      if (widget.staffId != null) {
        body['staff_id'] = widget.staffId;
      }

      if (_requestsController.text.trim().isNotEmpty) {
        body['notes'] = _requestsController.text.trim();
      }

      final res = await api.post(
        '/businesses/${widget.businessSlug}/bookings',
        body: body,
      );

      if (!mounted) return;

      final bookingData = res['booking'] ?? res;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            bookingData: Map<String, dynamic>.from(bookingData),
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Summary',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            SlideInWidget(
              delay: const Duration(milliseconds: 50),
              child: _buildSummaryCard(isDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            SlideInWidget(
              delay: const Duration(milliseconds: 100),
              child: _buildSectionTitle(
                isDark,
                'Your Details',
                Icons.person_outline,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nameController,
              label: 'Full Name *',
              hint: 'Your name',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number *',
              hint: 'Your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Phone number is required'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSectionTitle(
              isDark,
              'Special Requests',
              Icons.notes_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _requestsController,
              hint: 'Any preferences or special requirements...',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            SlideInWidget(
              delay: const Duration(milliseconds: 200),
              child: _buildPaymentNotice(isDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            SlideInWidget(
              delay: const Duration(milliseconds: 250),
              child: AppButton(
                label: 'Confirm Booking',
                trailingIcon: Icons.check_circle_outline_rounded,
                onPressed: _submitting ? null : _confirmBooking,
                isLoading: _submitting,
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            isDark,
            icon: Icons.medical_services_outlined,
            label: 'Service',
            value: widget.service?.name ?? 'Not specified',
          ),
          const Divider(height: AppSpacing.md),
          _buildDetailRow(
            isDark,
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formattedDate,
          ),
          const Divider(height: AppSpacing.md),
          _buildDetailRow(
            isDark,
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _formattedTime,
          ),
          if (widget.service != null) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: '${widget.service!.duration} minutes',
            ),
          ],
          if (widget.staffName != null) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.person_outline_rounded,
              label: 'Staff',
              value: widget.staffName!,
            ),
          ] else ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.person_outline_rounded,
              label: 'Staff',
              value: 'Any available',
            ),
          ],
          if (widget.service != null) ...[
            const Divider(height: AppSpacing.md),
            _buildDetailRow(
              isDark,
              icon: Icons.payments_outlined,
              label: 'Price',
              value: '₹${widget.service!.price.toStringAsFixed(0)}',
              valueColor: AppColors.experienceAppointment,
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
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.experienceAppointment),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color:
                  valueColor ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 20, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay at venue',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Payment will be collected at the venue after your appointment.',
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
}
