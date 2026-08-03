import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notifications/notifications_screen.dart';
import '../auth/auth_screen.dart';
import '../../design_system/components/toast.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/booking_service.dart';
import '../../services/trip_service.dart';
import '../../services/saved_service.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ThemeMode? themeMode;

  const ProfileScreen({super.key, this.onThemeChanged, this.themeMode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _isLoggedIn = false;
  User? _user;
  int _activeOrders = 0;
  int _upcomingBookings = 0;
  int _recentTrips = 0;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _loading = false;
          });
        }
        return;
      }

      final profileData = await AuthService.profile();
      User? user;
      if (profileData.isNotEmpty) {
        final data = profileData['data'];
        if (data is Map<String, dynamic>) {
          user = User.fromJson(data);
        } else {
          user = User.fromJson(profileData);
        }
      }

      final results = await Future.wait([
        OrderService.myOrders(),
        BookingService.myBookings(),
        TripService.myTrips(),
        SavedService.list(),
      ]);

      final orders = results[0] as List;
      final bookings = results[1] as List;
      final trips = results[2] as List;
      final saved = results[3] as List;

      final activeStatuses = {'pending', 'confirmed', 'preparing'};
      final activeOrders = orders
          .where((o) => activeStatuses.contains(o.status))
          .length;

      final now = DateTime.now();
      final upcomingBookings = bookings.where((b) {
        return b.bookingDate.isAfter(now);
      }).length;

      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _user = user;
          _activeOrders = activeOrders;
          _upcomingBookings = upcomingBookings;
          _recentTrips = trips.length;
          _savedCount = saved.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                'Profile, activity and settings',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => ToastHelper.show(context, 'Settings coming soon'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('⚙️', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF474E75)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileCard(context),
        const SizedBox(height: 20),
        const Text(
          'Your activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 11),
        _buildActivityGrid(context),
        const SizedBox(height: 20),
        _buildMenu(context),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final String initial;
    final String name;
    final String subtitle;

    if (_isLoggedIn && _user != null) {
      initial = _user!.initials;
      name = _user!.name;
      subtitle = 'Customer account · Lamka';
    } else {
      initial = 'G';
      name = 'Guest';
      subtitle = 'Tap to login';
    }

    return GestureDetector(
      onTap: _isLoggedIn
          ? null
          : () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
              _loadData();
            },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF252B45), Color(0xFF474E75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(27),
        ),
        child: Row(
          children: [
            Container(
              width: 61,
              height: 61,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFAD7D), Color(0xFFFF7043)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0B8C9),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isLoggedIn)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB0B8C9),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid(BuildContext context) {
    final String ordersSubtitle;
    final String bookingsSubtitle;
    final String ridesSubtitle;
    final String savedSubtitle;

    if (_isLoggedIn) {
      ordersSubtitle = _activeOrders > 0
          ? '$_activeOrders active'
          : 'No active';
      bookingsSubtitle = _upcomingBookings > 0
          ? '$_upcomingBookings upcoming'
          : 'No upcoming';
      ridesSubtitle = _recentTrips > 0
          ? '$_recentTrips recent'
          : 'No trips yet';
      savedSubtitle = _savedCount > 0 ? '$_savedCount listings' : 'No saved';
    } else {
      ordersSubtitle = 'Login to view';
      bookingsSubtitle = 'Login to view';
      ridesSubtitle = 'Login to view';
      savedSubtitle = 'Login to view';
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 11,
      crossAxisSpacing: 11,
      childAspectRatio: 1.6,
      children: [
        _buildActivityCard(context, '📦', 'Orders', ordersSubtitle),
        _buildActivityCard(context, '📅', 'Bookings', bookingsSubtitle),
        _buildActivityCard(context, '🚕', 'Rides', ridesSubtitle),
        _buildActivityCard(context, '❤️', 'Saved', savedSubtitle),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
  ) {
    return GestureDetector(
      onTap: () {
        if (!_isLoggedIn) {
          _navigateToLogin(context);
          return;
        }
        ToastHelper.show(context, '$title coming soon');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            '📍',
            'Addresses',
            null,
            () => ToastHelper.show(context, 'Opening addresses'),
          ),
          _buildMenuItem(context, '🔔', 'Notifications', null, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          }),
          _buildMenuItem(
            context,
            '🏪',
            'Claim a business',
            null,
            () => ToastHelper.show(context, 'Opening claim form'),
          ),
          _buildMenuItem(
            context,
            '➕',
            'Register a business',
            null,
            () => ToastHelper.show(context, 'Opening registration'),
          ),
          _buildMenuItem(
            context,
            '🌐',
            'Language',
            'English',
            () => ToastHelper.show(context, 'Language selector coming soon'),
          ),
          _buildMenuItem(context, '❓', 'Help & support', null, () async {
            final url = Uri.parse('mailto:support@hola.ehlom.com');
            if (await canLaunchUrl(url)) await launchUrl(url);
          }),
          if (_isLoggedIn)
            _buildMenuItem(context, '🚪', 'Logout', null, () async {
              await AuthService.logout();
              await AuthService.clearToken();
              if (context.mounted) {
                ToastHelper.show(context, 'Logged out');
                _loadData();
              }
            }, isLast: true)
          else
            _buildMenuItem(
              context,
              '🔑',
              'Login',
              null,
              () => _navigateToLogin(context),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String emoji,
    String title,
    String? trailing,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
              ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F7),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
              )
            else
              Text(
                '›',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
    _loadData();
  }
}
