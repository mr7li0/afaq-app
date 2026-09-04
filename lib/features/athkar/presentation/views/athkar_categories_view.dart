import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../shared/models/athkar_category.dart';
import '../../../../shared/widgets/mirrored_icon.dart';
import '../controllers/athkar_controller.dart';
import 'athkar_reader_view.dart';

/// Athkar Categories Overview Screen.
///
/// Spec requirements:
/// - Glassmorphic Grid View with frosted glass cards (BorderRadius.circular(20))
/// - Category title in Milan.ttf, icon from assets/icons/, progress indicator
/// - Search & Quick Filter Bar at top
/// - Progress completion indicator (e.g., "7 / 12 مكتمل")
/// - Audio quick-play for supported categories
/// - Reset counters option
class AthkarCategoriesView extends StatefulWidget {
  const AthkarCategoriesView({super.key});

  @override
  State<AthkarCategoriesView> createState() => _AthkarCategoriesViewState();
}

class _AthkarCategoriesViewState extends State<AthkarCategoriesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AthkarController>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<AthkarController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary,
                  strokeWidth: 2,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────
                _buildHeader(controller),

                // ── Search Bar ─────────────────────
                _buildSearchBar(controller),

                const SizedBox(height: 8),

                // ── Category Grid ──────────────────
                Expanded(
                  child: _buildCategoryGrid(controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────
  Widget _buildHeader(AthkarController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPaddingLarge,
        16,
        AppConstants.defaultPaddingLarge,
        8,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'أذكار المسلم',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Reset all button
          GestureDetector(
            onTap: () => _showResetDialog(controller),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const MirroredIcon(
                assetPath: AppIcons.refresh,
                size: 20,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────
  Widget _buildSearchBar(AthkarController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPaddingLarge),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusStadium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusStadium),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => controller.updateSearchQuery(q),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'بحث في الأذكار...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textHint),
                        onPressed: () {
                          _searchController.clear();
                          controller.updateSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Category Grid ─────────────────────────────────
  Widget _buildCategoryGrid(AthkarController controller) {
    final categories = controller.filteredCategories;

    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(color: AppColors.textHint),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(controller, categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(
      AthkarController controller, AthkarCategory category) {
    final hasAudio = category.audioAsset != null;

    return GestureDetector(
      onTap: () {
        controller.selectCategory(category);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AthkarReaderView(),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusCards),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: category.isFullyCompleted
                  ? AppColors.accentGreen.withValues(alpha: 0.08)
                  : AppColors.glassFill,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusCards),
              border: Border.all(
                color: category.isFullyCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.3)
                    : AppColors.glassBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Audio button row
                Row(
                  children: [
                    // Category icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconData(
                          category.iconCodePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),

                    const Spacer(),

                    // Audio play button
                    if (hasAudio)
                      GestureDetector(
                        onTap: () =>
                            controller.playCategoryAudio(category),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.glassFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            controller.isPlaying &&
                                    controller.currentAudioCategory ==
                                        category.name
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: AppColors.accentBlue,
                            size: 16,
                          ),
                        ),
                      ),

                    // Completed badge
                    if (category.isFullyCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.accentGreen,
                          size: 14,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Category name
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: AppConstants.fontArabic,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 6),

                // Progress indicator — "7 / 12 مكتمل"
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: category.completionProgress,
                          backgroundColor: AppColors.glassFill,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category.isFullyCompleted
                                ? AppColors.accentGreen
                                : AppColors.accentBlue,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${category.completedCount}/${category.totalItems}',
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reset Dialog ──────────────────────────────────
  void _showResetDialog(AthkarController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'إعادة العدّادات',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'هل تريد إعادة جميع عدّادات الأذكار إلى الصفر؟',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.resetAllCounters();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'إعادة',
              style: TextStyle(color: AppColors.starRed),
            ),
          ),
        ],
      ),
    );
  }
}
