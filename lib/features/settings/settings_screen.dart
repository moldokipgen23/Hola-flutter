import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api.dart';
import '../../services/localization.dart';
import '../../theme.dart';
import '../auth/auth_screen.dart';
import '../auth/email_verification_screen.dart';

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
  String? error;
  String currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDarkMode();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final lang = await AppLocalizations.getCurrentLanguage();
    if (mounted) setState(() => currentLang = lang);
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: AppLocalizations.languages.entries
            .map(
              (entry) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Row(
                  children: [
                    Icon(
                      entry.key == currentLang
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: entry.key == currentLang
                          ? AppTheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(entry.value, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && selected != currentLang) {
      await AppLocalizations.setLanguage(selected);
      setState(() => currentLang = selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language set to ${AppLocalizations.getNativeName(selected)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        error = 'Failed to load settings. Please try again.';
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : error != null && !loggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : !loggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Login to access settings',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ).then((_) => _loadProfile()),
                    child: const Text('Login'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        subtitle: Text(
                          AppLocalizations.getNativeName(currentLang),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showLanguagePicker,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email Verification'),
                        subtitle: Text(
                          user?['email_verified_at'] != null
                              ? 'Verified'
                              : 'Not verified',
                        ),
                        trailing: user?['email_verified_at'] != null
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                              )
                            : TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmailVerificationScreen(
                                      email: user?['email'] ?? '',
                                    ),
                                  ),
                                ),
                                child: const Text('Verify'),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
    );
  }
}
