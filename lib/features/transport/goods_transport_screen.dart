import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/form_fields.dart';
import '../../design_system/components/animations.dart';
import '../../services/api.dart';

class GoodsTransportScreen extends StatefulWidget {
  const GoodsTransportScreen({super.key});

  @override
  State<GoodsTransportScreen> createState() => _GoodsTransportScreenState();
}

class _GoodsTransportScreenState extends State<GoodsTransportScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _weightCategory = 'medium';
  bool _isSubmitting = false;
  String? _submittedRef;
  bool _hasQuote = false;

  final _weightOptions = [
    {
      'key': 'light',
      'label': 'Light',
      'desc': 'Up to 50 kg',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'key': 'medium',
      'label': 'Medium',
      'desc': '50-200 kg',
      'icon': Icons.inventory_outlined,
    },
    {
      'key': 'heavy',
      'label': 'Heavy',
      'desc': '200+ kg',
      'icon': Icons.local_shipping_outlined,
    },
  ];

  String get _suggestedVehicle {
    switch (_weightCategory) {
      case 'light':
        return 'Bike, Auto, or Pickup';
      case 'medium':
        return 'Pickup, Tempo, or Van';
      case 'heavy':
        return 'Truck or Large Tempo';
      default:
        return 'Any vehicle';
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitQuoteRequest() async {
    if (_pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup location')),
      );
      return;
    }
    if (_dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter drop-off location')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the goods')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and phone')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final weightKg = _weightCategory == 'light'
          ? 25.0
          : _weightCategory == 'heavy'
          ? 300.0
          : 100.0;

      final response = await api.post(
        '/bookings',
        body: {
          'booking_type': 'goods_transport',
          'customer_name': _nameController.text.trim(),
          'customer_phone': _phoneController.text.trim(),
          'pickup_location': _pickupController.text.trim(),
          'drop_location': _dropoffController.text.trim(),
          'load_description': _descriptionController.text.trim(),
          'load_weight': weightKg,
          'weight_category': _weightCategory,
          'notes': _weightController.text.trim().isEmpty
              ? null
              : _weightController.text.trim(),
        },
      );

      if (!mounted) return;

      final ref = response is Map
          ? (response['id'] ??
                response['booking']?['id']?.toString() ??
                'PENDING')
          : 'PENDING';
      setState(() {
        _submittedRef = ref.toString();
        _isSubmitting = false;
        _hasQuote = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    if (_hasQuote) {
      return _buildQuoteStatus(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Goods transport',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  SlideInWidget(child: _buildLocationInputs(isDark)),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildGoodsDescription(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildWeightSelector(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _buildVehicleSuggestion(isDark),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: _buildContactForm(isDark),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
          _buildSubmitButton(isDark),
        ],
      ),
    );
  }

  Widget _buildLocationInputs(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppTextField(
            controller: _pickupController,
            prefixIcon: Icons.circle,
            prefix: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            hint: 'Pickup location',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: AppSpacing.md + 4),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          AppTextField(
            controller: _dropoffController,
            prefixIcon: Icons.circle_outlined,
            prefix: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 2),
                ),
              ),
            ),
            hint: 'Drop-off location',
          ),
        ],
      ),
    );
  }

  Widget _buildGoodsDescription(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are you shipping?',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _descriptionController,
          hint: 'Describe your goods (e.g., furniture, boxes, electronics)',
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Add photo (optional)',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo upload coming soon')),
            );
          },
          type: AppButtonType.outline,
          size: AppButtonSize.sm,
          leadingIcon: Icons.camera_alt_rounded,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildWeightSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight category',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _weightOptions.map((opt) {
            final isSelected = _weightCategory == opt['key'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _weightCategory = opt['key'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.experienceGoodsTransport.withValues(
                              alpha: 0.1,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.experienceGoodsTransport
                            : (isDark
                                  ? AppColors.darkOutline
                                  : AppColors.outline),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.experienceGoodsTransport
                              : (isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          opt['label'] as String,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.experienceGoodsTransport
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          opt['desc'] as String,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _weightController,
          prefixIcon: Icons.scale_outlined,
          hint: 'Approximate weight in kg (optional)',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildVehicleSuggestion(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.experienceGoodsTransport.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.experienceGoodsTransport,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested vehicle',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _suggestedVehicle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your details',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                hint: 'Full name',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                hint: 'Phone number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
      ),
      child: AppButton(
        label: _isSubmitting ? 'Requesting quote...' : 'Request quote',
        onPressed: _isSubmitting ? null : _submitQuoteRequest,
        isLoading: _isSubmitting,
        isFullWidth: true,
        leadingIcon: Icons.request_quote_rounded,
      ),
    );
  }

  Widget _buildQuoteStatus(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quote requested',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.experienceGoodsTransport.withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.experienceGoodsTransport,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quote requested!',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_submittedRef != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.experienceGoodsTransport.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Ref: $_submittedRef',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.experienceGoodsTransport,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuoteDetailRow(
                      label: 'From',
                      value: _pickupController.text.trim(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuoteDetailRow(
                      label: 'To',
                      value: _dropoffController.text.trim(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuoteDetailRow(
                      label: 'Goods',
                      value: _descriptionController.text.trim(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuoteDetailRow(
                      label: 'Weight',
                      value:
                          _weightCategory[0].toUpperCase() +
                          _weightCategory.substring(1),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Operators will review your request and send you a quote. You will be notified via SMS or call.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Done',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                isFullWidth: true,
                type: AppButtonType.ghost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _QuoteDetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
