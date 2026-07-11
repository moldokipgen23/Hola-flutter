import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/safe_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'report_screen.dart';
import 'review_screen.dart';

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
      final res = await api.get('/businesses/${widget.slug}');
      if (!mounted) return;
      final biz = Business.fromJson(res['business']);
      setState(() { business = biz; loading = false; });
      try { api.post('/businesses/${widget.slug}/track', body: {'action': 'view'}); } catch (_) {}
      _loadReviews(biz.id);
      _loadRelated();
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadRelated() async {
    try {
      final res = await api.get('/businesses/${widget.slug}/related');
      if (!mounted) return;
      final raw = res is Map ? (res['related'] is List ? res['related'] : <dynamic>[]) : <dynamic>[];
      setState(() { related = (raw as List).map((b) => Business.fromJson(b)).toList(); });
    } catch (_) {}
  }

  Future<void> _loadReviews(int businessId) async {
    try {
      final result = await api.get('/businesses/$businessId/reviews');
      if (mounted) {
        setState(() {
          reviewStats = result['stats'];
          reviews = (result['reviews']?['data'] as List? ?? []).map((rv) => Review.fromJson(rv)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _call() async {
    if (business?.phone != null) {
      final uri = Uri.parse('tel:${business!.phone}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      try { api.post('/businesses/${widget.slug}/track', body: {'action': 'call'}); } catch (_) {}
    }
  }

  Future<void> _whatsapp() async {
    if (business?.whatsapp != null) {
      final uri = Uri.parse('https://wa.me/${business!.whatsapp}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      try { api.post('/businesses/${widget.slug}/track', body: {'action': 'whatsapp'}); } catch (_) {}
    }
  }

  Future<void> _directions() async {
    if (business?.lat != null && business?.lng != null) {
      final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${business!.lat},${business!.lng}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      try { api.post('/businesses/${widget.slug}/track', body: {'action': 'directions'}); } catch (_) {}
    }
  }

  void _share() {
    Share.share('Check out ${business?.name} on Hola!\nhttps://hola.ehlom.com/business/${business?.slug}');
    try { api.post('/businesses/${widget.slug}/track', body: {'action': 'share'}); } catch (_) {}
  }

  Future<void> _toggleSave() async {
    if (business == null) return;
    try {
      final result = await api.post('/saved/toggle', body: {'business_id': business!.id});
      setState(() {
        business = Business(
          id: business!.id, name: business!.name, slug: business!.slug,
          description: business!.description, address: business!.address,
          locality: business!.locality, district: business!.district,
          lat: business!.lat, lng: business!.lng, phone: business!.phone,
          whatsapp: business!.whatsapp, email: business!.email, website: business!.website,
          photos: business!.photos, workingHours: business!.workingHours,
          isActive: business!.isActive, isFeatured: business!.isFeatured,
          viewsCount: business!.viewsCount, savesCount: business!.savesCount,
          qualityScore: business!.qualityScore, averageRating: business!.averageRating,
          reviewCount: business!.reviewCount, category: business!.category,
          claimStatus: business!.claimStatus, distance: business!.distance,
          isSaved: result['saved'],
        );
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to save')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : business == null
              ? const Center(child: Text('Business not found'))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Photo Header
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      backgroundColor: AppTheme.primary,
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      actions: [
                        GestureDetector(
                          onTap: _toggleSave,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                              business!.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
                              color: business!.isSaved == true ? Colors.amber : Colors.white,
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (business!.photos.isNotEmpty)
                              SafeImage(path: business!.photos.first, width: double.infinity, height: 280)
                            else
                              Container(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                child: Center(child: Text(business!.category?.icon ?? '🏪', style: const TextStyle(fontSize: 80))),
                              ),
                            // Gradient overlay
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black45]),
                              ),
                            ),
                            // Photo count
                            if (business!.photos.length > 1)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                  child: Text('${business!.photos.length} photos', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(business!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (business!.category != null) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(business!.category!.name, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              if (business!.locality != null)
                                                Text(business!.locality!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (business!.averageRating > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded, size: 18, color: AppTheme.success),
                                            const SizedBox(width: 4),
                                            Text('${business!.averageRating}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.success)),
                                            const SizedBox(width: 2),
                                            Text('(${business!.reviewCount})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (business!.address != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(business!.address!, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
                                    ],
                                  ),
                                ],
                                // Open/Closed
                                if (business!.workingHours != null) ...[
                                  const SizedBox(height: 8),
                                  _buildOpenStatus(),
                                ],
                              ],
                            ),
                          ),

                          // Action Buttons
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border))),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    if (business!.phone != null)
                                      _buildActionBtn('Call Now', Icons.call_rounded, AppTheme.primary, _call),
                                    if (business!.whatsapp != null)
                                      _buildActionBtn('WhatsApp', Icons.chat_rounded, AppTheme.success, _whatsapp),
                                    if (business!.lat != null)
                                      _buildActionBtn('Directions', Icons.directions_rounded, AppTheme.textPrimary, _directions),
                                    _buildShareBtn(),
                                  ],
                                ),
                                if (business!.website != null) ...[
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(business!.website!);
                                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.language_rounded, size: 18, color: Colors.grey[600]),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              business!.website!,
                                              style: TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Description
                          if (business!.description != null && business!.description!.isNotEmpty)
                            _buildSection('About', [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(business!.description!, style: TextStyle(color: Colors.grey[600], height: 1.6, fontSize: 14)),
                              ),
                            ]),

                          // Working Hours
                          if (business!.workingHours != null)
                            _buildSection('Working Hours', business!.workingHours!.entries.map((e) {
                              final isToday = DateTime.now().weekday == _dayToInt(e.key);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_capitalize(e.key), style: TextStyle(color: isToday ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isToday ? FontWeight.w600 : FontWeight.normal)),
                                    Text(e.value.toString(), style: TextStyle(color: isToday ? AppTheme.primary : AppTheme.textPrimary, fontWeight: isToday ? FontWeight.w600 : FontWeight.normal)),
                                  ],
                                ),
                              );
                            }).toList()),

                          // Reviews
                          if (reviewStats != null)
                            _buildSection('Reviews', [
                              Row(
                                children: [
                                  Text('${reviewStats!['average']}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) => Icon(
                                          i < (reviewStats!['average'] as num).round() ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: AppTheme.warning, size: 18,
                                        )),
                                      ),
                                      Text('${reviewStats!['count']} reviews', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(business: business!))),
                                    child: const Text('Write Review'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...reviews.take(3).map((rv) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                          child: Text(rv.userName.isNotEmpty ? rv.userName[0] : '?', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(rv.userName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                                        Text(_timeAgo(rv.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(children: List.generate(5, (i) => Icon(
                                      i < rv.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: AppTheme.warning, size: 14,
                                    ))),
                                    if (rv.comment.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(rv.comment, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ],
                                ),
                              )),
                              if (reviews.length > 3)
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(business: business!))),
                                  child: Text('View all ${reviewStats!['count']} reviews'),
                                ),
                            ]),

                          // Similar Businesses
                          if (related.isNotEmpty)
                            _buildSection('Similar Businesses', [
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: related.length,
                                  itemBuilder: (context, index) {
                                    final r = related[index];
                                    return GestureDetector(
                                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(slug: r.slug))),
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.border),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                                child: r.photos.isNotEmpty
                                                    ? SafeImage(path: r.photos.first, width: double.infinity)
                                                    : Container(color: AppTheme.primary.withValues(alpha: 0.06), child: Center(child: Text(r.category?.icon ?? '🏪', style: const TextStyle(fontSize: 28)))),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(r.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ]),

                          // Report
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(business: business!))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flag_outlined, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text('Report an issue', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOpenStatus() {
    final now = DateTime.now();
    final dayName = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][now.weekday - 1];
    final todayHours = business!.workingHours?[dayName];
    if (todayHours == null) return const SizedBox.shrink();
    // Simple check
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('Open', style: TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareBtn() {
    return GestureDetector(
      onTap: _share,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
        child: const Column(
          children: [
            Icon(Icons.share_rounded, color: AppTheme.textSecondary, size: 22),
            SizedBox(height: 4),
            Text('Share', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  int _dayToInt(String day) {
    const days = {'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7};
    return days[day.toLowerCase()] ?? 1;
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}
