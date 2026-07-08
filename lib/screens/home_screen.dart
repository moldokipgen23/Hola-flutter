import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import 'business_detail_screen.dart';
import 'category_businesses_screen.dart';
import 'search_screen.dart';
import 'map_screen.dart';
import 'product_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];
  List<Business> featured = [];
  List<Business> trending = [];
  List<Business> newlyAdded = [];
  List<Product> popularProducts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        api.get('/categories'),
        api.get('/businesses/featured'),
        api.get('/businesses/trending'),
        api.get('/businesses/new'),
        api.get('/products/popular'),
      ]);

      if (mounted) {
        setState(() {
          categories = (results[0]['categories'] as List).map((c) => Category.fromJson(c)).toList();
          featured = (results[1]['businesses'] as List).map((b) => Business.fromJson(b)).toList();
          trending = (results[2]['businesses'] as List).map((b) => Business.fromJson(b)).toList();
          newlyAdded = (results[3]['businesses'] as List).map((b) => Business.fromJson(b)).toList();
          popularProducts = (results[4]['products'] as List).map((p) => Product.fromJson(p)).toList();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    title: const Text('Hola', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: widget.onSearchTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: widget.onSearchTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 12),
                              Text('Search businesses...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map, color: AppTheme.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('Map View', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('Products', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CategoryBusinessesScreen(category: cat),
                            )),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(cat.icon ?? '🏪', style: const TextStyle(fontSize: 28)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (featured.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text('Featured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildBusinessCard(featured[index]),
                        childCount: featured.length,
                      ),
                    ),
                  ],
                  if (trending.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text('Trending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildBusinessCard(trending[index]),
                        childCount: trending.length,
                      ),
                    ),
                  ],
                  if (newlyAdded.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text('Newly Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildBusinessCard(newlyAdded[index]),
                        childCount: newlyAdded.length,
                      ),
                    ),
                  ],
                  if (popularProducts.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text('Popular Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: popularProducts.length,
                          itemBuilder: (context, index) {
                            final product = popularProducts[index];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: product.image != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(product.image!, fit: BoxFit.cover),
                                          )
                                        : const Center(child: Text('📦', style: TextStyle(fontSize: 28))),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontSize: 11),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(slug: business.slug),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: business.photos.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(business.photos.first, fit: BoxFit.cover),
                    )
                  : const Center(child: Text('🏪', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    business.category?.name ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (business.isFeatured) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                      ],
                      if (business.distance != null) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(business.distance!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text('${business.viewsCount}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
