import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'dish_detail_screen.dart';
import 'restaurant_cart_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String slug;

  const RestaurantMenuScreen({super.key, required this.slug});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  Business? _business;
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _orderType = 'delivery';
  final Map<int, int> _cart = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  List<String> _sections = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final businessRes = await api.get('/businesses/${widget.slug}');
      final productsRes = await api.get('/businesses/${widget.slug}/products');

      if (!mounted) return;

      final business = Business.fromJson(
        businessRes['business'] ?? businessRes,
      );
      final rawProducts = productsRes['products'];
      final productData = rawProducts is Map<String, dynamic>
          ? rawProducts['data']
          : rawProducts;
      final products =
          (productData as List?)?.map((p) => Product.fromJson(p)).toList() ??
          [];

      final sectionSet = <String>{};
      for (final p in products) {
        sectionSet.add(p.menuSection ?? 'Menu');
      }

      setState(() {
        _business = business;
        _products = products;
        _sections = sectionSet.toList();
        for (final s in _sections) {
          _sectionKeys[s] = GlobalKey();
        }
        _loading = false;
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

  List<Product> get _filteredProducts {
    var list = _products;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return list;
  }

  Map<String, List<Product>> get _groupedProducts {
    final map = <String, List<Product>>{};
    for (final p in _filteredProducts) {
      final section = p.menuSection ?? 'Menu';
      map.putIfAbsent(section, () => []).add(p);
    }
    return map;
  }

  double get _cartTotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final p = _products.firstWhere(
        (x) => x.id == id,
        orElse: () => Product(id: id, name: '', slug: ''),
      );
      total += (p.price ?? 0) * qty;
    });
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _addToCart(Product product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _navigateToCart() {
    final entries = _cart.entries.map((e) {
      final product = _products.firstWhere(
        (x) => x.id == e.key,
        orElse: () => Product(id: e.key, name: '', slug: ''),
      );
      return RestaurantCartEntry(product: product, quantity: e.value);
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantCartScreen(
          entries: entries,
          businessSlug: widget.slug,
          orderType: _orderType,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _clearCart();
      }
    });
  }

  void _scrollToSection(String section) {
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openDishDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DishDetailScreen(product: product, businessSlug: widget.slug),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final grouped = _groupedProducts;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: _loading
          ? _buildLoadingState(isDark)
          : _error != null
          ? _buildErrorState(isDark)
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(isDark),
                if (!_isSearching && _searchQuery.isEmpty)
                  _buildOrderTypeToggle(isDark),
                if (!_isSearching && _searchQuery.isEmpty)
                  _buildSectionNav(isDark, grouped),
                if (_filteredProducts.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ...grouped.entries.map(
                    (entry) =>
                        _buildMenuSection(isDark, entry.key, entry.value),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      bottomSheet: _cartCount > 0 ? _buildCartBar(isDark) : null,
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: 100),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: const ProductCardSkeleton(),
            );
          }),
        ],
      ),
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
              'Failed to load menu',
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
              onPressed: _loadData,
              type: AppButtonType.outline,
              trailingIcon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No items match your search'
                  : 'No menu items available',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: _isSearching
          ? AppSearchField(
              controller: _searchController,
              hint: 'Search menu items...',
              onChanged: (v) => setState(() => _searchQuery = v),
              onClear: () => setState(() {
                _searchQuery = '';
                _isSearching = false;
              }),
            )
          : Text(
              _business?.name ?? 'Menu',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
      actions: [
        if (!_isSearching)
          AppIconButton(
            icon: Icons.search_rounded,
            onPressed: () => setState(() => _isSearching = true),
          ),
        if (_cartCount > 0 && !_isSearching)
          AppIconButton(
            icon: Icons.shopping_cart_rounded,
            onPressed: _navigateToCart,
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildOrderTypeToggle(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            _buildOrderTypeChip(
              'Delivery',
              Icons.delivery_dining_rounded,
              isDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildOrderTypeChip('Pickup', Icons.store_rounded, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeChip(String label, IconData icon, bool isDark) {
    final selected = (_orderType == label.toLowerCase());
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _orderType = label.toLowerCase()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.experienceRestaurant
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionNav(bool isDark, Map<String, List<Product>> grouped) {
    if (grouped.length <= 1) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        height: 44,
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: AppSpacing.screenPadding,
          itemCount: _sections.length,
          separatorBuilder: (a, b) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, index) {
            final section = _sections[index];
            return GestureDetector(
              onTap: () => _scrollToSection(section),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isDark ? AppColors.darkOutline : AppColors.outline,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    section,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuSection(bool isDark, String section, List<Product> items) {
    return SliverToBoxAdapter(
      key: _sectionKeys[section],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              section,
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          ...items.asMap().entries.map(
            (entry) => SlideInWidget(
              delay: Duration(milliseconds: 60 * entry.key),
              child: _buildProductTile(isDark, entry.value),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildProductTile(bool isDark, Product product) {
    final qty = _cart[product.id] ?? 0;
    final isSoldOut = product.soldOutUntil != null;
    final imageUrl = product.image != null
        ? ApiClient.imageUrl(product.image!)
        : '';

    return RippleEffect(
      onTap: isSoldOut ? null : () => _openDishDetail(product),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
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
                          style: AppTypography.titleSmall.copyWith(
                            color: isSoldOut
                                ? (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textTertiary)
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        product.displayPrice,
                        style: AppTypography.titleMedium.copyWith(
                          color: isSoldOut
                              ? (isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary)
                              : AppColors.experienceRestaurant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.preparationMinutes != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.preparationMinutes} min',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isSoldOut) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Sold out',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildImagePlaceholder(isDark),
                      ),
                    ),
                  )
                else
                  _buildImagePlaceholder(isDark),
                if (!isSoldOut) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (qty > 0)
                    AppQuantitySelector(
                      value: qty,
                      min: 0,
                      max: 99,
                      color: AppColors.experienceRestaurant,
                      onChanged: (v) {
                        setState(() {
                          if (v == 0) {
                            _cart.remove(product.id);
                          } else {
                            _cart[product.id] = v;
                          }
                        });
                      },
                    )
                  else
                    AppButton(
                      label: 'Add',
                      size: AppButtonSize.sm,
                      trailingIcon: Icons.add_rounded,
                      onPressed: () => _addToCart(product),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        size: 32,
      ),
    );
  }

  Widget _buildCartBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(
              alpha: 0.08,
            ),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.experienceRestaurant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$_cartCount items',
                style: AppTypography.labelSmall.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '₹${_cartTotal.toStringAsFixed(0)}',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            AppButton(
              label: 'View Cart',
              trailingIcon: Icons.shopping_cart_rounded,
              onPressed: _navigateToCart,
            ),
          ],
        ),
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
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? AppColors.success : AppColors.error,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
