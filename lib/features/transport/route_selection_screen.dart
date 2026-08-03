import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../models/models.dart';
import 'vehicle_selection_screen.dart';

class RouteSelectionScreen extends StatefulWidget {
  final String? initialDropoff;
  final Business? business;

  const RouteSelectionScreen({super.key, this.initialDropoff, this.business});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _isNow = true;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  double? _distanceKm;
  bool _calculatingRoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDropoff != null) {
      _dropoffController.text = widget.initialDropoff!;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (time != null && mounted) {
      setState(() => _scheduledTime = time);
    }
  }

  String get _scheduleLabel {
    final d = _scheduledDate;
    final t = _scheduledTime;
    return '${d.day}/${d.month}/${d.year} · ${t.format(context)}';
  }

  void _proceed() {
    if (_pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup location')),
      );
      return;
    }
    if (_dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter drop-off location')),
      );
      return;
    }

    final scheduledDateTime = !_isNow
        ? DateTime(
            _scheduledDate.year,
            _scheduledDate.month,
            _scheduledDate.day,
            _scheduledTime.hour,
            _scheduledTime.minute,
          )
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleSelectionScreen(
          pickup: _pickupController.text.trim(),
          dropoff: _dropoffController.text.trim(),
          distanceKm: _distanceKm,
          scheduledAt: scheduledDateTime,
          business: widget.business,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Select route',
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
                  _buildLocationInputs(isDark),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInWidget(child: _buildRoutePreview(isDark)),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 150),
                    child: _buildScheduleSection(isDark),
                  ),
                ],
              ),
            ),
          ),
          _buildProceedButton(isDark),
        ],
      ),
    );
  }

  Widget _buildLocationInputs(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppTextField(
            controller: _pickupController,
            prefixIcon: Icons.circle,
            prefix: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            hint: 'Pickup location',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: AppSpacing.md + 4),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          AppTextField(
            controller: _dropoffController,
            prefixIcon: Icons.circle_outlined,
            prefix: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 2),
                ),
              ),
            ),
            hint: 'Where to?',
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePreview(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route_rounded,
                        size: 36,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Route preview',
                        style: AppTypography.bodySmall.copyWith(
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
          ),
          if (_distanceKm != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RouteInfoChip(
                  icon: Icons.straighten_rounded,
                  label: '${_distanceKm!.toStringAsFixed(1)} km',
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _RouteInfoChip(
                  icon: Icons.schedule_rounded,
                  label: '~${(_distanceKm! * 2.5).toInt()} min',
                  isDark: isDark,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Calculate route',
              onPressed: () {
                setState(() {
                  _calculatingRoute = true;
                  _distanceKm = 5.0 + (DateTime.now().millisecond % 15);
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) setState(() => _calculatingRoute = false);
                });
              },
              type: AppButtonType.outline,
              size: AppButtonSize.sm,
              leadingIcon: Icons.calculate_rounded,
              isLoading: _calculatingRoute,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When?',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ScheduleToggle(
                  label: 'Now',
                  isSelected: _isNow,
                  isDark: isDark,
                  onTap: () => setState(() => _isNow = true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScheduleToggle(
                  label: 'Later',
                  isSelected: !_isNow,
                  isDark: isDark,
                  onTap: () => setState(() => _isNow = false),
                ),
              ),
            ],
          ),
          if (!_isNow) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppDatePickerField(
                    label: 'Date',
                    selectedDate: _scheduledDate,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTimePickerField(
                    label: 'Time',
                    selectedTime: _scheduledTime,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _scheduleLabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        label: 'Select vehicle',
        onPressed: _proceed,
        isFullWidth: true,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    );
  }
}

class _RouteInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _RouteInfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.experienceTaxi.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.experienceTaxi),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.experienceTaxi,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ScheduleToggle({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.experienceTaxi : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? AppColors.experienceTaxi
                  : (isDark ? AppColors.darkOutline : AppColors.outline),
            ),
          ),
          child: Center(
            child: Text(
              label,
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
      ),
    );
  }
}
