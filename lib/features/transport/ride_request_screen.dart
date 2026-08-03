import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'ride_confirmation_screen.dart';

class RideRequestScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double? distanceKm;
  final DateTime? scheduledAt;
  final Vehicle vehicle;
  final Business? business;

  const RideRequestScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.distanceKm,
    this.scheduledAt,
    required this.vehicle,
    this.business,
  });

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  double? get _estimatedFare {
    if (widget.vehicle.requiresQuote) return null;
    if (widget.distanceKm == null || widget.distanceKm! <= 0) return null;
    return widget.vehicle.estimatedFare(widget.distanceKm!);
  }

  String get _fareDisplay {
    final fare = _estimatedFare;
    if (fare != null) return '₹${fare.toStringAsFixed(0)}';
    return 'Quote required';
  }

  String _formatType(String type) {
    switch (type) {
      case 'car':
        return 'Sedan';
      case 'auto':
        return 'Auto';
      case 'suv':
        return 'SUV';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  Future<void> _submitRequest() async {
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
      final response = await api.post(
        '/bookings',
        body: {
          'business_id': widget.business?.id,
          'booking_type': 'taxi',
          'vehicle_id': widget.vehicle.id,
          'customer_name': _nameController.text.trim(),
          'customer_phone': _phoneController.text.trim(),
          'pickup_location': widget.pickup,
          'drop_location': widget.dropoff,
          'distance_km': widget.distanceKm,
          'fare': _estimatedFare,
          'fare_status': widget.vehicle.requiresQuote ? 'quote' : 'estimated',
          'scheduled_at': widget.scheduledAt?.toIso8601String(),
          'notes': _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
        },
      );

      if (!mounted) return;

      final bookingId = response is Map
          ? (response['id'] ?? response['booking']?['id'])
          : null;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RideConfirmationScreen(
            bookingId: bookingId?.toString() ?? 'PENDING',
            pickup: widget.pickup,
            dropoff: widget.dropoff,
            distanceKm: widget.distanceKm,
            fare: _estimatedFare,
            fareDisplay: _fareDisplay,
            vehicleType: _formatType(widget.vehicle.type),
            vehicleName: widget.vehicle.name,
            scheduledAt: widget.scheduledAt,
            businessName: widget.business?.name,
            businessPhone: widget.business?.phone,
            businessWhatsApp: widget.business?.whatsapp,
          ),
        ),
        (route) => route.isFirst,
      );
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Request ride',
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
                  FadeInWidget(child: _buildTripSummary(isDark)),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildCustomerForm(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildPaymentInfo(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _buildSpecialInstructions(isDark),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
          _buildRequestButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTripSummary(bool isDark) {
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
                  color: AppColors.experienceTaxi.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    widget.vehicle.typeIcon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_formatType(widget.vehicle.type)} · ${widget.vehicle.seats} seats',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _fareDisplay,
                style: AppTypography.headlineSmall.copyWith(
                  color: widget.vehicle.requiresQuote
                      ? AppColors.warning
                      : AppColors.experienceTaxi,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.circle,
            iconColor: AppColors.success,
            label: widget.pickup,
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Container(
                    width: 1,
                    height: 12,
                    color: isDark ? AppColors.darkOutline : AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          _SummaryRow(
            icon: Icons.circle_outlined,
            iconColor: AppColors.error,
            label: widget.dropoff,
            isDark: isDark,
          ),
          if (widget.distanceKm != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(width: AppSpacing.md + 12),
                Icon(
                  Icons.straighten_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${widget.distanceKm!.toStringAsFixed(1)} km',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (widget.scheduledAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const SizedBox(width: AppSpacing.md + 12),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Scheduled for ${widget.scheduledAt!.day}/${widget.scheduledAt!.month}/${widget.scheduledAt!.year} at ${TimeOfDay.fromDateTime(widget.scheduledAt!).format(context)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your details',
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

  Widget _buildPaymentInfo(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay driver directly — Cash',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Eiho One does not collect any payment',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special instructions',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _instructionsController,
          hint: 'e.g., near the blue gate, call on arrival...',
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildRequestButton(bool isDark) {
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
        label: _isSubmitting ? 'Requesting...' : 'Request ride · $_fareDisplay',
        onPressed: _isSubmitting ? null : _submitRequest,
        isLoading: _isSubmitting,
        isFullWidth: true,
        trailingIcon: Icons.send_rounded,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
