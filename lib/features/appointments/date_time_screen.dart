import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'booking_summary_screen.dart';

class DateTimeScreen extends StatefulWidget {
  final int businessId;
  final String businessSlug;
  final String? staffId;
  final String? serviceId;
  final List<Service> services;
  final String? staffName;

  const DateTimeScreen({
    super.key,
    required this.businessId,
    required this.businessSlug,
    this.staffId,
    this.serviceId,
    required this.services,
    this.staffName,
  });

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<Map<String, dynamic>> _timeSlots = [];
  bool _loadingSlots = false;
  Set<String> _availableDates = {};
  String? _slotsError;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _loadTimeSlots();
  }

  Future<void> _loadAvailability() async {
    try {
      final params = <String, String>{
        'business_id': widget.businessId.toString(),
      };
      if (widget.serviceId != null) params['service_id'] = widget.serviceId!;
      if (widget.staffId != null) params['staff_id'] = widget.staffId!;

      final res = await api.get(
        '/businesses/${widget.businessSlug}/availability',
        queryParams: params,
      );

      if (!mounted) return;

      final dates = <String>{};
      final availableDates = res['available_dates'] as List?;
      if (availableDates != null) {
        for (final d in availableDates) {
          dates.add(d.toString());
        }
      }

      setState(() {
        _availableDates = dates;
      });
    } catch (_) {
      // Silently handle errors - availability will default to showing all dates
    }
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
    });

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final params = <String, String>{'date': dateStr};
      if (widget.serviceId != null) params['service_id'] = widget.serviceId!;
      if (widget.staffId != null) params['staff_id'] = widget.staffId!;

      final res = await api.get(
        '/businesses/${widget.businessSlug}/slots',
        queryParams: params,
      );

      if (!mounted) return;

      final slots =
          (res['slots'] as List?)
              ?.map((s) => Map<String, dynamic>.from(s))
              .toList() ??
          [];

      setState(() {
        _timeSlots = slots;
        _loadingSlots = false;
        _selectedTime = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _slotsError = e.toString().replaceFirst('Exception: ', '');
          _loadingSlots = false;
        });
      }
    }
  }

  Service? get _selectedService {
    if (widget.serviceId == null) return null;
    try {
      return widget.services.firstWhere(
        (s) => s.id.toString() == widget.serviceId,
      );
    } catch (_) {
      return null;
    }
  }

  void _proceedToSummary() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(
          businessId: widget.businessId,
          businessSlug: widget.businessSlug,
          service: _selectedService,
          staffId: widget.staffId,
          staffName: widget.staffName,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime!,
        ),
      ),
    );
  }

  bool _isDateAvailable(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    if (_availableDates.isEmpty) return true;
    return _availableDates.contains(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Date & Time',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          if (_selectedService != null) ...[
            _buildServiceInfo(isDark),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (widget.staffName != null) ...[
            _buildStaffInfo(isDark),
            const SizedBox(height: AppSpacing.lg),
          ],
          _buildSectionTitle(
            isDark,
            'Select Date',
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCalendar(isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(
            isDark,
            'Available Times',
            Icons.access_time_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTimeSlots(isDark),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continue',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: _selectedTime != null ? _proceedToSummary : null,
            isFullWidth: true,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildServiceInfo(bool isDark) {
    final service = _selectedService!;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.experienceAppointment.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: AppColors.experienceAppointment,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${service.duration} min · ₹${service.price.toStringAsFixed(0)}',
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

  Widget _buildStaffInfo(bool isDark) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.experienceAppointment.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.experienceAppointment,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            widget.staffName!,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: CalendarDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)),
        onDateChanged: (date) {
          setState(() => _selectedDate = date);
          _loadTimeSlots();
        },
        selectableDayPredicate: (date) {
          return _isDateAvailable(date);
        },
      ),
    );
  }

  Widget _buildTimeSlots(bool isDark) {
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SlotSkeleton(),
      );
    }

    if (_slotsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Could not load time slots',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _slotsError!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_timeSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No available times for this date',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try selecting a different date',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _timeSlots.map((slot) {
        final time = slot['start_time']?.toString() ?? '';
        final available = slot['available'] ?? slot['is_available'] ?? true;
        final selected = _selectedTime == time;
        final displayTime = _formatTime(time);

        return ScaleInWidget(
          key: ValueKey('slot_$time'),
          beginScale: selected ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: available
                ? () => setState(() => _selectedTime = time)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: (MediaQuery.of(context).size.width - 56) / 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: !available
                    ? (isDark
                          ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
                          : AppColors.surfaceVariant.withValues(alpha: 0.5))
                    : selected
                    ? AppColors.experienceAppointment
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected
                      ? AppColors.experienceAppointment
                      : available
                      ? (isDark ? AppColors.darkOutline : AppColors.outline)
                      : (isDark
                            ? AppColors.darkOutline.withValues(alpha: 0.3)
                            : AppColors.outline.withValues(alpha: 0.3)),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    displayTime,
                    style: AppTypography.titleSmall.copyWith(
                      color: !available
                          ? (isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary)
                          : selected
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!available)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Unavailable',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mStr = m > 0 ? ':${m.toString().padLeft(2, '0')}' : '';
    return '$h12$mStr $period';
  }
}
