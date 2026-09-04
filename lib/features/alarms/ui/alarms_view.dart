import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/alarm_model.dart';

class AlarmsView extends StatefulWidget {
  const AlarmsView({super.key});

  @override
  State<AlarmsView> createState() => _AlarmsViewState();
}

class _AlarmsViewState extends State<AlarmsView> {
  late List<AlarmModel> _alarms;
  bool _loading = true;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() {
    _alarms = LocalStorageService().loadAlarms();
    _loading = false;
    setState(() {});
  }

  Future<void> _toggleAlarm(String id, bool value) async {
    setState(() { _loading = true; });
    try {
      final idx = _alarms.indexWhere((a) => a.id == id);
      if (idx == -1) { setState(() { _loading = false; }); return; }
      final updated = _alarms[idx].copyWith(isEnabled: value);
      _alarms[idx] = updated;
      await LocalStorageService().updateAlarm(id, updated);

      if (value && !_permissionRequested) {
        try { await NotificationService().requestNotificationPermission(); } catch (_) {}
        _permissionRequested = true;
      }

      try {
        final loc = LocalStorageService();
        await NotificationService().scheduleAllAlarms(
          latitude: loc.latitude, longitude: loc.longitude, method: loc.calculationMethod,
        );
      } catch (_) {}
    } catch (_) {}
    setState(() { _loading = false; });
  }

  Future<void> _showAlarmPopup(AlarmModel alarm) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AlarmPopup(alarm: alarm, onSave: (updated) async {
        await LocalStorageService().updateAlarm(alarm.id, updated);
        final idx = _alarms.indexWhere((a) => a.id == alarm.id);
        if (idx != -1) _alarms[idx] = updated;
        final loc = LocalStorageService();
        await NotificationService().scheduleAllAlarms(
          latitude: loc.latitude, longitude: loc.longitude, method: loc.calculationMethod,
        );
        setState(() {});
        if (mounted) Navigator.pop(ctx);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.ivory))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildSectionHeader('الصلوات المفروضة', Icons.mosque),
                  ..._alarms.where((a) => a.section == AlarmSection.prayers).map(_buildAlarmCard),
                  _buildSectionHeader('الصلوات النافلة', Icons.nightlight_round),
                  ..._alarms.where((a) => a.section == AlarmSection.sunnah).map(_buildAlarmCard),
                  _buildSectionHeader('الأذكار الدورية', Icons.replay),
                  ..._alarms.where((a) => a.section == AlarmSection.periodicDhikr).map(_buildAlarmCard),
                  _buildSectionHeader('ذكريات يوم الجمعة', Icons.calendar_month),
                  ..._alarms.where((a) => a.section == AlarmSection.friday).map(_buildAlarmCard),
                  const SizedBox(height: 100),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ivory, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppColors.ivory, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(AlarmModel alarm) {
    final isPrayer = alarm.section == AlarmSection.prayers;
    final isSunnah = alarm.section == AlarmSection.sunnah;
    final isDhikr = alarm.section == AlarmSection.periodicDhikr;

    final String subtitle;
    if (isPrayer) {
      final parts = <String>[];
      if (alarm.preAlarmEnabled) parts.add('قبل ${alarm.preAlarmOffset} دقيقة');
      if (alarm.exactAlarmEnabled) parts.add('وقت الأذان');
      if (alarm.postAlarmEnabled) parts.add('بعد ${alarm.postAlarmOffset} دقيقة');
      subtitle = parts.isEmpty ? 'غير مفعّل' : parts.join(' • ');
    } else if (isSunnah) {
      if (alarm.id == 'qiyam') {
        subtitle = alarm.customHour != null ? 'وقت مخصص: ${alarm.customHour}:${(alarm.customMinute ?? 0).toString().padLeft(2, '0')}' : 'الثلث الأخير من الليل';
      } else {
        subtitle = alarm.customHour != null ? 'وقت مخصص: ${alarm.customHour}:${(alarm.customMinute ?? 0).toString().padLeft(2, '0')}' : 'بعد شروق الشمس 15 دقيقة';
      }
    } else if (isDhikr) {
      subtitle = 'كل ${alarm.frequencyHours} ساعات';
    } else {
      subtitle = alarm.customHour != null ? 'كل جمعة الساعة ${alarm.customHour}:${(alarm.customMinute ?? 0).toString().padLeft(2, '0')}' : 'كل جمعة';
    }

    return GestureDetector(
      onTap: () => _showAlarmPopup(alarm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: alarm.isEnabled ? AppColors.ivory.withValues(alpha: 0.3) : AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: alarm.isEnabled ? AppColors.ivory.withValues(alpha: 0.2) : AppColors.cardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getAlarmIcon(alarm), color: alarm.isEnabled ? AppColors.ivory : AppColors.textHint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(alarm.nameAr, style: const TextStyle(color: AppColors.ivory, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: alarm.isEnabled,
              onChanged: (v) => _toggleAlarm(alarm.id, v),
              activeThumbColor: AppColors.ivory,
              activeTrackColor: AppColors.ivory.withValues(alpha: 0.3),
              inactiveTrackColor: AppColors.cardElevated,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAlarmIcon(AlarmModel alarm) {
    switch (alarm.section) {
      case AlarmSection.prayers: return Icons.mosque;
      case AlarmSection.sunnah: return alarm.id == 'qiyam' ? Icons.nightlight_round : Icons.wb_sunny;
      case AlarmSection.periodicDhikr: return Icons.replay;
      case AlarmSection.friday: return Icons.calendar_month;
      case AlarmSection.custom: return Icons.alarm;
    }
  }
}

class _AlarmPopup extends StatefulWidget {
  final AlarmModel alarm;
  final Future<void> Function(AlarmModel updated) onSave;

  const _AlarmPopup({required this.alarm, required this.onSave});

  @override
  State<_AlarmPopup> createState() => _AlarmPopupState();
}

class _AlarmPopupState extends State<_AlarmPopup> {
  late bool _preEnabled;
  late int _preOffset;
  late bool _exactEnabled;
  String? _exactAudio;
  late bool _postEnabled;
  late int _postOffset;
  int? _customHour;
  int? _customMinute;
  late int _frequencyHours;
  late AlarmRepeatType _repeatType;
  late List<int> _repeatDays;
  late bool _vibrationEnabled;
  late int _vibrationPattern;
  late bool _snoozeEnabled;
  late int _snoozeInterval;
  late int _snoozeMaxCount;
  String? _customMessage;
  late bool _ledEnabled;
  late int _ledColor;
  late bool _lockScreenVisible;
  late int _priority;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _preEnabled = a.preAlarmEnabled;
    _preOffset = a.preAlarmOffset;
    _exactEnabled = a.exactAlarmEnabled;
    _exactAudio = a.exactAlarmAudio;
    _postEnabled = a.postAlarmEnabled;
    _postOffset = a.postAlarmOffset;
    _customHour = a.customHour;
    _customMinute = a.customMinute;
    _frequencyHours = a.frequencyHours;
    _repeatType = a.repeatType;
    _repeatDays = List<int>.from(a.repeatDays);
    _vibrationEnabled = a.vibrationEnabled;
    _vibrationPattern = a.vibrationPattern;
    _snoozeEnabled = a.snoozeEnabled;
    _snoozeInterval = a.snoozeInterval;
    _snoozeMaxCount = a.snoozeMaxCount;
    _customMessage = a.customMessage;
    _ledEnabled = a.ledEnabled;
    _ledColor = a.ledColor;
    _lockScreenVisible = a.lockScreenVisible;
    _priority = a.priority;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(widget.alarm.nameAr, style: const TextStyle(color: AppColors.ivory, fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.alarm.section == AlarmSection.prayers) ..._buildPrayerOptions(),
            if (widget.alarm.section == AlarmSection.sunnah) ..._buildSunnahOptions(),
            if (widget.alarm.section == AlarmSection.periodicDhikr) ..._buildDhikrOptions(),
            if (widget.alarm.section == AlarmSection.friday) ..._buildFridayOptions(),
            const SizedBox(height: 16),
            _buildSectionDivider('الترقيع'),
            _buildSnoozeOptions(),
            const SizedBox(height: 16),
            _buildSectionDivider('الاهتزاز والإضاءة'),
            _buildVibrationAndLightOptions(),
            const SizedBox(height: 16),
            _buildSectionDivider('رسالة مخصصة'),
            _buildCustomMessageField(),
            const SizedBox(height: 16),
            _buildSectionDivider('الأولوية'),
            _buildPrioritySelector(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updated = widget.alarm.copyWith(
                  preAlarmEnabled: _preEnabled, preAlarmOffset: _preOffset,
                  exactAlarmEnabled: _exactEnabled, exactAlarmAudio: _exactAudio,
                  postAlarmEnabled: _postEnabled, postAlarmOffset: _postOffset,
                  customHour: _customHour, customMinute: _customMinute,
                  frequencyHours: _frequencyHours, repeatType: _repeatType, repeatDays: _repeatDays,
                  vibrationEnabled: _vibrationEnabled, vibrationPattern: _vibrationPattern,
                  snoozeEnabled: _snoozeEnabled, snoozeInterval: _snoozeInterval, snoozeMaxCount: _snoozeMaxCount,
                  customMessage: _customMessage, ledEnabled: _ledEnabled, ledColor: _ledColor,
                  lockScreenVisible: _lockScreenVisible, priority: _priority,
                );
                await widget.onSave(updated);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ivory, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Column(
      children: [
        const Divider(color: AppColors.cardBorder, height: 1),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: Text(title, style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildPrayerOptions() {
    return [
      _buildToggleRow('تنبيه قبل الأذان', _preEnabled, (v) => setState(() => _preEnabled = v)),
      if (_preEnabled) _buildOffsetDropdown('دقائق قبل', _preOffset, (v) => setState(() => _preOffset = v)),
      const SizedBox(height: 12),
      _buildToggleRow('وقت الأذان بالضبط', _exactEnabled, (v) => setState(() => _exactEnabled = v)),
      if (_exactEnabled) _buildAudioDropdown(),
      const SizedBox(height: 12),
      _buildToggleRow('تنبيه بعد الأذان / الإقامة', _postEnabled, (v) => setState(() => _postEnabled = v)),
      if (_postEnabled) _buildOffsetDropdown('دقائق بعد', _postOffset, (v) => setState(() => _postOffset = v)),
    ];
  }

  List<Widget> _buildSunnahOptions() {
    if (widget.alarm.id == 'qiyam') {
      return [
        _buildToggleRow('الثلث الأخير من الليل', _customHour == null, (v) { if (v) setState(() { _customHour = null; _customMinute = null; }); }),
        _buildToggleRow('وقت مخصص', _customHour != null, (v) { if (v) setState(() { _customHour = 3; _customMinute = 0; }); else setState(() { _customHour = null; _customMinute = null; }); }),
        if (_customHour != null) _buildTimePicker(),
      ];
    } else {
      return [
        _buildToggleRow('15 دقيقة بعد شروق الشمس', _customHour == null, (v) { if (v) setState(() { _customHour = null; _customMinute = null; }); }),
        _buildToggleRow('وقت مخصص', _customHour != null, (v) { if (v) setState(() { _customHour = 8; _customMinute = 0; }); else setState(() { _customHour = null; _customMinute = null; }); }),
        if (_customHour != null) _buildTimePicker(),
      ];
    }
  }

  List<Widget> _buildDhikrOptions() => [_buildFrequencyDropdown()];
  List<Widget> _buildFridayOptions() => [_buildTimePicker()];

  Widget _buildSnoozeOptions() {
    return Column(
      children: [
        _buildToggleRow('السماح بالترقيع', _snoozeEnabled, (v) => setState(() => _snoozeEnabled = v)),
        if (_snoozeEnabled) ...[
          _buildOffsetDropdown('الفاصل', _snoozeInterval, (v) => setState(() => _snoozeInterval = v)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Text('الحد الأقصى', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _snoozeMaxCount, dropdownColor: AppColors.cardElevated, style: const TextStyle(color: AppColors.ivory, fontSize: 14), underline: const SizedBox(),
                  items: [1, 2, 3, 5].map((m) => DropdownMenuItem(value: m, child: Text('$m مرات'))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _snoozeMaxCount = v); },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVibrationAndLightOptions() {
    return Column(
      children: [
        _buildToggleRow('الاهتزاز', _vibrationEnabled, (v) => setState(() => _vibrationEnabled = v)),
        if (_vibrationEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Text('نمط الاهتزاز', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _vibrationPattern, dropdownColor: AppColors.cardElevated, style: const TextStyle(color: AppColors.ivory, fontSize: 14), underline: const SizedBox(),
                  items: const [DropdownMenuItem(value: 0, child: Text('قصير')), DropdownMenuItem(value: 1, child: Text('طويل')), DropdownMenuItem(value: 2, child: Text('مزدوج')), DropdownMenuItem(value: 3, child: Text('مستمر'))],
                  onChanged: (v) { if (v != null) setState(() => _vibrationPattern = v); },
                ),
              ],
            ),
          ),
        _buildToggleRow('إضاءة LED', _ledEnabled, (v) => setState(() => _ledEnabled = v)),
        if (_ledEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Text('لون الإضاءة', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _ledColor, dropdownColor: AppColors.cardElevated, style: const TextStyle(color: AppColors.ivory, fontSize: 14), underline: const SizedBox(),
                  items: const [DropdownMenuItem(value: 0, child: Text('أحمر')), DropdownMenuItem(value: 1, child: Text('أخضر')), DropdownMenuItem(value: 2, child: Text('أزرق')), DropdownMenuItem(value: 3, child: Text('أصفر'))],
                  onChanged: (v) { if (v != null) setState(() => _ledColor = v); },
                ),
              ],
            ),
          ),
        _buildToggleRow('الظهور على شاشة القفل', _lockScreenVisible, (v) => setState(() => _lockScreenVisible = v)),
      ],
    );
  }

  Widget _buildCustomMessageField() {
    return TextField(
      controller: TextEditingController(text: _customMessage ?? ''),
      onChanged: (v) => setState(() => _customMessage = v.isEmpty ? null : v),
      style: const TextStyle(color: AppColors.ivory),
      decoration: InputDecoration(
        hintText: 'رسالة مخصصة للتنبيه...', hintStyle: TextStyle(color: AppColors.textHint),
        filled: true, fillColor: AppColors.cardElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      maxLines: 2,
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        const Text('الأولوية', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: _priority.toDouble(), min: 0, max: 2, divisions: 2,
            activeColor: AppColors.ivory, inactiveColor: AppColors.cardElevated,
            onChanged: (v) => setState(() => _priority = v.round()),
            label: _priority == 0 ? 'منخفضة' : (_priority == 1 ? 'عادية' : 'عالية'),
          ),
        ),
        Text(_priority == 0 ? 'منخفضة' : (_priority == 1 ? 'عادية' : 'عالية'), style: const TextStyle(color: AppColors.ivory, fontSize: 12)),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.ivory, fontSize: 14))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.ivory, activeTrackColor: AppColors.ivory.withValues(alpha: 0.3), inactiveTrackColor: AppColors.cardElevated),
        ],
      ),
    );
  }

  Widget _buildOffsetDropdown(String label, int current, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: current, dropdownColor: AppColors.cardElevated, style: const TextStyle(color: AppColors.ivory, fontSize: 14), underline: const SizedBox(),
            items: [5, 10, 15, 20, 30].map((m) => DropdownMenuItem(value: m, child: Text('$m دقيقة'))).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioDropdown() {
    final options = <String, String>{
      'assets/audio/notifications/athan-fajr.mp3': 'أذان الفجر',
      'assets/audio/notifications/athan-makkah.mp3': 'أذان مكة',
      'assets/audio/notifications/athan-madinah.mp3': 'أذان المدينة',
      'assets/audio/notifications/athan-masjid-nabawi.mp3': 'أذان المسجد النبوي',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Text('صوت الأذان', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _exactAudio, isExpanded: true, dropdownColor: AppColors.cardElevated, style: const TextStyle(color: AppColors.ivory, fontSize: 13), underline: const SizedBox(),
              items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) { if (v != null) setState(() => _exactAudio = v); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    final options = [1, 2, 4];
    final labels = {1: 'كل ساعة', 2: 'كل ساعتين', 4: 'كل 4 ساعات'};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Text('التكرار', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _frequencyHours, dropdownColor: AppColors.cardElevated, style: const TextStyle(color: AppColors.ivory, fontSize: 14), underline: const SizedBox(),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(labels[o]!))).toList(),
            onChanged: (v) { if (v != null) setState(() => _frequencyHours = v); },
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Text('الوقت', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _customHour ?? 10, minute: _customMinute ?? 0),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.ivory, surface: AppColors.cardDark)), child: child!),
              );
              if (t != null) setState(() { _customHour = t.hour; _customMinute = t.minute; });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Text('${(_customHour ?? 10).toString().padLeft(2, '0')}:${(_customMinute ?? 0).toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.ivory, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
