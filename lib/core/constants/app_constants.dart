/// Global app constants used across all features.
class AppConstants {
  AppConstants._();

  // ── App Identity ───────────────────────────────────
  static const String appName = 'آفاق';
  static const String appNameEn = 'Afaq';
  static const String appTagline = 'رفيقك الروحي اليومي';

  // ── Font Families ──────────────────────────────────
  static const String fontArabic = 'Milan';
  static const String fontEnglish = '.SF Pro Text';
  static const String fontQuran = 'Uthmani';

  // ── Hive Box Names ─────────────────────────────────
  static const String boxSettings = 'settings';
  static const String boxBookmarks = 'bookmarks';
  static const String boxWirdProgress = 'wird_progress';
  static const String boxAthkarCounters = 'athkar_counters';
  static const String boxAlarms = 'alarms';
  static const String boxReadHistory = 'read_history';

  // ── SharedPreferences Keys ─────────────────────────
  static const String keyLocale = 'app_locale';
  static const String keyDarkMode = 'dark_mode';
  static const String keyLastReadPage = 'last_read_page';
  static const String keyWirdGoal = 'wird_goal';
  static const String keyWirdGoalType = 'wird_goal_type';
  static const String keyQuietHoursStart = 'quiet_hours_start';
  static const String keyQuietHoursEnd = 'quiet_hours_end';
  static const String keyHawqalaEnabled = 'hawqala_enabled';
  static const String keySalawatEnabled = 'salawat_enabled';
  static const String keyKhushooMode = 'khushoo_mode';
  static const String keyLatitude = 'latitude';
  static const String keyLongitude = 'longitude';
  static const String keyCalculationMethod = 'calculation_method';
  static const String keyMadhab = 'madhab';

  // ── Asset Paths ────────────────────────────────────
  static const String quranDataPath = 'assets/data/quran_data.json';
  static const String tafsirDataPath = 'assets/data/tafsir.json';
  static const String translationDataPath = 'assets/data/translation.json';
  static const String hisnAlMuslimPath = 'assets/data/hisn_almuslim.json';
  static const String bukhariPath = 'assets/data/bukhari.json';
  static const String muslimPath = 'assets/data/muslim.json';
  static const String tirmidhiPath = 'assets/data/tirmidhi.json';
  static const String adhkarDuaaPath = 'assets/data/adhkar-duaa.json';
  static const String langArPath = 'assets/lang/ar.json';
  static const String langEnPath = 'assets/lang/en.json';

  // ── Audio Asset Paths ──────────────────────────────
  static const String audioBasePath = 'assets/audio/notifications';
  static const String athanFajr = '$audioBasePath/athan-fajr.mp3';
  static const String athanDuhr = '$audioBasePath/athan-dhuhr.mp3';
  static const String athanAsr = '$audioBasePath/athan-asr.mp3';
  static const String athanMaghrib = '$audioBasePath/athan-maghrib.mp3';
  static const String athanIsha = '$audioBasePath/athan-isha.mp3';
  static const String athkarMorning = '$audioBasePath/athkar-morning.mp3';
  static const String athkarEvening = '$audioBasePath/athkar-evening.mp3';
  static const String athkarSleep = '$audioBasePath/athkar-sleep.mp3';
  static const String duha = '$audioBasePath/duha.mp3';
  static const String fastingMonday = '$audioBasePath/fasting-monday.mp3';
  static const String fastingThursday = '$audioBasePath/fasting-thursday.mp3';
  static const String fridayAthan = '$audioBasePath/friday-athan.mp3';
  static const String midnight = '$audioBasePath/midnight.mp3';
  static const String qiyam = '$audioBasePath/qiyam.mp3';
  static const String whiteDays = '$audioBasePath/white-days.mp3';

  // ── Quran Constants ────────────────────────────────
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  static const int totalPages = 604;
  static const int totalJuz = 30;

  // ── Animation Durations ────────────────────────────
  static const Duration microBounceDuration = Duration(milliseconds: 250);
  static const Duration fadeTransitionDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // ── Glassmorphism Defaults ─────────────────────────
  static const double glassBlur = 12.0;
  static const double glassOpacity = 0.35; // Semi-transparent slate
  static const double glassBorderOpacity = 0.15; // 15% Ivory reflection
  static const double glassBorderWidth = 1.2;

  // ── Design System ──────────────────────────────────
  static const double borderRadiusCards = 20.0;
  static const double borderRadiusStadium = 50.0;
  static const double defaultPadding = 16.0;
  static const double defaultPaddingSmall = 8.0;
  static const double defaultPaddingLarge = 24.0;

  // ── Ayah of the Day ────────────────────────────────
  static const int maxSearchResults = 15;
  static const int ayahRefreshHour = 0; // Midnight refresh

  // ── Wird Defaults ──────────────────────────────────
  static const int defaultDailyPages = 4;
  static const int defaultDailyJuz = 1;
  static const int defaultDailyMinutes = 15;
}
