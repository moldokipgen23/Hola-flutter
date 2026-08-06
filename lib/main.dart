import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/search/search_screen.dart';
import 'features/shared/profile_screen.dart';
import 'features/shared/business_detail_screen.dart';
import 'features/shared/feature_unavailable_screen.dart';
import 'features/commerce/storefront_screen.dart';
import 'features/commerce/product_detail_screen.dart';
import 'features/commerce/cart_screen.dart';
import 'features/commerce/checkout_screen.dart';
import 'features/commerce/order_confirmation_screen.dart';
import 'features/commerce/order_status_screen.dart';
import 'features/restaurant/menu_screen.dart';
import 'features/restaurant/dish_detail_screen.dart';
import 'features/restaurant/restaurant_cart_screen.dart';
import 'features/restaurant/restaurant_checkout_screen.dart';
import 'features/restaurant/order_tracking_screen.dart';
import 'features/appointments/service_selection_screen.dart';
import 'features/appointments/staff_selection_screen.dart';
import 'features/appointments/date_time_screen.dart';
import 'features/appointments/booking_summary_screen.dart';
import 'features/appointments/booking_confirmation_screen.dart';
import 'features/turf/venue_discovery_screen.dart';
import 'features/turf/venue_detail_screen.dart';
import 'features/turf/slot_selection_screen.dart';
import 'features/turf/turf_booking_summary_screen.dart';
import 'features/turf/turf_booking_confirmation_screen.dart';
import 'features/stays/search_screen.dart';
import 'features/stays/property_detail_screen.dart';
import 'features/stays/room_selection_screen.dart';
import 'features/stays/stay_booking_summary_screen.dart';
import 'features/stays/stay_booking_confirmation_screen.dart';
import 'features/transport/taxi_home_screen.dart';
import 'features/transport/route_selection_screen.dart';
import 'features/transport/vehicle_selection_screen.dart';
import 'features/transport/ride_request_screen.dart';
import 'features/transport/ride_confirmation_screen.dart';
import 'features/transport/shared_trip_screen.dart';
import 'features/transport/seat_selection_screen.dart';
import 'features/transport/shared_booking_screen.dart';
import 'features/transport/rental_screen.dart';
import 'features/transport/goods_transport_screen.dart';
import 'features/shared/saved_screen.dart';
import 'features/activity/my_orders_screen.dart';
import 'features/activity/my_bookings_screen.dart';
import 'features/booking/booking_lookup_screen.dart';
import 'features/activity/my_trips_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/models.dart';
import 'services/notification_service.dart';
import 'services/launch_control_service.dart';
import 'models/launch_config.dart';
import 'design_system/tokens/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await LaunchControlService.instance.loadCached();
  await LaunchControlService.instance.refresh().timeout(
    const Duration(seconds: 5),
    onTimeout: () {},
  );
  runApp(const EihoOneApp());
}

class EihoOneApp extends StatefulWidget {
  const EihoOneApp({super.key});

  @override
  State<EihoOneApp> createState() => _EihoOneAppState();
}

class _EihoOneAppState extends State<EihoOneApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  Timer? _launchRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _launchRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => LaunchControlService.instance.refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(LaunchControlService.instance.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _launchRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eiho One',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      onGenerateRoute: (settings) {
        if (!LaunchControlService.instance.allowsRoute(settings.name)) {
          return MaterialPageRoute(
            builder: (_) => const FeatureUnavailableScreen(),
          );
        }
        final args = settings.arguments as Map<String, dynamic>?;
        final businessId = args?['businessId'] as int? ?? 0;
        final slug = args?['slug'] as String? ?? '';

        switch (settings.name) {
          // Owner routes — redirect to web vendor portal
          case '/owner/bookings':
          case '/owner/orders':
          case '/owner/products':
            return MaterialPageRoute(
              builder: (_) {
                final url = Uri.parse('https://hola.ehlom.com/vendor');
                launchUrl(url, mode: LaunchMode.externalApplication);
                return const Scaffold(
                  body: Center(child: Text('Opening vendor portal...')),
                );
              },
            );

          // Business detail
          case '/business':
            return MaterialPageRoute(
              builder: (_) => BusinessDetailScreen(slug: slug),
            );

          // Retail / Commerce
          case '/retail/storefront':
            return MaterialPageRoute(
              builder: (_) => StorefrontScreen(slug: slug),
            );
          case '/retail/product':
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: args?['product'] as Product,
                business: args?['business'] as Business,
              ),
            );
          case '/retail/cart':
            return MaterialPageRoute(
              builder: (_) => CartScreen(
                entries: args?['entries'] as List<CartEntry>? ?? [],
              ),
            );
          case '/retail/checkout':
            return MaterialPageRoute(
              builder: (_) => CheckoutScreen(
                business: args?['business'] as Business,
                entries: args?['entries'] as List<CartEntry>? ?? [],
                total: (args?['total'] as num?)?.toDouble() ?? 0,
              ),
            );
          case '/retail/order-confirmation':
            return MaterialPageRoute(
              builder: (_) => OrderConfirmationScreen(orderData: args ?? {}),
            );
          case '/retail/order-status':
            return MaterialPageRoute(
              builder: (_) =>
                  OrderStatusScreen(orderId: args?['orderId'] as int? ?? 0),
            );

          // Restaurant
          case '/restaurant/menu':
            return MaterialPageRoute(
              builder: (_) => RestaurantMenuScreen(slug: slug),
            );
          case '/restaurant/dish':
            return MaterialPageRoute(
              builder: (_) => DishDetailScreen(
                product: args?['product'] as Product,
                businessSlug: slug,
              ),
            );
          case '/restaurant/cart':
            return MaterialPageRoute(
              builder: (_) => RestaurantCartScreen(
                entries: args?['entries'] as List<RestaurantCartEntry>? ?? [],
                businessSlug: slug,
                orderType: args?['orderType'] as String? ?? 'pickup',
              ),
            );
          case '/restaurant/checkout':
            return MaterialPageRoute(
              builder: (_) => RestaurantCheckoutScreen(
                businessSlug: slug,
                entries: args?['entries'] as List<RestaurantCartEntry>? ?? [],
                subtotal: (args?['subtotal'] as num?)?.toDouble() ?? 0,
                deliveryFee: (args?['deliveryFee'] as num?)?.toDouble() ?? 0,
                total: (args?['total'] as num?)?.toDouble() ?? 0,
                orderType: args?['orderType'] as String? ?? 'pickup',
              ),
            );
          case '/restaurant/tracking':
            return MaterialPageRoute(
              builder: (_) =>
                  OrderTrackingScreen(orderId: args?['orderId'] as int? ?? 0),
            );

          // Appointments
          case '/appointment/services':
            return MaterialPageRoute(
              builder: (_) => ServiceSelectionScreen(slug: slug),
            );
          case '/appointment/staff':
            return MaterialPageRoute(
              builder: (_) => StaffSelectionScreen(
                businessId: businessId,
                businessSlug: slug,
                services: args?['services'] as List<Service>? ?? [],
                selectedServiceId: args?['selectedServiceId'] as String?,
              ),
            );
          case '/appointment/datetime':
            return MaterialPageRoute(
              builder: (_) => DateTimeScreen(
                businessId: businessId,
                businessSlug: slug,
                staffId: args?['staffId'] as String?,
                serviceId: args?['serviceId'] as String?,
                services: args?['services'] as List<Service>? ?? [],
                staffName: args?['staffName'] as String?,
              ),
            );
          case '/appointment/summary':
            return MaterialPageRoute(
              builder: (_) => BookingSummaryScreen(
                businessId: businessId,
                businessSlug: slug,
                service: args?['service'] as Service?,
                staffId: args?['staffId'] as String?,
                staffName: args?['staffName'] as String?,
                selectedDate:
                    args?['selectedDate'] as DateTime? ?? DateTime.now(),
                selectedTime: args?['selectedTime'] as String? ?? '',
              ),
            );
          case '/appointment/confirmation':
            return MaterialPageRoute(
              builder: (_) =>
                  BookingConfirmationScreen(bookingData: args ?? {}),
            );

          // Turf
          case '/turf/discover':
            return MaterialPageRoute(
              builder: (_) => const VenueDiscoveryScreen(),
            );
          case '/turf/venue':
            return MaterialPageRoute(
              builder: (_) => VenueDetailScreen(slug: slug),
            );
          case '/turf/slots':
            return MaterialPageRoute(
              builder: (_) => SlotSelectionScreen(
                businessId: args?['businessId'] as int? ?? 0,
                courtId: args?['courtId'] as String?,
              ),
            );
          case '/turf/summary':
            return MaterialPageRoute(
              builder: (_) => TurfBookingSummaryScreen(
                businessId: businessId,
                venueName: args?['venueName'] as String? ?? '',
                courtId: args?['courtId'] as String?,
                courtName: args?['courtName'] as String? ?? '',
                date: args?['date'] as DateTime? ?? DateTime.now(),
                time: args?['time'] as String? ?? '',
                duration: args?['duration'] as int? ?? 60,
                participants: args?['participants'] as int? ?? 1,
                totalPrice: (args?['totalPrice'] as num?)?.toDouble() ?? 0,
              ),
            );
          case '/turf/confirmation':
            return MaterialPageRoute(
              builder: (_) => TurfBookingConfirmationScreen(
                bookingData: args ?? {},
                venueName: args?['venueName'] as String? ?? '',
                courtName: args?['courtName'] as String? ?? '',
                date: args?['date'] as DateTime? ?? DateTime.now(),
                time: args?['time'] as String? ?? '',
                duration: args?['duration'] as int? ?? 60,
                participants: args?['participants'] as int? ?? 1,
                totalPrice: (args?['totalPrice'] as num?)?.toDouble() ?? 0,
                customerName: args?['customerName'] as String? ?? '',
              ),
            );

          // Stays / Hotels
          case '/stay/search':
            return MaterialPageRoute(builder: (_) => const StaySearchScreen());
          case '/stay/property':
            return MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(slug: slug),
            );
          case '/stay/rooms':
            return MaterialPageRoute(
              builder: (_) => RoomSelectionScreen(
                businessId: businessId,
                businessName: args?['businessName'] as String? ?? '',
                roomTypes: args?['roomTypes'] as List<dynamic>? ?? [],
                checkIn: args?['checkIn'] as DateTime?,
                checkOut: args?['checkOut'] as DateTime?,
                adults: args?['adults'] as int? ?? 2,
                children: args?['children'] as int? ?? 0,
                rooms: args?['rooms'] as int? ?? 1,
              ),
            );
          case '/stay/summary':
            return MaterialPageRoute(
              builder: (_) => StayBookingSummaryScreen(
                businessId: businessId,
                businessName: args?['businessName'] as String? ?? '',
                selectedRooms:
                    args?['selectedRooms'] as List<Map<String, dynamic>>? ?? [],
                checkIn: args?['checkIn'] as DateTime?,
                checkOut: args?['checkOut'] as DateTime?,
                nights: args?['nights'] as int? ?? 1,
                adults: args?['adults'] as int? ?? 2,
                children: args?['children'] as int? ?? 0,
                totalPrice: (args?['totalPrice'] as num?)?.toDouble() ?? 0,
              ),
            );
          case '/stay/confirmation':
            return MaterialPageRoute(
              builder: (_) => StayBookingConfirmationScreen(
                bookingData: args ?? {},
                businessName: args?['businessName'] as String? ?? '',
                checkIn: args?['checkIn'] as DateTime?,
                checkOut: args?['checkOut'] as DateTime?,
                nights: args?['nights'] as int? ?? 1,
                selectedRooms:
                    args?['selectedRooms'] as List<Map<String, dynamic>>? ?? [],
                adults: args?['adults'] as int? ?? 2,
                children: args?['children'] as int? ?? 0,
                totalPrice: (args?['totalPrice'] as num?)?.toDouble() ?? 0,
                customerName: args?['customerName'] as String? ?? '',
              ),
            );

          // Transport / Taxi
          case '/taxi/home':
            return MaterialPageRoute(builder: (_) => const TaxiHomeScreen());
          case '/taxi/route':
            return MaterialPageRoute(
              builder: (_) => RouteSelectionScreen(
                initialDropoff: args?['initialDropoff'] as String?,
                business: args?['business'] as Business?,
              ),
            );
          case '/taxi/vehicle':
            return MaterialPageRoute(
              builder: (_) => VehicleSelectionScreen(
                pickup: args?['pickup'] as String? ?? '',
                dropoff: args?['dropoff'] as String? ?? '',
                distanceKm: (args?['distanceKm'] as num?)?.toDouble(),
                scheduledAt: args?['scheduledAt'] as DateTime?,
                business: args?['business'] as Business?,
              ),
            );
          case '/taxi/request':
            return MaterialPageRoute(
              builder: (_) => RideRequestScreen(
                pickup: args?['pickup'] as String? ?? '',
                dropoff: args?['dropoff'] as String? ?? '',
                distanceKm: (args?['distanceKm'] as num?)?.toDouble(),
                scheduledAt: args?['scheduledAt'] as DateTime?,
                vehicle: args?['vehicle'] as Vehicle,
                business: args?['business'] as Business?,
              ),
            );
          case '/taxi/confirmation':
            return MaterialPageRoute(
              builder: (_) => RideConfirmationScreen(
                bookingId: args?['bookingId'] as String? ?? '',
                pickup: args?['pickup'] as String? ?? '',
                dropoff: args?['dropoff'] as String? ?? '',
                distanceKm: (args?['distanceKm'] as num?)?.toDouble(),
                fare: (args?['fare'] as num?)?.toDouble(),
                fareDisplay: args?['fareDisplay'] as String? ?? '',
                vehicleType: args?['vehicleType'] as String? ?? '',
                vehicleName: args?['vehicleName'] as String? ?? '',
                scheduledAt: args?['scheduledAt'] as DateTime?,
                businessName: args?['businessName'] as String?,
                businessPhone: args?['businessPhone'] as String?,
                businessWhatsApp: args?['businessWhatsApp'] as String?,
              ),
            );

          // Shared Transport
          case '/transport/shared':
            return MaterialPageRoute(builder: (_) => const SharedTripScreen());
          case '/transport/seats':
            return MaterialPageRoute(
              builder: (_) => SeatSelectionScreen(
                trip: args?['trip'] as Map<String, dynamic>? ?? {},
                passengerCount: args?['passengerCount'] as int? ?? 1,
                travelDate: args?['travelDate'] as DateTime? ?? DateTime.now(),
              ),
            );
          case '/transport/shared-booking':
            return MaterialPageRoute(
              builder: (_) => SharedBookingScreen(
                trip: args?['trip'] as Map<String, dynamic>? ?? {},
                seatCount: args?['seatCount'] as int? ?? 1,
                selectedSeats: args?['selectedSeats'] as List<String>? ?? [],
                travelDate: args?['travelDate'] as DateTime? ?? DateTime.now(),
              ),
            );
          case '/transport/rental':
            return MaterialPageRoute(builder: (_) => const RentalScreen());
          case '/transport/goods':
            return MaterialPageRoute(
              builder: (_) => const GoodsTransportScreen(),
            );

          // Activity
          case '/saved':
            return MaterialPageRoute(builder: (_) => const SavedScreen());
          case '/my-orders':
            return MaterialPageRoute(builder: (_) => const MyOrdersScreen());
          case '/my-bookings':
            return MaterialPageRoute(builder: (_) => const MyBookingsScreen());
          case '/booking-lookup':
            return MaterialPageRoute(builder: (_) => const BookingLookupScreen());
          case '/my-trips':
            return MaterialPageRoute(builder: (_) => const MyTripsScreen());

          // Settings & Auth
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => SettingsScreen(
                onThemeChanged:
                    args?['onThemeChanged'] as ValueChanged<ThemeMode>?,
                themeMode: args?['themeMode'] as ThemeMode?,
              ),
            );
          case '/auth':
            return MaterialPageRoute(builder: (_) => const AuthScreen());

          // Notifications
          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            );

          // Fallback for owner orders with ID — redirect to web vendor portal
          default:
            if (settings.name != null &&
                settings.name!.startsWith('/owner/orders/')) {
              return MaterialPageRoute(
                builder: (_) {
                  final url = Uri.parse('https://hola.ehlom.com/vendor');
                  launchUrl(url, mode: LaunchMode.externalApplication);
                  return const Scaffold(
                    body: Center(child: Text('Opening vendor portal...')),
                  );
                },
              );
            }
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '404',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Page not found'),
                    ],
                  ),
                ),
              ),
            );
        }
      },
      home: SplashScreen(
        nextScreen: _InitScreen(
          onThemeChanged: _setThemeMode,
          themeMode: _themeMode,
        ),
      ),
    );
  }
}

class _InitScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode themeMode;

  const _InitScreen({required this.onThemeChanged, required this.themeMode});

  @override
  State<_InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<_InitScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final welcomeSeen = prefs.getBool('welcome_seen') ?? false;

    if (!mounted) return;

    if (!onboardingSeen) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            onThemeChanged: widget.onThemeChanged,
            themeMode: widget.themeMode,
          ),
        ),
      );
    } else if (!welcomeSeen) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(
            onThemeChanged: widget.onThemeChanged,
            themeMode: widget.themeMode,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            onThemeChanged: widget.onThemeChanged,
            themeMode: widget.themeMode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ThemeMode? themeMode;
  final LaunchConfig? launchConfig;

  const MainScreen({
    super.key,
    this.onThemeChanged,
    this.themeMode,
    this.launchConfig,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LaunchControlService.instance,
      builder: (context, _) => _buildWithConfig(
        widget.launchConfig ?? LaunchControlService.instance.config,
      ),
    );
  }

  Widget _buildWithConfig(LaunchConfig config) {
    final screens = <Widget>[
      const DiscoverScreen(),
      const SearchScreen(),
      const SizedBox.shrink(),
      const SavedScreen(),
      ProfileScreen(
        onThemeChanged: widget.onThemeChanged,
        themeMode: widget.themeMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111345).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildPillItem(0, Icons.explore_outlined, Icons.explore, 'Discover'),
                _buildPillItem(1, Icons.search_outlined, Icons.search, 'Nearby'),
                _buildCenterFAB(config),
                _buildPillItem(3, Icons.bookmark_border, Icons.bookmark, 'Saved'),
                _buildPillItem(4, Icons.person_outline, Icons.person, 'You'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? filledIcon : outlineIcon,
                size: 20,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFAB(LaunchConfig config) {
    return GestureDetector(
      onTap: () => _showQuickBookSheet(context, config),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF1a1421),
          size: 26,
          weight: 900,
        ),
      ),
    );
  }

  void _showQuickBookSheet(BuildContext context, LaunchConfig config) {
    final items = <Map<String, dynamic>>[];

    if (config.experience('appointment')) {
      items.add({
        'emoji': '✂️',
        'label': 'Salon',
        'category': 'salons',
      });
    }
    if (config.experience('stay')) {
      items.add({
        'emoji': '🏨',
        'label': 'Hotel',
        'category': 'hotels-lodges',
      });
    }
    if (config.world('book')) {
      items.add({
        'emoji': '⚽',
        'label': 'Turf',
        'category': 'football-turf',
      });
    }

    if (items.isEmpty) {
      items.addAll([
        {'emoji': '✂️', 'label': 'Salon', 'category': 'salons'},
        {'emoji': '🏨', 'label': 'Hotel', 'category': 'hotels-lodges'},
        {'emoji': '⚽', 'label': 'Turf', 'category': 'football-turf'},
      ]);
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick book',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like to book?',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
              ),
              const SizedBox(height: 18),
              ...items.map((item) => _buildQuickBookItem(
                    context,
                    item['emoji'] as String,
                    item['label'] as String,
                    item['category'] as String,
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBookItem(
    BuildContext context,
    String emoji,
    String label,
    String category,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExploreScreen(initialCategory: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
