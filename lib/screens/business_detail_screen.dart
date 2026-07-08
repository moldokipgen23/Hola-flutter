import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'report_screen.dart';
import 'review_screen.dart';
import 'chat_screen.dart';
import 'payment_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String slug;

  const BusinessDetailScreen({super.key, required this.slug});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  Business? business;
  List<Business> related = [];
  List<Review> reviews = [];
  Map<String, dynamic>? reviewStats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final results = await Future.wait([
        api.get('/businesses/${widget.slug}'),
        api.get('/businesses/${widget.slug}/related'),
      ]);

      if (mounted) {
        final biz = Business.fromJson(results[0]['business']);
        setState(() {
          business = biz;
          related = (results[1]['related'] as List).map((b) => Business.fromJson(b)).toList();
          loading = false;
        });

        api.post('/businesses/${widget.slug}/track', body: {'action': 'view'});

        _loadReviews(biz.id);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadReviews(int businessId) async {
    try {
      final result = await api.get('/businesses/$businessId/reviews');
      if (mounted) {
        setState(() {
          reviewStats = result['stats'];
          reviews = (result['reviews']?['data'] as List? ?? [])
              .map((rv) => Review.fromJson(rv))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _call() async {
    if (business?.phone != null) {
      launchUrl(Uri.parse('tel:${business!.phone}'));
      api.post('/businesses/${widget.slug}/track', body: {'action': 'call'});
    }
  }

  Future<void> _whatsapp() async {
    if (business?.whatsapp != null) {
      launchUrl(Uri.parse('https://wa.me/${business!.whatsapp}'));
      api.post('/businesses/${widget.slug}/track', body: {'action': 'whatsapp'});
    }
  }

  Future<void> _directions() async {
    if (business?.lat != null && business?.lng != null) {
      launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${business!.lat},${business!.lng}'));
      api.post('/businesses/${widget.slug}/track', body: {'action': 'directions'});
    }
  }

  void _share() {
    Share.share('Check out ${business?.name} on Hola!\nhttps://hola.app/business/${business?.slug}');
    api.post('/businesses/${widget.slug}/track', body: {'action': 'share'});
  }

  Future<void> _toggleSave() async {
    try {
      final result = await api.post('/saved/toggle', body: {'business_id': business!.id});
      setState(() {
          business = Business(
          id: business!.id,
          name: business!.name,
          slug: business!.slug,
          description: business!.description,
          address: business!.address,
          locality: business!.locality,
          district: business!.district,
          lat: business!.lat,
          lng: business!.lng,
          phone: business!.phone,
          whatsapp: business!.whatsapp,
          email: business!.email,
          website: business!.website,
          photos: business!.photos,
          workingHours: business!.workingHours,
          isActive: business!.isActive,
          isFeatured: business!.isFeatured,
          viewsCount: business!.viewsCount,
          savesCount: business!.savesCount,
          qualityScore: business!.qualityScore,
          averageRating: business!.averageRating,
          reviewCount: business!.reviewCount,
          category: business!.category,
          claimStatus: business!.claimStatus,
          distance: business!.distance,
          isSaved: result['saved'],
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to save businesses')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : business == null
              ? const Center(child: Text('Business not found'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      actions: [
                        IconButton(
                          icon: Icon(
                            business!.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
                            color: business!.isSaved == true ? AppTheme.primary : null,
                          ),
                          onPressed: _toggleSave,
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: business!.photos.isNotEmpty
                            ? Image.network(business!.photos.first, fit: BoxFit.cover)
                            : Container(
                                color: AppTheme.primary.withOpacity(0.1),
                                child: const Center(child: Text('🏪', style: TextStyle(fontSize: 80))),
                              ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(business!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(business!.category?.name ?? '', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                if (business!.isFeatured)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 16, color: Colors.amber),
                                        SizedBox(width: 4),
                                        Text('Featured', style: TextStyle(fontSize: 12, color: Colors.amber)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (business!.address != null)
                              _buildInfoRow(Icons.location_on, business!.address!),
                            if (business!.phone != null)
                              _buildInfoRow(Icons.phone, business!.phone!),
                            if (business!.email != null)
                              _buildInfoRow(Icons.email, business!.email!),
                            const SizedBox(height: 20),
                            if (business!.description != null && business!.description!.isNotEmpty) ...[
                              const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(business!.description!, style: TextStyle(color: Colors.grey[600], height: 1.5)),
                              const SizedBox(height: 20),
                            ],
                            if (business!.workingHours != null) ...[
                              const Text('Working Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...business!.workingHours!.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: TextStyle(color: Colors.grey[600])),
                                    Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 20),
                            ],
                            // ─── Reviews Section ───
                            if (reviewStats != null) ...[
                              const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${reviewStats!['average']}',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) => Icon(
                                          i < (reviewStats!['average'] as num).round()
                                              ? Icons.star : Icons.star_border,
                                          color: Colors.amber, size: 18,
                                        )),
                                      ),
                                      Text('${reviewStats!['count']} reviews', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                    ],
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ReviewScreen(business: business!),
                                    )),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Write'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...reviews.take(3).map((rv) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            child: Text(rv.userName.isNotEmpty ? rv.userName[0] : '?', style: const TextStyle(fontSize: 12)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(rv.userName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                          Row(
                                            children: List.generate(5, (i) => Icon(
                                              i < rv.rating ? Icons.star : Icons.star_border,
                                              color: Colors.amber, size: 14,
                                            )),
                                          ),
                                        ],
                                      ),
                                      if (rv.comment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(rv.comment, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ],
                                  ),
                                ),
                              )),
                              if (reviews.length > 3)
                                TextButton(
                                  onPressed: () {},
                                  child: Text('View all ${reviewStats!['count']} reviews'),
                                ),
                              const SizedBox(height: 16),
                            ],

                            const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (business!.phone != null)
                                  _buildActionButton(Icons.call, 'Call', AppTheme.primary, _call),
                                if (business!.whatsapp != null)
                                  _buildActionButton(Icons.chat, 'WhatsApp', AppTheme.success, _whatsapp),
                                if (business!.lat != null)
                                  _buildActionButton(Icons.directions, 'Directions', Colors.blue, _directions),
                                _buildActionButton(Icons.chat_bubble, 'Message', AppTheme.secondary, () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatScreen(business: business!),
                                  ));
                                }),
                                _buildActionButton(Icons.share, 'Share', Colors.grey, _share),
                              ],
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const PaymentScreen(),
                              )),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 6),
                                  Text('Promote this business', style: TextStyle(fontSize: 13, color: Colors.amber[700])),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ReportScreen(business: business!),
                              )),
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 16, color: Colors.grey[500]),
                                  const SizedBox(width: 6),
                                  Text('Report an issue', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            if (related.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text('Similar Businesses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: related.length,
                                  itemBuilder: (context, index) {
                                    final r = related[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(context, MaterialPageRoute(
                                          builder: (_) => BusinessDetailScreen(slug: r.slug),
                                        ));
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🏪', style: TextStyle(fontSize: 24)),
                                            const SizedBox(height: 4),
                                            Text(r.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[600]))),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
