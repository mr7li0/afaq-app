import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';

/// iOS-style capsule / stadium-shaped button.
/// Used for toggles, quick actions, and input-style elements.
class CapsuleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isSmall;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsetsGeometry? padding;

  const CapsuleButton({
    super.key,
    required this.child,
    this.onTap,
    this.isActive = false,
    this.isSmall = false,
    this.activeColor,
    this.inactiveColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? (activeColor ?? AppColors.textPrimary.withValues(alpha: 0.15))
        : (inactiveColor ?? AppColors.glassFill);

    final textColor = isActive
        ? AppColors.textPrimary
        : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.microBounceDuration,
        curve: Curves.easeOut,
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: isSmall ? 12 : 20,
              vertical: isSmall ? 6 : 12,
            ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusStadium),
          border: Border.all(
            color: isActive
                ? AppColors.textPrimary.withValues(alpha: 0.3)
                : AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: isSmall ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Simple text-only capsule button.
class CapsuleTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isSmall;
  final IconData? icon;

  const CapsuleTextButton({
    super.key,
    required this.text,
    this.onTap,
    this.isActive = false,
    this.isSmall = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CapsuleButton(
      onTap: onTap,
      isActive: isActive,
      isSmall: isSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 14 : 16),
            SizedBox(width: isSmall ? 4 : 6),
          ],
          Text(text),
        ],
      ),
    );
  }
}
