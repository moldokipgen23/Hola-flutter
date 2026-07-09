import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';

class ReportScreen extends StatefulWidget {
  final Business business;

  const ReportScreen({super.key, required this.business});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedType = 'wrong_contact';
  final _messageController = TextEditingController();
  bool loading = false;

  final _reportTypes = [
    {'value': 'wrong_contact', 'label': 'Wrong contact details'},
    {'value': 'wrong_location', 'label': 'Wrong map location'},
    {'value': 'duplicate', 'label': 'Duplicate listing'},
    {'value': 'closed', 'label': 'Business closed'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _submit() async {
    setState(() => loading = true);

    try {
      await api.post('/reports', body: {
        'business_id': widget.business.id,
        'type': _selectedType,
        'message': _messageController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.business.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('What is the issue?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
              child: Column(
                children: _reportTypes.map((type) => ListTile(
                  title: Text(type['label']!),
                  leading: Radio<String>(
                    value: type['value']!,
                    activeColor: AppTheme.primary,
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => setState(() => _selectedType = type['value']!),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Additional details (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Provide any extra info...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
