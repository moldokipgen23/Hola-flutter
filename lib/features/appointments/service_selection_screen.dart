import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'staff_selection_screen.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final String slug;

  const ServiceSelectionScreen({super.key, required this.slug});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  Business? _business;
  List<Service> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final businessRes = await api.get('/businesses/${widget.slug}');
      final servicesRes = await api.get('/businesses/${widget.slug}/services');

      if (!mounted) return;

      final business = Business.fromJson(
        businessRes['business'] ?? businessRes,
      );
      final servicesList =
          (servicesRes['services'] as List?)
              ?.map((s) => Service.fromJson(s))
              .where((s) => s.isActive)
              .toList() ??
          [];

      setState(() {
        _business = business;
        _services = servicesList;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _selectService(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffSelectionScreen(
          businessId: _business!.id,
          businessSlug: widget.slug,
          services: _services,
          selectedServiceId: service.id.toString(),
        ),
      ),
    );
  }

  void _selectAnyStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffSelectionScreen(
          businessId: _business!.id,
          businessSlug: widget.slug,
          services: _services,
          selectedServiceId: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Service',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingState(isDark)
          : _error != null
          ? _buildErrorState(isDark)
          : _services.isEmpty
          ? _buildEmptyState(isDark)
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                if (_business != null) ...[
                  FadeInWidget(child: _buildBusinessHeader(isDark)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Available Services',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StaggeredAnimationList(
                  children: [
                    _buildAnyStaffOption(isDark),
                    const SizedBox(height: AppSpacing.sm),
                    ..._services.map(
                      (service) => _buildServiceCard(isDark, service),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        SkeletonBox(height: 100, borderRadius: AppRadius.md),
        const SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 180, height: 20),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: SkeletonBox(height: 72, borderRadius: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load services',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              onPressed: _loadData,
              type: AppButtonType.outline,
              trailingIcon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 48,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No services available',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check back later for available services.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeader(bool isDark) {
    final business = _business!;
    final photoUrl = business.photos.isNotEmpty
        ? ApiClient.imageUrl(business.photos.first)
        : '';

    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 72,
              height: 72,
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _buildBusinessPlaceholder(isDark),
                    )
                  : _buildBusinessPlaceholder(isDark),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (business.averageRating > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${business.averageRating.toStringAsFixed(1)} (${business.reviewCount})',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (business.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business.address!,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      child: Icon(
        Icons.store_rounded,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        size: 32,
      ),
    );
  }

  Widget _buildAnyStaffOption(bool isDark) {
    return RippleEffect(
      onTap: _selectAnyStaff,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        onTap: _selectAnyStaff,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.experienceAppointment.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                color: AppColors.experienceAppointment,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Any available staff',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(bool isDark, Service service) {
    return RippleEffect(
      onTap: () => _selectService(service),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        onTap: () => _selectService(service),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.experienceAppointment.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.medical_services_outlined,
                color: AppColors.experienceAppointment,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.duration} min',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '₹${service.price.toStringAsFixed(0)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.experienceAppointment,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
