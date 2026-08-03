import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import 'order_tracking_screen.dart';
import 'restaurant_cart_screen.dart';

class RestaurantCheckoutScreen extends StatefulWidget {
  final String businessSlug;
  final List<RestaurantCartEntry> entries;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String orderType;

  const RestaurantCheckoutScreen({
    super.key,
    required this.businessSlug,
    required this.entries,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.orderType,
  });

  @override
  State<RestaurantCheckoutScreen> createState() =>
      _RestaurantCheckoutScreenState();
}

class _RestaurantCheckoutScreenState extends State<RestaurantCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  bool get _isDelivery => widget.orderType == 'delivery';

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final items = widget.entries
          .map(
            (e) => {
              'product_id': e.product.id,
              'quantity': e.quantity,
              if (e.notes != null) 'notes': e.notes,
            },
          )
          .toList();

      final body = <String, dynamic>{
        'items': items,
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'delivery_method': widget.orderType,
        'payment_method': 'cod',
      };

      if (_isDelivery) {
        body['delivery_address'] = _addressController.text.trim();
      }

      if (_notesController.text.trim().isNotEmpty) {
        body['notes'] = _notesController.text.trim();
      }

      final res = await api.post(
        '/businesses/${widget.businessSlug}/orders',
        body: body,
      );

      if (!mounted) return;

      final orderId = res['order']?['id'] ?? res['id'];
      final orderNumber =
          res['order']?['order_number'] ?? res['order_number'] ?? '';

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: orderId is int
                ? orderId
                : int.tryParse(orderId.toString()) ?? 0,
            orderNumber: orderNumber.toString(),
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
    _addressController.dispose();
    _notesController.dispose();
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
          'Checkout',
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
              delay: const Duration(milliseconds: 100),
              child: _buildOrderSummaryCard(isDark),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isDelivery) ...[
              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      isDark,
                      'Delivery Address',
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _addressController,
                      label: 'Delivery Address *',
                      hint: 'Enter full delivery address',
                      prefixIcon: Icons.home_outlined,
                      maxLines: 2,
                      validator: (v) {
                        if (_isDelivery && (v == null || v.trim().isEmpty)) {
                          return 'Delivery address is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FadeInWidget(
              delay: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    isDark,
                    'Contact Details',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    hint: 'Your name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
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
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeInWidget(
              delay: const Duration(milliseconds: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    isDark,
                    'Order Notes',
                    Icons.notes_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _notesController,
                    hint: 'Any special requests for the restaurant...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SlideInWidget(
              delay: const Duration(milliseconds: 500),
              child: _buildPaymentNotice(isDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            SlideInWidget(
              delay: const Duration(milliseconds: 600),
              child: AppButton(
                label: 'Place Order — ₹${widget.total.toStringAsFixed(0)}',
                trailingIcon: Icons.check_circle_outline_rounded,
                onPressed: _submitting ? null : _placeOrder,
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

  Widget _buildOrderSummaryCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.experienceRestaurant.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.quantity}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.experienceRestaurant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      entry.product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${entry.totalPrice.toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppSpacing.md),
          _buildSummaryRow(
            isDark,
            label: 'Subtotal',
            value: '₹${widget.subtotal.toStringAsFixed(0)}',
          ),
          if (_isDelivery)
            _buildSummaryRow(
              isDark,
              label: 'Delivery fee',
              value: '₹${widget.deliveryFee.toStringAsFixed(0)}',
            ),
          const Divider(height: AppSpacing.md),
          _buildSummaryRow(
            isDark,
            label: 'Total',
            value: '₹${widget.total.toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    bool isDark, {
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                (isBold ? AppTypography.titleSmall : AppTypography.bodyMedium)
                    .copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
          ),
          Text(
            value,
            style:
                (isBold ? AppTypography.titleMedium : AppTypography.bodyMedium)
                    .copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
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
                  'Pay restaurant directly',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cash on Delivery (COD). Pay when you receive your order.',
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
