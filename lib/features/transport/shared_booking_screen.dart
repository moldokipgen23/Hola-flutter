import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';

class SharedBookingScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final int seatCount;
  final List<String> selectedSeats;
  final DateTime travelDate;

  const SharedBookingScreen({
    super.key,
    required this.trip,
    required this.seatCount,
    required this.selectedSeats,
    required this.travelDate,
  });

  @override
  State<SharedBookingScreen> createState() => _SharedBookingScreenState();
}

class _SharedBookingScreenState extends State<SharedBookingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedBoardingPoint;
  String? _selectedDroppingPoint;
  bool _isSubmitting = false;

  double get _totalPrice {
    final pricePerSeat = ((widget.trip['min_price'] ?? 200) as num).toDouble();
    return widget.seatCount * pricePerSeat;
  }

  List<String> get _boardingPoints {
    final points = widget.trip['boarding_points'] as List?;
    if (points != null && points.isNotEmpty) {
      return points.map((e) => e.toString()).toList();
    }
    return ['Main Stand', 'City Centre', 'Bus Terminal'];
  }

  List<String> get _droppingPoints {
    final points = widget.trip['dropping_points'] as List?;
    if (points != null && points.isNotEmpty) {
      return points.map((e) => e.toString()).toList();
    }
    return ['Main Stand', 'City Centre', 'Bus Terminal'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await api.post(
        '/bookings',
        body: {
          'business_id': widget.trip['id'],
          'booking_type': 'shared_transport',
          'customer_name': _nameController.text.trim(),
          'customer_phone': _phoneController.text.trim(),
          'travel_date': widget.travelDate.toIso8601String(),
          'seats': widget.seatCount,
          'seat_labels': widget.selectedSeats,
          'boarding_point': _selectedBoardingPoint,
          'dropping_point': _selectedDroppingPoint,
          'total_price': _totalPrice,
          'payment_method': 'pay_at_boarding',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed! Pay at boarding point.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final name = widget.trip['name'] ?? 'Unknown operator';
    final departureTime = widget.trip['departure_time'] ?? '--:--';
    final arrivalTime = widget.trip['arrival_time'] ?? '--:--';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Confirm booking',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  SlideInWidget(
                    child: _buildTripSummary(
                      isDark,
                      name,
                      departureTime,
                      arrivalTime,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildPassengerForm(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildBoardingPoints(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _buildDroppingPoints(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: _buildPaymentNotice(isDark),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
          _buildConfirmButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTripSummary(
    bool isDark,
    String name,
    String departureTime,
    String arrivalTime,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.experienceSharedTransport.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.experienceSharedTransport,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.travelDate.day}/${widget.travelDate.month}/${widget.travelDate.year}',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Departure',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      departureTime,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Arrival',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      arrivalTime,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seats (${widget.seatCount})',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                widget.selectedSeats.isNotEmpty
                    ? widget.selectedSeats.join(', ')
                    : '${widget.seatCount} seats',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                '₹${_totalPrice.toInt()}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.experienceSharedTransport,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passenger details',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                hint: 'Full name',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                hint: 'Phone number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoardingPoints(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boarding point',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          groupValue: _selectedBoardingPoint,
          onChanged: (value) => setState(() => _selectedBoardingPoint = value),
          child: Column(
            children: _boardingPoints
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: RadioListTile<String>(
                      value: point,
                      title: Text(
                        point,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.experienceSharedTransport;
                        }
                        return isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary;
                      }),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDroppingPoints(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dropping point',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          groupValue: _selectedDroppingPoint,
          onChanged: (value) => setState(() => _selectedDroppingPoint = value),
          child: Column(
            children: _droppingPoints
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: RadioListTile<String>(
                      value: point,
                      title: Text(
                        point,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.experienceSharedTransport;
                        }
                        return isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary;
                      }),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentNotice(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay at boarding',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Pay the driver/operator directly at the boarding point. Eiho One does not collect payment.',
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
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
      ),
      child: AppButton(
        label: _isSubmitting
            ? 'Confirming...'
            : 'Confirm booking · ₹${_totalPrice.toInt()}',
        onPressed: _isSubmitting ? null : _submitBooking,
        isLoading: _isSubmitting,
        isFullWidth: true,
        trailingIcon: Icons.check_circle_rounded,
      ),
    );
  }
}
