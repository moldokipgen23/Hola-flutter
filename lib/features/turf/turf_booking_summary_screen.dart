import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import 'turf_booking_confirmation_screen.dart';

class TurfBookingSummaryScreen extends StatefulWidget {
  final int businessId;
  final String venueName;
  final String? courtId;
  final String courtName;
  final DateTime date;
  final String time;
  final int duration;
  final int participants;
  final double totalPrice;

  const TurfBookingSummaryScreen({
    super.key,
    required this.businessId,
    required this.venueName,
    this.courtId,
    required this.courtName,
    required this.date,
    required this.time,
    required this.duration,
    required this.participants,
    required this.totalPrice,
  });

  @override
  State<TurfBookingSummaryScreen> createState() =>
      _TurfBookingSummaryScreenState();
}

class _TurfBookingSummaryScreenState extends State<TurfBookingSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Summary',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideInWidget(child: _buildBookingSummaryCard(isDark)),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: _buildCustomerDetails(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: _buildPaymentNotice(isDark),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildErrorMessage(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildConfirmButton(isDark),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard(bool isDark) {
    final startTime = _parseTime(widget.time);
    final endMinutes = startTime.hour * 60 + startTime.minute + widget.duration;
    final endTime = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.experienceTurf.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: AppColors.experienceTurf,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.venueName,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.courtName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.courtName,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(widget.date),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: '$startTime - $endTime',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.timelapse_rounded,
            label: 'Duration',
            value: '${widget.duration} minutes',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.people_outline_rounded,
            label: 'Participants',
            value: '${widget.participants}',
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${widget.totalPrice.toInt()}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.experienceTurf,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Details',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your name',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Name is required';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Phone number is required';
            }
            if (v.trim().length < 10) return 'Enter a valid phone number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.experienceTurf.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: AppColors.experienceTurf,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay at Venue',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pay directly at the venue when you arrive',
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

  Widget _buildErrorMessage(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _submitError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        label: _isSubmitting ? 'Confirming...' : 'Confirm Booking',
        onPressed: _isSubmitting ? null : _submitBooking,
        isFullWidth: true,
        isLoading: _isSubmitting,
        trailingIcon: Icons.check_circle_outline_rounded,
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final response = await api.post(
        '/bookings',
        body: {
          'business_id': widget.businessId,
          'service_id': widget.courtId != null
              ? int.tryParse(widget.courtId!)
              : null,
          'customer_name': _nameController.text.trim(),
          'customer_phone': _phoneController.text.trim(),
          'booking_date': _formatDate(widget.date),
          'start_time': widget.time,
          'duration_minutes': widget.duration,
          'party_size': widget.participants,
          'total_price': widget.totalPrice,
          'payment_method': 'cash',
          'experience': 'turf',
        },
      );

      if (!mounted) return;

      final bookingData = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TurfBookingConfirmationScreen(
            bookingData: bookingData,
            venueName: widget.venueName,
            courtName: widget.courtName,
            date: widget.date,
            time: widget.time,
            duration: widget.duration,
            participants: widget.participants,
            totalPrice: widget.totalPrice,
            customerName: _nameController.text.trim(),
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
