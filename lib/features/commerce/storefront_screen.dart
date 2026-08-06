import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class StorefrontScreen extends StatefulWidget {
  final String slug;

  const StorefrontScreen({super.key, required this.slug});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Business? _business;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<CartEntry> _cartEntries = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final businessResponse = await api.get('/businesses/${widget.slug}');
      final business = Business.fromJson(businessResponse);
      final productsResponse = await api.get(
        '/products',
        queryParams: {'business_id': business.id.toString()},
      );

      if (!mounted) return;

      final productsData = productsResponse is Map
          ? productsResponse['products'] ?? productsResponse['data'] ?? []
          : productsResponse;
      final products = (productsData as List)
          .map((p) => Product.fromJson(p))
          .toList();

      setState(() {
        _business = business;
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch =
            query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            (product.description?.toLowerCase().contains(query) ?? false);
        final matchesCategory =
            _selectedCategory == 'All' ||
            product.menuSection == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  List<String> get _categories {
    final cats = _products
        .map((p) => p.menuSection)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    return ['All', ...cats];
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartEntries.indexWhere(
        (e) => e.product.id == product.id,
      );
      if (existingIndex >= 0) {
        final existing = _cartEntries[existingIndex];
        _cartEntries[existingIndex] = CartEntry(
          product: existing.product,
          quantity: existing.quantity + 1,
        );
      } else {
        _cartEntries.add(CartEntry(product: product, quantity: 1));
      }
    });
  }

  int _cartItemCount() {
    return _cartEntries.fold(0, (sum, e) => sum + e.quantity);
  }

  double _cartTotal() {
    return _cartEntries.fold(
      0.0,
      (sum, e) => sum + ((e.product.price ?? 0) * e.quantity),
    );
  }

  void _openCart() {
    if (_cartEntries.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          entries: _cartEntries,
          onCartUpdated: (entries) {
            setState(() => _cartEntries = entries);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _error != null
          ? _buildErrorState(theme)
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(theme, isDark),
                SliverToBoxAdapter(child: _buildBusinessHeader(theme, isDark)),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildCategoriesScroll()),
                if (_filteredProducts.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(theme))
                else
                  _buildProductGrid(theme),
              ],
            ),
      floatingActionButton: _cartItemCount() > 0 ? _buildCartFAB(theme) : null,
    );
  }

  Widget _buildLoadingSkeleton() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Shimmer(child: SkeletonBox(height: 200)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ProductCardSkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark) {
    final coverPhoto = _business?.photos.isNotEmpty == true
        ? _business!.photos.first
        : null;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: coverPhoto != null
            ? Image.network(
                coverPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                ),
              )
            : Container(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
              ),
      ),
      actions: [
        if (_cartItemCount() > 0)
          IconButton(
            icon: Badge(
              label: Text('${_cartItemCount()}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: _openCart,
          ),
      ],
    );
  }

  Widget _buildBusinessHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _business?.name ?? '',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_business != null && _business!.averageRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _business!.averageRating.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_business?.distance != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_business!.distance} away',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AppSearchField(
        controller: _searchController,
        hint: 'Search products...',
        onChanged: (_) => _filterProducts(),
        onClear: _filterProducts,
      ),
    );
  }

  Widget _buildCategoriesScroll() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = category);
                _filterProducts();
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = _filteredProducts[index];
          return SlideInWidget(
            delay: Duration(milliseconds: 60 * index),
            beginOffset: const Offset(0, 0.2),
            child: _buildProductCard(product, theme),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme) {
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return RippleEffect(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(product: product, business: _business!),
          ),
        );
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: product.image != null
                    ? Image.network(
                        ApiClient.imageUrl(product.image!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      )
                    : Container(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        child: const Center(child: Icon(Icons.image_outlined)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.displayPrice,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: product.isInStock
                            ? () => _addToCart(product)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: product.isInStock
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildCartFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _openCart,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.shopping_cart),
      label: Text(
        '${_cartItemCount()} items · ₹${_cartTotal().toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
              Icons.shopping_bag_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No products found', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Something went wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(onPressed: _loadData, label: 'Retry'),
          ],
        ),
      ),
    );
  }
}
