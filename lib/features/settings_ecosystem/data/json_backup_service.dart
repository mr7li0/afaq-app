import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local JSON backup & restore utility.
///
/// Spec requirements:
/// - Export all user data to afaq_backup.json
/// - Import and validate JSON schema
/// - Overwrite local Hive/SharedPreferences databases
/// - Trigger app-wide state refresh
class JsonBackupService {
  static final JsonBackupService _instance = JsonBackupService._();
  factory JsonBackupService() => _instance;
  JsonBackupService._();

  /// Export all user data to a JSON file and share it.
  Future<bool> exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Gather all user data
      final backupData = {
        'version': '1.0.0',
        'appName': 'Afaq',
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          // Settings
          'settings': {
            'locale': prefs.getString('app_locale') ?? 'ar',
            'darkMode': prefs.getBool('dark_mode') ?? false,
            'lastReadPage': prefs.getInt('last_read_page') ?? 1,
            'wirdGoal': prefs.getInt('wird_goal') ?? 4,
            'wirdGoalType': prefs.getString('wird_goal_type') ?? 'pages',
            'quietHoursStart': prefs.getInt('quiet_hours_start') ?? 23,
            'quietHoursEnd': prefs.getInt('quiet_hours_end') ?? 6,
            'hawqalaEnabled': prefs.getBool('hawqala_enabled') ?? false,
            'salawatEnabled': prefs.getBool('salawat_enabled') ?? false,
            'khushooMode': prefs.getBool('khushoo_mode') ?? false,
            'latitude': prefs.getDouble('latitude'),
            'longitude': prefs.getDouble('longitude'),
            'calculationMethod': prefs.getString('calculation_method') ?? 'Umm Al-Qura',
            'madhab': prefs.getString('madhab') ?? 'Shafi\'i',
          },
          // Bookmarks
          'bookmarks': prefs.getStringList('quran_bookmarks') ?? [],
          // Athkar counters
          'athkarCounters': prefs.getString('athkar_counters_v2'),
          // Athkar favorites
          'athkarFavorites': prefs.getStringList('athkar_favorites_v2') ?? [],
          // Wird progress
          'wirdProgress': prefs.getString('wird_progress'),
          // Prayer sound modes
          'prayerSoundModes': {
            'fajr': prefs.getInt('sound_mode_fajr') ?? 0,
            'sunrise': prefs.getInt('sound_mode_sunrise') ?? 2,
            'dhuhr': prefs.getInt('sound_mode_dhuhr') ?? 0,
            'asr': prefs.getInt('sound_mode_asr') ?? 0,
            'maghrib': prefs.getInt('sound_mode_maghrib') ?? 0,
            'isha': prefs.getInt('sound_mode_isha') ?? 0,
          },
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'afaq_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Copy file path to clipboard
      await Clipboard.setData(ClipboardData(text: file.path));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import user data from a JSON file.
  Future<BackupResult> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupResult(success: false, message: 'الملف غير موجود');
      }

      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate version
      final version = backupData['version'] as String?;
      if (version == null) {
        return BackupResult(success: false, message: 'صيغة الملف غير صالحة');
      }

      final data = backupData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return BackupResult(success: false, message: 'بيانات غير مكتملة');
      }

      // Restore settings
      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        await _restoreSettings(settings);
      }

      // Restore bookmarks
      final bookmarks = data['bookmarks'] as List<dynamic>?;
      if (bookmarks != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'quran_bookmarks',
          bookmarks.map((e) => e.toString()).toList(),
        );
      }

      // Restore athkar counters
      final athkarCounters = data['athkarCounters'] as String?;
      if (athkarCounters != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('athkar_counters_v2', athkarCounters);
      }

      // Restore athkar favorites
      final athkarFavorites = data['athkarFavorites'] as List<dynamic>?;
      if (athkarFavorites != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'athkar_favorites_v2',
          athkarFavorites.map((e) => e.toString()).toList(),
        );
      }

      // Restore wird progress
      final wirdProgress = data['wirdProgress'] as String?;
      if (wirdProgress != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wird_progress', wirdProgress);
      }

      // Restore prayer sound modes
      final soundModes = data['prayerSoundModes'] as Map<String, dynamic>?;
      if (soundModes != null) {
        final prefs = await SharedPreferences.getInstance();
        for (final entry in soundModes.entries) {
          await prefs.setInt('sound_mode_${entry.key}', entry.value as int);
        }
      }

      return BackupResult(
        success: true,
        message: 'تم استيراد البيانات بنجاح',
        itemsRestored: _countItems(data),
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'خطأ في استيراد البيانات: ${e.toString()}',
      );
    }
  }

  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (settings['locale'] != null) {
      await prefs.setString('app_locale', settings['locale']);
    }
    if (settings['darkMode'] != null) {
      await prefs.setBool('dark_mode', settings['darkMode']);
    }
    if (settings['lastReadPage'] != null) {
      await prefs.setInt('last_read_page', settings['lastReadPage']);
    }
    if (settings['wirdGoal'] != null) {
      await prefs.setInt('wird_goal', settings['wirdGoal']);
    }
    if (settings['wirdGoalType'] != null) {
      await prefs.setString('wird_goal_type', settings['wirdGoalType']);
    }
    if (settings['quietHoursStart'] != null) {
      await prefs.setInt('quiet_hours_start', settings['quietHoursStart']);
    }
    if (settings['quietHoursEnd'] != null) {
      await prefs.setInt('quiet_hours_end', settings['quietHoursEnd']);
    }
    if (settings['hawqalaEnabled'] != null) {
      await prefs.setBool('hawqala_enabled', settings['hawqalaEnabled']);
    }
    if (settings['salawatEnabled'] != null) {
      await prefs.setBool('salawat_enabled', settings['salawatEnabled']);
    }
    if (settings['khushooMode'] != null) {
      await prefs.setBool('khushoo_mode', settings['khushooMode']);
    }
    if (settings['latitude'] != null) {
      await prefs.setDouble('latitude', settings['latitude']);
    }
    if (settings['longitude'] != null) {
      await prefs.setDouble('longitude', settings['longitude']);
    }
    if (settings['calculationMethod'] != null) {
      await prefs.setString('calculation_method', settings['calculationMethod']);
    }
    if (settings['madhab'] != null) {
      await prefs.setString('madhab', settings['madhab']);
    }
  }

  int _countItems(Map<String, dynamic> data) {
    int count = 0;
    final bookmarks = data['bookmarks'] as List<dynamic>?;
    if (bookmarks != null) count += bookmarks.length;
    final favorites = data['athkarFavorites'] as List<dynamic>?;
    if (favorites != null) count += favorites.length;
    return count;
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clear cache files
  Future<bool> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Result of a backup operation
class BackupResult {
  final bool success;
  final String message;
  final int itemsRestored;

  const BackupResult({
    required this.success,
    required this.message,
    this.itemsRestored = 0,
  });
}
