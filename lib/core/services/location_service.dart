import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Location service providing GPS coordinates for:
/// - Prayer time calculations (adhan library)
/// - Qibla compass direction
/// Supports both GPS and manual city selection.
class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  Position? _currentPosition;
  String? _selectedCity;
  String? _selectedCountry;

  Position? get currentPosition => _currentPosition;
  String? get selectedCity => _selectedCity;
  bool get hasLocation => _currentPosition != null || _selectedCity != null;

  // ── Get Current Position ───────────────────────────
  /// Request GPS position with high accuracy.
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

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(AppConstants.keyLatitude, _currentPosition!.latitude);
      await prefs.setDouble(AppConstants.keyLongitude, _currentPosition!.longitude);

      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  // ── Load Saved Location ────────────────────────────
  /// Load previously saved coordinates from SharedPreferences.
  Future<Position?> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.keyLatitude);
    final lon = prefs.getDouble(AppConstants.keyLongitude);

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
    return null;
  }

  // ── Manual City Selection ──────────────────────────
  /// Set location manually by city name (geocoding).
  Future<void> setManualLocation(String city, String country) async {
    _selectedCity = city;
    _selectedCountry = country;
    // TODO: Use geocoding package to convert city name to coordinates
    // For now, store city name and use known coordinates
  }

  // ── Get Coordinates for Calculations ───────────────
  /// Returns the best available coordinates (GPS > saved > default Mecca).
  Future<(double latitude, double longitude)> getCoordinates() async {
    if (_currentPosition != null) {
      return (_currentPosition!.latitude, _currentPosition!.longitude);
    }

    final saved = await loadSavedLocation();
    if (saved != null) {
      return (saved.latitude, saved.longitude);
    }

    // Default to Mecca if no location available
    return (21.4225, 39.8262);
  }

  // ── Listen to Position Changes ─────────────────────
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1000, // Update every 1km
      ),
    );
  }

  // ── Distance Between Two Points ────────────────────
  double distanceBetween(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }
}
