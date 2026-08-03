import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'checkout_screen.dart';

class CartEntry {
  final Product product;
  final int quantity;

  CartEntry({required this.product, required this.quantity});
}

class CartScreen extends StatefulWidget {
  final List<CartEntry> entries;
  final Function(List<CartEntry>)? onCartUpdated;

  const CartScreen({super.key, required this.entries, this.onCartUpdated});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.entries);
  }

  void _incrementItem(int index) {
    setState(() {
      final entry = _entries[index];
      _entries[index] = CartEntry(
        product: entry.product,
        quantity: entry.quantity + 1,
      );
    });
    _notifyCartUpdated();
  }

  void _decrementItem(int index) {
    setState(() {
      final entry = _entries[index];
      if (entry.quantity > 1) {
        _entries[index] = CartEntry(
          product: entry.product,
          quantity: entry.quantity - 1,
        );
      } else {
        _entries.removeAt(index);
      }
    });
    _notifyCartUpdated();
  }

  void _removeItem(int index) {
    setState(() => _entries.removeAt(index));
    _notifyCartUpdated();
  }

  void _notifyCartUpdated() {
    widget.onCartUpdated?.call(_entries);
  }

  double get _subtotal {
    return _entries.fold(
      0.0,
      (sum, e) => sum + ((e.product.price ?? 0) * e.quantity),
    );
  }

  double get _deliveryFee {
    return _subtotal >= 500 ? 0 : 40;
  }

  double get _total => _subtotal + _deliveryFee;

  Business? get _business =>
      _entries.isNotEmpty ? _entries.first.product.business : null;

  void _proceedToCheckout() {
    if (_entries.isEmpty || _business == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          business: _business!,
          entries: _entries,
          total: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _entries.clear());
                _notifyCartUpdated();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: _entries.isEmpty
          ? _buildEmptyState(theme)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(index, theme);
                    },
                  ),
                ),
                _buildOrderSummary(theme),
              ],
            ),
      bottomNavigationBar: _entries.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: RippleEffect(
                  onTap: _proceedToCheckout,
                  child: AppButton(
                    onPressed: _proceedToCheckout,
                    label: 'Proceed to Checkout',
                    isFullWidth: true,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCartItem(int index, ThemeData theme) {
    final entry = _entries[index];
    final product = entry.product;
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return SlideInWidget(
      delay: Duration(milliseconds: 60 * index),
      beginOffset: const Offset(0.3, 0),
      child: Dismissible(
        key: ValueKey('${product.id}_${entry.quantity}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _removeItem(index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: product.image != null
                      ? Image.network(
                          ApiClient.imageUrl(product.image!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 60,
                            height: 60,
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                            child: const Icon(Icons.image_outlined),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant,
                          child: const Icon(Icons.image_outlined),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.displayPrice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQuantityControls(index, entry, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(int index, CartEntry entry, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircleButton(
          icon: entry.quantity > 1 ? Icons.remove : Icons.delete_outline,
          onTap: () => _decrementItem(index),
          color: entry.quantity > 1 ? AppColors.textSecondary : AppColors.error,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              '${entry.quantity}',
              key: ValueKey(entry.quantity),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildCircleButton(
          icon: Icons.add,
          onTap: () => _incrementItem(index),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return RippleEffect(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            theme,
            'Subtotal',
            '₹${_subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'Delivery Fee',
            _deliveryFee == 0 ? 'Free' : '₹${_deliveryFee.toStringAsFixed(0)}',
            subtitle: _deliveryFee == 0 ? 'Orders above ₹500' : null,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            theme,
            'Total',
            '₹${_total.toStringAsFixed(0)}',
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pay business directly - Cash on pickup/delivery',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    String? subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Your cart is empty', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add items from a store to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              onPressed: () => Navigator.pop(context),
              label: 'Browse Stores',
            ),
          ],
        ),
      ),
    );
  }
}
