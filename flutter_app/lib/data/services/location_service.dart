import 'package:geolocator/geolocator.dart';
import 'storage_service.dart';


class LocationResult {
  final double lat;
  final double lng;
  final bool isFromDevice; // true = live GPS, false = stored user location

  const LocationResult({required this.lat, required this.lng, required this.isFromDevice});
}

/// Service for capturing the buyer's GPS location.
/// Priority:
///   1. Device GPS (live location, accuracy < 30 metres)
///   2. Stored user home location (from login response)
///   3. null (show all products, no proximity filtering)
class LocationService {
  /// Returns a [LocationResult] with coordinates, or null if unavailable.
  /// Uses stored user home location (disable GPS per user request)
  static Future<LocationResult?> getLocation() async {
    final storage = StorageService();
    final user = storage.user;
    if (user?.location != null) {
      return LocationResult(
        lat: user!.location!.lat,
        lng: user.location!.lng,
        isFromDevice: false, // Seeded location
      );
    }
    return null;
  }

  /// Raw position for backward compatibility
  static Future<Position?> getCurrentPosition() async {
    final result = await getLocation();
    if (result == null) return null;
    return Position(
      latitude: result.lat,
      longitude: result.lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  static void clearCache() {}
}
