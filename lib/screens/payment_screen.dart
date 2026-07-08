import 'package:flutter/material.dart';
import '../theme.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promote Your Business')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Get more visibility and grow your business',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _PricingCard(
              title: '1 Month',
              price: '₹499',
              badge: null,
              features: const [
                'Featured business badge',
                'Priority in search results',
                'Appears on homepage',
                'Basic analytics',
              ],
              onSubscribe: () => _showComingSoon(context),
            ),
            const SizedBox(height: 16),
            _PricingCard(
              title: '3 Months',
              price: '₹1,299',
              badge: 'Save 13%',
              features: const [
                'Featured business badge',
                'Priority in search results',
                'Appears on homepage',
                'Advanced analytics',
                'Social media promotion',
              ],
              onSubscribe: () => _showComingSoon(context),
            ),
            const SizedBox(height: 16),
            _PricingCard(
              title: '6 Months',
              price: '₹2,199',
              badge: 'Save 27%',
              features: const [
                'Featured business badge',
                'Priority in search results',
                'Appears on homepage',
                'Advanced analytics',
                'Social media promotion',
                'Dedicated support',
              ],
              onSubscribe: () => _showComingSoon(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final List<String> features;
  final VoidCallback onSubscribe;

  const _PricingCard({
    required this.title,
    required this.price,
    this.badge,
    required this.features,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              price,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 20, color: AppTheme.success),
                  const SizedBox(width: 12),
                  Text(feature, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onSubscribe,
                child: const Text('Subscribe', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
