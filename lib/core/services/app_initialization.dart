import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class AppInitialization {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.boxSettings);
    await Hive.openBox(AppConstants.boxAlarms);
    await LocalStorageService().init();
    await NotificationService().init();
    await NotificationService().requestNotificationPermission();
    await _syncLocation();
  }

  static Future<void> _syncLocation() async {
    try {
      final loc = LocationService();
      final coords = await loc.getCoordinates();
      await LocalStorageService().setLocation(coords.$1, coords.$2);
    } catch (_) {}
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
