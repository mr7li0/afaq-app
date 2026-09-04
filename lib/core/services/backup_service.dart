import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Local backup service for exporting and importing:
/// - User bookmarks (saved ayahs)
/// - Wird read history
/// - Alarm settings
/// Uses local JSON files — no server dependency.
class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  // ── Export Data ────────────────────────────────────
  /// Export all user data to a JSON file and share it.
  Future<bool> exportData({
    required Map<String, dynamic> bookmarks,
    required Map<String, dynamic> readHistory,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final backupData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Afaq',
        'data': {
          'bookmarks': bookmarks,
          'readHistory': readHistory,
          'settings': settings,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'afaq_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Copy file path to clipboard
      await Clipboard.setData(ClipboardData(text: file.path));

      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Import Data ────────────────────────────────────
  /// Import user data from a JSON file.
  Future<Map<String, dynamic>?> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate version compatibility
      final version = backupData['version'] as String?;
      if (version == null) return null;

      return backupData['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // ── Create Backup to App Directory ─────────────────
  /// Save backup to app's documents directory (for auto-backup).
  Future<String?> createLocalBackup({
    required Map<String, dynamic> data,
  }) async {
    try {
      final backupData = {
        'version': '1.0.0',
        'backupDate': DateTime.now().toIso8601String(),
        'data': data,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = 'afaq_auto_backup.json';
      final file = File('${backupDir.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  // ── Restore from Local Backup ──────────────────────
  Future<Map<String, dynamic>?> restoreLocalBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backups/afaq_auto_backup.json');

      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      return backupData['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
