import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/safe_image.dart';
import 'business_detail_screen.dart';

class CategoryBusinessesScreen extends StatefulWidget {
  final Category category;

  const CategoryBusinessesScreen({super.key, required this.category});

  @override
  State<CategoryBusinessesScreen> createState() => _CategoryBusinessesScreenState();
}

class _CategoryBusinessesScreenState extends State<CategoryBusinessesScreen> {
  List<Business> businesses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final result = await api.get('/categories/${widget.category.slug}/businesses');
      final businessesData = result['businesses'];
      final businessesList = businessesData is Map ? businessesData['data'] : businessesData;
      setState(() {
        businesses = (businessesList as List).map((b) => Business.fromJson(b)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : businesses.isEmpty
              ? const Center(child: Text('No businesses in this category'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) => _buildCard(businesses[index]),
                ),
    );
  }

  Widget _buildCard(Business business) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(slug: business.slug),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
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
            child: SafeImage(path: business.photos.isNotEmpty ? business.photos.first : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(business.address ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 4),
                  if (business.distance != null)
                    Text('${business.distance} away', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
