import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/safe_image.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/animations.dart';
import '../../features/shared/business_detail_screen.dart';

class CategoryBusinessesScreen extends StatefulWidget {
  final Category category;

  const CategoryBusinessesScreen({super.key, required this.category});

  @override
  State<CategoryBusinessesScreen> createState() =>
      _CategoryBusinessesScreenState();
}

class _CategoryBusinessesScreenState extends State<CategoryBusinessesScreen> {
  List<Business> businesses = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final result = await api.get(
        '/categories/${widget.category.slug}/businesses',
      );
      final businessesData = result['businesses'];
      final businessesList = businessesData is Map
          ? businessesData['data']
          : businessesData;
      setState(() {
        businesses = (businessesList as List)
            .map((b) => Business.fromJson(b))
            .toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Failed to load businesses.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryIcons.getColor(widget.category.name);
    final catIcon = CategoryIcons.getIcon(widget.category.name);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(catIcon, color: catColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              widget.category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(error!, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadBusinesses,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : businesses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    catIcon,
                    size: 64,
                    color: catColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No businesses found',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBusinesses,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: businesses.length,
                itemBuilder: (context, index) =>
                    _buildCard(businesses[index], index),
              ),
            ),
    );
  }

  Widget _buildCard(Business business, int index) {
    final catColor = CategoryIcons.getColor(business.category?.name);
    return FadeInSlide(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 60),
      child: ScaleOnTap(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(slug: business.slug),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: business.photos.isNotEmpty
                      ? SafeImage(
                          path: business.photos.first,
                          width: 80,
                          height: 80,
                        )
                      : Container(
                          color: catColor.withValues(alpha: 0.08),
                          child: Icon(
                            CategoryIcons.getIcon(business.category?.name),
                            color: catColor,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (business.address != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                business.address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (business.averageRating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${business.averageRating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (business.distance != null)
                            Text(
                              '${business.distance} away',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
