import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/animations.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Map<String, dynamic>> reports = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });
      final result = await api.get('/reports/mine');
      setState(() {
        reports =
            (result['reports'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'wrong_contact':
        return Icons.phone;
      case 'wrong_location':
        return Icons.location_on;
      case 'duplicate':
        return Icons.copy;
      case 'other':
        return Icons.flag;
      default:
        return Icons.report;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'wrong_contact':
        return 'Wrong Contact';
      case 'wrong_location':
        return 'Wrong Location';
      case 'duplicate':
        return 'Duplicate';
      case 'other':
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'wrong_contact':
        return const Color(0xFFEF4444);
      case 'wrong_location':
        return const Color(0xFFF97316);
      case 'duplicate':
        return const Color(0xFF8B5CF6);
      case 'other':
        return const Color(0xFF64748B);
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'resolved':
        return AppTheme.success;
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'resolved':
        return 'Resolved';
      case 'pending':
        return 'Pending';
      default:
        return status ?? 'Unknown';
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
          'My Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load reports',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadReports,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your submitted reports will appear here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final r = reports[index];
                  final business = r['business'] as Map<String, dynamic>?;
                  final type = r['type'] as String?;
                  final status = r['status'] as String?;
                  final createdAt = r['created_at'] as String?;
                  return FadeInSlide(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: index * 80),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _typeColor(
                                      type,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _typeIcon(type),
                                    color: _typeColor(type),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _typeLabel(type),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        business?['name']?.toString() ??
                                            'Unknown business',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (r['message'] != null &&
                                (r['message'] as String).isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                r['message'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                createdAt,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
