import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/animations.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderConfirmationScreen({super.key, required this.orderData});

  String get _orderId => (orderData['id'] ?? '').toString();
  String get _deliveryMethod => orderData['delivery_method'] ?? 'pickup';
  String get _estimatedTime => orderData['estimated_time'] ?? '30-45 minutes';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(),
                const SuccessCheckmark(size: 100, color: Colors.green),
                const SizedBox(height: AppSpacing.lg),
                SlideInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: _buildOrderNumber(theme),
                ),
                const SizedBox(height: AppSpacing.md),
                SlideInWidget(
                  delay: const Duration(milliseconds: 550),
                  child: _buildEstimatedTime(theme),
                ),
                const SizedBox(height: AppSpacing.md),
                SlideInWidget(
                  delay: const Duration(milliseconds: 700),
                  child: _buildVendorNotice(theme),
                ),
                const SizedBox(height: AppSpacing.md),
                SlideInWidget(
                  delay: const Duration(milliseconds: 850),
                  child: _buildPaymentNotice(theme),
                ),
                const Spacer(),
                SlideInWidget(
                  delay: const Duration(milliseconds: 1000),
                  child: _buildActionButtons(context, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderNumber(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Order Placed!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Order #$_orderId',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTime(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _deliveryMethod == 'pickup' ? Icons.store : Icons.delivery_dining,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Estimated $_deliveryMethod time: $_estimatedTime',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorNotice(ThemeData theme) {
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Awaiting vendor confirmation',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The business will confirm your order shortly. You\'ll be notified once accepted.',
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

  Widget _buildPaymentNotice(ThemeData theme) {
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
            child: Text(
              'Pay business directly - Cash on ${_deliveryMethod == 'pickup' ? 'pickup' : 'delivery'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            label: 'Back to Home',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('View in Activity'),
          ),
        ),
      ],
    );
  }
}
