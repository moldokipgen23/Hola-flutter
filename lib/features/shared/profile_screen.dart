import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../auth/auth_screen.dart';
import '../../design_system/components/toast.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
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
  int _upcomingBookings = 0;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

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
        BookingService.myBookings(),
        SavedService.list(),
      ]);

      final bookings = results[0] as List;
      final saved = results[1] as List;

      final now = DateTime.now();
      final upcomingBookings = bookings.where((b) {
        return b.bookingDate.isAfter(now);
      }).length;

      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _user = user;
          _upcomingBookings = upcomingBookings;
          _savedCount = saved.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildAccountSection(),
                  const SizedBox(height: 20),
                  _buildSupportSection(),
                  const SizedBox(height: 20),
                  _buildLegalSection(),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Eiho One · v0.1 prototype',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
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
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
              _loadData();
            },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF141846).withValues(alpha: 0.24),
              blurRadius: 80,
              offset: const Offset(0, 32),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1a1421),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'SILVER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildStatTile('$_upcomingBookings', 'Bookings'),
                const SizedBox(width: 10),
                _buildStatTile('$_savedCount', 'Saved'),
                const SizedBox(width: 10),
                _buildStatTile('₹0', 'Wallet'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACCOUNT',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            letterSpacing: 0.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _buildMenuItem('📅', 'My bookings', () {
                Navigator.pushNamed(context, '/my-bookings');
              }),
              _buildMenuItem('💳', 'Payments & wallet', () {
                ToastHelper.show(context, 'Payments coming soon');
              }),
              _buildMenuItem('🎁', 'Rewards & offers', () {
                ToastHelper.show(context, 'Rewards coming soon');
              }),
              _buildMenuItem('🏪', 'List your business', () {
                ToastHelper.show(context, 'Business registration coming soon');
              }, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUPPORT',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            letterSpacing: 0.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _buildMenuItem('❓', 'Help center', () async {
                final url = Uri.parse('mailto:support@ehlom.com');
                if (await canLaunchUrl(url)) await launchUrl(url);
              }),
              _buildMenuItem('✉️', 'Contact support', () async {
                final url = Uri.parse('mailto:support@ehlom.com');
                if (await canLaunchUrl(url)) await launchUrl(url);
              }, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEGAL',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            letterSpacing: 0.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _buildMenuItem('🔒', 'Privacy Policy', () {
                ToastHelper.show(context, 'Privacy policy coming soon');
              }),
              _buildMenuItem('📄', 'Terms of Service', () {
                ToastHelper.show(context, 'Terms of service coming soon');
              }),
              _buildMenuItem('🗑', 'Delete account', () {
                _showDeleteAccountSheet();
              }, isLast: true, isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    String emoji,
    String title,
    VoidCallback onTap, {
    bool isLast = false,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFfdeceb)
                    : AppColors.soft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDestructive ? const Color(0xFFc0392b) : null,
                ),
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountSheet() {
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
                'Delete your account?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFc0392b),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This permanently removes your profile, saved places and booking history. Vendors may still keep records of past bookings for tax purposes as required by law.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ToastHelper.show(context, 'Account deletion requested');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFc0392b),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Center(
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
