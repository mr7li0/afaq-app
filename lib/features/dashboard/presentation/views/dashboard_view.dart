import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/prayer_mini_widget.dart';

class DashboardView extends StatefulWidget {
  const DashboardView();
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardController>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async { dashboard.refreshOnResume(); },
          color: AppColors.ivory,
          backgroundColor: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      _buildDateCard(dashboard),
                      const SizedBox(height: 10),
                      _buildPrayerTracker(dashboard),
                      const SizedBox(height: 10),
                      _buildDhikrCard(dashboard),
                      const SizedBox(height: 10),
                      _buildAyahCard(dashboard),
                      const SizedBox(height: 10),
                      _buildHadithCard(dashboard),
                      const SizedBox(height: 100),
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

  Widget _buildDateCard(DashboardController dashboard) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12)),
            child: Text('${now.day}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dashboard.hijriDateStr, style: const TextStyle(color: AppColors.ivory, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(dashboard.dayName, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
          Text(dashboard.gregorianDateStr, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPrayerTracker(DashboardController dashboard) {
    final isTodayDate = dashboard.isToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('الصلاة القادمة ${dashboard.nextPrayerName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ivory)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(dashboard.nextPrayerTimeStr, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
              const Spacer(),
              Text(dashboard.countdownText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ivory)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: dashboard.prayerProgress,
            backgroundColor: AppColors.cardBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ivory),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PrayerMiniWidget(name: 'الفجر', time: dashboard.fivePrayers.isNotEmpty ? dashboard.fivePrayers[0].value : '--:--'),
              PrayerMiniWidget(name: 'الظهر', time: dashboard.fivePrayers.length > 2 ? dashboard.fivePrayers[2].value : '--:--'),
              PrayerMiniWidget(name: 'العصر', time: dashboard.fivePrayers.length > 3 ? dashboard.fivePrayers[3].value : '--:--'),
              PrayerMiniWidget(name: 'المغرب', time: dashboard.fivePrayers.length > 4 ? dashboard.fivePrayers[4].value : '--:--'),
              PrayerMiniWidget(name: 'العشاء', time: dashboard.fivePrayers.length > 5 ? dashboard.fivePrayers[5].value : '--:--'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!dashboard.canGoBack && !dashboard.canGoPreviousMonth)
                const SizedBox(width: 40)
              else
                GestureDetector(
                  onTap: () => dashboard.goToPreviousDay(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.chevron_right, color: AppColors.ivory, size: 22),
                  ),
                ),
              Column(
                children: [
                  if (!isTodayDate)
                    GestureDetector(
                      onTap: () => dashboard.resetToToday(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(10)),
                        child: const Text('العودة لليوم', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (!isTodayDate) const SizedBox(height: 4),
                  Text(dashboard.fullSelectedDate, style: const TextStyle(fontSize: 10, color: AppColors.ivory), textAlign: TextAlign.center),
                ],
              ),
              if (!dashboard.canGoForward && !dashboard.canGoNextMonth)
                const SizedBox(width: 40)
              else
                GestureDetector(
                  onTap: () => dashboard.goToNextDay(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.chevron_left, color: AppColors.ivory, size: 22),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrCard(DashboardController dashboard) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: SizedBox(
            height: 60,
            child: dashboard.currentDhikr.isNotEmpty
                ? Center(child: Text(dashboard.currentDhikr, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ivory)))
                : const Center(child: Text('سبحان الله وبحمده', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ivory))),
          ),
        ),
        Positioned(
          top: 6, left: 6,
          child: GestureDetector(
            onTap: () => dashboard.refreshDhikr(),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.refresh, size: 16, color: AppColors.ivory),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAyahCard(DashboardController dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('آية اليوم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ivory)),
          const SizedBox(height: 8),
          if (dashboard.currentVerse != null) ...[
            Text(dashboard.currentVerse!.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ivory, height: 1.8), textAlign: TextAlign.center),
            if (dashboard.currentTafsir.isNotEmpty) ...[const SizedBox(height: 8), Text(dashboard.currentTafsir, style: const TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.5))],
            if (dashboard.currentTranslation.isNotEmpty) ...[const SizedBox(height: 4), Text(dashboard.currentTranslation, style: const TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5))],
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: Text('سورة ${dashboard.currentVerse!.surahName} - الآية ${dashboard.currentVerse!.ayah}', style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
          ] else ...[
            const Center(child: Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ivory, height: 1.8), textAlign: TextAlign.center)),
          ],
        ],
      ),
    );
  }

  Widget _buildHadithCard(DashboardController dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('حديث اليوم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ivory)),
          const SizedBox(height: 8),
          if (dashboard.currentHadith.isNotEmpty) ...[
            Text(dashboard.currentHadith, style: const TextStyle(fontSize: 16, color: AppColors.ivory, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: Text(dashboard.currentHadithRef, style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
          ] else ...[
            const Center(child: Text('إن الله جميل يحب الجمال', style: TextStyle(fontSize: 16, color: AppColors.ivory, height: 1.6), textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: Text('رواه مسلم', style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
          ],
        ],
      ),
    );
  }
}
