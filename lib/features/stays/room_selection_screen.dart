import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import 'stay_booking_summary_screen.dart';

class RoomSelectionScreen extends StatefulWidget {
  final int businessId;
  final String businessName;
  final List<dynamic> roomTypes;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;
  final int rooms;

  const RoomSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.roomTypes,
    this.checkIn,
    this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
  });

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  final Map<int, int> _selectedQuantities = {};
  int get _nights {
    if (widget.checkIn == null || widget.checkOut == null) return 1;
    return widget.checkOut!.difference(widget.checkIn!).inDays.clamp(1, 30);
  }

  double get _totalPrice {
    double total = 0;
    for (final entry in _selectedQuantities.entries) {
      final room = widget.roomTypes.firstWhere(
        (r) => r['id'] == entry.key,
        orElse: () => null,
      );
      if (room != null) {
        final price = (room['price'] as num? ?? 0).toDouble();
        total += price * _nights * entry.value;
      }
    }
    return total;
  }

  int get _totalRoomsSelected =>
      _selectedQuantities.values.fold(0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
        title: Text(
          'Select Rooms',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStaySummary(isDark),
          Expanded(
            child: widget.roomTypes.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: widget.roomTypes.length,
                    itemBuilder: (context, index) => SlideInWidget(
                      delay: Duration(milliseconds: 60 * index),
                      child: _buildRoomTypeCard(
                        widget.roomTypes[index],
                        isDark,
                      ),
                    ),
                  ),
          ),
          if (_totalRoomsSelected > 0) _buildTotalBar(isDark),
        ],
      ),
    );
  }

  Widget _buildStaySummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.calendar_today_rounded,
            label: _formatDateRange(),
          ),
          Container(
            width: 1,
            height: 32,
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
          _SummaryItem(
            icon: Icons.nights_stay_rounded,
            label: '$_nights night${_nights > 1 ? 's' : ''}',
          ),
          Container(
            width: 1,
            height: 32,
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
          _SummaryItem(
            icon: Icons.people_outline_rounded,
            label: '${widget.adults + widget.children} guests',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel_rounded,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No room types available',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try different dates',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(Map<String, dynamic> room, bool isDark) {
    final id = room['id'] as int;
    final name = room['name'] as String? ?? 'Room';
    final price = (room['price'] as num? ?? 0).toDouble();
    final capacity = room['capacity'] as int? ?? 2;
    final bedType = room['bed_type'] as String? ?? '';
    final amenities = room['amenities'] as List<dynamic>? ?? [];
    final isAvailable = room['is_available'] as bool? ?? true;
    final quantity = _selectedQuantities[id] ?? 0;
    final totalForRoom = price * _nights * quantity;

    return RippleEffect(
      onTap: isAvailable ? () {} : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'Sold Out',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$capacity guests',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (bedType.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.bed_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bedType,
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
                      children: amenities.take(5).map((a) {
                        final label = a is Map
                            ? a['name']?.toString() ?? ''
                            : a.toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
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
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${price.toInt()} / night',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.experienceStay,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (quantity > 0)
                            ScaleInWidget(
                              child: Text(
                                '₹${totalForRoom.toInt()} total ($_nights nights × $quantity)',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isAvailable)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkOutline
                                  : AppColors.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QtyButton(
                                icon: Icons.remove_rounded,
                                onTap: quantity > 0
                                    ? () => setState(
                                        () => _selectedQuantities[id] =
                                            quantity - 1,
                                      )
                                    : null,
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 40),
                                child: Text(
                                  quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add_rounded,
                                onTap: () => setState(
                                  () => _selectedQuantities[id] = quantity + 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBar(bool isDark) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalRoomsSelected room${_totalRoomsSelected > 1 ? 's' : ''} × $_nights nights',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${_totalPrice.toInt()}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.experienceStay,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.experienceStay.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.experienceStay,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pay property directly at check-in',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.experienceStay,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Proceed to Booking',
            onPressed: () => _proceedToSummary(),
            isFullWidth: true,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  void _proceedToSummary() {
    final selectedRooms = <Map<String, dynamic>>[];
    for (final entry in _selectedQuantities.entries) {
      if (entry.value > 0) {
        final room = widget.roomTypes.firstWhere((r) => r['id'] == entry.key);
        selectedRooms.add({
          ...room as Map<String, dynamic>,
          'quantity': entry.value,
          'subtotal': (room['price'] as num).toDouble() * _nights * entry.value,
        });
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StayBookingSummaryScreen(
          businessId: widget.businessId,
          businessName: widget.businessName,
          selectedRooms: selectedRooms,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          nights: _nights,
          adults: widget.adults,
          children: widget.children,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  String _formatDateRange() {
    if (widget.checkIn == null || widget.checkOut == null) {
      return 'Select dates';
    }
    final months = [
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
    final ci = widget.checkIn!;
    final co = widget.checkOut!;
    return '${ci.day} ${months[ci.month - 1]} - ${co.day} ${months[co.month - 1]}';
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.experienceStay),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.experienceStay
              : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
        ),
      ),
    );
  }
}
