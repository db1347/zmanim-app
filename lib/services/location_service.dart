import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// A resolved place: either from GPS or the built-in city list.
class ResolvedLocation {
  final String name;
  final double latitude;
  final double longitude;
  final bool inIsrael;

  const ResolvedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.inIsrael,
  });
}

/// Built-in city list — the manual fallback when GPS is denied. Never a dead
/// end: onboarding always lets the user pick one of these.
const List<ResolvedLocation> kCities = [
  ResolvedLocation(
      name: 'ירושלים', latitude: 31.7780, longitude: 35.2354, inIsrael: true),
  ResolvedLocation(
      name: 'תל אביב', latitude: 32.0853, longitude: 34.7818, inIsrael: true),
  ResolvedLocation(
      name: 'חיפה', latitude: 32.7940, longitude: 34.9896, inIsrael: true),
  ResolvedLocation(
      name: 'בני ברק', latitude: 32.0807, longitude: 34.8338, inIsrael: true),
  ResolvedLocation(
      name: 'באר שבע', latitude: 31.2530, longitude: 34.7915, inIsrael: true),
  ResolvedLocation(
      name: 'ניו יורק',
      latitude: 40.7128,
      longitude: -74.0060,
      inIsrael: false),
  ResolvedLocation(
      name: 'לייקווד',
      latitude: 40.0960,
      longitude: -74.2221,
      inIsrael: false),
  ResolvedLocation(
      name: 'לוס אנג׳לס',
      latitude: 34.0522,
      longitude: -118.2437,
      inIsrael: false),
  ResolvedLocation(
      name: 'מיאמי', latitude: 25.7617, longitude: -80.1918, inIsrael: false),
  ResolvedLocation(
      name: 'טורונטו',
      latitude: 43.6532,
      longitude: -79.3832,
      inIsrael: false),
  ResolvedLocation(
      name: 'לונדון', latitude: 51.5074, longitude: -0.1278, inIsrael: false),
  ResolvedLocation(
      name: 'פריז', latitude: 48.8566, longitude: 2.3522, inIsrael: false),
  ResolvedLocation(
      name: 'אנטוורפן',
      latitude: 51.2194,
      longitude: 4.4025,
      inIsrael: false),
  ResolvedLocation(
      name: 'בואנוס איירס',
      latitude: -34.6037,
      longitude: -58.3816,
      inIsrael: false),
  ResolvedLocation(
      name: 'מקסיקו סיטי',
      latitude: 19.4326,
      longitude: -99.1332,
      inIsrael: false),
  ResolvedLocation(
      name: 'מלבורן',
      latitude: -37.8136,
      longitude: 144.9631,
      inIsrael: false),
  ResolvedLocation(
      name: 'יוהנסבורג',
      latitude: -26.2041,
      longitude: 28.0473,
      inIsrael: false),
];

/// Rough Israel bounding box, used to flag GPS fixes inside Israel.
bool _looksLikeIsrael(double lat, double lng) =>
    lat >= 29.4 && lat <= 33.4 && lng >= 34.2 && lng <= 35.9;

class LocationService {
  const LocationService._();

  /// Requests permission and returns the current GPS position, or null if
  /// denied/unavailable. Callers must offer the manual city list on null.
  static Future<ResolvedLocation?> getCurrent() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return ResolvedLocation(
        name: 'המיקום הנוכחי',
        latitude: pos.latitude,
        longitude: pos.longitude,
        inIsrael: _looksLikeIsrael(pos.latitude, pos.longitude),
      );
    } catch (e) {
      debugPrint('LocationService: $e');
      return null;
    }
  }
}
