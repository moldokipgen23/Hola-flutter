import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import '../../widgets/safe_image.dart';
import 'room_selection_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String slug;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;
  final int rooms;

  const PropertyDetailScreen({
    super.key,
    required this.slug,
    this.checkIn,
    this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Map<String, dynamic>? _property;
  bool _isLoading = true;
  String? _error;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      final response = await api.get('/businesses/${widget.slug}');
      if (!mounted) return;
      setState(() {
        _property = response as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.experienceStay),
        ),
      );
    }

    if (_error != null || _property == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _error ?? 'Property not found',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Try Again', onPressed: _loadProperty),
            ],
          ),
        ),
      );
    }

    final photos = _property!['photos'] as List<dynamic>? ?? [];
    final amenities = _property!['amenities'] as List<dynamic>? ?? [];
    final roomTypes = _property!['room_types'] as List<dynamic>? ?? [];
    final policies = _property!['policies'] as Map<String, dynamic>?;
    final description = _property!['description'] as String?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildPhotoGallery(photos, isDark),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInWidget(child: _buildPropertyInfo(isDark)),
                if (amenities.isNotEmpty)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildAmenitiesGrid(amenities, isDark),
                  ),
                if (description != null && description.isNotEmpty)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildDescription(description, isDark),
                  ),
                if (policies != null)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 250),
                    child: _buildPolicies(policies, isDark),
                  ),
                if (roomTypes.isNotEmpty)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _buildRoomTypes(roomTypes, isDark),
                  ),
                FadeInWidget(
                  delay: const Duration(milliseconds: 350),
                  child: _buildMapPreview(isDark),
                ),
                FadeInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: _buildContactSection(isDark),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildCheckRoomsButton(isDark),
    );
  }

  Widget _buildPhotoGallery(List<dynamic> photos, bool isDark) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              itemCount: photos.isEmpty ? 1 : photos.length,
              onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
              itemBuilder: (context, index) {
                if (photos.isEmpty) {
                  return Container(
                    color: AppColors.experienceStay.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(
                        Icons.hotel_rounded,
                        size: 64,
                        color: AppColors.experienceStay,
                      ),
                    ),
                  );
                }
                return SafeImage(
                  path: photos[index].toString(),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                );
              },
            ),
            if (photos.length > 1)
              Positioned(
                bottom: AppSpacing.md,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    return Container(
                      width: i == _currentPhotoIndex ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == _currentPhotoIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(bool isDark) {
    final name = _property!['name'] as String? ?? 'Unknown Property';
    final rating = _property!['average_rating'] != null
        ? (_property!['average_rating'] as num).toDouble()
        : 0.0;
    final reviewCount = _property!['review_count'] as int? ?? 0;
    final address = _property!['address'] as String?;
    final distance = _property!['distance']?.toString();
    final priceRange = _property!['price_range'] as int?;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (rating > 0) ...[
                Icon(Icons.star_rounded, size: 18, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviewCount reviews)',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (distance != null) ...[
                Icon(
                  Icons.near_me_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  distance,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (priceRange != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Price: ${'₹' * priceRange}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.experienceStay,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenitiesGrid(List<dynamic> amenities, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2,
            ),
            itemCount: amenities.length,
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              final name = amenity['name'] as String? ?? amenity.toString();
              final icon = _getAmenityIcon(name);

              return SlideInWidget(
                beginOffset: const Offset(0, 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: AppColors.experienceStay),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('pool')) return Icons.pool_rounded;
    if (lower.contains('ac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('restaurant') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('spa')) return Icons.spa_rounded;
    if (lower.contains('tv')) return Icons.tv_rounded;
    if (lower.contains('room service')) return Icons.room_service_rounded;
    if (lower.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (lower.contains('bar')) return Icons.local_bar_rounded;
    if (lower.contains('garden')) return Icons.park_rounded;
    if (lower.contains('security')) return Icons.security_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildDescription(String description, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this property',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicies(Map<String, dynamic> policies, bool isDark) {
    final checkIn = policies['check_in_time'] as String? ?? '2:00 PM';
    final checkOut = policies['check_out_time'] as String? ?? '12:00 PM';
    final cancellation = policies['cancellation'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Policies',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PolicyRow(
            icon: Icons.login_rounded,
            label: 'Check-in',
            value: checkIn,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PolicyRow(
            icon: Icons.logout_rounded,
            label: 'Check-out',
            value: checkOut,
          ),
          if (cancellation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _PolicyRow(
              icon: Icons.cancel_outlined,
              label: 'Cancellation',
              value: cancellation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomTypes(List<dynamic> roomTypes, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Types',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...roomTypes.map((room) {
            final name = room['name'] as String? ?? 'Room';
            final price = room['price'] as num? ?? 0;
            final capacity = room['capacity'] as int? ?? 2;
            final bedType = room['bed_type'] as String? ?? '';

            return SlideInWidget(
              beginOffset: const Offset(0.2, 0),
              child: AppCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$capacity guests${bedType.isNotEmpty ? ' · $bedType' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${price.toInt()}',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.experienceStay,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/ night',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapPreview(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 32,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'View on map',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    final phone = _property!['phone'] as String?;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (phone != null)
            Expanded(
              child: AppButton(
                label: 'Call Property',
                onPressed: () {},
                leadingIcon: Icons.call_outlined,
                type: AppButtonType.outline,
              ),
            ),
          if (phone != null) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: 'Directions',
              onPressed: () {},
              leadingIcon: Icons.directions_outlined,
              type: AppButtonType.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRoomsButton(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        label: 'Check Rooms',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomSelectionScreen(
                businessId: _property!['id'] as int,
                businessName: _property!['name'] as String? ?? '',
                roomTypes: _property!['room_types'] as List<dynamic>? ?? [],
                checkIn: widget.checkIn,
                checkOut: widget.checkOut,
                adults: widget.adults,
                children: widget.children,
                rooms: widget.rooms,
              ),
            ),
          );
        },
        isFullWidth: true,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PolicyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.experienceStay),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
