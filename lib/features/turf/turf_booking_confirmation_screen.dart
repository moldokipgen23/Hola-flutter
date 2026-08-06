import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../features/home/home_screen.dart';

class TurfBookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String venueName;
  final String courtName;
  final DateTime date;
  final String time;
  final int duration;
  final int participants;
  final double totalPrice;
  final String customerName;

  const TurfBookingConfirmationScreen({
    super.key,
    required this.bookingData,
    required this.venueName,
    required this.courtName,
    required this.date,
    required this.time,
    required this.duration,
    required this.participants,
    required this.totalPrice,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final bookingRef =
        bookingData['reference']?.toString() ??
        bookingData['id']?.toString() ??
        'N/A';
    final status = bookingData['status'] as String? ?? 'pending';
    final isRequestMode =
        bookingData['availability_mode'] == 'request' || status == 'pending';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const SuccessCheckmark(size: 100, color: AppColors.success),
              const SizedBox(height: AppSpacing.lg),
              FadeInWidget(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    Text(
                      'Booking Confirmed!',
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Thank you, $customerName',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (isRequestMode) ...[
                const SizedBox(height: AppSpacing.md),
                SlideInWidget(
                  delay: const Duration(milliseconds: 500),
                  child: _buildRequestNotice(isDark),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SlideInWidget(
                delay: const Duration(milliseconds: 600),
                child: _buildBookingDetailsCard(
                  bookingRef,
                  isRequestMode,
                  isDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SlideInWidget(
                delay: const Duration(milliseconds: 700),
                child: _buildActionButtons(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your booking is awaiting confirmation from the venue. You will be notified once confirmed.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard(String ref, bool isRequestMode, bool isDark) {
    final startTime = _parseTime(time);
    final endMinutes = startTime.hour * 60 + startTime.minute + duration;
    final endTime = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Details',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isRequestMode
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isRequestMode ? 'Awaiting Confirmation' : 'Confirmed',
                  style: AppTypography.labelSmall.copyWith(
                    color: isRequestMode
                        ? AppColors.warning
                        : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Reference', value: ref, isCopyable: true),
          const Divider(height: AppSpacing.md),
          _DetailRow(label: 'Venue', value: venueName),
          if (courtName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(label: 'Court', value: courtName),
          ],
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Date', value: _formatDisplayDate(date)),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Time', value: '$startTime - $endTime'),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Duration', value: '$duration minutes'),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Participants', value: '$participants'),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${totalPrice.toInt()}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.experienceTurf,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Call Venue',
                onPressed: () async {
                  final phone = bookingData['business']?['phone']?.toString() ??
                      bookingData['business_phone']?.toString() ?? '';
                  if (phone.isEmpty) return;
                  final uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                leadingIcon: Icons.call_outlined,
                type: AppButtonType.outline,
                isFullWidth: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'WhatsApp',
                onPressed: () async {
                  final phone = bookingData['business']?['whatsapp']?.toString() ??
                      bookingData['business']?['phone']?.toString() ?? '';
                  if (phone.isEmpty) return;
                  final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                  final uri = Uri.parse('https://wa.me/$cleaned');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                leadingIcon: Icons.chat_outlined,
                type: AppButtonType.outline,
                isFullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'View in Activity',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          leadingIcon: Icons.receipt_long_outlined,
          type: AppButtonType.outline,
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Back to Home',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
          isFullWidth: true,
        ),
      ],
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
