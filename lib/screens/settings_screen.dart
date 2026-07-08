import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'email_verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ThemeMode? themeMode;

  const SettingsScreen({super.key, this.onThemeChanged, this.themeMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool loggedIn = false;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDarkMode();
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

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    if (!mounted) return;
    setState(() => darkMode = isDark);
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => darkMode = value);
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(value ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {}
    await api.setToken(null);
    setState(() {
      user = null;
      loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : !loggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Login to access settings', style: TextStyle(color: Colors.grey)),
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Toggle dark theme'),
                            secondary: const Icon(Icons.dark_mode),
                            value: darkMode,
                            activeThumbColor: AppTheme.primary,
                            onChanged: _toggleDarkMode,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('Language'),
                            subtitle: const Text('English'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coming soon'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email Verification'),
                            subtitle: Text(
                              user?['email_verified_at'] != null ? 'Verified' : 'Not verified',
                            ),
                            trailing: user?['email_verified_at'] != null
                                ? const Icon(Icons.check_circle, color: AppTheme.success)
                                : TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => EmailVerificationScreen(email: user?['email'] ?? ''),
                                    )),
                                    child: const Text('Verify'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('App Version'),
                            subtitle: Text('1.0.0'),
                          ),
                        ],
                      ),
                    ),
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
    );
  }
}
