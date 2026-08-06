import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../models/order.dart';
import '../../services/api.dart';
import 'my_orders_screen.dart';
import 'my_bookings_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _activities = [];

  static const List<Map<String, dynamic>> _tabData = [
    {'label': 'All', 'icon': Icons.receipt_long_rounded},
    {'label': 'Orders', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Bookings', 'icon': Icons.calendar_month_rounded},
    {'label': 'Stays', 'icon': Icons.hotel_rounded},
    {'label': 'Trips', 'icon': Icons.local_taxi_rounded},
    {'label': 'Appointments', 'icon': Icons.content_cut_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabData.length, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        api.get('/my-orders').catchError((_) => const <String, dynamic>{}),
        api.get('/my-bookings').catchError((_) => const <String, dynamic>{}),
      ]);

      final ordersRes = results[0] is Map<String, dynamic>
          ? results[0] as Map<String, dynamic>
          : const <String, dynamic>{};
      final bookingsRes = results[1] is Map<String, dynamic>
          ? results[1] as Map<String, dynamic>
          : const <String, dynamic>{};

      final orders = (ordersRes['orders']?['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
      final bookings = (bookingsRes['bookings']?['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final activities = <Map<String, dynamic>>[
        for (final o in orders) _orderToActivity(o),
        for (final b in bookings) _bookingToActivity(b),
      ]..sort((a, b) {
          final at = a['time'] as String;
          final bt = b['time'] as String;
          return at.compareTo(bt);
        });

      if (!mounted) return;
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activities = [];
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _orderToActivity(Order o) {
    final itemsLabel = o.items.take(2).map((i) => i.name).join(', ');
    final subtitle = [
      o.businessName ?? 'Order',
      if (itemsLabel.isNotEmpty) itemsLabel,
    ].join(' • ');
    final statusLabel = o.displayStatus;
    final actions = <String>[];
    if (o.isPending || o.isConfirmed || o.isPreparing) actions.add('Track');
    if (o.isDelivered) actions.add('Reorder');
    if (o.isPending || o.isConfirmed) actions.add('Cancel');
    return {
      'id': 'order_${o.id}',
      'type': 'orders',
      'title': 'Order from ${o.businessName ?? 'Business'}',
      'subtitle': subtitle,
      'status': o.status,
      'statusLabel': statusLabel,
      'amount': '₹${o.total.toStringAsFixed(0)}',
      'time': _formatTime(o.createdAt),
      'icon': Icons.shopping_bag_rounded,
      'iconColor': AppColors.experienceRestaurant,
      'actions': actions,
      'data': o,
    };
  }

  Map<String, dynamic> _bookingToActivity(Map<String, dynamic> b) {
    final business = b['business'] is Map
        ? b['business'] as Map<String, dynamic>
        : null;
    final service = b['service'] is Map ? b['service'] as Map<String, dynamic> : null;
    final businessName = business?['name']?.toString() ?? 'Booking';
    final serviceName = service?['name']?.toString() ?? 'Service';
    final status = b['status']?.toString() ?? 'pending';
    final statusLabel = status[0].toUpperCase() + status.substring(1);
    final amount = b['total'] ?? b['amount'] ?? b['price'] ?? 0;
    final scheduledAt = b['starts_at'] ?? b['scheduled_at'] ?? b['booking_time'];
    final time = scheduledAt != null ? _formatTime(DateTime.tryParse(scheduledAt.toString())) : '';
    return {
      'id': 'booking_${b['id']}',
      'type': 'bookings',
      'title': '$serviceName at $businessName',
      'subtitle': businessName,
      'status': status,
      'statusLabel': statusLabel,
      'amount': '₹${(amount is num ? amount : double.tryParse(amount.toString()) ?? 0).toStringAsFixed(0)}',
      'time': time,
      'icon': Icons.calendar_month_rounded,
      'iconColor': AppColors.experienceAppointment,
      'actions': status == 'cancelled' || status == 'completed'
          ? const <String>[]
          : const <String>['View Details', 'Cancel'],
      'data': b,
    };
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final date = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = today.difference(date).inDays;
    final hh = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hh:$mm $ampm';
    if (dayDiff == 0) return 'Today, $timeStr';
    if (dayDiff == 1) return 'Yesterday, $timeStr';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FadeInWidget(child: _buildHeader(isDark)),
            FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: _buildTabs(isDark),
            ),
            Expanded(
              child: FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildContent(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Activity',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          AppIconButton(
            icon: Icons.filter_list_rounded,
            onPressed: _showFilterSheet,
            type: AppButtonType.outline,
            size: AppButtonSize.sm,
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: Icons.refresh_rounded,
            onPressed: () {
              _loadActivities();
            },
            type: AppButtonType.ghost,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.darkTextTertiary
            : AppColors.textTertiary,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: _tabData
            .map(
              (t) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t['icon'] as IconData, size: 16),
                    const SizedBox(width: 6),
                    Text(t['label'] as String),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: _tabData
          .map(
            (t) => _buildActivityList(
              isDark,
              (t['label'] as String).toLowerCase(),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActivityList(bool isDark, String filter) {
    final filtered = filter == 'all'
        ? _activities
        : _activities.where((a) => a['type'] == filter).toList();

    if (_isLoading && filtered.isEmpty) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const TimelineSkeleton();
        },
      );
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(isDark, filter);
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      color: AppColors.primary,
      child: StaggeredAnimationList(
        children: filtered.map((activity) {
          return RippleEffect(
            child: _ActivityCard(
              activity: activity,
              onTap: () => _navigateToDetail(activity),
              onAction: (action) => _handleAction(activity, action),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String filter) {
    final messages = {
      'all': 'No activity yet',
      'orders': 'No orders yet',
      'bookings': 'No bookings yet',
      'stays': 'No stays yet',
      'trips': 'No trips yet',
      'appointments': 'No appointments yet',
    };

    final icons = {
      'all': Icons.receipt_long_outlined,
      'orders': Icons.shopping_bag_outlined,
      'bookings': Icons.calendar_month_outlined,
      'stays': Icons.hotel_outlined,
      'trips': Icons.local_taxi_outlined,
      'appointments': Icons.content_cut_outlined,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons[filter] ?? Icons.receipt_long_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            messages[filter] ?? 'No activity',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your ${filter == 'all' ? 'activity' : filter} will appear here',
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

  void _showFilterSheet() {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Filter Activity',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.date_range_rounded),
              title: const Text('Date Range'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.filter_alt_rounded),
              title: const Text('Status'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.attach_money_rounded),
              title: const Text('Amount Range'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> activity) {
    final data = activity['data'];
    if (activity['type'] == 'orders' && data is Order) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  void _handleAction(Map<String, dynamic> activity, String action) {
    switch (action) {
      case 'Track':
      case 'Reorder':
      case 'Cancel':
      case 'View Details':
        _navigateToDetail(activity);
      default:
        break;
    }
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final void Function(String) onAction;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(activity['status'] as String);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.darkOutline : AppColors.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (activity['iconColor'] as Color).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['iconColor'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity['subtitle'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleInWidget(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        activity['statusLabel'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    activity['amount'] as String,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    activity['time'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: (activity['actions'] as List<String>).map((action) {
                  return AppButton(
                    label: action,
                    onPressed: () => onAction(action),
                    type: AppButtonType.outline,
                    size: AppButtonSize.sm,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'preparing':
        return AppColors.accent;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}
