import 'package:flutter/material.dart';
import '../../design_system/components/hero_card.dart';
import '../../design_system/components/category_grid.dart';
import '../../design_system/components/eiho_bottom_sheet.dart';
import '../../design_system/components/toast.dart';
import '../../models/models.dart';
import '../../models/launch_config.dart';
import '../../services/business_service.dart';
import '../../services/trip_service.dart';
import '../../services/auth_service.dart';
import '../../services/launch_control_service.dart';
import '../activity/my_trips_screen.dart';

class RideScreen extends StatefulWidget {
  final LaunchConfig? launchConfig;
  const RideScreen({super.key, this.launchConfig});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userPhone = '';
  List<Business> _taxiBusinesses = [];
  List<Business> _sharedBusinesses = [];
  List<Trip> _recentTrips = [];

  String _pickupLocation = '';
  String _dropLocation = '';

  LaunchConfig get _launchConfig =>
      widget.launchConfig ?? LaunchControlService.instance.config;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    final loggedIn = await AuthService.isLoggedIn();
    _isLoggedIn = loggedIn;

    final futures = <Future>[
      _launchConfig.experience('taxi')
          ? BusinessService.list(experience: 'taxi')
          : Future.value(<Business>[]),
      _launchConfig.experience('shared_transport')
          ? BusinessService.list(experience: 'shared_transport')
          : Future.value(<Business>[]),
      if (loggedIn) TripService.myTrips() else Future.value(<Trip>[]),
    ];

    if (loggedIn) {
      futures.add(AuthService.profile());
    }

    final results = await Future.wait(futures);

    if (!mounted) return;
    setState(() {
      _taxiBusinesses = results[0] as List<Business>;
      _sharedBusinesses = results[1] as List<Business>;
      if (loggedIn) {
        _recentTrips = results[2] as List<Trip>;
        final profile = results[3] as Map<String, dynamic>;
        _userName = (profile['name'] ?? profile['user']?['name'] ?? '')
            .toString();
        _userPhone = (profile['phone'] ?? profile['user']?['phone'] ?? '')
            .toString();
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ride',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                'Local transport in Churachandpur',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (_isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                );
              } else {
                ToastHelper.show(context, 'Login to view trip history');
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🕘', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HeroCard(
          gradientColors: [Color(0xFF1256CF), Color(0xFF2E8CF4)],
          kicker: 'LOCAL MOBILITY',
          title: 'Move around Lamka with ease.',
          description:
              'Request taxis, shared trips, rentals and goods transport.',
          ctaText: '',
          artEmoji: '🚕',
        ),
        const SizedBox(height: 20),
        const Text(
          'Where are you going?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 11),
        _buildRouteBox(),
        const SizedBox(height: 20),
        const Text(
          'Choose a service',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 11),
        CategoryGrid(
          categories: [
            if (_launchConfig.experience('taxi'))
              CategoryItem(
                emoji: '🚕',
                label: 'Local Taxi',
                onTap: () => _openBusinessSheet('taxi'),
              ),
            if (_launchConfig.experience('shared_transport'))
              CategoryItem(
                emoji: '🚐',
                label: 'Shared Ride',
                onTap: () => _openBusinessSheet('shared'),
              ),
            if (_launchConfig.experience('taxi'))
              CategoryItem(
                emoji: '🛣️',
                label: 'Outstation',
                onTap: () => ToastHelper.show(context, 'Coming soon'),
              ),
            if (_launchConfig.experience('vehicle_rental'))
              CategoryItem(
                emoji: '🚙',
                label: 'Rental',
                onTap: () => ToastHelper.show(context, 'Coming soon'),
              ),
            if (_launchConfig.experience('goods_transport'))
              CategoryItem(
                emoji: '🚚',
                label: 'Goods',
                onTap: () => ToastHelper.show(context, 'Coming soon'),
              ),
            if (_launchConfig.experience('taxi'))
              CategoryItem(
                emoji: '📅',
                label: 'Schedule',
                onTap: () => ToastHelper.show(context, 'Coming soon'),
              ),
            CategoryItem(
              emoji: '📍',
              label: 'Saved Places',
              onTap: () => ToastHelper.show(context, 'Coming soon'),
            ),
            CategoryItem(
              emoji: '☎️',
              label: 'Call Driver',
              onTap: () => ToastHelper.show(context, 'Coming soon'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent trip',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            GestureDetector(
              onTap: () {
                if (_isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                  );
                }
              },
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        _buildRecentTrip(),
      ],
    );
  }

  Widget _buildRouteBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 17,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF245FE0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 34,
                      color: const Color(0xFFE7EAF0),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7043),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _openLocationPicker(context, 'pickup'),
                      child: _buildRouteField(
                        _pickupLocation.isEmpty
                            ? 'Current location'
                            : _pickupLocation,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openLocationPicker(context, 'destination'),
                      child: _buildRouteField(
                        _dropLocation.isEmpty
                            ? 'Enter destination'
                            : _dropLocation,
                        isLast: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openRideSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF393BB7), Color(0xFF5D5FEF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Find available rides',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteField(String hint, {bool isLast = false}) {
    return Container(
      height: 44,
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
            ),
      alignment: Alignment.centerLeft,
      child: Text(
        hint,
        style: TextStyle(
          fontSize: 13,
          color: (hint == 'Current location' || hint == 'Enter destination')
              ? const Color(0xFF667085)
              : const Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildRecentTrip() {
    if (!_isLoggedIn) {
      return _buildEmptyTrip('Login to see your recent trips');
    }

    if (_recentTrips.isEmpty) {
      return _buildEmptyTrip('No recent trips');
    }

    final trip = _recentTrips.first;
    final statusLabel = trip.isCompleted
        ? 'Completed'
        : trip.isCancelled
        ? 'Cancelled'
        : trip.status[0].toUpperCase() + trip.status.substring(1);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 67,
            height: 67,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                trip.vehicle?.typeIcon ?? '🚕',
                style: const TextStyle(fontSize: 29),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.pickupLocation} → ${trip.dropLocation}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '$statusLabel · ₹${trip.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${trip.fare.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTrip(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🚕', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationPicker(BuildContext context, String type) {
    final controller = TextEditingController(
      text: type == 'pickup' ? _pickupLocation : _dropLocation,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E6EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: type == 'pickup'
                        ? 'Enter pickup location'
                        : 'Enter destination',
                    prefixIcon: Icon(
                      type == 'pickup' ? Icons.circle : Icons.location_on,
                      color: type == 'pickup' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      if (type == 'pickup') {
                        _pickupLocation = value.trim();
                      } else {
                        _dropLocation = value.trim();
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Current location'),
                subtitle: const Text('Use GPS'),
                onTap: () {
                  setState(() {
                    if (type == 'pickup') {
                      _pickupLocation = 'Current location';
                    } else {
                      _dropLocation = 'Current location';
                    }
                  });
                  Navigator.pop(context);
                  ToastHelper.show(context, 'Using current location');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Tuibuang'),
                subtitle: const Text('Recent'),
                onTap: () {
                  setState(() {
                    if (type == 'pickup') {
                      _pickupLocation = 'Tuibuang';
                    } else {
                      _dropLocation = 'Tuibuang';
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('New Lamka'),
                subtitle: const Text('Recent'),
                onTap: () {
                  setState(() {
                    if (type == 'pickup') {
                      _pickupLocation = 'New Lamka';
                    } else {
                      _dropLocation = 'New Lamka';
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openBusinessSheet(String type) {
    final businesses = type == 'taxi' ? _taxiBusinesses : _sharedBusinesses;
    final title = type == 'taxi' ? 'Local Taxis' : 'Shared Rides';

    if (businesses.isEmpty) {
      ToastHelper.show(context, 'No $title available nearby');
      return;
    }

    EihoBottomSheet.show(
      context,
      Column(
        children: [
          SheetHeader(title: title),
          const SizedBox(height: 8),
          ...businesses.map(
            (b) => SheetListItem(
              emoji: '🚕',
              title: b.name,
              subtitle: b.description ?? b.address ?? 'Ride service',
              trailing: '›',
              onTap: () {
                Navigator.pop(context);
                _openVehicleSheet(b);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _openVehicleSheet(Business business) async {
    if (_pickupLocation.isEmpty || _dropLocation.isEmpty) {
      ToastHelper.show(context, 'Please set pickup and destination first');
      return;
    }

    EihoBottomSheet.show(
      context,
      Column(
        children: [
          SheetHeader(title: business.name),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 17,
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF245FE0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 34,
                        color: const Color(0xFFE7EAF0),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7043),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 12,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _pickupLocation,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 12,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _dropLocation,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available vehicles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 11),
          _VehicleList(
            business: business,
            pickupLocation: _pickupLocation,
            dropLocation: _dropLocation,
            isLoggedIn: _isLoggedIn,
            userName: _userName,
            userPhone: _userPhone,
          ),
        ],
      ),
    );
  }

  void _openRideSheet() {
    if (_pickupLocation.isEmpty || _dropLocation.isEmpty) {
      ToastHelper.show(context, 'Please set pickup and destination first');
      return;
    }
    _openBusinessSheet('taxi');
  }
}

class _VehicleList extends StatefulWidget {
  final Business business;
  final String pickupLocation;
  final String dropLocation;
  final bool isLoggedIn;
  final String userName;
  final String userPhone;
  const _VehicleList({
    required this.business,
    required this.pickupLocation,
    required this.dropLocation,
    required this.isLoggedIn,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<_VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<_VehicleList> {
  bool _loading = true;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final vehicles = await BusinessService.vehicles(widget.business.slug);
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles.where((v) => v.isActive && v.isRequestable).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_vehicles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No vehicles available',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ),
      );
    }

    return Column(
      children: [
        ..._vehicles.map(
          (v) => GestureDetector(
            onTap: () => setState(() => _selectedVehicle = v),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: _selectedVehicle?.id == v.id
                      ? const Color(0xFF5D5FEF)
                      : const Color(0xFFE7EAF0),
                  width: _selectedVehicle?.id == v.id ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(v.typeIcon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${v.seats} seats · ₹${v.baseFare.toStringAsFixed(0)} base',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedVehicle?.id == v.id)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF5D5FEF),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 67,
                height: 67,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    '₹',
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVehicle != null
                          ? 'Estimated ₹${_selectedVehicle!.baseFare.toStringAsFixed(0)}+'
                          : 'Select a vehicle',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Driver confirms final fare · Pay directly',
                      style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _selectedVehicle != null
              ? () => _sendRideRequest(context)
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _selectedVehicle != null
                    ? const [Color(0xFF393BB7), Color(0xFF5D5FEF)]
                    : [Colors.grey[300]!, Colors.grey[400]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Send ride request',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendRideRequest(BuildContext context) async {
    final vehicle = _selectedVehicle;
    if (vehicle == null) return;

    final pickup = widget.pickupLocation;
    final drop = widget.dropLocation;

    if (pickup.isEmpty || drop.isEmpty) {
      ToastHelper.show(context, 'Please set pickup and destination');
      return;
    }

    String name = widget.userName;
    String phone = widget.userPhone;

    if (!widget.isLoggedIn || name.isEmpty || phone.isEmpty) {
      final result = await _showGuestInfoSheet();
      if (result == null) return;
      name = result['name']!;
      phone = result['phone']!;
    }

    if (!context.mounted) return;
    final busCtx = context;
    showDialog(
      context: busCtx,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      ),
    );

    final result = await TripService.create(
      businessSlug: widget.business.slug,
      vehicleId: vehicle.id,
      customerName: name,
      customerPhone: phone,
      pickupLocation: pickup,
      dropLocation: drop,
    );

    if (!busCtx.mounted) return;
    Navigator.pop(busCtx);

    if (result.isNotEmpty && result['data'] != null) {
      ToastHelper.show(busCtx, 'Ride request sent!');
      Navigator.pop(busCtx);
    } else {
      ToastHelper.show(busCtx, 'Failed to send request. Try again.');
    }
  }

  Future<Map<String, String>?> _showGuestInfoSheet() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E6EC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FB),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FB),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Phone is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GestureDetector(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF393BB7), Color(0xFF5D5FEF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    return result;
  }
}
