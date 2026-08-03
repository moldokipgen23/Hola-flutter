import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../models/models.dart';
import '../../services/api.dart';

class DishDetailScreen extends StatefulWidget {
  final Product product;
  final String businessSlug;

  const DishDetailScreen({
    super.key,
    required this.product,
    required this.businessSlug,
  });

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  bool get _isSoldOut => widget.product.soldOutUntil != null;
  double get _totalPrice => (widget.product.price ?? 0) * _quantity;

  void _addToCart() {
    Navigator.pop(context, {
      'product': widget.product,
      'quantity': _quantity,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final product = widget.product;
    final imageUrl = product.image != null
        ? ApiClient.imageUrl(product.image!)
        : '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildImageHeader(isDark, imageUrl),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 100),
                          child: _buildTitleSection(isDark),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 150),
                          child: _buildDetailsRow(isDark),
                        ),
                        if (product.description != null &&
                            product.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          SlideInWidget(
                            delay: const Duration(milliseconds: 200),
                            child: _buildDescription(isDark),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 250),
                          child: _buildQuantitySection(isDark),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SlideInWidget(
                          delay: const Duration(milliseconds: 300),
                          child: _buildNotesSection(isDark),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isSoldOut) _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildImageHeader(bool isDark, String imageUrl) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.surface)
                .withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.isNotEmpty
            ? ScaleInWidget(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholder(isDark),
                    ),
                    if (_isSoldOut)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                              'SOLD OUT',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      child: Icon(
        Icons.restaurant_rounded,
        size: 64,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    final product = widget.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (product.foodType != null) ...[
              _FoodTypeBadge(foodType: product.foodType!),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                product.name,
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          product.displayPrice,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.experienceRestaurant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(bool isDark) {
    final product = widget.product;
    return Row(
      children: [
        if (product.preparationMinutes != null) ...[
          _DetailChip(
            icon: Icons.timer_outlined,
            label: '${product.preparationMinutes} min prep',
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (product.foodType != null)
          _DetailChip(
            icon: product.foodType == 'veg' ? Icons.circle : Icons.circle,
            label: product.foodType == 'veg' ? 'Vegetarian' : 'Non-Vegetarian',
            isDark: isDark,
            iconColor: product.foodType == 'veg'
                ? AppColors.success
                : AppColors.error,
          ),
      ],
    );
  }

  Widget _buildDescription(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.product.description!,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection(bool isDark) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        AppQuantitySelector(
          value: _quantity,
          min: 1,
          max: 20,
          color: AppColors.experienceRestaurant,
          onChanged: (v) => setState(() => _quantity = v),
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Instructions',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _notesController,
          hint: 'e.g., extra spicy, no onions, allergies...',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          label: 'Add to Cart — ₹${_totalPrice.toStringAsFixed(0)}',
          trailingIcon: Icons.shopping_cart_rounded,
          onPressed: _addToCart,
          isFullWidth: true,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? iconColor;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                iconColor ??
                (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTypeBadge extends StatelessWidget {
  final String foodType;

  const _FoodTypeBadge({required this.foodType});

  @override
  Widget build(BuildContext context) {
    final isVeg = foodType == 'veg';
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? AppColors.success : AppColors.error,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
