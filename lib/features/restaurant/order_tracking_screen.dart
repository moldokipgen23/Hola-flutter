import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../models/models.dart';
import '../../services/api.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String? orderNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.orderNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadOrder(),
    );
  }

  Future<void> _loadOrder() async {
    try {
      final res = await api.get('/orders/${widget.orderId}');
      if (!mounted) return;
      final orderData = res['order'] ?? res;
      setState(() {
        _order = Order.fromJson(orderData);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await api.post('/orders/${widget.orderId}/cancel');
      if (mounted) {
        _loadOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    _pollTimer?.cancel();
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
          'Order #${widget.orderNumber ?? widget.orderId}',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingSkeleton(isDark)
          : _error != null
          ? _buildErrorState(isDark)
          : _order == null
          ? _buildEmptyState(isDark)
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                SlideInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: _buildStatusBanner(isDark),
                ),
                const SizedBox(height: AppSpacing.lg),
                SlideInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: _buildTimeline(isDark),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_order!.estimatedReadyAt != null)
                  SlideInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _buildEstimatedTime(isDark),
                  ),
                if (_order!.estimatedReadyAt != null)
                  const SizedBox(height: AppSpacing.md),
                SlideInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: _buildOrderItems(isDark),
                ),
                const SizedBox(height: AppSpacing.md),
                SlideInWidget(
                  delay: const Duration(milliseconds: 500),
                  child: _buildVendorContact(isDark),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_order!.isPending)
                  SlideInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: _buildCancelButton(isDark),
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.md),
        SkeletonBox(
          width: double.infinity,
          height: 80,
          borderRadius: AppRadius.md,
        ),
        const SizedBox(height: AppSpacing.lg),
        SkeletonBox(
          width: double.infinity,
          height: 200,
          borderRadius: AppRadius.md,
        ),
        const SizedBox(height: AppSpacing.lg),
        SkeletonBox(
          width: double.infinity,
          height: 120,
          borderRadius: AppRadius.md,
        ),
        const SizedBox(height: AppSpacing.md),
        SkeletonBox(
          width: double.infinity,
          height: 160,
          borderRadius: AppRadius.md,
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load order',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              onPressed: _loadOrder,
              type: AppButtonType.outline,
              trailingIcon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Order not found',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isDark) {
    final order = _order!;
    return AppCard(
      backgroundColor: order.statusColor.withValues(alpha: 0.1),
      borderColor: order.statusColor.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: order.statusColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.displayStatus,
                  style: AppTypography.titleMedium.copyWith(
                    color: order.statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusDescription(order.status),
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

  Widget _buildTimeline(bool isDark) {
    final order = _order!;
    final steps = [
      _TimelineStep(
        label: 'Order Placed',
        icon: Icons.receipt_long_rounded,
        isCompleted: true,
      ),
      _TimelineStep(
        label: 'Accepted',
        icon: Icons.check_circle_outline_rounded,
        isCompleted:
            order.isConfirmed ||
            order.isPreparing ||
            order.isReady ||
            order.isOutForDelivery ||
            order.isDelivered,
        isCurrent: order.isConfirmed,
      ),
      _TimelineStep(
        label: 'Preparing',
        icon: Icons.restaurant_rounded,
        isCompleted:
            order.isPreparing ||
            order.isReady ||
            order.isOutForDelivery ||
            order.isDelivered,
        isCurrent: order.isPreparing,
      ),
      _TimelineStep(
        label: order.deliveryMethod == 'pickup'
            ? 'Ready for Pickup'
            : 'Out for Delivery',
        icon: order.deliveryMethod == 'pickup'
            ? Icons.store_rounded
            : Icons.delivery_dining_rounded,
        isCompleted:
            order.isReady || order.isOutForDelivery || order.isDelivered,
        isCurrent: order.isReady || order.isOutForDelivery,
      ),
      _TimelineStep(
        label: 'Completed',
        icon: Icons.done_all_rounded,
        isCompleted: order.isDelivered,
        isCurrent: false,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            return SlideInWidget(
              delay: Duration(milliseconds: 80 * index),
              child: _buildTimelineStep(isDark, step, isLast),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(bool isDark, _TimelineStep step, bool isLast) {
    final activeColor = AppColors.experienceRestaurant;
    final inactiveColor = isDark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: step.isCurrent
                    ? activeColor
                    : step.isCompleted
                    ? activeColor.withValues(alpha: 0.15)
                    : (isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant),
                shape: BoxShape.circle,
                border: step.isCompleted || step.isCurrent
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.darkOutline
                            : AppColors.outline,
                      ),
              ),
              child: Icon(
                step.icon,
                size: 16,
                color: step.isCurrent
                    ? Colors.white
                    : step.isCompleted
                    ? activeColor
                    : inactiveColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: step.isCompleted
                    ? activeColor.withValues(alpha: 0.3)
                    : (isDark ? AppColors.darkOutline : AppColors.outline),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              step.label,
              style: AppTypography.bodyMedium.copyWith(
                color: step.isCurrent
                    ? activeColor
                    : step.isCompleted
                    ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary)
                    : (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary),
                fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTime(bool isDark) {
    final order = _order!;
    final estimated = order.estimatedReadyAt!;
    final now = DateTime.now();
    final remaining = estimated.difference(now);
    final minutes = remaining.inMinutes;

    return AppCard(
      backgroundColor: AppColors.warning.withValues(alpha: 0.08),
      borderColor: AppColors.warning.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Ready Time',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  minutes > 0
                      ? 'About $minutes minutes remaining'
                      : 'Should be ready soon',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(bool isDark) {
    final order = _order!;
    if (order.items.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.experienceRestaurant.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
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
                      item.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
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
            label: 'Total',
            value: '₹${order.total.toStringAsFixed(0)}',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? AppTypography.titleSmall : AppTypography.bodyMedium)
              .copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: (isBold ? AppTypography.titleMedium : AppTypography.bodyMedium)
              .copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildVendorContact(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Restaurant',
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
                  onPressed: () {},
                  type: AppButtonType.outline,
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'WhatsApp',
                  leadingIcon: Icons.chat_rounded,
                  onPressed: () {},
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

  Widget _buildCancelButton(bool isDark) {
    return AppButton(
      label: 'Cancel Order',
      type: AppButtonType.destructive,
      leadingIcon: Icons.cancel_outlined,
      onPressed: _cancelOrder,
      isFullWidth: true,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.receipt_long_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'preparing':
        return Icons.restaurant_rounded;
      case 'ready':
        return Icons.store_rounded;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Your order has been placed and is awaiting confirmation.';
      case 'confirmed':
        return 'Restaurant has accepted your order.';
      case 'preparing':
        return 'Your order is being prepared now.';
      case 'ready':
        return 'Your order is ready for pickup.';
      case 'out_for_delivery':
        return 'Your order is on its way to you.';
      case 'delivered':
        return 'Your order has been delivered. Enjoy your meal!';
      case 'cancelled':
        return 'This order has been cancelled.';
      default:
        return '';
    }
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  _TimelineStep({
    required this.label,
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}
