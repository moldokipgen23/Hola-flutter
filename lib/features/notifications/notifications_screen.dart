import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/animations.dart';

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
          notifications = raw is Map && raw['data'] is List
              ? List<dynamic>.from(raw['data'])
              : (raw is List ? raw : []);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Failed to load notifications.';
        });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All marked as read')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'review':
        return Icons.star_rounded;
      case 'claim':
        return Icons.business_rounded;
      case 'message':
        return Icons.chat_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'system':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'review':
        return AppTheme.warning;
      case 'claim':
        return AppTheme.primary;
      case 'message':
        return AppTheme.success;
      case 'promo':
        return AppTheme.accent;
      case 'system':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (notifications.any((n) => n['read_at'] == null))
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : error != null
          ? _buildError()
          : notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, idx) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildNotificationCard(notifications[index], index),
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see updates about your businesses here',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isUnread = notification['read_at'] == null;
    final type = notification['type'] as String?;
    final icon = _getNotificationIcon(type);
    final color = _getNotificationColor(type);

    return FadeInSlide(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 50),
      child: ScaleOnTap(
        onTap: isUnread ? () => _markRead(notification['id']) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? color.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread ? color.withValues(alpha: 0.15) : AppTheme.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification['body'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification['body'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(notification['created_at']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
