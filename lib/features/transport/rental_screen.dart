import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../models/models.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = TimeOfDay.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _returnTime = TimeOfDay.now();
  String _selectedType = 'all';
  bool _isLoading = true;
  String? _error;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isSubmitting = false;
  bool _returnSameLocation = true;

  final _types = [
    {'key': 'all', 'label': 'All'},
    {'key': 'car', 'label': 'Sedan'},
    {'key': 'suv', 'label': 'SUV'},
    {'key': 'van', 'label': 'Van'},
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await api.get(
        '/businesses',
        queryParams: {'experience': 'vehicle_rental'},
      );
      final data = response is Map
          ? response['data'] ?? response['businesses'] ?? []
          : [];
      final businesses = (data as List)
          .map((e) => Business.fromJson(e))
          .toList();
      final vehicles = <Vehicle>[];
      for (final b in businesses) {
        vehicles.addAll(
          b.vehicles.where((v) => v.serviceMode == 'rental' && v.isRequestable),
        );
      }
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPickupDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() {
        _pickupDate = date;
        if (_returnDate.isBefore(_pickupDate)) {
          _returnDate = _pickupDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickPickupTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
    );
    if (time != null && mounted) setState(() => _pickupTime = time);
  }

  Future<void> _pickReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: _pickupDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _returnDate = date);
  }

  Future<void> _pickReturnTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _returnTime,
    );
    if (time != null && mounted) setState(() => _returnTime = time);
  }

  Duration get _rentalDuration {
    final pickup = DateTime(
      _pickupDate.year,
      _pickupDate.month,
      _pickupDate.day,
      _pickupTime.hour,
      _pickupTime.minute,
    );
    final ret = DateTime(
      _returnDate.year,
      _returnDate.month,
      _returnDate.day,
      _returnTime.hour,
      _returnTime.minute,
    );
    return ret.difference(pickup);
  }

  String get _durationDisplay {
    final d = _rentalDuration;
    final days = d.inDays;
    final hours = d.inHours % 24;
    if (days > 0 && hours > 0) return '$days days, $hours hours';
    if (days > 0) return '$days days';
    return '$hours hours';
  }

  double _estimateRentalPrice(Vehicle v) {
    final hours = _rentalDuration.inHours.toDouble().clamp(1, double.infinity);
    return v.baseFare + (hours * v.farePerKm);
  }

  List<Vehicle> get _filteredVehicles {
    if (_selectedType == 'all') return _vehicles;
    return _vehicles.where((v) => v.type == _selectedType).toList();
  }

  void _selectVehicle(Vehicle v) {
    setState(() => _selectedVehicle = v);
  }

  Future<void> _confirmBooking() async {
    if (_selectedVehicle == null ||
        _nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final pickup = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );
      final ret = DateTime(
        _returnDate.year,
        _returnDate.month,
        _returnDate.day,
        _returnTime.hour,
        _returnTime.minute,
      );

      await api.post(
        '/bookings',
        body: {
          'vehicle_id': _selectedVehicle!.id,
          'booking_type': 'rental',
          'customer_name': _nameController.text.trim(),
          'customer_phone': _phoneController.text.trim(),
          'pickup_location': _pickupLocationController.text.trim().isEmpty
              ? null
              : _pickupLocationController.text.trim(),
          'return_location': _returnSameLocation
              ? null
              : _returnLocationController.text.trim().isEmpty
              ? null
              : _returnLocationController.text.trim(),
          'scheduled_at': pickup.toIso8601String(),
          'return_at': ret.toIso8601String(),
          'total_price': _estimateRentalPrice(_selectedVehicle!),
          'payment_method': 'pay_at_pickup',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed! Pay at pickup.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _returnLocationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Vehicle rental',
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
                  _buildTypeFilter(isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildScheduleForm(isDark),
                  const SizedBox(height: AppSpacing.lg),
                  _buildVehicleList(isDark),
                  if (_selectedVehicle != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildBookingSummary(isDark),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
          if (_selectedVehicle != null) _buildConfirmButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _types.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.experienceVehicleRental
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: isSelected
                      ? AppColors.experienceVehicleRental
                      : (isDark ? AppColors.darkOutline : AppColors.outline),
                ),
              ),
              child: Center(
                child: Text(
                  type['label']!,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleForm(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _pickupLocationController,
            prefixIcon: Icons.location_on_outlined,
            hint: 'Pickup location (optional)',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppDatePickerField(
                  label: 'Pickup date',
                  selectedDate: _pickupDate,
                  onTap: _pickPickupDate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTimePickerField(
                  label: 'Pickup time',
                  selectedTime: _pickupTime,
                  onTap: _pickPickupTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Return at different location',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            value: !_returnSameLocation,
            onChanged: (v) => setState(() => _returnSameLocation = !v),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.experienceVehicleRental;
              }
              return isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.experienceVehicleRental.withValues(alpha: 0.5);
              }
              return isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant;
            }),
          ),
          if (!_returnSameLocation)
            AppTextField(
              controller: _returnLocationController,
              prefixIcon: Icons.flag_outlined,
              hint: 'Return location (optional)',
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppDatePickerField(
                  label: 'Return date',
                  selectedDate: _returnDate,
                  onTap: _pickReturnDate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTimePickerField(
                  label: 'Return time',
                  selectedTime: _returnTime,
                  onTap: _pickReturnTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.experienceVehicleRental.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.experienceVehicleRental,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Duration: $_durationDisplay',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.experienceVehicleRental,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(bool isDark) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 16),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Shimmer(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.darkOutline : AppColors.outline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Retry',
                onPressed: _loadVehicles,
                type: AppButtonType.outline,
              ),
            ],
          ),
        ),
      );
    }
    if (_filteredVehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 48,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No vehicles available',
                style: AppTypography.bodyMedium.copyWith(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available vehicles',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(_filteredVehicles.length, (index) {
          final v = _filteredVehicles[index];
          return SlideInWidget(
            duration: AppAnimations.medium,
            delay: Duration(milliseconds: 80 * index),
            child: _RentalVehicleCard(
              vehicle: v,
              isSelected: _selectedVehicle?.id == v.id,
              isDark: isDark,
              estimatedPrice: _estimateRentalPrice(v),
              onTap: () => _selectVehicle(v),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookingSummary(bool isDark) {
    final price = _estimateRentalPrice(_selectedVehicle!);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppTextField(
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
            hint: 'Full name *',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            hint: 'Phone number *',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated total',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${price.toInt()}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.experienceVehicleRental,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
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
        label: _isSubmitting
            ? 'Confirming...'
            : 'Confirm rental · ₹${_estimateRentalPrice(_selectedVehicle!).toInt()}',
        onPressed: _isSubmitting ? null : _confirmBooking,
        isLoading: _isSubmitting,
        isFullWidth: true,
        trailingIcon: Icons.check_circle_rounded,
      ),
    );
  }
}

class _RentalVehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isSelected;
  final bool isDark;
  final double estimatedPrice;
  final VoidCallback onTap;

  const _RentalVehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.isDark,
    required this.estimatedPrice,
    required this.onTap,
  });

  String _formatType(String type) {
    switch (type) {
      case 'car':
        return 'Sedan';
      case 'suv':
        return 'SUV';
      case 'van':
        return 'Van';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RippleEffect(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AppCard(
          isSelected: isSelected,
          isSelectable: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.experienceVehicleRental.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    vehicle.typeIcon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.name,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.experienceVehicleRental,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatType(vehicle.type)} · ${vehicle.seats} seats',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${vehicle.baseFare.toInt()} base + ₹${vehicle.farePerKm.toInt()}/hr',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.experienceVehicleRental,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${estimatedPrice.toInt()}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.experienceVehicleRental,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
