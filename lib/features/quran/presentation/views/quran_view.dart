import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../shared/models/quran_verse.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/mirrored_icon.dart';
import '../controllers/quran_controller.dart';
import '../search/quran_search_engine.dart';
import 'story_studio_view.dart';

/// Quran & Wird Reader — complete reading experience.
///
/// Sections:
/// 1. Glassmorphic top bar (surah/juz selector, search, ambient, progress)
/// 2. Verse rendering canvas (Uthmani font, ayah end markers)
/// 3. Full-screen search overlay
/// 4. Ayah action sheet (recitation, tafseer, copy, bookmark, story)
/// 5. Ambient audio panel (rain, mosque volume sliders)
/// 6. Auto-scroll floating capsule
class QuranView extends StatefulWidget {
  const QuranView({super.key});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showAmbientPanel = false;
  bool _showSurahSelector = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<QuranController>();
      controller.init();
      controller.setScrollController(_scrollController);
      controller.loadTafsir();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<QuranController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
                strokeWidth: 2,
              ),
            );
          }

          return Stack(
            children: [
              // ── Main Content ──────────────────────
              Column(
                children: [
                  _buildTopBar(controller),
                  Expanded(child: _buildVerseCanvas(controller)),
                ],
              ),

              // ── Search Overlay ────────────────────
              if (controller.isSearchActive)
                _buildSearchOverlay(controller),

              // ── Ambient Audio Panel ───────────────
              if (_showAmbientPanel)
                _buildAmbientPanel(controller),

              // ── Auto-Scroll FAB ───────────────────
              _buildAutoScrollFab(controller),

              // ── Surah Selector Modal ──────────────
              if (_showSurahSelector)
                _buildSurahSelectorOverlay(controller),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 1. GLASSMORPHIC TOP BAR
  // ═══════════════════════════════════════════════════
  Widget _buildTopBar(QuranController controller) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary.withValues(alpha: 0.8),
            border: const Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: AppConstants.glassBorderWidth),
            ),
          ),
          child: Column(
            children: [
              // ── Row 1: Title + Actions ───────────
              Row(
                children: [
                  // Surah/Juz selector
                  GestureDetector(
                    onTap: () => setState(() => _showSurahSelector = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'سورة ${_surahNameArabic(controller.currentSurah)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              color: AppColors.textSecondary, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Progress capsule
                  _buildProgressCapsule(controller),

                  const SizedBox(width: 8),

                  // Search button
                  GestureDetector(
                    onTap: () => controller.activateSearch(),
                    child: _topBarIcon(AppIcons.search),
                  ),

                  const SizedBox(width: 8),

                  // Ambient audio button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showAmbientPanel = !_showAmbientPanel),
                    child: _topBarIcon(AppIcons.settings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBarIcon(String assetPath) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Center(
        child: MirroredIcon(
          assetPath: assetPath,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProgressCapsule(QuranController controller) {
    final progress = controller.wirdProgress.completionPercentage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        '${(progress * 100).toInt()}%',
        style: const TextStyle(
          color: AppColors.accentGreen,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 2. VERSE RENDERING CANVAS
  // ═══════════════════════════════════════════════════
  Widget _buildVerseCanvas(QuranController controller) {
    final verses = controller.currentVerses;

    if (verses.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد آيات',
          style: TextStyle(color: AppColors.textHint),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPaddingLarge,
        vertical: 16,
      ),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        return _buildVerseTile(controller, verse, index);
      },
    );
  }

  Widget _buildVerseTile(
      QuranController controller, QuranVerse verse, int index) {
    final isCurrentlyPlaying =
        controller.currentlyPlayingVerse?.key == verse.key;
    final isBookmarked = controller.isBookmarked(verse);

    return GestureDetector(
      onTap: () => _showAyahActionSheet(controller, verse),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentlyPlaying
              ? AppColors.accentBlue.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentlyPlaying
              ? Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bismillah (only for verse 1 of non-Fatiha surahs)
            if (verse.ayah == 1 && verse.surah != 1 && verse.surah != 9)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.fontQuran,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                    height: 2.0,
                  ),
                ),
              ),

            // Verse text + ayah marker
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse text
                Expanded(
                  child: Text(
                    verse.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppConstants.fontQuran,
                      fontSize: 24,
                      color: AppColors.textPrimary,
                      height: 2.0,
                    ),
                  ),
                ),
              ],
            ),

            // Ayah end marker
            Center(child: _buildAyahMarker(verse.ayah)),

            // Bottom info row
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الجزء ${verse.juz}  •  الصفحة ${verse.page}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                  if (isBookmarked) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star,
                      color: Color(0xFFE2B93B),
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ayah End Marker ───────────────────────────────
  Widget _buildAyahMarker(int ayahNumber) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          QuranController.toArabicNumerals(ayahNumber),
          style: const TextStyle(
            fontFamily: AppConstants.fontQuran,
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 3. FULL-SCREEN SEARCH OVERLAY
  // ═══════════════════════════════════════════════════
  Widget _buildSearchOverlay(QuranController controller) {
    return Positioned.fill(
      child: Container(
        color: AppColors.backgroundPrimary,
        child: SafeArea(
          child: Column(
            children: [
              // ── Search Input ──────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Close button
                    GestureDetector(
                      onTap: () {
                        controller.deactivateSearch();
                        _searchController.clear();
                      },
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (q) => controller.updateSearchQuery(q),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ابحث في القرآن...',
                          hintStyle: const TextStyle(
                              color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textHint),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Results count ─────────────────────
              if (controller.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${controller.searchResults.length} نتيجة',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ── Search Results ────────────────────
              Expanded(
                child: controller.isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: controller.searchResults.length,
                        itemBuilder: (context, index) {
                          final result = controller.searchResults[index];
                          return _buildSearchResultTile(controller, result);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(
      QuranController controller, SearchResult result) {
    return GestureDetector(
      onTap: () {
        controller.navigateToSearchResult(result);
        _searchController.clear();
      },
      child: GlassmorphismCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    // Surah + Ayah reference
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.glassFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            'سورة ${result.verse.surahName}',
                            style: const TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'آية ${result.verse.ayah}',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Highlighted verse text
                    RichText(
                      text: TextSpan(
                        children: result.highlightedSegments.map((segment) {
                          return TextSpan(
                            text: segment.text,
                            style: TextStyle(
                              fontFamily: AppConstants.fontQuran,
                              fontSize: 20,
                              height: 1.8,
                              color: segment.isHighlighted
                                  ? AppColors.starYellow
                                  : AppColors.textPrimary,
                              backgroundColor: segment.isHighlighted
                                  ? AppColors.starYellow.withValues(alpha: 0.15)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 4. AYAH ACTION SHEET
  // ═══════════════════════════════════════════════════
  void _showAyahActionSheet(QuranController controller, QuranVerse verse) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AyahActionSheetContent(
        verse: verse,
        controller: controller,
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 5. AMBIENT AUDIO PANEL
  // ═══════════════════════════════════════════════════
  Widget _buildAmbientPanel(QuranController controller) {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder, width: AppConstants.glassBorderWidth),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'الأصوات المحيطة',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showAmbientPanel = false),
                      child: const Icon(Icons.close,
                          color: AppColors.textHint, size: 18),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rain volume
                _buildVolumeSlider(
                  label: 'المطر',
                  value: controller.rainVolume,
                  onChanged: (v) => controller.setRainVolume(v),
                  icon: Icons.water_drop,
                ),

                const SizedBox(height: 12),

                // Mosque ambience volume
                _buildVolumeSlider(
                  label: 'المسجد',
                  value: controller.mosqueVolume,
                  onChanged: (v) => controller.setMosqueVolume(v),
                  icon: Icons.mosque,
                ),

                const SizedBox(height: 12),

                // Play/Stop button
                GestureDetector(
                  onTap: () => controller.toggleAmbient(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: controller.ambientPlaying
                          ? AppColors.accentGreen.withValues(alpha: 0.15)
                          : AppColors.glassFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      controller.ambientPlaying
                          ? 'إيقاف الأصوات'
                          : 'تشغيل الأصوات',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: controller.ambientPlaying
                            ? AppColors.accentGreen
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.textPrimary,
            inactiveColor: AppColors.glassFill,
            min: 0,
            max: 1,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // 6. AUTO-SCROLL FAB
  // ═══════════════════════════════════════════════════
  Widget _buildAutoScrollFab(QuranController controller) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: GestureDetector(
        onTap: () => controller.toggleAutoScroll(),
        child: AnimatedContainer(
          duration: AppConstants.microBounceDuration,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: controller.autoScrollEnabled
                ? AppColors.accentGreen.withValues(alpha: 0.2)
                : AppColors.glassFill,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusStadium),
            border: Border.all(
              color: controller.autoScrollEnabled
                  ? AppColors.accentGreen.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.autoScrollEnabled ? Icons.pause : Icons.play_arrow,
                color: controller.autoScrollEnabled
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                controller.autoScrollEnabled ? 'إيقاف' : 'تمرير تلقائي',
                style: TextStyle(
                  color: controller.autoScrollEnabled
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 7. SURAH SELECTOR OVERLAY
  // ═══════════════════════════════════════════════════
  Widget _buildSurahSelectorOverlay(QuranController controller) {
    return Positioned.fill(
      child: Container(
        color: AppColors.backgroundPrimary,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showSurahSelector = false),
                      child: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'اختر سورة',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Surah list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 114,
                  itemBuilder: (context, index) {
                    final surahNum = index + 1;
                    final isSelected = surahNum == controller.currentSurah;
                    return GestureDetector(
                      onTap: () {
                        controller.loadSurah(surahNum);
                        setState(() => _showSurahSelector = false);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentBlue.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.accentBlue
                                      .withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Number
                            Text(
                              '$surahNum',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accentBlue
                                    : AppColors.textHint,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Arabic name
                            Expanded(
                              child: Text(
                                _surahNameArabic(surahNum),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // English name
                            Text(
                              _surahNameEnglish(surahNum),
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Surah Name Helpers ────────────────────────────
  String _surahNameArabic(int num) {
    const names = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
      'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
      'هود', 'يوسф', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
      'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
      'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
      'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
      'يس', 'الصافات', 'Sad', 'الزمر', 'غافر',
      'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
      'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
      'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
      'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
      'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
      'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
      'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
      'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج',
      'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
      'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين',
      'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
      'القارعة', 'التكاثر', 'العون', 'القارعة', 'الhumaza',
      'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون',
      'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس',
    ];
    return num >= 1 && num <= 114 ? names[num - 1] : '$num';
  }

  String _surahNameEnglish(int num) {
    const names = [
      'Al-Fatiha', 'Al-Baqara', 'Ali Imran', 'An-Nisa', 'Al-Maida',
      'Al-Anam', 'Al-Araf', 'Al-Anfal', 'At-Tawba', 'Yunus',
      'Hud', 'Yusuf', 'Ar-Rad', 'Ibrahim', 'Al-Hijr',
      'An-Nahl', 'Al-Isra', 'Al-Kahf', 'Maryam', 'Taha',
      'Al-Anbiya', 'Al-Hajj', 'Al-Muminun', 'An-Nur', 'Al-Furqan',
      'Ash-Shuara', 'An-Naml', 'Al-Qasas', 'Al-Ankabut', 'Ar-Rum',
      'Luqman', 'As-Sajda', 'Al-Ahzab', 'Saba', 'Fatir',
      'Ya-Sin', 'As-Saffat', 'Sad', 'Az-Zumar', 'Ghafir',
      'Fussilat', 'Ash-Shura', 'Az-Zukhruf', 'Ad-Dukhan', 'Al-Jathiya',
      'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf',
      'Adh-Dhariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman',
      'Al-Waqia', 'Al-Hadid', 'Al-Mujadila', 'Al-Hashr', 'Al-Mumtahina',
      'As-Saff', 'Al-Jumuah', 'Al-Munafiqun', 'At-Taghabun', 'At-Talaq',
      'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', 'Al-Maarij',
      'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddaththir', 'Al-Qiyama',
      'Al-Insan', 'Al-Mursalat', 'An-Naba', 'An-Naziat', 'Abasa',
      'At-Takwir', 'Al-Infitar', 'Al-Mutaffifin', 'Al-Inshiqaq', 'Al-Buruj',
      'At-Tariq', 'Al-Ala', 'Al-Ghashiya', 'Al-Fajr', 'Al-Balad',
      'Ash-Shams', 'Al-Lail', 'Ad-Duha', 'Ash-Sharh', 'At-Tin',
      'Al-Alaq', 'Al-Qadr', 'Al-Bayyina', 'Az-Zalzala', 'Al-Adiyat',
      'Al-Qaria', 'At-Takathur', 'Al-Asr', 'Al-Humaza', 'Al-Fil',
      'Quraysh', 'Al-Maun', 'Al-Kawthar', 'Al-Kafirun', 'An-Nasr',
      'Al-Masad', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas',
    ];
    return num >= 1 && num <= 114 ? names[num - 1] : '$num';
  }
}

// ═══════════════════════════════════════════════════════════
// AYAH ACTION SHEET CONTENT
// ═══════════════════════════════════════════════════════════
class _AyahActionSheetContent extends StatelessWidget {
  final QuranVerse verse;
  final QuranController controller;

  const _AyahActionSheetContent({
    required this.verse,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final tafsir = controller.getTafsir(verse.surah, verse.ayah);
    final isBookmarked = controller.isBookmarked(verse);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppConstants.borderRadiusCards),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusCards),
            ),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: AppConstants.glassBorderWidth),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Verse preview
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Text(
                  verse.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppConstants.fontQuran,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                    height: 1.8,
                  ),
                ),
              ),

              Text(
                '${verse.surahName} : ${verse.ayah}',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),

              const Divider(color: AppColors.glassBorder),

              // Action buttons
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    children: [
                      // Play recitation
                      _buildActionRow(
                        icon: controller.isPlaying &&
                                controller.currentlyPlayingVerse?.key ==
                                    verse.key
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        label: 'استماع التلاوة',
                        onTap: () {
                          if (controller.isPlaying &&
                              controller.currentlyPlayingVerse?.key ==
                                  verse.key) {
                            controller.pauseRecitation();
                          } else {
                            controller.playRecitation(verse);
                          }
                        },
                        color: AppColors.accentBlue,
                      ),

                      // Tafseer
                      if (tafsir.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildActionRow(
                          icon: Icons.menu_book,
                          label: 'التفسير',
                          onTap: () {
                            Navigator.pop(context);
                            _showTafseerSheet(context, tafsir);
                          },
                          color: AppColors.textSecondary,
                        ),
                      ],

                      // Copy text
                      const SizedBox(height: 8),
                      _buildActionRow(
                        icon: Icons.copy,
                        label: 'نسخ النص',
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: verse.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم النسخ'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        color: AppColors.textSecondary,
                      ),

                      // Bookmark
                      const SizedBox(height: 8),
                      _buildActionRow(
                        icon: isBookmarked
                            ? Icons.star
                            : Icons.star_border,
                        label: isBookmarked
                            ? 'إزالة من المفضلة'
                            : 'إضافة للمفضلة',
                        onTap: () {
                          controller.toggleBookmark(verse);
                          Navigator.pop(context);
                        },
                        color: isBookmarked
                            ? const Color(0xFFE2B93B)
                            : AppColors.textSecondary,
                      ),

                      // Story Studio
                      const SizedBox(height: 8),
                      _buildActionRow(
                        icon: Icons.image,
                        label: 'استوديو القصص والخلفيات',
                        onTap: () {
                          Navigator.pop(context);
                          _openStoryStudio(context);
                        },
                        color: AppColors.accentOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            MirroredIcon(
              assetPath: AppIcons.arrowRight,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _showTafseerSheet(BuildContext context, String tafsir) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusCards),
        ),
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusCards),
            ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'التفسير',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(color: AppColors.glassBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tafsir,
                      style: const TextStyle(
                        fontFamily: AppConstants.fontArabic,
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openStoryStudio(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StoryStudioView(verse: verse),
      ),
    );
  }
}
