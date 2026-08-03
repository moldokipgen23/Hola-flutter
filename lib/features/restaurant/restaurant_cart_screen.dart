import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'restaurant_checkout_screen.dart';

class RestaurantCartEntry {
  final Product product;
  final int quantity;
  final String? notes;

  RestaurantCartEntry({
    required this.product,
    required this.quantity,
    this.notes,
  });

  double get totalPrice => (product.price ?? 0) * quantity;
}

class RestaurantCartScreen extends StatefulWidget {
  final List<RestaurantCartEntry> entries;
  final String businessSlug;
  final String orderType;

  const RestaurantCartScreen({
    super.key,
    required this.entries,
    required this.businessSlug,
    required this.orderType,
  });

  @override
  State<RestaurantCartScreen> createState() => _RestaurantCartScreenState();
}

class _RestaurantCartScreenState extends State<RestaurantCartScreen> {
  late List<RestaurantCartEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.entries);
  }

  double get _subtotal => _entries.fold(0, (sum, e) => sum + e.totalPrice);

  double get _deliveryFee => widget.orderType == 'delivery' ? 40.0 : 0.0;

  double get _total => _subtotal + _deliveryFee;

  int get _totalItems => _entries.fold(0, (sum, e) => sum + e.quantity);

  void _updateQuantity(int index, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _entries.removeAt(index);
      } else {
        final old = _entries[index];
        _entries[index] = RestaurantCartEntry(
          product: old.product,
          quantity: newQty,
          notes: old.notes,
        );
      }
    });

    if (_entries.isEmpty) {
      Navigator.pop(context, true);
    }
  }

  void _removeItem(int index) {
    setState(() => _entries.removeAt(index));
    if (_entries.isEmpty) {
      Navigator.pop(context, true);
    }
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantCheckoutScreen(
          businessSlug: widget.businessSlug,
          entries: _entries,
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          total: _total,
          orderType: widget.orderType,
        ),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
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
          'Your Order ($_totalItems items)',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _entries.clear());
                Navigator.pop(context, true);
              },
              child: Text(
                'Clear All',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: _entries.isEmpty
          ? _buildEmptyState(isDark)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) => _buildCartItem(isDark, index),
                  ),
                ),
                _buildOrderSummary(isDark),
              ],
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_rounded,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your cart is empty',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add items from the menu to get started',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(bool isDark, int index) {
    final entry = _entries[index];
    final product = entry.product;
    final imageUrl = product.image != null
        ? ApiClient.imageUrl(product.image!)
        : '';

    return SlideInWidget(
      delay: Duration(milliseconds: 60 * index),
      beginOffset: const Offset(0.3, 0),
      child: AppCard(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildImagePlaceholder(isDark),
                  ),
                ),
              )
            else
              _buildImagePlaceholder(isDark),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                        onPressed: () => _removeItem(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.notes!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        product.displayPrice,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.experienceRestaurant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      AppQuantitySelector(
                        value: entry.quantity,
                        min: 1,
                        max: 99,
                        color: AppColors.experienceRestaurant,
                        onChanged: (v) => _updateQuantity(index, v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        size: 28,
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSummaryRow(
              isDark,
              label: 'Subtotal ($_totalItems items)',
              value: '₹${_subtotal.toStringAsFixed(0)}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildSummaryRow(
              isDark,
              label: widget.orderType == 'delivery' ? 'Delivery fee' : 'Pickup',
              value: widget.orderType == 'delivery'
                  ? '₹${_deliveryFee.toStringAsFixed(0)}'
                  : 'Free',
              valueColor: widget.orderType == 'pickup'
                  ? AppColors.success
                  : null,
            ),
            const Divider(height: AppSpacing.md),
            _buildSummaryRow(
              isDark,
              label: 'Total',
              value: '₹${_total.toStringAsFixed(0)}',
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Pay restaurant directly — Cash/COD',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RippleEffect(
              onTap: _proceedToCheckout,
              child: AppButton(
                label: 'Proceed to Checkout',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _proceedToCheckout,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    bool isDark, {
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
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
                      color:
                          valueColor ??
                          (isBold
                              ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary)
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary)),
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    ),
          ),
        ],
      ),
    );
  }
}
