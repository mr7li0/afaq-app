import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../utils/prayer_time_utils.dart';
import '../../shared/models/alarm_model.dart';
import 'local_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final Map<String, int> _snoozeCount = {};

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Aden'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (response.actionId == 'snooze') {
      _handleSnooze(payload);
    } else if (response.actionId == 'dismiss') {
      _handleDismiss(payload);
    }
  }

  Future<void> _handleSnooze(String alarmId) async {
    final currentCount = _snoozeCount[alarmId] ?? 0;
    final alarms = LocalStorageService().loadAlarms();
    final alarm = alarms.firstWhere(
      (a) => a.id == alarmId,
      orElse: () => AlarmModel(id: '', nameAr: '', section: AlarmSection.prayers),
    );

    if (currentCount < alarm.snoozeMaxCount) {
      _snoozeCount[alarmId] = currentCount + 1;
      final snoozeTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: alarm.snoozeInterval));

      await _schedule(
        id: alarmId.hashCode + 10000 + currentCount,
        title: 'إعادة التنبيه ${currentCount + 1}/${alarm.snoozeMaxCount}',
        body: alarm.customMessage ?? alarm.nameAr,
        scheduledTime: snoozeTime,
        alarmId: alarmId,
        vibrationEnabled: alarm.vibrationEnabled,
        vibrationPattern: alarm.vibrationPattern,
        ledEnabled: alarm.ledEnabled,
        ledColor: alarm.ledColor,
        priority: alarm.priority,
      );
    }
  }

  void _handleDismiss(String alarmId) {
    _snoozeCount.remove(alarmId);
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        await LocalStorageService().setNotificationPermissionRequested();
        return granted ?? false;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> requestPermissions() => requestNotificationPermission();

  Future<bool> requestExactAlarmPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestExactAlarmsPermission();
        return granted ?? false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    String? alarmId,
    bool vibrationEnabled = true,
    int vibrationPattern = 0,
    bool ledEnabled = true,
    int ledColor = 0,
    int priority = 1,
  }) async {
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final vibrationPatternList = _getVibrationPattern(vibrationPattern);
    final ledColorValue = _getLedColor(ledColor);

    final androidDetails = AndroidNotificationDetails(
      'afaq_alarms',
      'منبهات آفاق',
      channelDescription: 'تنبيهات الصلاة والأذكار',
      importance: Importance.max,
      priority: Priority.values[priority],
      enableVibration: vibrationEnabled,
      vibrationPattern: vibrationPatternList,
      ledColor: ledColorValue,
      enableLights: ledEnabled,
      ongoing: true,
      autoCancel: false,
      actions: [
        const AndroidNotificationAction('snooze', ' إعادة', showsUserInterface: true),
        const AndroidNotificationAction('dismiss', 'إغلاق', showsUserInterface: false),
      ],
    );

    await _plugin.zonedSchedule(
      id, title, body, scheduledTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: alarmId,
    );
  }

  Int64List _getVibrationPattern(int pattern) {
    switch (pattern) {
      case 0: return Int64List.fromList([0, 200, 100, 200]);
      case 1: return Int64List.fromList([0, 500, 200, 500]);
      case 2: return Int64List.fromList([0, 100, 50, 100, 50, 100]);
      case 3: return Int64List.fromList([0, 300, 100, 300, 100, 300, 100, 300]);
      default: return Int64List.fromList([0, 200, 100, 200]);
    }
  }

  Color _getLedColor(int color) {
    switch (color) {
      case 0: return const Color(0xFFFF0000);
      case 1: return const Color(0xFF00FF00);
      case 2: return const Color(0xFF0000FF);
      case 3: return const Color(0xFFFFFF00);
      default: return const Color(0xFFFF0000);
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    String? alarmId,
    bool vibrationEnabled = true,
    int vibrationPattern = 0,
    bool ledEnabled = true,
    int ledColor = 0,
    int priority = 1,
  }) async {
    final vibrationPatternList = _getVibrationPattern(vibrationPattern);
    final ledColorValue = _getLedColor(ledColor);

    final androidDetails = AndroidNotificationDetails(
      'afaq_alarms', 'منبهات آفاق',
      channelDescription: 'تنبيهات الصلاة والأذكار',
      importance: Importance.max, priority: Priority.values[priority],
      enableVibration: vibrationEnabled, vibrationPattern: vibrationPatternList,
      ledColor: ledColorValue, enableLights: ledEnabled, ongoing: true, autoCancel: false,
      actions: [
        const AndroidNotificationAction('snooze', ' إعادة', showsUserInterface: true),
        const AndroidNotificationAction('dismiss', 'إغلاق', showsUserInterface: false),
      ],
    );

    await _plugin.zonedSchedule(
      id, title, body, scheduledTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: alarmId,
    );
  }

  Future<void> _schedulePeriodic({
    required int id,
    required String title,
    required String body,
    required Duration interval,
    String? alarmId,
    bool vibrationEnabled = true,
    int vibrationPattern = 0,
    bool ledEnabled = true,
    int ledColor = 0,
    int priority = 1,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final next = now.add(interval);
    final vibrationPatternList = _getVibrationPattern(vibrationPattern);
    final ledColorValue = _getLedColor(ledColor);

    final androidDetails = AndroidNotificationDetails(
      'afaq_dhikr', 'منبهات الذكر',
      channelDescription: 'تذكيرات دورية بالأذكار',
      importance: Importance.defaultImportance, priority: Priority.values[priority],
      enableVibration: vibrationEnabled, vibrationPattern: vibrationPatternList,
      ledColor: ledColorValue, enableLights: ledEnabled,
    );

    await _plugin.zonedSchedule(
      id, title, body, next,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: alarmId,
    );
  }

  Future<void> cancelAlarm(int id) async { await _plugin.cancel(id); }
  Future<void> cancelAll() async { await _plugin.cancelAll(); }

  Future<void> schedulePrayerAlarm(AlarmModel alarm, {required double latitude, required double longitude, required String method}) async {
    if (!alarm.isEnabled) { await _cancelAlarmGroup(alarm.id); return; }

    final now = tz.TZDateTime.now(tz.local);
    final todayPrayers = _calculatePrayerTimes(latitude, longitude, method, now);
    final tomorrowPrayers = _calculatePrayerTimes(latitude, longitude, method, now.add(const Duration(days: 1)));

    final prayerNames = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final prayerNamesAr = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final prayerTimesToday = [todayPrayers['fajr']!, todayPrayers['sunrise']!, todayPrayers['dhuhr']!, todayPrayers['asr']!, todayPrayers['maghrib']!, todayPrayers['isha']!];
    final prayerTimesTomorrow = [tomorrowPrayers['fajr']!, tomorrowPrayers['sunrise']!, tomorrowPrayers['dhuhr']!, tomorrowPrayers['asr']!, tomorrowPrayers['maghrib']!, tomorrowPrayers['isha']!];

    for (int i = 0; i < prayerNames.length; i++) {
      final pNameAr = prayerNamesAr[i];
      final pTime = prayerTimesToday[i];
      final pTimeTomorrow = prayerTimesTomorrow[i];
      final idBase = '${alarm.id}_${prayerNames[i]}'.hashCode;

      if (alarm.preAlarmEnabled) {
        final preTime = pTime.subtract(Duration(minutes: alarm.preAlarmOffset));
        if (preTime.isAfter(now)) {
          await _schedule(id: idBase + 1, title: 'تنبيه قبل الأذان', body: alarm.customMessage ?? 'صلاة $pNameAr بعد ${alarm.preAlarmOffset} دقيقة', scheduledTime: preTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        } else {
          final preTimeTomorrow = pTimeTomorrow.subtract(Duration(minutes: alarm.preAlarmOffset));
          await _schedule(id: idBase + 1, title: 'تنبيه قبل الأذان', body: alarm.customMessage ?? 'صلاة $pNameAr بعد ${alarm.preAlarmOffset} دقيقة', scheduledTime: preTimeTomorrow, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        }
      }

      if (alarm.exactAlarmEnabled) {
        if (pTime.isAfter(now)) {
          await _schedule(id: idBase + 2, title: pNameAr, body: alarm.customMessage ?? 'حان وقت $pNameAr', scheduledTime: pTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        } else {
          await _schedule(id: idBase + 2, title: pNameAr, body: alarm.customMessage ?? 'حان وقت $pNameAr', scheduledTime: pTimeTomorrow, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        }
      }

      if (alarm.postAlarmEnabled) {
        final postTime = pTime.add(Duration(minutes: alarm.postAlarmOffset));
        if (postTime.isAfter(now)) {
          await _schedule(id: idBase + 3, title: 'تنبيه الإقامة', body: alarm.customMessage ?? 'إقامة $pNameAr', scheduledTime: postTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        } else {
          final postTimeTomorrow = pTimeTomorrow.add(Duration(minutes: alarm.postAlarmOffset));
          await _schedule(id: idBase + 3, title: 'تنبيه الإقامة', body: alarm.customMessage ?? 'إقامة $pNameAr', scheduledTime: postTimeTomorrow, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        }
      }
    }
  }

  Map<String, tz.TZDateTime> _calculatePrayerTimes(double lat, double lon, String method, tz.TZDateTime date) {
    final times = PrayerTimeUtils.calculate(latitude: lat, longitude: lon, methodName: method, date: DateTime(date.year, date.month, date.day));
    return {
      'fajr': _dateTimeToTZ(times.fajr), 'sunrise': _dateTimeToTZ(times.sunrise),
      'dhuhr': _dateTimeToTZ(times.dhuhr), 'asr': _dateTimeToTZ(times.asr),
      'maghrib': _dateTimeToTZ(times.maghrib), 'isha': _dateTimeToTZ(times.isha),
    };
  }

  tz.TZDateTime _dateTimeToTZ(DateTime dt) => tz.TZDateTime(tz.local, dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  Future<void> scheduleQiyamAlarm(AlarmModel alarm, {required double latitude, required double longitude, required String method}) async {
    if (!alarm.isEnabled) { await cancelAlarm(alarm.id.hashCode); return; }

    final now = tz.TZDateTime.now(tz.local);
    final todayPrayers = _calculatePrayerTimes(latitude, longitude, method, now);
    final tomorrowPrayers = _calculatePrayerTimes(latitude, longitude, method, now.add(const Duration(days: 1)));

    final maghribTime = todayPrayers['maghrib']!;
    final fajrTime = tomorrowPrayers['fajr']!;
    final nightDuration = fajrTime.difference(maghribTime);
    final lastThirdStart = fajrTime.subtract(Duration(milliseconds: nightDuration.inMilliseconds ~/ 3));

    tz.TZDateTime scheduledTime;
    if (alarm.customHour != null && alarm.customMinute != null) {
      scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, alarm.customHour!, alarm.customMinute!);
      if (scheduledTime.isBefore(now)) scheduledTime = scheduledTime.add(const Duration(days: 1));
    } else {
      scheduledTime = lastThirdStart;
      if (scheduledTime.isBefore(now)) {
        final tomorrowMaghrib = todayPrayers['maghrib']!;
        final dayAfterFajr = _calculatePrayerTimes(latitude, longitude, method, now.add(const Duration(days: 2)))['fajr']!;
        final nightDur2 = dayAfterFajr.difference(tomorrowMaghrib);
        scheduledTime = dayAfterFajr.subtract(Duration(milliseconds: nightDur2.inMilliseconds ~/ 3));
      }
    }

    await _schedule(id: alarm.id.hashCode, title: 'صلاة القيام', body: alarm.customMessage ?? 'وقت صلاة القيام - الثلث الأخير من الليل', scheduledTime: scheduledTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
  }

  Future<void> scheduleDuhaAlarm(AlarmModel alarm, {required double latitude, required double longitude, required String method}) async {
    if (!alarm.isEnabled) { await cancelAlarm(alarm.id.hashCode); return; }

    final now = tz.TZDateTime.now(tz.local);
    final todayPrayers = _calculatePrayerTimes(latitude, longitude, method, now);
    final tomorrowPrayers = _calculatePrayerTimes(latitude, longitude, method, now.add(const Duration(days: 1)));

    tz.TZDateTime scheduledTime;
    if (alarm.customHour != null && alarm.customMinute != null) {
      scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, alarm.customHour!, alarm.customMinute!);
      if (scheduledTime.isBefore(now)) scheduledTime = scheduledTime.add(const Duration(days: 1));
    } else {
      scheduledTime = todayPrayers['sunrise']!.add(const Duration(minutes: 15));
      if (scheduledTime.isBefore(now)) scheduledTime = tomorrowPrayers['sunrise']!.add(const Duration(minutes: 15));
    }

    await _schedule(id: alarm.id.hashCode, title: 'صلاة الضحى', body: alarm.customMessage ?? 'حان وقت صلاة الضحى', scheduledTime: scheduledTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
  }

  Future<void> schedulePeriodicDhikr(AlarmModel alarm) async {
    if (!alarm.isEnabled) { await cancelAlarm(alarm.id.hashCode); return; }
    await _schedulePeriodic(id: alarm.id.hashCode, title: 'تذكير بالذكر', body: alarm.customMessage ?? 'سبحان الله وبحمده', interval: Duration(hours: alarm.frequencyHours), alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
  }

  Future<void> scheduleFridayReminder(AlarmModel alarm) async {
    if (!alarm.isEnabled) { await cancelAlarm(alarm.id.hashCode); return; }

    final now = tz.TZDateTime.now(tz.local);
    final hour = alarm.customHour ?? 10;
    final minute = alarm.customMinute ?? 0;
    final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) return;

    final title = alarm.id == 'friday_kahf' ? 'قراءة سورة الكهف' : 'الصلاة على النبي ﷺ';
    final body = alarm.id == 'friday_kahf' ? (alarm.customMessage ?? 'أكمل قراءة سورة الكهف يوم الجمعة') : (alarm.customMessage ?? 'صلِّ على النبي ﷺ يوم الجمعة');

    await _scheduleWeekly(id: alarm.id.hashCode, title: title, body: body, scheduledTime: scheduledTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
  }

  Future<void> scheduleCustomAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) { await cancelAlarm(alarm.id.hashCode); return; }
    if (alarm.customHour == null || alarm.customMinute == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, alarm.customHour!, alarm.customMinute!);
    if (scheduledTime.isBefore(now)) scheduledTime = scheduledTime.add(const Duration(days: 1));

    switch (alarm.repeatType) {
      case AlarmRepeatType.once:
        await _schedule(id: alarm.id.hashCode, title: alarm.nameAr, body: alarm.customMessage ?? alarm.nameAr, scheduledTime: scheduledTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        break;
      case AlarmRepeatType.daily:
        await _schedulePeriodic(id: alarm.id.hashCode, title: alarm.nameAr, body: alarm.customMessage ?? alarm.nameAr, interval: const Duration(days: 1), alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        break;
      case AlarmRepeatType.weekly:
        await _scheduleWeekly(id: alarm.id.hashCode, title: alarm.nameAr, body: alarm.customMessage ?? alarm.nameAr, scheduledTime: scheduledTime, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        break;
      case AlarmRepeatType.custom:
        for (final day in alarm.repeatDays) {
          final daySchedule = scheduledTime.add(Duration(days: (day - now.weekday) % 7));
          if (daySchedule.isBefore(now)) daySchedule.add(const Duration(days: 7));
          await _schedule(id: alarm.id.hashCode + day, title: alarm.nameAr, body: alarm.customMessage ?? alarm.nameAr, scheduledTime: daySchedule, alarmId: alarm.id, vibrationEnabled: alarm.vibrationEnabled, vibrationPattern: alarm.vibrationPattern, ledEnabled: alarm.ledEnabled, ledColor: alarm.ledColor, priority: alarm.priority);
        }
        break;
    }
  }

  Future<void> scheduleAthanNotification({required String prayerName, required DateTime exactTime, required bool isArabic, required bool fiveMinutesBefore}) async {
    if (fiveMinutesBefore) {
      final preTime = exactTime.subtract(const Duration(minutes: 5));
      if (preTime.isAfter(DateTime.now())) {
        await _schedule(id: 'athan_pre_$prayerName'.hashCode, title: 'تنبيه قبل الأذان', body: 'صلاة $prayerName بعد 5 دقائق', scheduledTime: _dateTimeToTZ(preTime));
      }
    } else {
      if (exactTime.isAfter(DateTime.now())) {
        await _schedule(id: 'athan_$prayerName'.hashCode, title: prayerName, body: 'حان وقت $prayerName', scheduledTime: _dateTimeToTZ(exactTime));
      }
    }
  }

  Future<void> scheduleAllAlarms({required double latitude, required double longitude, required String method}) async {
    try {
      final alarms = LocalStorageService().loadAlarms();
      for (final alarm in alarms) {
        try {
          switch (alarm.section) {
            case AlarmSection.prayers:
              await schedulePrayerAlarm(alarm, latitude: latitude, longitude: longitude, method: method);
              break;
            case AlarmSection.sunnah:
              if (alarm.id == 'qiyam') await scheduleQiyamAlarm(alarm, latitude: latitude, longitude: longitude, method: method);
              else if (alarm.id == 'duha') await scheduleDuhaAlarm(alarm, latitude: latitude, longitude: longitude, method: method);
              break;
            case AlarmSection.periodicDhikr:
              await schedulePeriodicDhikr(alarm);
              break;
            case AlarmSection.friday:
              await scheduleFridayReminder(alarm);
              break;
            case AlarmSection.custom:
              await scheduleCustomAlarm(alarm);
              break;
          }
        } catch (e) {
          debugPrint('Error scheduling alarm ${alarm.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in scheduleAllAlarms: $e');
    }
  }

  Future<void> _cancelAlarmGroup(String groupId) async {
    final baseId = groupId.hashCode;
    for (int i = 0; i < 20; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<List<PendingNotificationRequest>> getPending() async {
    return await _plugin.pendingNotificationRequests();
  }
}
