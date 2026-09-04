import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';

/// Reusable glassmorphism card component.
/// Uses BackdropFilter for frosted glass effect with subtle borders.
///
/// Spec: blur: 12.0, opacity: 10% Ivory, light borders (20%)
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Border? customBorder;
  final bool usePhase2Style;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.borderRadiusCards,
    this.blur = 12.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.customBorder,
    this.usePhase2Style = false,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = usePhase2Style ? AppColors.glassSurface : AppColors.glassFill;
    final borderColor = usePhase2Style ? AppColors.glassBorder20 : AppColors.glassBorder;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppConstants.defaultPadding),
          margin: margin,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: customBorder ??
                Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
