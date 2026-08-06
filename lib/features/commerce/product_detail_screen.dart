import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Business business;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.business,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<Product> _relatedProducts = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final response = await api.get(
        '/products',
        queryParams: {'business_id': widget.business.id.toString()},
      );
      if (!mounted) return;

      final data = response is Map
          ? response['products'] ?? response['data'] ?? response
          : response;
      final products = (data as List)
          .map((p) => Product.fromJson(p))
          .where((p) => p.id != widget.product.id)
          .take(6)
          .toList();

      setState(() {
        _relatedProducts = products;
        _isLoadingRelated = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRelated = false);
    }
  }

  void _addToCart() {
    Navigator.pop(
      context,
      CartEntry(product: widget.product, quantity: _quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(isDark),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildStockStatus(theme),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 150),
                    child: _buildProductInfo(theme),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildQuantitySelector(theme),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 250),
                    child: _buildAddToCartButton(),
                  ),
                  if (widget.product.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SlideInWidget(
                      delay: const Duration(milliseconds: 300),
                      child: _buildDescription(theme),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 350),
                    child: _buildRelatedProducts(theme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(bool isDark) {
    return ScaleInWidget(
      child: Container(
        width: double.infinity,
        height: 300,
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        child: widget.product.image != null
            ? Image.network(
                ApiClient.imageUrl(widget.product.image!),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 64),
                ),
              )
            : const Center(child: Icon(Icons.image_outlined, size: 64)),
      ),
    );
  }

  Widget _buildStockStatus(ThemeData theme) {
    final inStock = widget.product.isInStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: inStock
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: inStock ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            inStock ? 'In Stock' : 'Out of Stock',
            style: theme.textTheme.bodySmall?.copyWith(
              color: inStock ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.product.displayPrice,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(ThemeData theme) {
    return Row(
      children: [
        Text('Quantity', style: theme.textTheme.titleMedium),
        const Spacer(),
        AppQuantitySelector(
          value: _quantity,
          onChanged: (value) {
            setState(() => _quantity = value);
          },
          min: 1,
          max: widget.product.stock ?? 99,
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    final price = widget.product.price ?? 0;
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        onPressed: widget.product.isInStock ? _addToCart : null,
        label: widget.product.isInStock
            ? 'Add to Cart · ₹${(price * _quantity).toStringAsFixed(0)}'
            : 'Out of Stock',
        leadingIcon: Icons.add_shopping_cart,
      ),
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.product.description!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProducts(ThemeData theme) {
    if (_isLoadingRelated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Products',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _relatedProducts.length,
            itemBuilder: (context, index) {
              final product = _relatedProducts[index];
              return _buildRelatedProductCard(product, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(Product product, ThemeData theme) {
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              business: widget.business,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: product.image != null
                    ? Image.network(
                        ApiClient.imageUrl(product.image!),
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant,
                          child: const Icon(Icons.image_outlined),
                        ),
                      )
                    : Container(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        child: const Icon(Icons.image_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.name,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product.displayPrice,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
