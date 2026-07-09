import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
import 'owner_dashboard_screen.dart';
import 'saved_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ThemeMode? themeMode;

  const ProfileScreen({super.key, this.onThemeChanged, this.themeMode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final hasToken = await api.hasToken();
      if (!hasToken) {
        setState(() {
          loggedIn = false;
          loading = false;
        });
        return;
      }

      final result = await api.get('/auth/profile');
      setState(() {
        user = result['user'];
        loggedIn = true;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loggedIn = false;
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await api.post('/auth/logout');
    } catch (e) {
      // Logout may fail on server side, but we still clear local token
    }
    await api.setToken(null);
    setState(() {
      user = null;
      loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            )),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : !loggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Login to view your profile', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        )).then((_) => _loadProfile()),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          _initial(user?['name']),
                          style: const TextStyle(fontSize: 32, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user?['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user?['email'] ?? '', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 32),
                      _buildMenuItem(Icons.dashboard, 'Owner Dashboard', () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const OwnerDashboardScreen(),
                        ));
                      }),
                      _buildMenuItem(Icons.chat, 'Messages', () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ConversationsScreen(),
                        ));
                      }),
                      _buildMenuItem(Icons.notifications, 'Notifications', () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ));
                      }),
                      _buildMenuItem(Icons.bookmark, 'My Saved', () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SavedScreen(),
                        ));
                      }),
                      _buildMenuItem(Icons.business, 'My Claims', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Claims feature coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }),
                      _buildMenuItem(Icons.report, 'My Reports', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reports feature coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }),
                      _buildMenuItem(Icons.settings, 'Settings', () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            onThemeChanged: widget.onThemeChanged,
                            themeMode: widget.themeMode,
                          ),
                        ));
                      }),
                      _buildMenuItem(Icons.help, 'Help', () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Help & Support'),
                            content: const Text('For any questions or issues, please contact us at support@hola.app'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _initial(String? name) {
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
