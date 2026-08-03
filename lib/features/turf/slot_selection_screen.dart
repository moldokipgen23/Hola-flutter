import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import 'turf_booking_summary_screen.dart';

class SlotSelectionScreen extends StatefulWidget {
  final int businessId;
  final String? courtId;

  const SlotSelectionScreen({
    super.key,
    required this.businessId,
    this.courtId,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 60;
  int _participantCount = 1;
  String? _selectedSlotTime;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  String? _error;
  Map<String, dynamic>? _venue;
  List<Map<String, dynamic>> _timeSlots = [];

  static const List<int> _durations = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _loadVenueAndSlots();
  }

  Future<void> _loadVenueAndSlots() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        api.get('/businesses/${widget.businessId}'),
        _fetchSlots(),
      ]);
      if (!mounted) return;
      setState(() {
        _venue = results[0] as Map<String, dynamic>;
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

  Future<List<Map<String, dynamic>>> _fetchSlots() async {
    final queryParams = <String, String>{
      'date': _formatDate(_selectedDate),
      'duration': _selectedDuration.toString(),
    };
    if (widget.courtId != null) {
      queryParams['court_id'] = widget.courtId!;
    }
    try {
      final response = await api.get(
        '/businesses/${widget.businessId}/slots',
        queryParams: queryParams,
      );
      final slots = (response['slots'] as List<dynamic>?) ?? [];
      return slots.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlotTime = null;
    });
    try {
      final slots = await _fetchSlots();
      if (!mounted) return;
      setState(() {
        _timeSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

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
          'Select Slot',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.experienceTurf),
            )
          : _error != null
          ? _buildErrorState(isDark)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateSelector(isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDurationSelector(isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildParticipantSelector(isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTimeSlotGrid(isDark),
                        const SizedBox(height: AppSpacing.xl),
                        _buildPriceCalculation(isDark),
                      ],
                    ),
                  ),
                ),
                if (_selectedSlotTime != null)
                  _buildSelectedSlotSummary(isDark),
              ],
            ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return FadeInWidget(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              _error ?? 'Something went wrong',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Try Again', onPressed: _loadVenueAndSlots),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return FadeInWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = _isSameDay(_selectedDate, date);
                final isToday = index == 0;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _refreshSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.experienceTurf
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
                        Text(
                          _getDayName(date),
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textTertiary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: AppTypography.titleLarge.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          _getMonthName(date),
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textTertiary),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.experienceTurf,
                              shape: BoxShape.circle,
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

  Widget _buildDurationSelector(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _durations.map((duration) {
              final isSelected = _selectedDuration == duration;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDuration = duration);
                    _refreshSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.experienceTurf
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
                      ),
                    ),
                    child: Text(
                      '${duration}m',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSelector(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 150),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Participants',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
            ),
            child: Row(
              children: [
                _ParticipantButton(
                  icon: Icons.remove_rounded,
                  onTap: _participantCount > 1
                      ? () => setState(() => _participantCount--)
                      : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    _participantCount.toString(),
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ParticipantButton(
                  icon: Icons.add_rounded,
                  onTap: _participantCount < 20
                      ? () => setState(() => _participantCount++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(bool isDark) {
    if (_isLoadingSlots) {
      return const SlotSkeleton();
    }

    if (_timeSlots.isEmpty) {
      return FadeInWidget(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No slots available for this date',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Slots',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSlotLegend(isDark),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _timeSlots.map((slot) {
            final isSelected = _selectedSlotTime == slot['time'];
            Widget chip = _TimeSlotChip(
              slot: slot,
              isSelected: isSelected,
              onTap: () {
                if (slot['status'] == 'available' ||
                    slot['status'] == 'limited') {
                  setState(() => _selectedSlotTime = slot['time'] as String);
                }
              },
            );
            if (isSelected) {
              chip = ScaleInWidget(child: chip);
            }
            return chip;
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlotLegend(bool isDark) {
    return Row(
      children: [
        _LegendItem(color: AppColors.success, label: 'Available'),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(color: AppColors.warning, label: 'Limited'),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(color: AppColors.error, label: 'Full'),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(color: AppColors.textTertiary, label: 'Past'),
      ],
    );
  }

  Widget _buildPriceCalculation(bool isDark) {
    final pricePerHour = _venue?['price_per_hour'] as num? ?? 0;
    final hours = _selectedDuration / 60.0;
    final totalPrice = pricePerHour * hours;

    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            _PriceRow(
              label: 'Rate per hour',
              value: '₹${pricePerHour.toInt()}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _PriceRow(label: 'Duration', value: '$_selectedDuration min'),
            const SizedBox(height: AppSpacing.xs),
            _PriceRow(label: 'Participants', value: '$_participantCount'),
            const Divider(height: AppSpacing.md),
            _PriceRow(
              label: 'Estimated Total',
              value: '₹${totalPrice.toInt()}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSlotSummary(bool isDark) {
    final pricePerHour = _venue?['price_per_hour'] as num? ?? 0;
    final hours = _selectedDuration / 60.0;
    final totalPrice = pricePerHour * hours;
    final venueName = _venue?['name'] as String? ?? 'Venue';
    final courts = _venue?['courts'] as List<dynamic>? ?? [];
    final courtName = courts.isNotEmpty
        ? courts[0]['name'] as String? ?? ''
        : '';

    return SlideInWidget(
      beginOffset: const Offset(0, 0.3),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.experienceTurf.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: AppColors.experienceTurf,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$_selectedSlotTime · $_selectedDuration min · $venueName',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.experienceTurf,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${totalPrice.toInt()}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.experienceTurf,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Proceed to Book',
              onPressed: () => _proceedToBooking(
                totalPrice.toDouble(),
                venueName,
                courtName,
              ),
              isFullWidth: true,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToBooking(
    double totalPrice,
    String venueName,
    String courtName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TurfBookingSummaryScreen(
          businessId: widget.businessId,
          venueName: venueName,
          courtId: widget.courtId,
          courtName: courtName,
          date: _selectedDate,
          time: _selectedSlotTime!,
          duration: _selectedDuration,
          participants: _participantCount,
          totalPrice: totalPrice,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String _getMonthName(DateTime date) {
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
    return months[date.month - 1];
  }
}

class _ParticipantButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ParticipantButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final enabled = onTap != null;

    return RippleEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.experienceTurf
              : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final Map<String, dynamic> slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final time = slot['time'] as String? ?? '';
    final status = slot['status'] as String? ?? 'unavailable';
    final spotsLeft = slot['spots_left'] as int?;

    Color chipColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case 'available':
        chipColor = isSelected
            ? AppColors.success
            : AppColors.success.withValues(alpha: 0.1);
        textColor = isSelected ? Colors.white : AppColors.success;
        borderColor = AppColors.success;
      case 'limited':
        chipColor = isSelected
            ? AppColors.warning
            : AppColors.warning.withValues(alpha: 0.1);
        textColor = isSelected ? Colors.white : AppColors.warning;
        borderColor = AppColors.warning;
      case 'full':
        chipColor = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceVariant;
        textColor = isDark
            ? AppColors.darkTextTertiary
            : AppColors.textTertiary;
        borderColor = isDark ? AppColors.darkOutline : AppColors.outline;
      default:
        chipColor = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceVariant;
        textColor = isDark
            ? AppColors.darkTextTertiary
            : AppColors.textTertiary;
        borderColor = isDark ? AppColors.darkOutline : AppColors.outline;
    }

    return RippleEffect(
      onTap: status != 'full' && status != 'stale' ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? borderColor
                : (isDark ? AppColors.darkOutline : AppColors.outline),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: AppTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (spotsLeft != null && status != 'full') ...[
              const SizedBox(height: 2),
              Text(
                '$spotsLeft left',
                style: AppTypography.labelSmall.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (status == 'full') ...[
              const SizedBox(height: 2),
              Text(
                'Full',
                style: AppTypography.labelSmall.copyWith(color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              (isTotal ? AppTypography.titleMedium : AppTypography.bodyMedium)
                  .copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
        ),
        Text(
          value,
          style:
              (isTotal ? AppTypography.titleMedium : AppTypography.bodyMedium)
                  .copyWith(
                    color: isTotal
                        ? AppColors.experienceTurf
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                  ),
        ),
      ],
    );
  }
}
