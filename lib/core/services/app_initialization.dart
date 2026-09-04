import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/notification_service.dart';

class AppInitialization {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.boxSettings);
    await Hive.openBox(AppConstants.boxAlarms);
    await LocalStorageService().init();
    await NotificationService().init();
    await NotificationService().requestNotificationPermission();
  }

  static Future<void> scheduleAlarms() async {
    try {
      final loc = LocalStorageService();
      await NotificationService().scheduleAllAlarms(
        latitude: loc.latitude,
        longitude: loc.longitude,
        method: loc.calculationMethod,
      );
    } catch (e) {
      debugPrint('Schedule alarms error: $e');
    }
  }
}
