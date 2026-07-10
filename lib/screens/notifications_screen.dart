import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await api.get('/notifications');
      if (mounted) {
        setState(() {
          final raw = result['notifications'];
          // Backend returns a Laravel paginator: { data: [...], ... }
          notifications = raw is Map && raw['data'] is List
              ? List<dynamic>.from(raw['data'])
              : (raw is List ? raw : []);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { loading = false; error = 'Failed to load notifications.'; });
      }
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await api.post('/notifications/$id/read');
      setState(() {
        final idx = notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          notifications[idx]['read_at'] = DateTime.now().toIso8601String();
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await api.post('/notifications/read-all');
      setState(() {
        for (final n in notifications) {
          n['read_at'] = DateTime.now().toIso8601String();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => n['read_at'] == null))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: AppTheme.primary)),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadNotifications, child: const Text('Retry')),
                    ],
                  ),
                )
              : notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final isUnread = n['read_at'] == null;
                      return Card(
                        child: ListTile(
                          leading: isUnread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          title: Text(n['title'] ?? '', style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n['body'] != null) Text(n['body'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_timeAgo(n['created_at']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          onTap: isUnread ? () => _markRead(n['id']) : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
