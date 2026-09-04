import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/asset_constants.dart';
import '../../core/localization/l10n.dart';

/// Floating glassmorphic bottom navigation bar.
class GlassmorphicBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassmorphicBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(svgPath: AppIcons.home, labelKey: 'nav.home'),
    _NavItem(svgPath: AppIcons.bookOpen, labelKey: 'nav.quran'),
    _NavItem(svgPath: AppIcons.bell, labelKey: 'nav.athkar'),
    _NavItem(svgPath: AppIcons.layoutGrid, labelKey: 'nav.widgets'),
    _NavItem(svgPath: AppIcons.user, labelKey: 'nav.profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.read<LocalizationProvider>();
    final isRtl = l10n.isArabic || l10n.isKurdish;

    return Positioned(
      bottom: 16,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusStadium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusStadium),
              border: Border.all(
                color: AppColors.glassBorder,
                width: AppConstants.glassBorderWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                return _buildNavItem(index, l10n, isRtl);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, LocalizationProvider l10n, bool isRtl) {
    final item = _items[index];
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.microBounceDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusStadium),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(0, 0, isRtl ? -1.0 : 1.0),
              child: SvgPicture.asset(
                item.svgPath,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  isActive ? AppColors.textPrimary : AppColors.textHint,
                  BlendMode.srcIn,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              AnimatedSize(
                duration: AppConstants.microBounceDuration,
                curve: Curves.easeOut,
                child: Text(
                  l10n.t(item.labelKey),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String svgPath;
  final String labelKey;

  const _NavItem({
    required this.svgPath,
    required this.labelKey,
  });
}
