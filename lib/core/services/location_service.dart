import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Location service providing GPS coordinates for prayer time calculations.
class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;
  bool get hasLocation => _currentPosition != null;

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final box = Hive.box(AppConstants.boxSettings);
      await box.put(AppConstants.keyLatitude, _currentPosition!.latitude);
      await box.put(AppConstants.keyLongitude, _currentPosition!.longitude);

      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  Future<Position?> loadSavedLocation() async {
    try {
      final box = Hive.box(AppConstants.boxSettings);
      final lat = (box.get(AppConstants.keyLatitude) as num?)?.toDouble();
      final lon = (box.get(AppConstants.keyLongitude) as num?)?.toDouble();

      if (lat != null && lon != null) {
        _currentPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        return _currentPosition;
      }
    } catch (_) {}
    return null;
  }

  Future<(double latitude, double longitude)> getCoordinates() async {
    if (_currentPosition != null) {
      return (_currentPosition!.latitude, _currentPosition!.longitude);
    }

    final saved = await loadSavedLocation();
    if (saved != null) {
      return (saved.latitude, saved.longitude);
    }

    return (21.4225, 39.8262);
  }
}
