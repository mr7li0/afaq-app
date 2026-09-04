import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class AppInitialization {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Hive
    try {
      await Hive.initFlutter();
      if (!Hive.isBoxOpen(AppConstants.boxSettings)) {
        await Hive.openBox(AppConstants.boxSettings);
      }
      if (!Hive.isBoxOpen(AppConstants.boxAlarms)) {
        await Hive.openBox(AppConstants.boxAlarms);
      }
    } catch (e) {
      debugPrint('Hive init error: $e');
    }

    // LocalStorageService
    try {
      await LocalStorageService().init();
    } catch (e) {
      debugPrint('LocalStorageService init error: $e');
    }

    // NotificationService
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }

    // Request notification permission (non-blocking)
    try {
      await NotificationService().requestNotificationPermission();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    // Sync location (non-blocking)
    try {
      await _syncLocation();
    } catch (e) {
      debugPrint('Location sync error: $e');
    }
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
