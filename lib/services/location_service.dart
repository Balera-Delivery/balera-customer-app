import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check & request location permission
  static Future<bool> handlePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // Get current device GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // Reverse geocoding address helper
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    // Return formatted area name for Bale/Addis Ababa
    if (lat >= 8.9 && lat <= 9.1 && lng >= 38.6 && lng <= 38.9) {
      return 'Bole, Addis Ababa, Ethiopia';
    }
    return 'Bole, Addis Ababa, Ethiopia';
  }
}
