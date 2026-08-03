import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../design_system/components/buttons.dart';
import '../../design_system/components/cards.dart';
import '../../design_system/components/animations.dart';
import '../../design_system/components/skeletons.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'date_time_screen.dart';

class StaffSelectionScreen extends StatefulWidget {
  final int businessId;
  final String businessSlug;
  final List<Service> services;
  final String? selectedServiceId;

  const StaffSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessSlug,
    required this.services,
    this.selectedServiceId,
  });

  @override
  State<StaffSelectionScreen> createState() => _StaffSelectionScreenState();
}

class _StaffSelectionScreenState extends State<StaffSelectionScreen> {
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await api.get('/businesses/${widget.businessSlug}/staff');
      if (!mounted) return;

      final staffList = (res['staff'] as List?) ?? [];
      setState(() {
        _staff = staffList.cast<Map<String, dynamic>>();
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

  void _selectStaff(Map<String, dynamic>? staff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DateTimeScreen(
          businessId: widget.businessId,
          businessSlug: widget.businessSlug,
          staffId: staff?['id']?.toString(),
          serviceId: widget.selectedServiceId,
          services: widget.services,
          staffName: staff?['name'],
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
          'Select Staff',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingState(isDark)
          : _error != null
          ? _buildErrorState(isDark)
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                FadeInWidget(child: _buildAnyAvailableOption(isDark)),
                const SizedBox(height: AppSpacing.sm),
                if (_staff.isEmpty)
                  _buildEmptyState(isDark)
                else
                  StaggeredAnimationList(
                    children: _staff
                        .map((staff) => _buildStaffCard(isDark, staff))
                        .toList(),
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
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: SkeletonBox(height: 72, borderRadius: 12),
        ),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const SkeletonCircle(size: 52),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 120, height: 16),
                      SizedBox(height: 4),
                      SkeletonBox(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
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
              'Failed to load staff',
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
              onPressed: _loadStaff,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No specific staff listed',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose "Any available" to proceed.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnyAvailableOption(bool isDark) {
    return AppCard(
      onTap: () => _selectStaff(null),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.experienceAppointment.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              color: AppColors.experienceAppointment,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Any available staff',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Let the business assign the best available staff',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(bool isDark, Map<String, dynamic> staff) {
    final name = staff['name']?.toString() ?? 'Staff';
    final photo = staff['photo']?.toString();
    final specialties = staff['specialties'] as List?;
    final rating = staff['average_rating']?.toDouble();
    final reviewCount = staff['review_count'] ?? 0;
    final photoUrl = photo != null ? ApiClient.imageUrl(photo) : '';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () => _selectStaff(staff),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              width: 52,
              height: 52,
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _buildAvatarPlaceholder(name, isDark),
                    )
                  : _buildAvatarPlaceholder(name, isDark),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                if (specialties != null && specialties.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (specialties).take(3).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.experienceAppointment.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          s.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.experienceAppointment,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rating != null && rating > 0) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '($reviewCount)',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
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
    );
  }

  Widget _buildAvatarPlaceholder(String name, bool isDark) {
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    return Container(
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      child: Center(
        child: Text(
          initials,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.experienceAppointment,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
