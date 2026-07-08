import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import 'conversations_screen.dart';

class _DashboardData {
  final int totalViews;
  final int totalCalls;
  final int totalWhatsapps;
  final int totalDirections;
  final List<Business> businesses;
  final List<dynamic> recentConversations;

  _DashboardData({
    required this.totalViews,
    required this.totalCalls,
    required this.totalWhatsapps,
    required this.totalDirections,
    this.businesses = const [],
    this.recentConversations = const [],
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) {
    return _DashboardData(
      totalViews: json['total_views'] ?? 0,
      totalCalls: json['total_calls'] ?? 0,
      totalWhatsapps: json['total_whatsapps'] ?? 0,
      totalDirections: json['total_directions'] ?? 0,
      businesses: (json['businesses'] as List?)?.map((b) => Business.fromJson(b)).toList() ?? [],
      recentConversations: json['recent_conversations'] ?? [],
    );
  }
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  _DashboardData? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { loading = true; error = null; });
      final result = await api.get('/owner/dashboard');
      if (mounted) {
        setState(() {
          data = _DashboardData.fromJson(result);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('Failed to load dashboard', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard(Icons.visibility, 'Views', data!.totalViews, AppTheme.primary),
                          _buildStatCard(Icons.call, 'Calls', data!.totalCalls, AppTheme.success),
                          _buildStatCard(Icons.chat, 'WhatsApp', data!.totalWhatsapps, const Color(0xFF25D366)),
                          _buildStatCard(Icons.directions, 'Directions', data!.totalDirections, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Your Businesses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (data!.businesses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No businesses yet', style: TextStyle(color: Colors.grey[500]))),
                        )
                      else
                        ...data!.businesses.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: const Text('🏪', style: TextStyle(fontSize: 20)),
                            ),
                            title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'Reviews: ${b.qualityScore} | Reports: 0',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ),
                        )),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const ConversationsScreen(),
                          ));
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                const Text(
                                  'Recent Conversations',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
