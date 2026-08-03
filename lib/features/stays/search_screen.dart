import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../widgets/safe_image.dart';
import 'property_detail_screen.dart';

class StaySearchScreen extends StatefulWidget {
  const StaySearchScreen({super.key});

  @override
  State<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends State<StaySearchScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;
  String _sortBy = 'recommended';
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _properties = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _loadProperties();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
      _loadProperties();
    });
  }

  Future<void> _loadProperties() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, String>{
        'experience': 'stay',
        'page': _currentPage.toString(),
        'per_page': '20',
        'sort': _sortBy,
      };
      if (_destinationController.text.isNotEmpty) {
        queryParams['q'] = _destinationController.text.trim();
      }
      if (_checkInDate != null) {
        queryParams['check_in'] = _formatDate(_checkInDate!);
      }
      if (_checkOutDate != null) {
        queryParams['check_out'] = _formatDate(_checkOutDate!);
      }
      queryParams['adults'] = _adults.toString();
      queryParams['children'] = _children.toString();
      queryParams['rooms'] = _rooms.toString();

      final response = await api.get('/businesses', queryParams: queryParams);
      final paginated = response['businesses'] as Map<String, dynamic>;
      final data = (paginated['data'] as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        if (_currentPage == 1) _properties.clear();
        _properties.addAll(data);
        _currentPage++;
        _hasMore = _currentPage <= (paginated['last_page'] as int? ?? 1);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(isDark),
            _buildSortBar(isDark),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return FadeInWidget(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.outline,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            AppSearchField(
              controller: _destinationController,
              hint: 'Where are you going?',
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDateChip('Check-in', _checkInDate, true, isDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDateChip(
                    'Check-out',
                    _checkOutDate,
                    false,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildGuestsChip(isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(
    String label,
    DateTime? date,
    bool isCheckIn,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _pickDate(isCheckIn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date != null ? _formatDisplayDate(date) : 'Select',
              style: AppTypography.bodySmall.copyWith(
                color: date != null
                    ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary)
                    : (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsChip(bool isDark) {
    final totalGuests = _adults + _children;
    return GestureDetector(
      onTap: _showGuestsPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guests',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$totalGuests guests, $_rooms room${_rooms > 1 ? 's' : ''}',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBar(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Text(
              '${_properties.length} properties',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            _buildSortChip('Recommended', 'recommended', isDark),
            const SizedBox(width: AppSpacing.sm),
            _buildSortChip('Price', 'price', isDark),
            const SizedBox(width: AppSpacing.sm),
            _buildSortChip('Rating', 'rating', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _currentPage = 1;
          _hasMore = true;
        });
        _loadProperties();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.experienceStay.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? AppColors.experienceStay
                : (isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_properties.isEmpty && _isLoading) return _buildShimmer(isDark);
    if (_properties.isEmpty) return _buildEmptyState(isDark);

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        _hasMore = true;
        await _loadProperties();
      },
      color: AppColors.experienceStay,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _properties.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _properties.length) {
            return _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.experienceStay,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return StaggeredAnimationList(
            key: ValueKey(_currentPage),
            children: [
              RippleEffect(
                onTap: () => _navigateToDetail(_properties[index]),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _PropertyCard(property: _properties[index]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      itemBuilder: (_, _) => const BusinessCardSkeleton(),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeInWidget(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No properties found',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different destination or dates',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Clear Search',
              onPressed: () {
                setState(() {
                  _destinationController.clear();
                  _checkInDate = null;
                  _checkOutDate = null;
                  _currentPage = 1;
                  _hasMore = true;
                });
                _loadProperties();
              },
              type: AppButtonType.outline,
              size: AppButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? now)
          : (_checkOutDate ?? now.add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.experienceStay),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
      if (_checkInDate != null && _checkOutDate != null) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
        });
        _loadProperties();
      }
    }
  }

  void _showGuestsPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestsPickerSheet(
        adults: _adults,
        children: _children,
        rooms: _rooms,
        onConfirm: (adults, children, rooms) {
          setState(() {
            _adults = adults;
            _children = children;
            _rooms = rooms;
            _currentPage = 1;
            _hasMore = true;
          });
          _loadProperties();
        },
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> property) {
    final slug = property['slug'] as String?;
    if (slug == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(
          slug: slug,
          checkIn: _checkInDate,
          checkOut: _checkOutDate,
          adults: _adults,
          children: _children,
          rooms: _rooms,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final photos = property['photos'] as List<dynamic>? ?? [];
    final name = property['name'] as String? ?? 'Unknown Property';
    final rating = property['average_rating'] != null
        ? (property['average_rating'] as num).toDouble()
        : 0.0;
    final reviewCount = property['review_count'] as int? ?? 0;
    final distance = property['distance']?.toString();
    final amenities = property['amenities_preview'] as List<dynamic>? ?? [];
    final pricePerNight = property['price_per_night'] as num?;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: photos.isNotEmpty
                      ? SafeImage(
                          path: photos[0].toString(),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.experienceStay.withValues(
                            alpha: 0.1,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.hotel_rounded,
                              size: 48,
                              color: AppColors.experienceStay,
                            ),
                          ),
                        ),
                ),
              ),
              if (rating > 0)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    if (distance != null) ...[
                      Icon(
                        Icons.near_me_outlined,
                        size: 14,
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
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (reviewCount > 0) ...[
                      Icon(
                        Icons.reviews_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$reviewCount reviews',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: amenities.take(4).map((a) {
                      final label = a is Map
                          ? a['name']?.toString() ?? ''
                          : a.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (pricePerNight != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '₹${pricePerNight.toInt()} / night',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.experienceStay,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestsPickerSheet extends StatefulWidget {
  final int adults;
  final int children;
  final int rooms;
  final void Function(int adults, int children, int rooms) onConfirm;

  const _GuestsPickerSheet({
    required this.adults,
    required this.children,
    required this.rooms,
    required this.onConfirm,
  });

  @override
  State<_GuestsPickerSheet> createState() => _GuestsPickerPickerState();
}

class _GuestsPickerPickerState extends State<_GuestsPickerSheet> {
  late int _adults;
  late int _children;
  late int _rooms;

  @override
  void initState() {
    super.initState();
    _adults = widget.adults;
    _children = widget.children;
    _rooms = widget.rooms;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return SlideInWidget(
      beginOffset: const Offset(0, 0.3),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Guests & Rooms',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _GuestCounter(
              label: 'Adults',
              value: _adults,
              min: 1,
              max: 20,
              onChanged: (v) => setState(() => _adults = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _GuestCounter(
              label: 'Children',
              value: _children,
              min: 0,
              max: 10,
              onChanged: (v) => setState(() => _children = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _GuestCounter(
              label: 'Rooms',
              value: _rooms,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _rooms = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Done',
              onPressed: () {
                widget.onConfirm(_adults, _children, _rooms);
                Navigator.pop(context);
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _GuestCounter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            _CounterButton(
              icon: Icons.remove_rounded,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 48),
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _CounterButton(
              icon: Icons.add_rounded,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final enabled = onTap != null;

    return RippleEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.experienceStay
              : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
        ),
      ),
    );
  }
}
