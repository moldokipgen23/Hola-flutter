import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'cart_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Business business;
  final List<CartEntry> entries;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.business,
    required this.entries,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _deliveryMethod = 'pickup';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _pincodeError;
  bool _pincodeValid = false;

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _checkPincode(String pincode) async {
    if (pincode.length != 6) {
      setState(() {
        _pincodeError = null;
        _pincodeValid = false;
      });
      return;
    }

    try {
      final response = await api.post(
        '/businesses/${widget.business.slug}/check-pincode',
        body: {'pincode': pincode},
      );
      if (!mounted) return;

      final available = response['available'] as bool? ?? false;
      setState(() {
        _pincodeValid = available;
        _pincodeError = available
            ? null
            : 'Delivery not available in this area';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pincodeValid = false;
        _pincodeError = 'Could not verify delivery area';
      });
    }
  }

  bool get _canSubmit {
    if (_deliveryMethod == 'delivery') {
      return _addressController.text.isNotEmpty &&
          _pincodeValid &&
          _phoneController.text.length >= 10;
    }
    return _phoneController.text.length >= 10;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final items = widget.entries
          .map(
            (e) => {
              'product_id': e.product.id,
              'quantity': e.quantity,
              'price': e.product.price,
            },
          )
          .toList();

      final data = {
        'business_id': widget.business.id,
        'items': items,
        'delivery_method': _deliveryMethod,
        'phone': _phoneController.text.trim(),
      };

      if (_deliveryMethod == 'delivery') {
        data['address'] = _addressController.text.trim();
        data['pincode'] = _pincodeController.text.trim();
      }

      final response = await api.post(
        '/businesses/${widget.business.slug}/orders',
        body: data,
      );
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(orderData: response),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInWidget(child: _buildDeliveryMethodSelector(theme)),
                    const SizedBox(height: AppSpacing.lg),
                    if (_deliveryMethod == 'delivery') ...[
                      SlideInWidget(child: _buildDeliveryFields(theme)),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    FadeInWidget(
                      delay: const Duration(milliseconds: 150),
                      child: _buildPhoneField(theme),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: _buildOrderSummary(theme),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeInWidget(
                      delay: const Duration(milliseconds: 250),
                      child: _buildCODNotice(theme),
                    ),
                  ],
                ),
              ),
            ),
            _buildPlaceOrderButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildDeliveryOption(
                theme,
                'pickup',
                Icons.store,
                'Pickup',
                'Collect from store',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDeliveryOption(
                theme,
                'delivery',
                Icons.delivery_dining,
                'Delivery',
                'Delivered to you',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryOption(
    ThemeData theme,
    String value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final isSelected = _deliveryMethod == value;
    return RippleEffect(
      onTap: () => setState(() => _deliveryMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutline : AppColors.outline),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _addressController,
          label: 'Full Address',
          hint: 'House no, street, landmark',
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _pincodeController,
          label: 'Pincode',
          hint: '6-digit pincode',
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: _checkPincode,
          errorText: _pincodeError,
        ),
        if (_pincodeValid) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text('Delivery available', style: TextStyle(color: Colors.green)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _phoneController,
          label: 'Phone',
          hint: 'For order updates',
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.length < 10) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.product.name} × ${entry.quantity}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '₹${((entry.product.price ?? 0) * entry.quantity).toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            _buildSummaryRow(
              theme,
              'Total',
              '₹${widget.total.toStringAsFixed(0)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCODNotice(ThemeData theme) {
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.money, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay business directly',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cash on ${_deliveryMethod == 'pickup' ? 'pickup' : 'delivery'}. No online payment needed.',
                  style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildPlaceOrderButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          child: RippleEffect(
            onTap: _canSubmit && !_isSubmitting ? _placeOrder : null,
            child: AppButton(
              onPressed: _canSubmit && !_isSubmitting ? _placeOrder : null,
              label: _isSubmitting ? 'Placing Order...' : 'Place Order',
              leadingIcon: _isSubmitting ? null : Icons.check,
            ),
          ),
        ),
      ),
    );
  }
}
