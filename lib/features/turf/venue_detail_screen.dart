import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';
import '../../widgets/safe_image.dart';
import 'slot_selection_screen.dart';

class VenueDetailScreen extends StatefulWidget {
  final String slug;

  const VenueDetailScreen({super.key, required this.slug});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  Map<String, dynamic>? _venue;
  bool _isLoading = true;
  String? _error;
  int _selectedCourtIndex = 0;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVenue();
  }

  Future<void> _loadVenue() async {
    try {
      final response = await api.get('/businesses/${widget.slug}');
      if (!mounted) return;
      setState(() {
        _venue = response as Map<String, dynamic>;
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
          child: CircularProgressIndicator(color: AppColors.experienceTurf),
        ),
      );
    }

    if (_error != null || _venue == null) {
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
                _error ?? 'Venue not found',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Try Again', onPressed: _loadVenue),
            ],
          ),
        ),
      );
    }

    final photos = _venue!['photos'] as List<dynamic>? ?? [];
    final courts = _venue!['courts'] as List<dynamic>? ?? [];
    final amenities = _venue!['amenities'] as List<dynamic>? ?? [];
    final gallery = _venue!['gallery'] as List<dynamic>? ?? photos;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildPhotoGallery(photos, isDark),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInWidget(child: _buildVenueInfo(isDark)),
                if (courts.isNotEmpty)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildCourtSelector(courts, isDark),
                  ),
                if (amenities.isNotEmpty)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildAmenities(amenities, isDark),
                  ),
                FadeInWidget(
                  delay: const Duration(milliseconds: 300),
                  child: _buildMapPreview(isDark),
                ),
                if (gallery.length > 1)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 350),
                    child: _buildPhotoGallerySection(gallery, isDark),
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
      bottomSheet: _buildCheckAvailabilityButton(isDark),
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
                    color: AppColors.experienceTurf.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        size: 64,
                        color: AppColors.experienceTurf,
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

  Widget _buildVenueInfo(bool isDark) {
    final name = _venue!['name'] as String? ?? 'Unknown Venue';
    final rating = _venue!['average_rating'] != null
        ? (_venue!['average_rating'] as num).toDouble()
        : 0.0;
    final reviewCount = _venue!['review_count'] as int? ?? 0;
    final address = _venue!['address'] as String?;
    final distance = _venue!['distance']?.toString();
    final priceRange = _venue!['price_range'] as int?;

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
                color: AppColors.experienceTurf,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourtSelector(List<dynamic> courts, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Court / Field',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: courts.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final court = courts[index];
                final courtName =
                    court['name'] as String? ?? 'Court ${index + 1}';
                final courtType = court['type'] as String? ?? '';
                final isSelected = _selectedCourtIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCourtIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.experienceTurf.withValues(alpha: 0.1)
                          : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.experienceTurf
                            : (isDark
                                  ? AppColors.darkOutline
                                  : AppColors.outline),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer_rounded,
                          size: 24,
                          color: isSelected
                              ? AppColors.experienceTurf
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          courtName,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.experienceTurf
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (courtType.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            courtType,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(List<dynamic> amenities, bool isDark) {
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: amenities.map((amenity) {
              final name = amenity['name'] as String? ?? amenity.toString();
              final icon = _getAmenityIcon(name);
              return SlideInWidget(
                beginOffset: const Offset(0, 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: AppColors.experienceTurf),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('light') || lower.contains('floodlight')) {
      return Icons.light_mode_rounded;
    }
    if (lower.contains('chang') || lower.contains('shower')) {
      return Icons.shower_rounded;
    }
    if (lower.contains('water') || lower.contains('drinking')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('seating') || lower.contains('spectator')) {
      return Icons.event_seat_rounded;
    }
    if (lower.contains('score') || lower.contains('board')) {
      return Icons.scoreboard_rounded;
    }
    if (lower.contains('equip')) return Icons.sports_baseball_rounded;
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('cctv') || lower.contains('security')) {
      return Icons.security_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildMapPreview(bool isDark) {
    final lat = _venue!['latitude'] ?? _venue!['lat'];

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
                    lat != null ? 'View on map' : 'Location not available',
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

  Widget _buildPhotoGallerySection(List<dynamic> gallery, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Gallery',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gallery.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SafeImage(
                    path: gallery[index].toString(),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    final phone = _venue!['phone'] as String?;
    final whatsapp = _venue!['whatsapp'] as String?;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (phone != null)
            Expanded(
              child: AppButton(
                label: 'Call',
                onPressed: () {},
                leadingIcon: Icons.call_outlined,
                type: AppButtonType.outline,
              ),
            ),
          if (phone != null && whatsapp != null)
            const SizedBox(width: AppSpacing.sm),
          if (whatsapp != null)
            Expanded(
              child: AppButton(
                label: 'WhatsApp',
                onPressed: () {},
                leadingIcon: Icons.chat_outlined,
                type: AppButtonType.outline,
              ),
            ),
          if (phone != null || whatsapp != null)
            const SizedBox(width: AppSpacing.sm),
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

  Widget _buildCheckAvailabilityButton(bool isDark) {
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
        label: 'Check Availability',
        onPressed: () {
          final businessId = _venue!['id'] as int?;
          final courts = _venue!['courts'] as List<dynamic>? ?? [];
          final courtId = courts.isNotEmpty
              ? courts[_selectedCourtIndex]['id']?.toString()
              : null;
          if (businessId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SlotSelectionScreen(
                  businessId: businessId,
                  courtId: courtId,
                ),
              ),
            );
          }
        },
        isFullWidth: true,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    );
  }
}
