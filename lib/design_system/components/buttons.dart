import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;

    final (backgroundColor, foregroundColor, borderColor) = switch (type) {
      AppButtonType.primary => (
        enabled
            ? AppColors.primary
            : (isDark
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.primary.withValues(alpha: 0.5)),
        AppColors.onPrimary,
        Colors.transparent,
      ),
      AppButtonType.secondary => (
        enabled
            ? AppColors.accent
            : (isDark
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.accent.withValues(alpha: 0.5)),
        AppColors.onPrimary,
        Colors.transparent,
      ),
      AppButtonType.outline => (
        Colors.transparent,
        enabled
            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
            : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
        enabled
            ? (isDark ? AppColors.darkOutline : AppColors.outline)
            : (isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant),
      ),
      AppButtonType.ghost => (
        Colors.transparent,
        enabled
            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
            : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
        Colors.transparent,
      ),
      AppButtonType.destructive => (
        enabled ? AppColors.error : AppColors.error.withValues(alpha: 0.5),
        AppColors.onPrimary,
        Colors.transparent,
      ),
    };

    final horizontalPadding = size == AppButtonSize.sm
        ? AppSpacing.md
        : AppSpacing.lg;
    final verticalPadding = size == AppButtonSize.sm
        ? AppSpacing.xs
        : AppSpacing.sm;
    final fontSize = size == AppButtonSize.sm ? 13.0 : 15.0;
    final iconSize = size == AppButtonSize.sm ? 16.0 : 18.0;
    final borderRadius = size == AppButtonSize.sm ? AppRadius.sm : AppRadius.md;
    final minHeight = size == AppButtonSize.sm ? 36.0 : 48.0;

    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else if (leadingIcon != null)
          Icon(leadingIcon, size: iconSize, color: foregroundColor),
        if (leadingIcon != null || isLoading)
          const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
              letterSpacing: 0.25,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(trailingIcon, size: iconSize, color: foregroundColor),
        ],
      ],
    );

    final button = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(borderRadius),
      child: isFullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final Color? customColor;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.type = AppButtonType.ghost,
    this.size = AppButtonSize.md,
    this.customColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final enabled = onPressed != null;

    final sizeValue = size == AppButtonSize.sm ? 36.0 : 44.0;
    final iconSize = size == AppButtonSize.sm ? 18.0 : 22.0;
    final color =
        customColor ??
        (enabled
            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
            : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary));

    Widget button = Container(
      width: sizeValue,
      height: sizeValue,
      decoration: BoxDecoration(
        color: type == AppButtonType.ghost
            ? Colors.transparent
            : (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: type == AppButtonType.outline
            ? Border.all(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
                width: 1.5,
              )
            : null,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: button,
    );
  }
}

class AppButtonGroup extends StatelessWidget {
  final List<AppButton> buttons;
  final MainAxisAlignment alignment;
  final double spacing;

  const AppButtonGroup({
    super.key,
    required this.buttons,
    this.alignment = MainAxisAlignment.center,
    this.spacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: buttons
          .expand(
            (button) => [
              button,
              if (button != buttons.last) SizedBox(width: spacing),
            ],
          )
          .toList(),
    );
  }
}

enum AppButtonType { primary, secondary, outline, ghost, destructive }

enum AppButtonSize { sm, md }
