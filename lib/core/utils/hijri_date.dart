import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Hijri date utilities for the Afaq dashboard.
/// Wraps the hijri package with convenience methods for display.
class HijriDateUtils {
  HijriDateUtils._();

  // ── Current Hijri Date ─────────────────────────────
  static HijriCalendar get today => HijriCalendar.now();

  /// Get formatted Hijri date string.
  /// e.g., "14 ربيع الآخر 1447" (Arabic) / "14 Rabi' al-Thani 1447" (English)
  static String format({required bool isArabic}) {
    final hijri = HijriCalendar.now();
    if (isArabic) {
      return '${hijri.hijriDay} ${_arabicMonthName(hijri.hijriMonth)} ${hijri.hijriYear}';
    }
    return '${hijri.hijriDay} ${_englishMonthName(hijri.hijriMonth)} ${hijri.hijriYear}';
  }

  /// Get Hijri date adjusted by [dayOffset] from today.
  static HijriCalendar adjustDays(int dayOffset) {
    final hijri = HijriCalendar.now();
    hijri.hijriDay = hijri.hijriDay + dayOffset;
    return hijri;
  }

  /// Format adjusted Hijri date with day offset.
  static String formatAdjusted({
    required int dayOffset,
    required bool isArabic,
  }) {
    final hijri = adjustDays(dayOffset);
    if (isArabic) {
      return '${hijri.hijriDay} ${_arabicMonthName(hijri.hijriMonth)} ${hijri.hijriYear}';
    }
    return '${hijri.hijriDay} ${_englishMonthName(hijri.hijriMonth)} ${hijri.hijriYear}';
  }

  /// Get formatted Gregorian date string.
  static String formatGregorian({required bool isArabic}) {
    final now = DateTime.now();
    if (isArabic) {
      return DateFormat('d MMMM yyyy', 'ar').format(now);
    }
    return DateFormat('d MMMM yyyy', 'en').format(now);
  }

  // ── Day of Week Checks (for Smart Context Cards) ──
  static bool get isSunday => DateTime.now().weekday == DateTime.sunday;
  static bool get isWednesday => DateTime.now().weekday == DateTime.wednesday;
  static bool get isThursday => DateTime.now().weekday == DateTime.thursday;
  static bool get isFriday => DateTime.now().weekday == DateTime.friday;

  /// Check if today is the 12th of a Hijri month (White Days).
  static bool get isWhiteDay => today.hijriDay == 12;

  /// Check if current time is in the last third of the night.
  /// (Approximation: last third before Fajr)
  static bool isLastThirdOfNight({
    required DateTime fajrTime,
    required DateTime maghribTime,
  }) {
    final now = DateTime.now();
    final nightStart = maghribTime;
    final nightEnd = fajrTime.add(const Duration(days: 1));
    final nightDuration = nightEnd.difference(nightStart);
    final lastThirdStart = nightStart.add(
      Duration(milliseconds: (nightDuration.inMilliseconds * 2 / 3).round()),
    );
    return now.isAfter(lastThirdStart) && now.isBefore(nightEnd);
  }

  // ── Arabic Month Names ─────────────────────────────
  static String _arabicMonthName(int month) {
    const names = [
      '', // placeholder for index 0
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    return month >= 1 && month <= 12 ? names[month] : '';
  }

  // ── English Month Names ────────────────────────────
  static String _englishMonthName(int month) {
    const names = [
      '', // placeholder for index 0
      'Muharram',
      'Safar',
      "Rabi' al-Awwal",
      "Rabi' al-Thani",
      'Jumada al-Ula',
      'Jumada al-Thani',
      'Rajab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      "Dhu al-Qi'dah",
      'Dhu al-Hijjah',
    ];
    return month >= 1 && month <= 12 ? names[month] : '';
  }
}
