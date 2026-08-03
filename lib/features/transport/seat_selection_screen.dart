import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import 'shared_booking_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final int passengerCount;
  final DateTime travelDate;

  const SeatSelectionScreen({
    super.key,
    required this.trip,
    required this.passengerCount,
    required this.travelDate,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int _selectedSeats = 1;
  final List<String> _selectedSeatLabels = [];
  bool _hasSeatLayout = false;

  static const List<String> _seatLabels = [
    '1A',
    '1B',
    '1C',
    '1D',
    '2A',
    '2B',
    '2C',
    '2D',
    '3A',
    '3B',
    '3C',
    '3D',
    '4A',
    '4B',
    '4C',
    '4D',
    '5A',
    '5B',
    '5C',
    '5D',
    '6A',
    '6B',
    '6C',
    '6D',
  ];

  Set<String> get _bookedSeats => {'1C', '2B', '3A', '4D', '5C'};
  Set<String> get _heldSeats => {'1A', '3C'};

  int get _maxSeats => widget.passengerCount;
  double get _seatPrice => (widget.trip['min_price'] ?? 200).toDouble();

  @override
  void initState() {
    super.initState();
    _hasSeatLayout = widget.trip['has_seat_layout'] == true;
    if (_hasSeatLayout) {
      _selectedSeats = 0;
    } else {
      _selectedSeats = widget.passengerCount;
    }
  }

  bool _isSeatAvailable(String label) =>
      !_bookedSeats.contains(label) && !_heldSeats.contains(label);

  void _toggleSeat(String label) {
    if (!_isSeatAvailable(label)) return;
    setState(() {
      if (_selectedSeatLabels.contains(label)) {
        _selectedSeatLabels.remove(label);
        _selectedSeats = _selectedSeatLabels.length;
      } else {
        if (_selectedSeatLabels.length < _maxSeats) {
          _selectedSeatLabels.add(label);
          _selectedSeats = _selectedSeatLabels.length;
        }
      }
    });
  }

  void _proceed() {
    if (_selectedSeats < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one seat')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedBookingScreen(
          trip: widget.trip,
          seatCount: _selectedSeats,
          selectedSeats: _selectedSeatLabels,
          travelDate: widget.travelDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final name = widget.trip['name'] ?? 'Unknown operator';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Select seats',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildTripHeader(isDark, name),
                  const SizedBox(height: AppSpacing.lg),
                  if (_hasSeatLayout) ...[
                    _buildSeatLegend(isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildSeatGrid(isDark),
                  ] else ...[
                    _buildSeatCountSelector(isDark),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildPriceSummary(isDark),
                ],
              ),
            ),
          ),
          _buildProceedButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTripHeader(bool isDark, String name) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.experienceSharedTransport.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: AppColors.experienceSharedTransport,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Passengers: $_maxSeats',
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
      ),
    );
  }

  Widget _buildSeatLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          label: 'Available',
          color: isDark ? AppColors.darkOutline : AppColors.outline,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(
          label: 'Selected',
          color: AppColors.experienceSharedTransport,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(label: 'Booked', color: AppColors.error, isDark: isDark),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(label: 'Held', color: AppColors.warning, isDark: isDark),
      ],
    );
  }

  Widget _buildSeatGrid(bool isDark) {
    final rows = <List<String>>[];
    for (var i = 0; i < _seatLabels.length; i += 4) {
      rows.add(_seatLabels.sublist(i, (i + 4).clamp(0, _seatLabels.length)));
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Front of vehicle',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...row.map((label) {
                    final isBooked = _bookedSeats.contains(label);
                    final isHeld = _heldSeats.contains(label);
                    final isSelected = _selectedSeatLabels.contains(label);

                    Color bgColor;
                    Color fgColor;
                    if (isSelected) {
                      bgColor = AppColors.experienceSharedTransport;
                      fgColor = Colors.white;
                    } else if (isBooked) {
                      bgColor = AppColors.error.withValues(alpha: 0.15);
                      fgColor = AppColors.error;
                    } else if (isHeld) {
                      bgColor = AppColors.warning.withValues(alpha: 0.15);
                      fgColor = AppColors.warning;
                    } else {
                      bgColor = isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant;
                      fgColor = isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: RippleEffect(
                        onTap: isBooked || isHeld
                            ? null
                            : () => _toggleSeat(label),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.experienceSharedTransport
                                  : (isDark
                                        ? AppColors.darkOutline
                                        : AppColors.outline),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: AppTypography.labelSmall.copyWith(
                                color: fgColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (row.length < 4)
                    ...List.generate(
                      4 - row.length,
                      (_) => const SizedBox(width: 50),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Back of vehicle',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatCountSelector(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Select number of seats',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedSeats > 1
                    ? () => setState(() => _selectedSeats--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                iconSize: 36,
                color: AppColors.experienceSharedTransport,
              ),
              const SizedBox(width: AppSpacing.xl),
              Text(
                '$_selectedSeats',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.experienceSharedTransport,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              IconButton(
                onPressed: _selectedSeats < _maxSeats
                    ? () => setState(() => _selectedSeats++)
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
                iconSize: 36,
                color: AppColors.experienceSharedTransport,
              ),
            ],
          ),
          Text(
            'of $_maxSeats available',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(bool isDark) {
    final total = _selectedSeats * _seatPrice;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seats',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                '$_selectedSeats × ₹${_seatPrice.toInt()}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${total.toInt()}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.experienceSharedTransport,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
      ),
      child: AppButton(
        label: _selectedSeats > 0
            ? 'Proceed · $_selectedSeats seat${_selectedSeats > 1 ? 's' : ''}'
            : 'Select seats',
        onPressed: _selectedSeats > 0 ? _proceed : null,
        isFullWidth: true,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
