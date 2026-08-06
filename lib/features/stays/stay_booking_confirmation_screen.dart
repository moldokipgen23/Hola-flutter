import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';

class StayBookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String businessName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final List<Map<String, dynamic>> selectedRooms;
  final int adults;
  final int children;
  final double totalPrice;
  final String customerName;

  const StayBookingConfirmationScreen({
    super.key,
    required this.bookingData,
    required this.businessName,
    this.checkIn,
    this.checkOut,
    required this.nights,
    required this.selectedRooms,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.customerName,
  });

  @override
  State<StayBookingConfirmationScreen> createState() =>
      _StayBookingConfirmationScreenState();
}

class _StayBookingConfirmationScreenState
    extends State<StayBookingConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final bookingRef =
        widget.bookingData['reference']?.toString() ??
        widget.bookingData['id']?.toString() ??
        'N/A';
    final status = widget.bookingData['status'] as String? ?? 'pending';
    final isRequestMode =
        widget.bookingData['availability_mode'] == 'request' ||
        status == 'pending';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              _buildSuccessAnimation(),
              const SizedBox(height: AppSpacing.lg),
              _buildConfirmationTitle(isDark),
              if (isRequestMode) ...[
                const SizedBox(height: AppSpacing.md),
                _buildRequestNotice(isDark),
              ],
              const SizedBox(height: AppSpacing.lg),
              SlideInWidget(
                delay: const Duration(milliseconds: 400),
                child: _buildBookingDetailsCard(
                  bookingRef,
                  isRequestMode,
                  isDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SlideInWidget(
                delay: const Duration(milliseconds: 500),
                child: _buildActionButtons(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return const SuccessCheckmark();
  }

  Widget _buildConfirmationTitle(bool isDark) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Text(
            'Booking Confirmed!',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Thank you, ${widget.customerName}',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              'Your booking is awaiting confirmation from the property. You will be notified once confirmed.',
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
          _DetailRow(label: 'Property', value: widget.businessName),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Check-in',
            value: _formatDisplayDate(widget.checkIn),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Check-out',
            value: _formatDisplayDate(widget.checkOut),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Duration',
            value: '${widget.nights} night${widget.nights > 1 ? 's' : ''}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Guests',
            value:
                '${widget.adults} adults${widget.children > 0 ? ', ${widget.children} children' : ''}',
          ),
          const Divider(height: AppSpacing.md),
          Text(
            'Rooms',
            style: AppTypography.labelMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...widget.selectedRooms.map((room) {
            final name = room['name'] as String? ?? 'Room';
            final quantity = room['quantity'] as int? ?? 1;
            final price = (room['price'] as num? ?? 0).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$name × $quantity',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹$price/night',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
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
                '₹${widget.totalPrice.toInt()}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.experienceStay,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        AppButton(
          label: 'Get Directions',
          onPressed: () {},
          leadingIcon: Icons.directions_outlined,
          type: AppButtonType.outline,
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Call Property',
                onPressed: () async {
                  final phone = widget.bookingData['business']?['phone']?.toString() ??
                      widget.bookingData['business_phone']?.toString() ?? '';
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
                  final phone = widget.bookingData['business']?['whatsapp']?.toString() ??
                      widget.bookingData['business']?['phone']?.toString() ?? '';
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
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          isFullWidth: true,
        ),
      ],
    );
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'N/A';
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
