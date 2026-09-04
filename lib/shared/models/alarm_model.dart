import 'dart:convert';

enum AlarmSection { prayers, sunnah, periodicDhikr, friday, custom }

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

enum SunnahType { qiyam, duha }

enum AlarmRepeatType { once, daily, weekly, custom }

class AlarmModel {
  final String id;
  final String nameAr;
  final AlarmSection section;
  final bool isEnabled;
  final bool preAlarmEnabled;
  final int preAlarmOffset;
  final bool exactAlarmEnabled;
  final String exactAlarmAudio;
  final bool postAlarmEnabled;
  final int postAlarmOffset;
  final int? customHour;
  final int? customMinute;
  final int frequencyHours;
  final int windowStartHour;
  final int windowStartMinute;
  final int windowEndHour;
  final int windowEndMinute;

  final AlarmRepeatType repeatType;
  final List<int> repeatDays;
  final bool vibrationEnabled;
  final int vibrationPattern;
  final bool snoozeEnabled;
  final int snoozeInterval;
  final int snoozeMaxCount;
  final String? customMessage;
  final bool ledEnabled;
  final int ledColor;
  final bool lockScreenVisible;
  final int priority;

  const AlarmModel({
    required this.id,
    required this.nameAr,
    required this.section,
    this.isEnabled = false,
    this.preAlarmEnabled = false,
    this.preAlarmOffset = 10,
    this.exactAlarmEnabled = true,
    this.exactAlarmAudio = 'assets/audio/notifications/athan-fajr.mp3',
    this.postAlarmEnabled = false,
    this.postAlarmOffset = 15,
    this.customHour,
    this.customMinute,
    this.frequencyHours = 2,
    this.windowStartHour = 8,
    this.windowStartMinute = 0,
    this.windowEndHour = 22,
    this.windowEndMinute = 0,
    this.repeatType = AlarmRepeatType.daily,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.vibrationEnabled = true,
    this.vibrationPattern = 0,
    this.snoozeEnabled = true,
    this.snoozeInterval = 5,
    this.snoozeMaxCount = 3,
    this.customMessage,
    this.ledEnabled = true,
    this.ledColor = 0,
    this.lockScreenVisible = true,
    this.priority = 1,
  });

  AlarmModel copyWith({
    bool? isEnabled,
    bool? preAlarmEnabled,
    int? preAlarmOffset,
    bool? exactAlarmEnabled,
    String? exactAlarmAudio,
    bool? postAlarmEnabled,
    int? postAlarmOffset,
    int? customHour,
    int? customMinute,
    int? frequencyHours,
    int? windowStartHour,
    int? windowStartMinute,
    int? windowEndHour,
    int? windowEndMinute,
    AlarmRepeatType? repeatType,
    List<int>? repeatDays,
    bool? vibrationEnabled,
    int? vibrationPattern,
    bool? snoozeEnabled,
    int? snoozeInterval,
    int? snoozeMaxCount,
    String? customMessage,
    bool? ledEnabled,
    int? ledColor,
    bool? lockScreenVisible,
    int? priority,
  }) {
    return AlarmModel(
      id: id,
      nameAr: nameAr,
      section: section,
      isEnabled: isEnabled ?? this.isEnabled,
      preAlarmEnabled: preAlarmEnabled ?? this.preAlarmEnabled,
      preAlarmOffset: preAlarmOffset ?? this.preAlarmOffset,
      exactAlarmEnabled: exactAlarmEnabled ?? this.exactAlarmEnabled,
      exactAlarmAudio: exactAlarmAudio ?? this.exactAlarmAudio,
      postAlarmEnabled: postAlarmEnabled ?? this.postAlarmEnabled,
      postAlarmOffset: postAlarmOffset ?? this.postAlarmOffset,
      customHour: customHour ?? this.customHour,
      customMinute: customMinute ?? this.customMinute,
      frequencyHours: frequencyHours ?? this.frequencyHours,
      windowStartHour: windowStartHour ?? this.windowStartHour,
      windowStartMinute: windowStartMinute ?? this.windowStartMinute,
      windowEndHour: windowEndHour ?? this.windowEndHour,
      windowEndMinute: windowEndMinute ?? this.windowEndMinute,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeInterval: snoozeInterval ?? this.snoozeInterval,
      snoozeMaxCount: snoozeMaxCount ?? this.snoozeMaxCount,
      customMessage: customMessage ?? this.customMessage,
      ledEnabled: ledEnabled ?? this.ledEnabled,
      ledColor: ledColor ?? this.ledColor,
      lockScreenVisible: lockScreenVisible ?? this.lockScreenVisible,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'nameAr': nameAr, 'section': section.index,
    'isEnabled': isEnabled,
    'preAlarmEnabled': preAlarmEnabled, 'preAlarmOffset': preAlarmOffset,
    'exactAlarmEnabled': exactAlarmEnabled, 'exactAlarmAudio': exactAlarmAudio,
    'postAlarmEnabled': postAlarmEnabled, 'postAlarmOffset': postAlarmOffset,
    'customHour': customHour, 'customMinute': customMinute,
    'frequencyHours': frequencyHours,
    'windowStartHour': windowStartHour, 'windowStartMinute': windowStartMinute,
    'windowEndHour': windowEndHour, 'windowEndMinute': windowEndMinute,
    'repeatType': repeatType.index,
    'repeatDays': repeatDays,
    'vibrationEnabled': vibrationEnabled,
    'vibrationPattern': vibrationPattern,
    'snoozeEnabled': snoozeEnabled,
    'snoozeInterval': snoozeInterval,
    'snoozeMaxCount': snoozeMaxCount,
    'customMessage': customMessage,
    'ledEnabled': ledEnabled,
    'ledColor': ledColor,
    'lockScreenVisible': lockScreenVisible,
    'priority': priority,
  };

  factory AlarmModel.fromJson(Map<String, dynamic> j) => AlarmModel(
    id: j['id'] ?? '', nameAr: j['nameAr'] ?? '',
    section: AlarmSection.values[j['section'] ?? 0],
    isEnabled: j['isEnabled'] ?? false,
    preAlarmEnabled: j['preAlarmEnabled'] ?? false,
    preAlarmOffset: j['preAlarmOffset'] ?? 10,
    exactAlarmEnabled: j['exactAlarmEnabled'] ?? true,
    exactAlarmAudio: j['exactAlarmAudio'] ?? 'assets/audio/notifications/athan-fajr.mp3',
    postAlarmEnabled: j['postAlarmEnabled'] ?? false,
    postAlarmOffset: j['postAlarmOffset'] ?? 15,
    customHour: j['customHour'], customMinute: j['customMinute'],
    frequencyHours: j['frequencyHours'] ?? 2,
    windowStartHour: j['windowStartHour'] ?? 8, windowStartMinute: j['windowStartMinute'] ?? 0,
    windowEndHour: j['windowEndHour'] ?? 22, windowEndMinute: j['windowEndMinute'] ?? 0,
    repeatType: AlarmRepeatType.values[j['repeatType'] ?? 1],
    repeatDays: j['repeatDays'] != null ? List<int>.from(j['repeatDays']) : [1, 2, 3, 4, 5, 6, 7],
    vibrationEnabled: j['vibrationEnabled'] ?? true,
    vibrationPattern: j['vibrationPattern'] ?? 0,
    snoozeEnabled: j['snoozeEnabled'] ?? true,
    snoozeInterval: j['snoozeInterval'] ?? 5,
    snoozeMaxCount: j['snoozeMaxCount'] ?? 3,
    customMessage: j['customMessage'],
    ledEnabled: j['ledEnabled'] ?? true,
    ledColor: j['ledColor'] ?? 0,
    lockScreenVisible: j['lockScreenVisible'] ?? true,
    priority: j['priority'] ?? 1,
  );

  static List<AlarmModel> defaultAlarms() => [
    const AlarmModel(id: 'fajr', nameAr: 'الفجر', section: AlarmSection.prayers),
    const AlarmModel(id: 'sunrise', nameAr: 'الشروق', section: AlarmSection.prayers),
    const AlarmModel(id: 'dhuhr', nameAr: 'الظهر', section: AlarmSection.prayers),
    const AlarmModel(id: 'asr', nameAr: 'العصر', section: AlarmSection.prayers),
    const AlarmModel(id: 'maghrib', nameAr: 'المغرب', section: AlarmSection.prayers),
    const AlarmModel(id: 'isha', nameAr: 'العشاء', section: AlarmSection.prayers),
    const AlarmModel(id: 'qiyam', nameAr: 'صلاة القيام', section: AlarmSection.sunnah),
    const AlarmModel(id: 'duha', nameAr: 'صلاة الضحى', section: AlarmSection.sunnah),
    const AlarmModel(id: 'hawqala', nameAr: 'الحوقلة الدورية', section: AlarmSection.periodicDhikr),
    const AlarmModel(id: 'friday_kahf', nameAr: 'سورة الكهف', section: AlarmSection.friday),
    const AlarmModel(id: 'friday_salawat', nameAr: 'الصلاة على النبي ﷺ', section: AlarmSection.friday),
  ];

  static String encodeList(List<AlarmModel> alarms) => json.encode(alarms.map((a) => a.toJson()).toList());
  static List<AlarmModel> decodeList(String source) => (json.decode(source) as List).map((e) => AlarmModel.fromJson(e as Map<String, dynamic>)).toList();
}
