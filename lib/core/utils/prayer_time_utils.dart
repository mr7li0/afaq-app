import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

/// Prayer time calculation utilities using the adhan library.
class PrayerTimeUtils {
  PrayerTimeUtils._();

  static const Map<String, CalculationMethod> calculationMethods = {
    'Umm Al-Qura': CalculationMethod.umm_al_qura,
    'Egyptian Authority': CalculationMethod.egyptian,
    'Muslim World League': CalculationMethod.muslim_world_league,
    'Kuwait': CalculationMethod.kuwait,
    'Qatar': CalculationMethod.qatar,
    'Singapore': CalculationMethod.singapore,
    'Turkey': CalculationMethod.turkey,
    'Tehran': CalculationMethod.tehran,
    'Karachi': CalculationMethod.karachi,
  };

  static const Map<String, String> methodNamesAr = {
    'Umm Al-Qura': 'أم القرى',
    'Egyptian Authority': 'الهيئة المصرية العامة للمساحة',
    'Muslim World League': 'رابطة العالم الإسلامي',
    'Kuwait': 'الكويت',
    'Qatar': 'قطر',
    'Singapore': 'سنغافورة',
    'Turkey': 'تركيا',
    'Tehran': 'طهران',
    'Karachi': 'كراتشي',
  };

  static const Map<String, Madhab> madhabOptions = {
    'Shafi\'i': Madhab.shafi,
    'Hanafi': Madhab.hanafi,
  };

  static const Map<String, String> madhabNamesAr = {
    'Shafi\'i': 'الشافعي',
    'Hanafi': 'الحنفي',
  };

  static PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required String methodName,
    String madhabName = 'Shafi\'i',
    DateTime? date,
  }) {
    final coords = Coordinates(latitude, longitude);
    final method = calculationMethods[methodName] ?? CalculationMethod.umm_al_qura;
    final madhab = madhabOptions[madhabName] ?? Madhab.shafi;
    final params = method.getParameters();
    params.madhab = madhab;

    return PrayerTimes.today(coords, params);
  }

  static Prayer getNextPrayer({
    required double latitude,
    required double longitude,
    required String methodName,
    String madhabName = 'Shafi\'i',
  }) {
    final times = calculate(
      latitude: latitude,
      longitude: longitude,
      methodName: methodName,
      madhabName: madhabName,
    );
    return times.nextPrayer();
  }

  static Duration? getTimeUntilNext({
    required double latitude,
    required double longitude,
    required String methodName,
    String madhabName = 'Shafi\'i',
  }) {
    final times = calculate(
      latitude: latitude,
      longitude: longitude,
      methodName: methodName,
      madhabName: madhabName,
    );
    return times.timeForPrayer(times.nextPrayer())?.difference(DateTime.now());
  }

  static String formatDuration(Duration duration, {required bool isArabic}) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (isArabic) {
      if (hours > 0) return '$hours ساعة و $minutes دقيقة';
      return '$minutes دقيقة و $seconds ثانية';
    }
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m ${seconds}s';
  }

  static String formatPrayerTime(DateTime time, {required bool isArabic, bool use24Hour = false}) {
    if (use24Hour) return DateFormat('HH:mm').format(time);
    if (isArabic) return DateFormat('hh:mm a', 'ar').format(time);
    return DateFormat('hh:mm a', 'en').format(time);
  }

  static String getAthanAssetPath(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr': return 'assets/audio/notifications/athan-fajr.mp3';
      case 'dhuhr': return 'assets/audio/notifications/athan-dhuhr.mp3';
      case 'asr': return 'assets/audio/notifications/athan-asr.mp3';
      case 'maghrib': return 'assets/audio/notifications/athan-maghrib.mp3';
      case 'isha': return 'assets/audio/notifications/athan-isha.mp3';
      default: return 'assets/audio/notifications/athan-fajr.mp3';
    }
  }

  static String displayName(String prayerName, {required bool isArabic}) {
    const ar = {'fajr': 'الفجر', 'sunrise': 'الشروق', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء'};
    const en = {'fajr': 'Fajr', 'sunrise': 'Sunrise', 'dhuhr': 'Dhuhr', 'asr': 'Asr', 'maghrib': 'Maghrib', 'isha': 'Isha'};
    if (isArabic) return ar[prayerName.toLowerCase()] ?? prayerName;
    return en[prayerName.toLowerCase()] ?? prayerName;
  }
}
