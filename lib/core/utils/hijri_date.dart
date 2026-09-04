import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Hijri date utilities for the Afaq dashboard.
class HijriDateUtils {
  HijriDateUtils._();

  static HijriCalendar get today => HijriCalendar.now();

  static String format({required bool isArabic}) {
    final hijri = HijriCalendar.now();
    if (isArabic) {
      return '${hijri.hDay} ${_arabicMonthName(hijri.hMonth)} ${hijri.hYear}';
    }
    return '${hijri.hDay} ${_englishMonthName(hijri.hMonth)} ${hijri.hYear}';
  }

  static HijriCalendar adjustDays(int dayOffset) {
    final hijri = HijriCalendar.now();
    hijri.hDay = hijri.hDay + dayOffset;
    return hijri;
  }

  static String formatAdjusted({
    required int dayOffset,
    required bool isArabic,
  }) {
    final hijri = adjustDays(dayOffset);
    if (isArabic) {
      return '${hijri.hDay} ${_arabicMonthName(hijri.hMonth)} ${hijri.hYear}';
    }
    return '${hijri.hDay} ${_englishMonthName(hijri.hMonth)} ${hijri.hYear}';
  }

  static String formatGregorian({required bool isArabic}) {
    final now = DateTime.now();
    if (isArabic) {
      return DateFormat('d MMMM yyyy', 'ar').format(now);
    }
    return DateFormat('d MMMM yyyy', 'en').format(now);
  }

  static bool get isSunday => DateTime.now().weekday == DateTime.sunday;
  static bool get isWednesday => DateTime.now().weekday == DateTime.wednesday;
  static bool get isThursday => DateTime.now().weekday == DateTime.thursday;
  static bool get isFriday => DateTime.now().weekday == DateTime.friday;

  static bool get isWhiteDay => today.hDay == 12;

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

  static String _arabicMonthName(int month) {
    const names = [
      '',
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

  static String _englishMonthName(int month) {
    const names = [
      '',
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
