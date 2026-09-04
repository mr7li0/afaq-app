import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../shared/models/alarm_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._();
  factory LocalStorageService() => _instance;
  LocalStorageService._();

  late Box _settingsBox;
  late Box _alarmsBox;
  SharedPreferences? _prefs;

  Box get settingsBox => _settingsBox;
  Box get alarmsBox => _alarmsBox;
  SharedPreferences get prefs => _prefs!;

  Future<void> init() async {
    _settingsBox = Hive.isBoxOpen(AppConstants.boxSettings)
        ? Hive.box(AppConstants.boxSettings)
        : await Hive.openBox(AppConstants.boxSettings);
    _alarmsBox = Hive.isBoxOpen(AppConstants.boxAlarms)
        ? Hive.box(AppConstants.boxAlarms)
        : await Hive.openBox(AppConstants.boxAlarms);
    _prefs = await SharedPreferences.getInstance();
  }

  String get locale => _settingsBox.get(AppConstants.keyLocale, defaultValue: 'ar');
  Future<void> setLocale(String code) => _settingsBox.put(AppConstants.keyLocale, code);

  bool get isFirstLaunch => _settingsBox.get('is_first_launch', defaultValue: true);
  Future<void> setFirstLaunchDone() => _settingsBox.put('is_first_launch', false);

  int get lastReadPage => _settingsBox.get(AppConstants.keyLastReadPage, defaultValue: 1);
  Future<void> setLastReadPage(int page) => _settingsBox.put(AppConstants.keyLastReadPage, page);

  double get latitude => (_settingsBox.get(AppConstants.keyLatitude) as num?)?.toDouble() ?? 21.4225;
  double get longitude => (_settingsBox.get(AppConstants.keyLongitude) as num?)?.toDouble() ?? 39.8262;
  Future<void> setLocation(double lat, double lon) async {
    await _settingsBox.put(AppConstants.keyLatitude, lat);
    await _settingsBox.put(AppConstants.keyLongitude, lon);
  }

  String get calculationMethod => _settingsBox.get(AppConstants.keyCalculationMethod, defaultValue: 'Umm Al-Qura');
  Future<void> setCalculationMethod(String method) => _settingsBox.put(AppConstants.keyCalculationMethod, method);

  List<AlarmModel> loadAlarms() {
    final raw = _alarmsBox.get('alarms_list');
    if (raw == null) {
      final defaults = AlarmModel.defaultAlarms();
      _alarmsBox.put('alarms_list', AlarmModel.encodeList(defaults));
      return defaults;
    }
    return AlarmModel.decodeList(raw as String);
  }

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    await _alarmsBox.put('alarms_list', AlarmModel.encodeList(alarms));
  }

  Future<void> updateAlarm(String id, AlarmModel updated) async {
    final alarms = loadAlarms();
    final index = alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      alarms[index] = updated;
      await saveAlarms(alarms);
    }
  }

  bool get notificationPermissionRequested => _prefs?.getBool('notif_perm_requested') ?? false;
  Future<void> setNotificationPermissionRequested() async { await _prefs?.setBool('notif_perm_requested', true); }

  String exportAllData() {
    final data = <String, dynamic>{
      'settings': Map<String, dynamic>.from(_settingsBox.toMap()),
      'alarms': _alarmsBox.get('alarms_list'),
      'locale': locale,
      'lastReadPage': lastReadPage,
    };
    return json.encode(data);
  }

  Future<void> importData(String jsonString) async {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    if (data.containsKey('settings')) {
      final settings = Map<String, dynamic>.from(data['settings']);
      for (final entry in settings.entries) {
        await _settingsBox.put(entry.key, entry.value);
      }
    }
    if (data.containsKey('alarms')) {
      await _alarmsBox.put('alarms_list', data['alarms']);
    }
  }

  Future<void> clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      for (final file in files) {
        try { file.deleteSync(recursive: true); } catch (_) {}
      }
    } catch (_) {}
  }

  Future<int> getCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      int size = 0;
      final files = dir.listSync(recursive: true);
      for (final file in files) {
        try {
          if (file is File) size += file.lengthSync();
        } catch (_) {}
      }
      return size;
    } catch (_) {}
    return 0;
  }

  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
