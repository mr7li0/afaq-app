import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../controllers/settings_controller.dart';

/// Afaq Ecosystem & Settings View.
///
/// Spec requirements:
/// - Accordion Cards Directory with ecosystem links
/// - Direct Telegram Feedback Engine
/// - Local JSON Backup & Restore
/// - App Preferences (Language, Theme, Cache)
class EcosystemSettingsView extends StatefulWidget {
  const EcosystemSettingsView({super.key});

  @override
  State<EcosystemSettingsView> createState() => _EcosystemSettingsViewState();
}

class _EcosystemSettingsViewState extends State<EcosystemSettingsView> {
  // ── Feedback State ─────────────────────────────────
  FeedbackCategory _selectedCategory = FeedbackCategory.generalFeedback;
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsController>().init();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<SettingsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary,
                  strokeWidth: 2,
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                // ── Header ─────────────────────
                const Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.glassFill,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'آفاق',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'رفيقك الروحي اليومي',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Feedback Section ───────────
                _buildSectionTitle('الملاحظات والاقتراحات'),
                _buildFeedbackCard(),

                const SizedBox(height: 20),

                // ── Ecosystem Directory ────────
                _buildSectionTitle('منظومة آفاق'),
                _buildEcosystemDirectory(controller),

                const SizedBox(height: 20),

                // ── Backup Section ─────────────
                _buildSectionTitle('النسخ الاحتياطي'),
                _buildBackupSection(controller),

                const SizedBox(height: 20),

                // ── Language Section ───────────
                _buildSectionTitle('اللغة'),
                _buildLanguageSection(controller),

                const SizedBox(height: 20),

                // ── Theme Section ──────────────
                _buildSectionTitle('المظهر'),
                _buildThemeSection(controller),

                const SizedBox(height: 20),

                // ── Cache Section ──────────────
                _buildSectionTitle('التخزين'),
                _buildCacheSection(controller),

                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FEEDBACK SECTION
  // ═══════════════════════════════════════════════════
  Widget _buildFeedbackCard() {
    return GlassmorphismCard(
      child: Column(
        children: [
          // ── Category Selection ─────────────
          _buildFeedbackCategoryChip(
            FeedbackCategory.bugReport,
            'تقرير خلل',
            Icons.bug_report,
          ),
          const Divider(color: AppColors.glassBorder),
          _buildFeedbackCategoryChip(
            FeedbackCategory.featureSuggestion,
            'اقتراح ميزة',
            Icons.lightbulb_outline,
          ),
          const Divider(color: AppColors.glassBorder),
          _buildFeedbackCategoryChip(
            FeedbackCategory.generalFeedback,
            'ملاحظات عامة',
            Icons.chat_bubble_outline,
          ),

          const SizedBox(height: 16),

          // ── Rating Stars ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating
                        ? AppColors.starYellow
                        : AppColors.textHint,
                    size: 32,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // ── Message Input ──────────────────
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'اكتب ملاحظاتك هنا...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.textPrimary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Submit Button ──────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('إرسال'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCategoryChip(
    FeedbackCategory category,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.textPrimary : AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textHint,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.accentGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() async {
    if (_feedbackController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تقييم وكتابة ملاحظاتك'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final controller = context.read<SettingsController>();
    final success = await controller.submitFeedback(
      category: _selectedCategory,
      message: _feedbackController.text,
      rating: _rating,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شكراً لملاحظاتك!'),
          duration: Duration(seconds: 2),
        ),
      );
      _feedbackController.clear();
      setState(() {
        _rating = 0;
        _selectedCategory = FeedbackCategory.generalFeedback;
      });
    }
  }

  // ═══════════════════════════════════════════════════
  // ECOSYSTEM DIRECTORY
  // ═══════════════════════════════════════════════════
  Widget _buildEcosystemDirectory(SettingsController controller) {
    return GlassmorphismCard(
      child: Column(
        children: controller.ecosystemItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == controller.ecosystemItems.length - 1;

          return Column(
            children: [
              _buildEcosystemItem(controller, item, index),
              if (!isLast) const Divider(color: AppColors.glassBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEcosystemItem(
      SettingsController controller, EcosystemItem item, int index) {
    final isArabic = controller.locale.languageCode == 'ar';
    final isExpanded = controller.expandedEcosystemIndex == index;

    return GestureDetector(
      onTap: () => controller.toggleEcosystemExpansion(index),
      child: AnimatedContainer(
        duration: AppConstants.microBounceDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // ── Collapsed Row ──────────────────
            Row(
              children: [
                // Avatar icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.accentBlue,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? item.titleAr : item.titleEn,
                        style: const TextStyle(
                          fontFamily: AppConstants.fontArabic,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic ? item.descriptionAr : item.descriptionEn,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Follower count badge
                if (item.followerCount.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      item.followerCount,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Expand arrow
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: AppConstants.microBounceDuration,
                  child: const Icon(
                    Icons.expand_more,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              ],
            ),

            // ── Expanded Content ──────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Spacer(),
                    // Join button
                    GestureDetector(
                      onTap: () => controller.openEcosystemLink(item.url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusStadium),
                        ),
                        child: Text(
                          isArabic ? 'انضمام' : 'Join',
                          style: const TextStyle(
                            color: AppColors.backgroundPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppConstants.microBounceDuration,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // BACKUP SECTION
  // ═══════════════════════════════════════════════════
  Widget _buildBackupSection(SettingsController controller) {
    return GlassmorphismCard(
      child: Column(
        children: [
          // Export
          GestureDetector(
            onTap: () => _exportData(controller),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.upload, color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تصدير البيانات',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Export bookmarks & progress',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.glassBorder),
          // Import
          GestureDetector(
            onTap: () => _importData(controller),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.download,
                      color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استيراد البيانات',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Import from JSON backup',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(SettingsController controller) async {
    final success = await controller.exportData();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تصدير البيانات بنجاح'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _importData(SettingsController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final importResult =
          await controller.importData(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // LANGUAGE SECTION
  // ═══════════════════════════════════════════════════
  Widget _buildLanguageSection(SettingsController controller) {
    final isArabic = controller.locale.languageCode == 'ar';

    return GlassmorphismCard(
      child: Row(
        children: [
          const Icon(Icons.language,
              color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اللغة',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isArabic ? 'العربية' : 'English',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Language toggle chips
          Row(
            children: [
              _buildLanguageChip(controller, 'عربي', isArabic),
              const SizedBox(width: 4),
              _buildLanguageChip(controller, 'EN', !isArabic),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(
      SettingsController controller, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        final newLocale =
            isActive ? controller.locale : (label == 'عربي' ? const Locale('ar') : const Locale('en'));
        controller.setLocale(newLocale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.textPrimary.withValues(alpha: 0.15)
              : AppColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.textPrimary.withValues(alpha: 0.3)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // THEME SECTION
  // ═══════════════════════════════════════════════════
  Widget _buildThemeSection(SettingsController controller) {
    return GlassmorphismCard(
      child: Column(
        children: [
          // Frosted Glass Toggle
          Row(
            children: [
              const Icon(Icons.blur_on,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تأثير الزجاج',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: controller.useFrostedGlass,
                onChanged: (_) => controller.toggleFrostedGlass(),
                activeThumbColor: AppColors.textPrimary,
                activeTrackColor:
                    AppColors.textPrimary.withValues(alpha: 0.3),
                inactiveTrackColor: AppColors.glassFill,
              ),
            ],
          ),
          const Divider(color: AppColors.glassBorder),
          // Blur Intensity Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'كثافة التمويه',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Slider(
                value: controller.blurIntensity,
                min: 0,
                max: 30,
                divisions: 6,
                onChanged: (v) => controller.setBlurIntensity(v),
                activeColor: AppColors.textPrimary,
                inactiveColor: AppColors.glassFill,
              ),
            ],
          ),
          const Divider(color: AppColors.glassBorder),
          // Text Size Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.text_fields,
                      color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'حجم النص',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Slider(
                value: controller.textSizeMultiplier,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                onChanged: (v) => controller.setTextSizeMultiplier(v),
                activeColor: AppColors.textPrimary,
                inactiveColor: AppColors.glassFill,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CACHE SECTION
  // ═══════════════════════════════════════════════════
  Widget _buildCacheSection(SettingsController controller) {
    return GlassmorphismCard(
      child: Row(
        children: [
          const Icon(Icons.storage,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التخزين المؤقت',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  controller.formattedCacheSize,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: controller.isClearingCache
                ? null
                : () => controller.clearCache(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: controller.isClearingCache
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Text(
                      'مسح',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
