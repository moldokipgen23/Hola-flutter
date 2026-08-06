import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'photo_gallery_screen.dart';
import '../activity/review_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String slug;
  const BusinessDetailScreen({super.key, required this.slug});
  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with SingleTickerProviderStateMixin {
  Business? business;
  List<Review> reviews = [];
  Map<String, dynamic>? reviewStats;
  bool loading = true;
  String? error;
  int _currentPhoto = 0;
  late TabController _tabController;
  final PageController _photoController = PageController();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBusiness();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await api.get('/businesses/${widget.slug}');
      if (!mounted) return;
      final biz = Business.fromJson(res['business']);
      setState(() {
        business = biz;
        _isSaved = biz.isSaved ?? false;
        loading = false;
      });
      _loadReviews(biz.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call() async {
    if (business?.phone != null) {
      _launchUrl('tel:${business!.phone}');
    }
  }

  Future<void> _whatsapp() async {
    if (business?.whatsapp != null) {
      _launchUrl('https://wa.me/${business!.whatsapp}');
    }
  }

  Future<void> _directions() async {
    if (business?.lat != null && business?.lng != null) {
      _launchUrl(
        'https://www.google.com/maps/dir/?api=1&destination=${business!.lat},${business!.lng}',
      );
    }
  }

  void _share() {
    Share.share(
      'Check out ${business?.name} on Eiho One!\nhttps://hola.ehlom.com/business/${business?.slug}',
    );
  }

  void _navigateToBook() {
    if (business == null) return;
    if (business!.hasBookingsModule || business!.hasTurfModule) {
      Navigator.pushNamed(
        context,
        '/appointment/services',
        arguments: {'slug': business!.slug, 'businessId': business!.id},
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookings not available')));
    }
  }

  void _showWriteReview() {
    if (business == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(business: business!)),
    );
  }

  Future<void> _toggleSave() async {
    if (business == null) return;
    try {
      final result = await api.post(
        '/saved/toggle',
        body: {'business_id': business!.id},
      );
      setState(() => _isSaved = result['saved'] ?? false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login to save')));
      }
    }
  }

  Color _getExperienceColor(String? experience) {
    switch (experience) {
      case 'restaurant':
        return AppColors.experienceRestaurant;
      case 'retail':
        return AppColors.experienceRetail;
      case 'appointment':
        return AppColors.experienceAppointment;
      case 'stay':
        return AppColors.experienceStay;
      case 'turf':
        return AppColors.experienceTurf;
      case 'taxi':
        return AppColors.experienceTaxi;
      case 'shared_transport':
        return AppColors.experienceSharedTransport;
      case 'vehicle_rental':
        return AppColors.experienceVehicleRental;
      case 'goods_transport':
        return AppColors.experienceGoodsTransport;
      case 'seat_event':
        return AppColors.experienceSeatEvent;
      default:
        return AppColors.primary;
    }
  }

  IconData _getExperienceIcon(String? experience) {
    switch (experience) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'retail':
        return Icons.shopping_bag_rounded;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'stay':
        return Icons.hotel_rounded;
      case 'turf':
        return Icons.sports_soccer_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'shared_transport':
        return Icons.directions_bus_rounded;
      case 'vehicle_rental':
        return Icons.directions_car_rounded;
      case 'goods_transport':
        return Icons.local_shipping_rounded;
      case 'seat_event':
        return Icons.event_seat_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: loading
          ? _buildLoadingSkeleton(isDark)
          : error != null
              ? _buildErrorState(isDark)
              : business == null
                  ? _buildNotFoundState(isDark)
                  : Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              _buildSliverAppBar(isDark),
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeaderInfo(isDark),
                                    _buildActionGrid(isDark),
                                    if (business!.hasAnyBookingModule) ...[
                                      _buildOfferBanner(isDark),
                                    ],
                                    _buildTabSection(isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (business!.hasAnyBookingModule)
                          _buildStickyBookBar(isDark),
                      ],
                    ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Shimmer(
            child: Container(
              height: 280,
              width: double.infinity,
              color: isDark ? AppColors.darkSurface : AppColors.surface,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonCircle(size: 48),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(
                            width: double.infinity,
                            height: 20,
                            borderRadius: AppRadius.xs,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SkeletonBox(
                            width: 120,
                            height: 14,
                            borderRadius: AppRadius.xs,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    SkeletonBox(
                      width: 80,
                      height: 14,
                      borderRadius: AppRadius.xs,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SkeletonBox(
                      width: 140,
                      height: 14,
                      borderRadius: AppRadius.xs,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: SkeletonBox(height: 40, borderRadius: AppRadius.sm),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonBox(height: 40, borderRadius: AppRadius.sm),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonBox(height: 40, borderRadius: AppRadius.sm),
                ),
              ],
            ),
          ),
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: SkeletonBox(
                      width: 60,
                      height: 14,
                      borderRadius: AppRadius.xs,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error ?? 'Unknown error',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              onPressed: _loadBusiness,
              leadingIcon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Business not found',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleSave,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppColors.gold : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (business!.photos.isNotEmpty)
              Hero(
                tag: 'business_image_${business!.id}',
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoGalleryScreen(
                        photos: business!.photos,
                        initialIndex: _currentPhoto,
                        businessName: business!.name,
                      ),
                    ),
                  ),
                  child: PageView.builder(
                    controller: _photoController,
                    itemCount: business!.photos.length,
                    onPageChanged: (i) => setState(() => _currentPhoto = i),
                    itemBuilder: (context, index) {
                      final url = ApiClient.imageUrl(business!.photos[index]);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, s) => Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                _getExperienceIcon(business?.category?.slug),
                                color: AppColors.primary,
                                size: 64,
                              ),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black45,
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    _getExperienceIcon(business?.category?.slug),
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
              ),
            if (business!.photos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    business!.photos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentPhoto ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentPhoto
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  business!.name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (business!.averageRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 3),
                      Text(
                        business!.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${business!.reviewCount})',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (business!.category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getExperienceColor(business!.category!.slug).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    business!.category!.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _getExperienceColor(business!.category!.slug),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (business!.locality != null)
                Text(
                  business!.locality!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
          if (business!.address != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    business!.address!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ],
          if (business!.distance != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  business!.distance!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
      ),
      child: Row(
        children: [
          if (business!.phone != null)
            _buildActionTile(
              Icons.call_rounded,
              'Call',
              AppColors.success,
              _call,
            ),
          if (business!.phone != null) const SizedBox(width: 10),
          if (business!.whatsapp != null)
            _buildActionTile(
              Icons.chat_rounded,
              'WhatsApp',
              const Color(0xFF25D366),
              _whatsapp,
            ),
          if (business!.whatsapp != null) const SizedBox(width: 10),
          if (business!.lat != null)
            _buildActionTile(
              Icons.directions_outlined,
              'Directions',
              AppColors.primary,
              _directions,
            ),
          if (business!.lat != null) const SizedBox(width: 10),
          _buildActionTile(
            Icons.share_outlined,
            'Share',
            Colors.grey[600]!,
            _share,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🏷', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'New user first-booking discount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1a1421),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBookBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: GestureDetector(
        onTap: _navigateToBook,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'Book now',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1a1421),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
      ),
      child: Column(
        children: [
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: AppColors.line,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Services'),
                Tab(text: 'Reviews'),
                Tab(text: 'Photos'),
              ],
            ),
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDark),
                _buildServicesTab(isDark),
                _buildReviewsTab(isDark),
                _buildPhotosTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (business!.description != null &&
              business!.description!.isNotEmpty)
            _buildSection('About', isDark, [
              Text(
                business!.description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ]),
          if (business!.workingHours != null)
            _buildSection('Working Hours', isDark, [
              ...business!.workingHours!.entries.map((e) {
                final isToday = DateTime.now().weekday == _dayToInt(e.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _capitalize(e.key),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isToday
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        e.value.toString(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isToday
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]),
          if (business!.phone != null || business!.email != null)
            _buildSection('Contact', isDark, [
              if (business!.phone != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        business!.phone!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (business!.email != null)
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      business!.email!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ]),
        ],
      ),
    );
  }

  Widget _buildServicesTab(bool isDark) {
    final products = business!.topProducts;
    final services = business!.topServices;

    if (products.isEmpty && services.isEmpty) {
      return _buildEmptyState(
        'No services available',
        'This business hasn\'t added any services yet.',
        Icons.work_outline_rounded,
        isDark,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (services.isNotEmpty) ...[
          Text(
            'Services',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...services.map(
            (service) => AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.work_outline_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  service.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  service.price > 0
                      ? '₹${service.price.toStringAsFixed(0)}'
                      : 'Price on request',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (products.isNotEmpty) ...[
          if (services.isNotEmpty) const SizedBox(height: AppSpacing.md),
          Text(
            'Products',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...products.map(
            (product) => AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: product.image != null
                        ? Image.network(
                            ApiClient.imageUrl(product.image),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, s) => Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.shopping_bag_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                title: Text(
                  product.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  product.displayPrice,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    return Column(
      children: [
        if (reviewStats != null)
          FadeInWidget(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    '${reviewStats!['average'] ?? 0}',
                    style: AppTypography.headlineLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (reviewStats!['average'] as num? ?? 0).round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                        ),
                      ),
                      Text(
                        '${reviewStats!['count'] ?? 0} reviews',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Write Review',
                    onPressed: _showWriteReview,
                    type: AppButtonType.outline,
                    size: AppButtonSize.sm,
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: reviews.isEmpty
              ? _buildEmptyState(
                  'No reviews yet',
                  'Be the first to review this business.',
                  Icons.rate_review_outlined,
                  isDark,
                )
              : StaggeredAnimationList(
                  children: reviews.map((rv) {
                    return _buildReviewCard(rv, isDark);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review, bool isDark) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _timeAgo(review.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppColors.warning,
                size: 16,
              ),
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
          if (review.ownerResponse != null &&
              review.ownerResponse!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner Response',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    review.ownerResponse!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosTab(bool isDark) {
    if (business!.photos.isEmpty) {
      return _buildEmptyState(
        'No photos available',
        'This business hasn\'t added any photos yet.',
        Icons.photo_library_outlined,
        isDark,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: business!.photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoGalleryScreen(
                photos: business!.photos,
                initialIndex: index,
                businessName: business!.name,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              ApiClient.imageUrl(business!.photos[index]),
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, bool isDark, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _dayToInt(String day) {
    const days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
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
