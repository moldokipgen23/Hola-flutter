import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() {
        if (_currentPage == 1) {
          _activities = _getMockActivities();
        }
        _isLoading = false;
        _hasMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getMockActivities() {
    return [
      {
        'id': '1',
        'type': 'trip',
        'title': 'Ride to Airport',
        'subtitle': 'Pilot Taxi Service • Sedan',
        'status': 'confirmed',
        'statusLabel': 'Confirmed',
        'amount': '₹450',
        'time': 'Today, 10:30 AM',
        'icon': Icons.local_taxi_rounded,
        'iconColor': AppColors.experienceTaxi,
        'actions': ['Track', 'Contact Driver', 'Cancel'],
      },
      {
        'id': '2',
        'type': 'order',
        'title': 'Order from Tasty Bites',
        'subtitle': 'Butter Chicken, Naan, Rice',
        'status': 'preparing',
        'statusLabel': 'Preparing',
        'amount': '₹320',
        'time': '15 mins ago',
        'icon': Icons.restaurant_rounded,
        'iconColor': AppColors.experienceRestaurant,
        'actions': ['Track', 'Contact Restaurant'],
      },
      {
        'id': '3',
        'type': 'booking',
        'title': 'Turf Booking - 7v7',
        'subtitle': 'Fit Turf • Court 1',
        'status': 'pending',
        'statusLabel': 'Pending',
        'amount': '₹800',
        'time': 'Tomorrow, 6:00 PM',
        'icon': Icons.sports_soccer_rounded,
        'iconColor': AppColors.experienceTurf,
        'actions': ['View Details', 'Cancel'],
      },
      {
        'id': '4',
        'type': 'stay',
        'title': 'Hotel Stay - Deluxe Room',
        'subtitle': 'Grand Stay Hotel • 2 Nights',
        'status': 'confirmed',
        'statusLabel': 'Confirmed',
        'amount': '₹5,000',
        'time': 'Check-in: Dec 25',
        'icon': Icons.hotel_rounded,
        'iconColor': AppColors.experienceStay,
        'actions': ['View Details', 'Modify'],
      },
      {
        'id': '5',
        'type': 'appointment',
        'title': 'Haircut Appointment',
        'subtitle': 'Style Salon • John',
        'status': 'completed',
        'statusLabel': 'Completed',
        'amount': '₹500',
        'time': 'Yesterday, 4:00 PM',
        'icon': Icons.content_cut_rounded,
        'iconColor': AppColors.experienceAppointment,
        'actions': ['Rate', 'Re-book'],
      },
      {
        'id': '6',
        'type': 'trip',
        'title': 'Bus to Imphal',
        'subtitle': 'Pilot Bus Service • AC Sleeper',
        'status': 'confirmed',
        'statusLabel': 'Confirmed',
        'amount': '₹1,200',
        'time': 'Dec 28, 8:00 PM',
        'icon': Icons.directions_bus_rounded,
        'iconColor': AppColors.experienceSharedTransport,
        'actions': ['View Ticket', 'Contact'],
      },
    ];
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
              setState(() {
                _currentPage = 1;
                _hasMore = true;
              });
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${activity['type']} detail coming soon')),
    );
  }

  void _handleAction(Map<String, dynamic> activity, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action for ${activity['type']} coming soon')),
    );
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
