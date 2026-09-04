import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../../shared/models/quran_verse.dart';

class DashboardController extends ChangeNotifier {
  Timer? _countdownTimer;

  String _nextPrayerName = '';
  String _nextPrayerTimeStr = '';
  String _countdownText = '00:00:00';
  double _prayerProgress = 0.0;
  List<MapEntry<String, String>> _fivePrayers = [];

  DateTime _selectedDate = DateTime.now();

  String _currentDhikr = '';
  int _lastDhikrMinute = -1;

  QuranVerse? _currentVerse;
  String _currentTafsir = '';
  String _currentTranslation = '';
  List<QuranVerse> _allVerses = [];
  Map<int, Map<int, String>> _tafsirData = {};
  Map<int, Map<int, String>> _translationData = {};

  String _currentHadith = '';
  String _currentHadithRef = '';
  List<Map<String, String>> _allHadiths = [];

  bool _isLoading = true;
  bool _isInitialized = false;

  String get nextPrayerName => _nextPrayerName;
  String get nextPrayerTimeStr => _nextPrayerTimeStr;
  String get countdownText => _countdownText;
  double get prayerProgress => _prayerProgress;
  List<MapEntry<String, String>> get fivePrayers => _fivePrayers;
  String get currentDhikr => _currentDhikr;
  QuranVerse? get currentVerse => _currentVerse;
  String get currentTafsir => _currentTafsir;
  String get currentTranslation => _currentTranslation;
  String get currentHadith => _currentHadith;
  String get currentHadithRef => _currentHadithRef;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  bool get isToday => _selectedDate.year == DateTime.now().year &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.day == DateTime.now().day;

  bool get canGoBack => _selectedDate.day > 1;
  bool get canGoForward {
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return _selectedDate.day < lastDay;
  }

  bool get canGoPreviousMonth {
    final now = DateTime.now();
    return _selectedDate.year > now.year || (_selectedDate.year == now.year && _selectedDate.month > now.month);
  }

  bool get canGoNextMonth {
    final now = DateTime.now();
    return _selectedDate.year < now.year || (_selectedDate.year == now.year && _selectedDate.month < now.month + 3);
  }

  String get selectedDateHijri {
    final hijri = HijriCalendar.fromDate(_selectedDate);
    return '${hijri.hDay} ${_hijriMonthName(hijri.hMonth)} ${hijri.hYear}';
  }

  String get selectedDateGregorian => DateFormat('d MMMM', 'ar').format(_selectedDate);

  String get selectedDayName {
    const days = ['', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[_selectedDate.weekday];
  }

  String get fullSelectedDate => '${selectedDayName}  ${selectedDateHijri}  •  ${selectedDateGregorian}';

  String get hijriDateStr {
    final hijri = HijriCalendar.now();
    return '${hijri.hDay} ${_hijriMonthName(hijri.hMonth)} ${hijri.hYear}';
  }

  String get gregorianDateStr => DateFormat('d/M', 'ar').format(DateTime.now());

  String get dayName {
    const days = ['', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[DateTime.now().weekday];
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadQuranData(),
        _loadHadithData(),
        _loadDhikrData(),
      ]);
      _loadAyahOfTheDay();
      _loadRandomDhikr();
      _loadRandomHadith();
      _startCountdown();
    } catch (e) {
      debugPrint('DashboardController init error: $e');
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  void refreshOnResume() {
    _selectedDate = DateTime.now();
    _loadRandomDhikr();
    _loadRandomHadith();
    _startCountdown();
    notifyListeners();
  }

  void refreshDhikr() {
    _lastDhikrMinute = -1;
    _loadRandomDhikr();
    notifyListeners();
  }

  void goToPreviousDay() {
    if (canGoBack) {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loadPrayersForSelectedDate();
      notifyListeners();
    } else {
      goToPreviousMonth();
    }
  }

  void goToNextDay() {
    if (canGoForward) {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _loadPrayersForSelectedDate();
      notifyListeners();
    } else {
      goToNextMonth();
    }
  }

  void goToPreviousMonth() {
    if (canGoPreviousMonth) {
      final newMonth = _selectedDate.month - 1;
      final newYear = _selectedDate.year + (newMonth < 1 ? -1 : 0);
      final month = newMonth < 1 ? 12 : newMonth;
      final lastDay = DateTime(newYear, month + 1, 0).day;
      final newDay = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
      _selectedDate = DateTime(newYear, month, newDay);
      _loadPrayersForSelectedDate();
      notifyListeners();
    }
  }

  void goToNextMonth() {
    if (canGoNextMonth) {
      final newMonth = _selectedDate.month + 1;
      final newYear = _selectedDate.year + (newMonth > 12 ? 1 : 0);
      final month = newMonth > 12 ? 1 : newMonth;
      final lastDay = DateTime(newYear, month + 1, 0).day;
      final newDay = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
      _selectedDate = DateTime(newYear, month, newDay);
      _loadPrayersForSelectedDate();
      notifyListeners();
    }
  }

  void resetToToday() {
    _selectedDate = DateTime.now();
    _loadPrayersForSelectedDate();
    notifyListeners();
  }

  Future<void> _loadQuranData() async {
    try {
      final jsonStr = (await rootBundle.loadString(AppConstants.quranDataPath)).replaceAll('\uFEFF', '');
      final List<dynamic> jsonList = json.decode(jsonStr);
      _allVerses = jsonList.map((e) => QuranVerse.fromJson(e)).toList();
    } catch (_) { _allVerses = []; }

    try {
      final tafsirStr = (await rootBundle.loadString(AppConstants.tafsirDataPath)).replaceAll('\uFEFF', '');
      final Map<String, dynamic> tj = json.decode(tafsirStr);
      final surahs = tj['data']?['surahs'] as List<dynamic>? ?? [];
      for (final surah in surahs) {
        final n = surah['number'] as int;
        final ayahs = surah['ayahs'] as List<dynamic>? ?? [];
        _tafsirData[n] = {};
        for (final ayah in ayahs) {
          final an = ayah['numberInSurah'] as int? ?? ayah['number'] as int;
          _tafsirData[n]![an] = ayah['text'] as String? ?? '';
        }
      }
    } catch (_) {}

    try {
      final transStr = (await rootBundle.loadString(AppConstants.translationDataPath)).replaceAll('\uFEFF', '');
      final Map<String, dynamic> tj = json.decode(transStr);
      final surahs = tj['data']?['surahs'] as List<dynamic>? ?? [];
      for (final surah in surahs) {
        final n = surah['number'] as int;
        final ayahs = surah['ayahs'] as List<dynamic>? ?? [];
        _translationData[n] = {};
        for (final ayah in ayahs) {
          final an = ayah['numberInSurah'] as int? ?? ayah['number'] as int;
          _translationData[n]![an] = ayah['text'] as String? ?? '';
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHadithData() async {
    _allHadiths = [];
    try {
      final raw = (await rootBundle.loadString(AppConstants.bukhariPath)).replaceAll('\uFEFF', '');
      final List<dynamic> list = json.decode(raw);
      for (final item in list) {
        final text = item['text'] as String? ?? '';
        if (text.length > 30) _allHadiths.add({'text': text, 'ref': 'صحيح البخاري'});
      }
    } catch (_) {}
    try {
      final raw = (await rootBundle.loadString(AppConstants.muslimPath)).replaceAll('\uFEFF', '');
      final List<dynamic> list = json.decode(raw);
      for (final item in list) {
        final text = item['text'] as String? ?? '';
        if (text.length > 30) _allHadiths.add({'text': text, 'ref': 'صحيح مسلم'});
      }
    } catch (_) {}
    try {
      final raw = (await rootBundle.loadString(AppConstants.tirmidhiPath)).replaceAll('\uFEFF', '');
      final List<dynamic> list = json.decode(raw);
      for (final item in list) {
        final text = item['text'] as String? ?? '';
        final grade = item['grade'] as String? ?? '';
        if (text.length > 30 && (grade.contains('Sahih') || grade.contains('Hasan'))) {
          _allHadiths.add({'text': text, 'ref': 'سنن الترمذي'});
        }
      }
    } catch (_) {}
  }

  List<Map<String, String>> _adhkarItems = [];

  Future<void> _loadDhikrData() async {
    try {
      final raw = (await rootBundle.loadString(AppConstants.adhkarDuaaPath)).replaceAll('\uFEFF', '');
      final Map<String, dynamic> data = json.decode(raw);
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final category = item['category'] as String? ?? '';
        final text = item['text'] as String? ?? '';
        if (text.isNotEmpty) _adhkarItems.add({'text': text, 'category': category});
      }
    } catch (_) {}
  }

  void _loadAyahOfTheDay() {
    if (_allVerses.isEmpty) return;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    _currentVerse = _allVerses[dayOfYear % _allVerses.length];
    if (_currentVerse != null) {
      _currentTafsir = _tafsirData[_currentVerse!.surah]?[_currentVerse!.ayah] ?? '';
      _currentTranslation = _translationData[_currentVerse!.surah]?[_currentVerse!.ayah] ?? '';
    }
  }

  void _loadRandomDhikr() {
    final now = DateTime.now();
    final currentMinute = now.hour * 60 + now.minute;
    if (currentMinute != _lastDhikrMinute && _adhkarItems.isNotEmpty) {
      _lastDhikrMinute = currentMinute;
      final item = _adhkarItems[Random().nextInt(_adhkarItems.length)];
      _currentDhikr = item['text']!;
    } else if (_adhkarItems.isEmpty) {
      _currentDhikr = 'سبحان الله وبحمده سبحان الله العظيم';
    }
  }

  void _loadRandomHadith() {
    if (_allHadiths.isNotEmpty) {
      final h = _allHadiths[Random().nextInt(_allHadiths.length)];
      _currentHadith = h['text']!;
      _currentHadithRef = h['ref']!;
    } else {
      _currentHadith = 'إن الله جميل يحب الجمال';
      _currentHadithRef = 'رواه مسلم';
    }
  }

  void _loadPrayersForSelectedDate() {
    try {
      final lat = LocalStorageService().latitude;
      final lon = LocalStorageService().longitude;
      final method = LocalStorageService().calculationMethod;

      final times = PrayerTimeUtils.calculate(
        latitude: lat, longitude: lon, methodName: method, date: _selectedDate,
      );
      final prayerNamesAr = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
      final prayerDateTimes = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha];

      _fivePrayers = [];
      for (int i = 0; i < prayerNamesAr.length; i++) {
        _fivePrayers.add(MapEntry(prayerNamesAr[i], DateFormat('h:mm a', 'ar').format(prayerDateTimes[i])));
      }

      if (isToday) {
        _updateCountdownFromTimes(prayerDateTimes, prayerNamesAr);
      } else {
        _nextPrayerName = prayerNamesAr[0];
        _nextPrayerTimeStr = DateFormat('h:mm a', 'ar').format(prayerDateTimes[0]);
        _countdownText = DateFormat('h:mm a', 'ar').format(prayerDateTimes[0]);
        _prayerProgress = 1.0;
      }
    } catch (e) {
      debugPrint('Prayer load error: $e');
    }
    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    try {
      final lat = LocalStorageService().latitude;
      final lon = LocalStorageService().longitude;
      final method = LocalStorageService().calculationMethod;

      final times = PrayerTimeUtils.calculate(latitude: lat, longitude: lon, methodName: method);
      final prayerNamesAr = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
      final prayerDateTimes = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha];

      _updateCountdownFromTimes(prayerDateTimes, prayerNamesAr);

      if (isToday) {
        _fivePrayers = [];
        for (int i = 0; i < prayerNamesAr.length; i++) {
          _fivePrayers.add(MapEntry(prayerNamesAr[i], DateFormat('h:mm a', 'ar').format(prayerDateTimes[i])));
        }
      }
    } catch (e) {
      debugPrint('Countdown error: $e');
      _countdownText = '--:--:--';
      _nextPrayerName = 'الفجر';
      _prayerProgress = 0.0;
      if (_fivePrayers.isEmpty) {
        _fivePrayers = [
          const MapEntry('الفجر', '--:--'),
          const MapEntry('الشروق', '--:--'),
          const MapEntry('الظهر', '--:--'),
          const MapEntry('العصر', '--:--'),
          const MapEntry('المغرب', '--:--'),
          const MapEntry('العشاء', '--:--'),
        ];
      }
    }
    notifyListeners();
  }

  void _updateCountdownFromTimes(List<DateTime> prayerDateTimes, List<String> prayerNamesAr) {
    final now = DateTime.now();

    DateTime? nextTime;
    String nextName = '';
    DateTime? prevTime;

    for (int i = 0; i < prayerNamesAr.length; i++) {
      if (prayerDateTimes[i].isAfter(now)) {
        nextTime = prayerDateTimes[i];
        nextName = prayerNamesAr[i];
        prevTime = i > 0 ? prayerDateTimes[i - 1] : null;
        break;
      }
    }

    nextTime ??= prayerDateTimes[0].add(const Duration(days: 1));
    if (nextName.isEmpty) nextName = 'الفجر';

    _nextPrayerName = nextName;
    _nextPrayerTimeStr = DateFormat('h:mm a', 'ar').format(nextTime);

    final remaining = nextTime.difference(now);
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    _countdownText = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    if (prevTime != null) {
      final totalDuration = nextTime.difference(prevTime);
      final remainingDuration = nextTime.difference(now);
      _prayerProgress = (remainingDuration.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
    } else {
      final lastPrayerYesterday = prayerDateTimes[0].subtract(const Duration(days: 1));
      final totalDuration = nextTime.difference(lastPrayerYesterday);
      final remainingDuration = nextTime.difference(now);
      _prayerProgress = (remainingDuration.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
    }
  }

  String _hijriMonthName(int month) {
    const names = ['', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
    return month >= 1 && month <= 12 ? names[month] : '';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
