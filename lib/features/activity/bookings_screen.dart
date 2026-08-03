import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/area_selector.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/safe_image.dart';
import 'booking_screen.dart';
import '../../features/shared/business_detail_screen.dart';
import 'trip_booking_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final searchCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  final List<Business> _allBusinesses = [];
  List<Business> businesses = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  int page = 1;
  String? error;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(_handleScroll);
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    scrollCtrl
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (scrollCtrl.position.extentAfter < 350 && hasMore && !loadingMore) {
      _loadData();
    }
  }

  void _filter(String query) {
    final term = query.trim().toLowerCase();
    setState(() {
      businesses = term.isEmpty
          ? List.of(_allBusinesses)
          : _allBusinesses.where((business) {
              return business.name.toLowerCase().contains(term) ||
                  (business.category?.name ?? '').toLowerCase().contains(
                    term,
                  ) ||
                  (business.address ?? '').toLowerCase().contains(term) ||
                  business.topServices.any(
                    (service) => service.name.toLowerCase().contains(term),
                  );
            }).toList();
    });
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      page = 1;
      hasMore = true;
      if (mounted) {
        setState(() {
          loading = true;
          loadingMore = false;
          error = null;
        });
      }
    } else {
      if (!hasMore || loading || loadingMore) return;
      setState(() => loadingMore = true);
    }

    try {
      final response = await api.get(
        '/businesses',
        queryParams: {
          'module': 'bookings,transport,turf',
          'per_page': '20',
          'page': '$page',
        },
      );
      final pager = response is Map ? response['businesses'] : null;
      final raw = pager is Map && pager['data'] is List
          ? pager['data'] as List
          : _extractList(response);
      final incoming = raw
          .map((item) => Business.fromJson(item as Map<String, dynamic>))
          .toList();
      final currentPage = pager is Map
          ? int.tryParse('${pager['current_page']}') ?? page
          : page;
      final lastPage = pager is Map
          ? int.tryParse('${pager['last_page']}') ?? currentPage
          : currentPage;

      if (!mounted) return;
      setState(() {
        if (refresh) _allBusinesses.clear();
        final knownIds = _allBusinesses.map((item) => item.id).toSet();
        _allBusinesses.addAll(
          incoming.where((item) => !knownIds.contains(item.id)),
        );
        page = currentPage + 1;
        hasMore = currentPage < lastPage;
        loading = false;
        loadingMore = false;
        error = null;
      });
      _filter(searchCtrl.text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadingMore = false;
        error = _allBusinesses.isEmpty
            ? 'We could not load bookable businesses. Check your connection and retry.'
            : 'Could not load more businesses.';
      });
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      for (final value in response.values) {
        if (value is List) return value;
        if (value is Map && value['data'] is List) {
          return value['data'] as List;
        }
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _loadData(refresh: true),
        color: AppTheme.accent,
        child: loading
            ? _shimmerLoading()
            : CustomScrollView(
                controller: scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  const SliverToBoxAdapter(child: _OfflineNotice()),
                  if (error != null && _allBusinesses.isEmpty)
                    SliverFillRemaining(child: _errorState())
                  else if (businesses.isEmpty)
                    SliverFillRemaining(child: _emptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      sliver: SliverList.builder(
                        itemCount: businesses.length,
                        itemBuilder: (context, index) => FadeInSlide(
                          delay: Duration(
                            milliseconds: (index.clamp(0, 5)) * 45,
                          ),
                          child: _buildBookingCard(businesses[index]),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildFooter()),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book local',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Appointments, stays, seats & transport',
                      style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 132, child: AreaSelector()),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchCtrl,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Search businesses or loaded services',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              suffixIcon: searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchCtrl.clear();
                        _filter('');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Business business) {
    final theme = Theme.of(context);
    final color = CategoryIcons.getColor(business.category?.name);
    final services = business.topServices;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () => _openDetails(business),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: SafeImage(
                        path: business.photos.isNotEmpty
                            ? business.photos.first
                            : null,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (business.averageRating > 0)
                              _ratingBadge(business.averageRating),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            if (business.category != null)
                              _tag(business.category!.name, color),
                            if (business.hasBookingsModule)
                              _tag(
                                _bookingTypeLabel(services),
                                AppTheme.accent,
                                icon: _bookingTypeIcon(services),
                              ),
                            if (business.hasTurfModule)
                              _tag(
                                'Turf / slots',
                                AppTheme.success,
                                icon: Icons.sports_soccer_outlined,
                              ),
                            if (business.hasTransportModule)
                              _tag(
                                'Transport',
                                const Color(0xFFF97316),
                                icon: Icons.directions_car_outlined,
                              ),
                          ],
                        ),
                        if (business.address?.isNotEmpty == true) ...[
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  business.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (services.isNotEmpty &&
              (business.hasBookingsModule || business.hasTurfModule)) ...[
            Divider(height: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 5),
              child: Column(
                children: services
                    .take(3)
                    .map((service) => _serviceRow(service))
                    .toList(),
              ),
            ),
          ] else if (business.hasTransportModule) ...[
            Divider(height: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 19,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Send pickup and drop details. The operator confirms vehicle, availability, and fare.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openDetails(business),
                  icon: const Icon(Icons.info_outline_rounded, size: 17),
                  label: const Text('Details'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openPrimaryAction(business),
                  style: FilledButton.styleFrom(
                    backgroundColor: _actionColor(business),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: Icon(_actionIcon(business), size: 17),
                  label: Text(_actionLabel(business)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceRow(Service service) {
    final theme = Theme.of(context);
    final modeColor = _serviceModeColor(service.bookingMode);
    final detail = _serviceDetail(service);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _serviceModeIcon(service.bookingMode),
              size: 17,
              color: modeColor,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${service.price.toStringAsFixed(0)}${_priceSuffix(service)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _bookingTypeLabel(List<Service> services) {
    final modes = services.map((service) => service.bookingMode).toSet();
    if (modes.contains('stay')) return 'Rooms / stays';
    if (modes.contains('seat')) return 'Seat booking';
    if (modes.contains('slot')) return 'Time slots';
    return 'Appointments';
  }

  IconData _bookingTypeIcon(List<Service> services) {
    final modes = services.map((service) => service.bookingMode).toSet();
    if (modes.contains('stay')) return Icons.hotel_outlined;
    if (modes.contains('seat')) return Icons.event_seat_outlined;
    if (modes.contains('slot')) return Icons.schedule_outlined;
    return Icons.calendar_month_outlined;
  }

  String _serviceDetail(Service service) {
    switch (service.bookingMode) {
      case 'stay':
        final unit = service.unitLabel ?? 'room';
        return '${service.inventoryUnits} $unit${service.inventoryUnits == 1 ? '' : 's'} • ${service.minStayNights} night minimum';
      case 'seat':
        return '${service.capacity} seats • availability confirmed by vendor';
      case 'slot':
        return '${_durationLabel(service.duration)} • choose an available slot';
      default:
        return '${_durationLabel(service.duration)} • request an appointment';
    }
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
  }

  String _priceSuffix(Service service) {
    switch (service.priceUnit) {
      case 'night':
        return '/night';
      case 'seat':
        return '/seat';
      case 'hour':
        return '/hr';
      case 'person':
        return '/person';
      default:
        return '';
    }
  }

  IconData _serviceModeIcon(String mode) {
    switch (mode) {
      case 'stay':
        return Icons.bed_outlined;
      case 'seat':
        return Icons.event_seat_outlined;
      case 'slot':
        return Icons.schedule_outlined;
      default:
        return Icons.calendar_month_outlined;
    }
  }

  Color _serviceModeColor(String mode) {
    switch (mode) {
      case 'stay':
        return AppTheme.primary;
      case 'seat':
        return const Color(0xFFF97316);
      case 'slot':
        return AppTheme.success;
      default:
        return AppTheme.accent;
    }
  }

  bool _hasMultipleFlows(Business business) {
    final booking = business.hasBookingsModule || business.hasTurfModule;
    return business.hasTransportModule && booking;
  }

  String _actionLabel(Business business) {
    if (_hasMultipleFlows(business)) return 'Choose service';
    if (business.hasTransportModule) return 'Request transport';
    final modes = business.topServices.map((item) => item.bookingMode).toSet();
    if (modes.contains('stay')) return 'Check rooms';
    if (modes.contains('seat')) return 'Choose seats';
    if (business.hasTurfModule || modes.contains('slot')) return 'Check slots';
    return 'Request booking';
  }

  IconData _actionIcon(Business business) {
    if (_hasMultipleFlows(business)) return Icons.grid_view_rounded;
    if (business.hasTransportModule) return Icons.directions_car_outlined;
    final modes = business.topServices.map((item) => item.bookingMode).toSet();
    if (modes.contains('stay')) return Icons.hotel_outlined;
    if (modes.contains('seat')) return Icons.event_seat_outlined;
    return Icons.event_available_outlined;
  }

  Color _actionColor(Business business) {
    if (!_hasMultipleFlows(business) && business.hasTransportModule) {
      return const Color(0xFFF97316);
    }
    return const Color(0xFF7C3AED);
  }

  void _openPrimaryAction(Business business) {
    if (_hasMultipleFlows(business)) {
      _showFlowPicker(business);
    } else if (business.hasTransportModule) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripBookingScreen(business: business),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(business: business)),
      );
    }
  }

  void _showFlowPicker(Business business) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you need?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                business.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (business.hasBookingsModule || business.hasTurfModule)
                _flowTile(
                  icon: Icons.event_available_outlined,
                  color: AppTheme.accent,
                  title: _actionLabelForBookingOnly(business),
                  subtitle: 'Choose a service, date, and available time',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(business: business),
                      ),
                    );
                  },
                ),
              if (business.hasTransportModule) ...[
                const SizedBox(height: 10),
                _flowTile(
                  icon: Icons.directions_car_outlined,
                  color: const Color(0xFFF97316),
                  title: 'Request transport',
                  subtitle: 'Share pickup and drop; the operator confirms fare',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripBookingScreen(business: business),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _actionLabelForBookingOnly(Business business) {
    final modes = business.topServices.map((item) => item.bookingMode).toSet();
    if (modes.contains('stay')) return 'Book a room or stay';
    if (modes.contains('seat')) return 'Reserve seats';
    if (business.hasTurfModule || modes.contains('slot')) {
      return 'Book a time slot';
    }
    return 'Book an appointment';
  }

  Widget _flowTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      tileColor: color.withValues(alpha: 0.06),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppTheme.success),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.success,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && _allBusinesses.isNotEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry loading more'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _emptyState() {
    final searching = searchCtrl.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 52,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              searching
                  ? 'No loaded businesses match your search'
                  : 'No bookable businesses yet',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (searching) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  searchCtrl.clear();
                  _filter('');
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _loadData(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 58, 16, 80),
      itemCount: 5,
      itemBuilder: (_, index) => const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: ShimmerBox(
          width: double.infinity,
          height: 186,
          borderRadius: 20,
        ),
      ),
    );
  }

  void _openDetails(Business business) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(slug: business.slug),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.forum_outlined, color: AppTheme.accent, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your request goes to the vendor. They confirm availability and you pay them directly—no online payment.',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
