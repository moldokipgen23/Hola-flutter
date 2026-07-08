import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';

class ClaimScreen extends StatefulWidget {
  final int businessId;
  final String businessName;

  const ClaimScreen({super.key, required this.businessId, required this.businessName});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _messageController = TextEditingController();
  bool loading = false;

  Future<void> _submit() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await api.post('/claims', body: {
        'business_id': widget.businessId,
        'message': _messageController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim submitted! We will review it soon.')),
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
      appBar: AppBar(title: const Text('Claim Business')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.businessName, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Why do you own this business?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Please provide proof of ownership. Our team will review your claim within 24-48 hours.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'I am the owner because...',
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
                    : const Text('Submit Claim'),
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
