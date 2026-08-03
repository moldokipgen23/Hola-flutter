import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../services/api.dart';
import 'seat_selection_screen.dart';

class SharedTripScreen extends StatefulWidget {
  const SharedTripScreen({super.key});

  @override
  State<SharedTripScreen> createState() => _SharedTripScreenState();
}

class _SharedTripScreenState extends State<SharedTripScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _passengerCount = 1;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _trips = [];
  String _sortBy = 'departure';

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await api.get(
        '/businesses',
        queryParams: {'experience': 'shared_transport'},
      );
      final data = response is Map
          ? response['data'] ?? response['businesses'] ?? []
          : [];
      final trips = (data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) {
        setState(() {
          _trips = trips;
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  List<Map<String, dynamic>> get _sortedTrips {
    final sorted = List<Map<String, dynamic>>.from(_trips);
    switch (_sortBy) {
      case 'price':
        sorted.sort(
          (a, b) => (a['min_price'] ?? 0).compareTo(b['min_price'] ?? 0),
        );
      case 'departure':
        sorted.sort(
          (a, b) =>
              (a['departure_time'] ?? '').compareTo(b['departure_time'] ?? ''),
        );
      case 'duration':
        sorted.sort(
          (a, b) => (a['duration_minutes'] ?? 0).compareTo(
            b['duration_minutes'] ?? 0,
          ),
        );
    }
    return sorted;
  }

  void _selectTrip(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          trip: trip,
          passengerCount: _passengerCount,
          travelDate: _selectedDate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Shared transport',
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
          _buildSearchForm(isDark),
          _buildSortBar(isDark),
          Expanded(child: _buildResultsList(isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchForm(bool isDark) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _fromController,
                  prefixIcon: Icons.circle,
                  hint: 'From',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _toController,
                  prefixIcon: Icons.circle_outlined,
                  hint: 'To',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppDatePickerField(
                  label: 'Date',
                  selectedDate: _selectedDate,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passengers',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutline
                              : AppColors.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: _passengerCount > 1
                                ? () => setState(() => _passengerCount--)
                                : null,
                            color: AppColors.experienceSharedTransport,
                          ),
                          Expanded(
                            child: Text(
                              '$_passengerCount',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: _passengerCount < 10
                                ? () => setState(() => _passengerCount++)
                                : null,
                            color: AppColors.experienceSharedTransport,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Search buses & trains',
            onPressed: _loadTrips,
            isFullWidth: true,
            leadingIcon: Icons.search_rounded,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${_trips.length} routes found',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          _SortChip(
            label: 'Price',
            isSelected: _sortBy == 'price',
            isDark: isDark,
            onTap: () => setState(() => _sortBy = 'price'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _SortChip(
            label: 'Departure',
            isSelected: _sortBy == 'departure',
            isDark: isDark,
            onTap: () => setState(() => _sortBy = 'departure'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _SortChip(
            label: 'Duration',
            isSelected: _sortBy == 'duration',
            isDark: isDark,
            onTap: () => setState(() => _sortBy = 'duration'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(bool isDark) {
    if (_isLoading) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: List.generate(3, (_) => const BusinessCardSkeleton()),
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
                onPressed: _loadTrips,
                type: AppButtonType.outline,
              ),
            ],
          ),
        ),
      );
    }

    if (_sortedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No routes found',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try different dates or locations',
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
      itemCount: _sortedTrips.length,
      itemBuilder: (context, index) {
        final trip = _sortedTrips[index];
        return SlideInWidget(
          duration: AppAnimations.medium,
          delay: Duration(milliseconds: 80 * index),
          child: _TripResultCard(
            trip: trip,
            isDark: isDark,
            onTap: () => _selectTrip(trip),
          ),
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SortChip({
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
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.experienceSharedTransport
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected
                  ? AppColors.experienceSharedTransport
                  : (isDark ? AppColors.darkOutline : AppColors.outline),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
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
  }
}

class _TripResultCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isDark;
  final VoidCallback onTap;

  const _TripResultCard({
    required this.trip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = trip['name'] ?? 'Unknown operator';
    final from = trip['locality'] ?? trip['address'] ?? '';
    final to = trip['district'] ?? '';
    final departureTime = trip['departure_time'] ?? '--:--';
    final arrivalTime = trip['arrival_time'] ?? '--:--';
    final price = trip['min_price'];
    final seatsAvail = trip['seats_available'] ?? trip['capacity'] ?? 0;
    final rating = (trip['average_rating'] ?? 0).toDouble();
    final vehicleTypes = trip['vehicle_types'] as List? ?? [];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.experienceSharedTransport.withValues(
                    alpha: 0.1,
                  ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (rating > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (price != null)
                Text(
                  '₹${(price as num).toInt()}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.experienceSharedTransport,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: AppColors.experienceSharedTransport,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                from.isNotEmpty ? from : 'From',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      departureTime,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        color: isDark
                            ? AppColors.darkOutline
                            : AppColors.outline,
                      ),
                    ),
                    Text(
                      arrivalTime,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.circle_outlined, size: 8, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Text(
                to.isNotEmpty ? to : 'To',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.event_seat_rounded,
                size: 14,
                color: AppColors.experienceSharedTransport,
              ),
              const SizedBox(width: 4),
              Text(
                '$seatsAvail seats available',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.experienceSharedTransport,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (vehicleTypes.isNotEmpty)
                Text(
                  vehicleTypes.join(', '),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
