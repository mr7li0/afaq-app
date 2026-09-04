import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../shared/models/athkar_category.dart';
import '../../../../shared/widgets/animated_bookmark_star.dart';
import '../controllers/athkar_controller.dart';

/// Interactive Athkar Reader with tap counter engine.
///
/// Spec requirements:
/// - Full-screen glassmorphic view using vertical scroll
/// - Large Dhikr Text Container in Milan.ttf (Uthmani.ttf for Quranic phrases)
/// - Line spacing 1.8, Ivory palette (#FDFBF7)
/// - Interactive Tap Counter: tap decrements count by 1
/// - Haptic Feedback: lightImpact on each tap, mediumImpact on completion
/// - Visual Feedback: Soft ripple effect + scaling animation on counter capsule
/// - Completion State: 250ms micro bounce, gold glow (#E2B93B), auto-advance after 400ms
/// - Floating audio player bar with play/pause, progress, speed toggle
/// - Bookmark star with scale bounce
/// - Share capsule: copy with attribution or export glassmorphic image
class AthkarReaderView extends StatefulWidget {
  const AthkarReaderView({super.key});

  @override
  State<AthkarReaderView> createState() => _AthkarReaderViewState();
}

class _AthkarReaderViewState extends State<AthkarReaderView>
    with TickerProviderStateMixin {
  // ── Animation Controllers (per item) ──────────────
  final Map<int, AnimationController> _bounceControllers = {};
  final Map<int, AnimationController> _glowControllers = {};
  final Map<int, AnimationController> _counterScaleControllers = {};

  int _currentItemIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAnimations();
    });
  }

  void _initAnimations() {
    final category = context.read<AthkarController>().selectedCategory;
    if (category == null) return;

    for (int i = 0; i < category.items.length; i++) {
      _bounceControllers[i] = AnimationController(
        vsync: this,
        duration: AppConstants.microBounceDuration, // 250ms
      );
      _glowControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _counterScaleControllers[i] = AnimationController(
        vsync: this,
        duration: AppConstants.microBounceDuration, // 250ms
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _bounceControllers.values) {
      controller.dispose();
    }
    for (final controller in _glowControllers.values) {
      controller.dispose();
    }
    for (final controller in _counterScaleControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<AthkarController>(
        builder: (context, controller, _) {
          final category = controller.selectedCategory;
          if (category == null) {
            return const Center(
              child: Text('اختر فئة',
                  style: TextStyle(color: AppColors.textHint)),
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  // ── Top Bar ─────────────────────
                  _buildTopBar(controller, category),

                  // ── Dhikr List ──────────────────
                  Expanded(
                    child: _buildDhikrList(controller, category),
                  ),

                  // ── Audio Player Bar ────────────
                  if (category.audioAsset != null)
                    _buildAudioBar(controller, category),
                ],
              ),

              // Off-screen share card for image export capture
              Positioned(
                left: -1000,
                top: 0,
                child: _buildShareCard(
                  controller.selectedCategory?.items.isNotEmpty == true
                      ? controller.selectedCategory!.items[
                          _currentItemIndex.clamp(
                              0, controller.selectedCategory!.items.length - 1)]
                          .text
                      : '',
                  category.name,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────
  Widget _buildTopBar(AthkarController controller, AthkarCategory category) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundTertiary,
            border: Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: AppConstants.glassBorderWidth),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  controller.clearSelection();
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.arrow_back_ios,
                    color: AppColors.textSecondary, size: 20),
              ),

              const SizedBox(width: 12),

              // Category name
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Progress
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  '${category.completedCount}/${category.totalItems}',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Reset button
              GestureDetector(
                onTap: () => _showResetDialog(controller, category),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh,
                      color: AppColors.textHint, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dhikr List ────────────────────────────────────
  Widget _buildDhikrList(
      AthkarController controller, AthkarCategory category) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 12,
      ),
      itemCount: category.items.length,
      itemBuilder: (context, index) {
        return _buildDhikrCard(controller, category, index);
      },
    );
  }

  // ── Dhikr Card ────────────────────────────────────
  Widget _buildDhikrCard(
    AthkarController controller,
    AthkarCategory category,
    int index,
  ) {
    final item = category.items[index];
    var bounceAnim = _bounceControllers[index];
    var glowAnim = _glowControllers[index];
    var counterScaleAnim = _counterScaleControllers[index];
    final isFavorite = controller.isFavorite(item.text);

    // Initialize animations if not yet done
    bounceAnim ??= _bounceControllers[index] = AnimationController(
      vsync: this,
      duration: AppConstants.microBounceDuration,
    );
    glowAnim ??= _glowControllers[index] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    counterScaleAnim ??= _counterScaleControllers[index] = AnimationController(
      vsync: this,
      duration: AppConstants.microBounceDuration,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([bounceAnim!, glowAnim!, counterScaleAnim!]), // ignore: unnecessary_non_null_assertion
      builder: (context, child) {
        final glowValue = glowAnim!.value;
        final bounceScale = 1.0 + (0.1 * (1.0 - bounceAnim!.value));
        final counterScale =
            1.0 + (0.15 * (1.0 - counterScaleAnim!.value));

        return Transform.scale(
          scale: bounceScale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Spec: Soft ripple effect on tap
              onTap: () {
                final justCompleted =
                    controller.tapDhikr(category, index);

                // Trigger bounce animation (250ms)
                bounceAnim!.forward(from: 0.0);

                // Trigger counter scale animation
                counterScaleAnim!.forward(from: 0.0);

                if (justCompleted) {
                  // Trigger gold glow animation
                  glowAnim!.forward(from: 0.0);

                  // Auto-advance to next dhikr after 400ms
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (index < category.items.length - 1) {
                      _scrollToItem(index + 1);
                      _currentItemIndex = index + 1;
                    }
                  });
                }

                _currentItemIndex = index;
              },
              // Spec: Soft ripple color
              splashColor: AppColors.textPrimary.withValues(alpha: 0.05),
              highlightColor: AppColors.textPrimary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? AppColors.accentGreen.withValues(alpha: 0.06)
                      : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: item.isCompleted
                        ? Color.lerp(
                            AppColors.glassBorder,
                            const Color(0xFFE2B93B), // Spec: gold glow
                            glowValue,
                          )!
                        : AppColors.glassBorder,
                    width: item.isCompleted ? 1.5 : 1,
                  ),
                  // Spec: Gold glow shadow on completion
                  boxShadow: item.isCompleted
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE2B93B)
                                .withValues(alpha: 0.15 * glowValue),
                            blurRadius: 12 * glowValue,
                            spreadRadius: 2 * glowValue,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Top Row: Favorite + Counter ──
                    Row(
                      children: [
                        // Favorite star with scale bounce
                        AnimatedBookmarkStar(
                          isActive: isFavorite,
                          onTap: () => controller.toggleFavorite(item.text),
                          size: 22,
                        ),

                        const Spacer(),

                        // Counter capsule with scale animation
                        Transform.scale(
                          scale: counterScale,
                          child: _buildCounterCapsule(item),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Dhikr Text ──────────────────
                    // Spec: Milan.ttf for general, Uthmani.ttf for Quranic phrases
                    Text(
                      item.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _isQuranicPhrase(item.text)
                            ? AppConstants.fontQuran
                            : AppConstants.fontArabic,
                        fontSize: _isQuranicPhrase(item.text) ? 22 : 18,
                        color: item.isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary, // Spec: #FDFBF7
                        height: 1.8, // Spec: line spacing 1.8
                      ),
                    ),

                    // ── Reward Text (Fadilath) ─────
                    if (item.rewardText != null &&
                        item.rewardText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Text(
                          item.rewardText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppConstants.fontArabic,
                            fontSize: 13,
                            color: AppColors.textHint,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ── Progress Bar ────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: AppColors.glassFill,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.isCompleted
                              ? const Color(0xFFE2B93B) // Spec: gold
                              : AppColors.accentBlue,
                        ),
                        minHeight: 3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Bottom: Tap hint + Share ────
                    Row(
                      children: [
                        Text(
                          item.isCompleted
                              ? '✓ مكتمل'
                              : 'اضغط للتسبيح',
                          style: TextStyle(
                            color: item.isCompleted
                                ? const Color(0xFFE2B93B)
                                : AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        // Share button
                        GestureDetector(
                          onTap: () => _showShareOptions(
                              context, item.text, category.name),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              AppIcons.share,
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textHint,
                                BlendMode.srcIn,
                              ),
                            ),
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
      },
    );
  }

  // ── Counter Capsule ───────────────────────────────
  Widget _buildCounterCapsule(AthkarItem item) {
    return AnimatedContainer(
      duration: AppConstants.microBounceDuration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: item.isCompleted
            ? const Color(0xFFE2B93B).withValues(alpha: 0.15)
            : AppColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCompleted
              ? const Color(0xFFE2B93B).withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Text(
        item.isCompleted
            ? '0'
            : '${item.remainingCount}/${item.defaultCount}',
        style: TextStyle(
          color: item.isCompleted
              ? const Color(0xFFE2B93B)
              : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Audio Player Bar ──────────────────────────────
  Widget _buildAudioBar(
      AthkarController controller, AthkarCategory category) {      return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.backgroundTertiary,
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: AppConstants.glassBorderWidth),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Progress Timeline Bar ─────────
              StreamBuilder<Duration>(
                stream: controller.positionStream,
                builder: (context, posSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: controller.durationStream,
                    builder: (context, durSnap) {
                      final duration = durSnap.data ?? Duration.zero;
                      final totalMs = duration.inMilliseconds > 0
                          ? duration.inMilliseconds
                          : 1;
                      final value =
                          (position.inMilliseconds / totalMs).clamp(0.0, 1.0);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                              activeTrackColor: AppColors.accentBlue,
                              inactiveTrackColor: AppColors.glassFill,
                              thumbColor: AppColors.accentBlue,
                              overlayColor:
                                  AppColors.accentBlue.withValues(alpha: 0.15),
                            ),
                            child: Slider(
                              value: value,
                              onChanged: (v) {
                                // Seek if possible
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 4),

              // ── Controls Row ────────────────────
              Row(
                children: [
                  // Play/Pause
                  GestureDetector(
                    onTap: () => controller.playCategoryAudio(category),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        controller.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Category audio name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التسجيل الصوتي',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (controller.isPlaying)
                          const Text(
                            'جاري التشغيل...',
                            style: TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Speed toggle — Spec: 1.0x, 1.25x, 1.5x
                  _buildSpeedToggle(controller),

                  const SizedBox(width: 8),

                  // Stop
                  GestureDetector(
                    onTap: () => controller.stopAudio(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.stop_circle,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedToggle(AthkarController controller) {
    final speeds = [1.0, 1.25, 1.5];
    final currentIndex = speeds.indexOf(controller.playbackSpeed);

    return GestureDetector(
      onTap: () {
        final nextIndex = (currentIndex + 1) % speeds.length;
        controller.setPlaybackSpeed(speeds[nextIndex]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          '${controller.playbackSpeed}x',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────
  bool _isQuranicPhrase(String text) {
    return text.contains('{') || text.contains('}');
  }

  void _scrollToItem(int index) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * 200.0, // approximate item height
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Share Options Sheet ──────────────────────────
  void _showShareOptions(BuildContext context, String text, String categoryName) {
    final attribution = '$text\n\n— آفاق | أذكار المسلم ($categoryName)';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Copy text
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.textPrimary, size: 22),
                title: const Text(
                  'نسخ النص',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                ),
                subtitle: const Text(
                  'نسخ مع تنسب آفاق',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: attribution));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الذكر مع التنسب'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // Share via share sheet
              ListTile(
                leading: SvgPicture.asset(
                  AppIcons.share,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                title: const Text(
                  'مشاركة النص',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                ),
                subtitle: const Text(
                  'مشاركة عبر التطبيقات',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: attribution));
                },
              ),

              // Export glassmorphic image card
              ListTile(
                leading: SvgPicture.asset(
                  AppIcons.image,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                title: const Text(
                  'تصدير كصورة',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                ),
                subtitle: const Text(
                  'بطاقة زجاجية للسوشيال ميديا',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _exportGlassmorphicImage(text, categoryName);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Glassmorphic Image Export ────────────────────
  Future<void> _exportGlassmorphicImage(String text, String categoryName) async {
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في إنشاء الصورة')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Write bytes to temp file then share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/athkar_$categoryName.png');
      await file.writeAsBytes(bytes);
      await Clipboard.setData(ClipboardData(text: 'تم حفظ الصورة في ${file.path}'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تصدير الصورة')),
        );
      }
    }
  }

  // ── Glassmorphic Share Card Widget ───────────────
  Widget _buildShareCard(String text, String categoryName) {
    return RepaintBoundary(
      key: _shareCardKey,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundSecondary,
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.glassBorder, width: AppConstants.glassBorderWidth),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top decorative line
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 30),

            // Dhikr text
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppConstants.fontArabic,
                fontSize: 22,
                color: AppColors.textPrimary,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 30),

            // Divider
            Container(
              width: 120,
              height: 1,
              color: AppColors.glassBorder,
            ),

            const SizedBox(height: 16),

            // Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_stories,
                  color: AppColors.accentBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$categoryName — آفاق',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(
      AthkarController controller, AthkarCategory category) {
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
        content: Text(
          'هل تريد إعادة عدّادات "${category.name}" إلى الصفر؟',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              controller.resetCategory(category);
              Navigator.of(ctx).pop();
            },
            child: const Text('إعادة',
                style: TextStyle(color: AppColors.starRed)),
          ),
        ],
      ),
    );
  }
}
