import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import '../../models/models.dart';
import 'ride_request_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double? distanceKm;
  final DateTime? scheduledAt;
  final Business? business;

  const VehicleSelectionScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.distanceKm,
    this.scheduledAt,
    this.business,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  bool _isLoading = true;
  String? _error;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;

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
      final slug = widget.business?.slug;
      final response = slug != null
          ? await api.get('/businesses/$slug/vehicles')
          : await api.get('/vehicles', queryParams: {'service_mode': 'taxi'});
      final data = response is Map
          ? (response['vehicles'] ?? response['data'] ?? [])
          : [];
      final vehicles = (data as List).map((e) => Vehicle.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _vehicles = vehicles.where((v) => v.isRequestable).toList();
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

  String _formatType(String type) {
    switch (type) {
      case 'car':
        return 'Sedan';
      case 'auto':
        return 'Auto';
      case 'suv':
        return 'SUV';
      case 'bike':
        return 'Bike';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  String _formatCapacity(Vehicle v) {
    if (v.capacityValue != null) {
      return '${v.capacityValue!.toStringAsFixed(0)} ${v.capacityUnit}';
    }
    return '${v.seats} seats';
  }

  String _fareDisplay(Vehicle v) {
    if (v.requiresQuote) return 'Quote required';
    if (widget.distanceKm == null || widget.distanceKm! <= 0) {
      return 'From ₹${v.baseFare.toStringAsFixed(0)}';
    }
    final fare = v.estimatedFare(widget.distanceKm!);
    return '₹${fare.toStringAsFixed(0)}';
  }

  String _fareRange(Vehicle v) {
    if (v.requiresQuote) return 'Operator will confirm fare';
    final low = v.estimatedFare(2);
    final high = v.estimatedFare(widget.distanceKm ?? 15);
    return '₹${low.toStringAsFixed(0)} – ₹${high.toStringAsFixed(0)}';
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() => _selectedVehicle = vehicle);
  }

  void _proceed() {
    if (_selectedVehicle == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideRequestScreen(
          pickup: widget.pickup,
          dropoff: widget.dropoff,
          distanceKm: widget.distanceKm,
          scheduledAt: widget.scheduledAt,
          vehicle: _selectedVehicle!,
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
          'Choose vehicle',
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
          _buildRouteSummary(isDark),
          Expanded(child: _buildVehicleList(isDark)),
          _buildSelectButton(isDark),
        ],
      ),
    );
  }

  Widget _buildRouteSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1.5,
                height: 20,
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pickup,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.dropoff,
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
          if (widget.distanceKm != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.experienceTaxi.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${widget.distanceKm!.toStringAsFixed(1)} km',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.experienceTaxi,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(bool isDark) {
    if (_isLoading) {
      return Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: List.generate(
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
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
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
                textAlign: TextAlign.center,
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

    if (_vehicles.isEmpty) {
      return Center(
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try another operator or check back later',
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenPadding,
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final isSelected = _selectedVehicle?.id == vehicle.id;
        return SlideInWidget(
          duration: AppAnimations.medium,
          delay: Duration(milliseconds: 80 * index),
          child: ScaleInWidget(
            beginScale: isSelected ? 0.95 : 0.98,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _VehicleOptionCard(
                vehicle: vehicle,
                isSelected: isSelected,
                isDark: isDark,
                fareDisplay: _fareDisplay(vehicle),
                fareRange: _fareRange(vehicle),
                typeLabel: _formatType(vehicle.type),
                capacityLabel: _formatCapacity(vehicle),
                businessName: widget.business?.name,
                onTap: () => _selectVehicle(vehicle),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectButton(bool isDark) {
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
        label: _selectedVehicle != null
            ? 'Continue · ${_fareDisplay(_selectedVehicle!)}'
            : 'Select a vehicle',
        onPressed: _selectedVehicle != null ? _proceed : null,
        isFullWidth: true,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isSelected;
  final bool isDark;
  final String fareDisplay;
  final String fareRange;
  final String typeLabel;
  final String capacityLabel;
  final String? businessName;
  final VoidCallback onTap;

  const _VehicleOptionCard({
    required this.vehicle,
    required this.isSelected,
    required this.isDark,
    required this.fareDisplay,
    required this.fareRange,
    required this.typeLabel,
    required this.capacityLabel,
    this.businessName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      isSelected: isSelected,
      isSelectable: true,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.experienceTaxi.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                vehicle.typeIcon,
                style: const TextStyle(fontSize: 28),
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
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$typeLabel · $capacityLabel',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                if (businessName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    businessName!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  fareRange,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            fareDisplay,
            style: AppTypography.titleMedium.copyWith(
              color: vehicle.requiresQuote
                  ? AppColors.warning
                  : AppColors.experienceTaxi,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
