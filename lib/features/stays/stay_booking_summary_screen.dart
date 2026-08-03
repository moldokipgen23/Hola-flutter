import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import 'stay_booking_confirmation_screen.dart';

class StayBookingSummaryScreen extends StatefulWidget {
  final int businessId;
  final String businessName;
  final List<Map<String, dynamic>> selectedRooms;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final int adults;
  final int children;
  final double totalPrice;

  const StayBookingSummaryScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.selectedRooms,
    this.checkIn,
    this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.totalPrice,
  });

  @override
  State<StayBookingSummaryScreen> createState() =>
      _StayBookingSummaryScreenState();
}

class _StayBookingSummaryScreenState extends State<StayBookingSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specialRequestsController.dispose();
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
                    SlideInWidget(
                      delay: const Duration(milliseconds: 50),
                      child: _buildStaySummaryCard(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: _buildPriceBreakdown(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 150),
                      child: _buildRoomDetails(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: _buildCustomerDetails(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 250),
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

  Widget _buildStaySummaryCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.experienceStay.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: AppColors.experienceStay,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.businessName,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Check-in',
            value: _formatDate(widget.checkIn),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Check-out',
            value: _formatDate(widget.checkOut),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.nights_stay_rounded,
            label: 'Duration',
            value: '${widget.nights} night${widget.nights > 1 ? 's' : ''}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.bed_rounded,
            label: 'Rooms',
            value: '${widget.selectedRooms.length}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.people_outline_rounded,
            label: 'Guests',
            value:
                '${widget.adults} adults${widget.children > 0 ? ', ${widget.children} children' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.selectedRooms.map((room) {
            final name = room['name'] as String? ?? 'Room';
            final price = (room['price'] as num? ?? 0).toDouble();
            final quantity = room['quantity'] as int? ?? 1;
            final subtotal =
                room['subtotal'] as double? ?? price * widget.nights * quantity;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$name × $quantity',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${price.toInt()} × ${widget.nights}n × $quantity',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '₹${subtotal.toInt()}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${widget.totalPrice.toInt()}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.experienceStay,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetails(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rooms Selected',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...widget.selectedRooms.map((room) {
          final name = room['name'] as String? ?? 'Room';
          final quantity = room['quantity'] as int? ?? 1;
          final capacity = room['capacity'] as int? ?? 2;
          final bedType = room['bed_type'] as String? ?? '';

          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.bed_rounded,
                  size: 20,
                  color: AppColors.experienceStay,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name × $quantity',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$capacity guests${bedType.isNotEmpty ? ' · $bedType' : ''}',
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
        }),
      ],
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
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _emailController,
          label: 'Email (optional)',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _specialRequestsController,
          label: 'Special Requests (optional)',
          hint: 'Any special requirements...',
          prefixIcon: Icons.note_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPaymentNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.experienceStay.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: AppColors.experienceStay,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay Property Directly',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Payment will be collected by the property at check-in',
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
      final roomsPayload = widget.selectedRooms
          .map(
            (r) => {
              'room_type_id': r['id'],
              'quantity': r['quantity'],
              'price_per_night': r['price'],
            },
          )
          .toList();

      final response = await api.post(
        '/bookings',
        body: {
          'business_id': widget.businessId,
          'customer_name': _nameController.text.trim(),
          'customer_phone': _phoneController.text.trim(),
          'customer_email': _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          'check_in_date': _formatDate(widget.checkIn),
          'check_out_date': _formatDate(widget.checkOut),
          'nights': widget.nights,
          'party_size': widget.adults + widget.children,
          'total_price': widget.totalPrice,
          'payment_method': 'cash',
          'experience': 'stay',
          'rooms': roomsPayload,
          'special_requests': _specialRequestsController.text.trim().isNotEmpty
              ? _specialRequestsController.text.trim()
              : null,
        },
      );

      if (!mounted) return;

      final bookingData = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => StayBookingConfirmationScreen(
            bookingData: bookingData,
            businessName: widget.businessName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            nights: widget.nights,
            selectedRooms: widget.selectedRooms,
            adults: widget.adults,
            children: widget.children,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
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
