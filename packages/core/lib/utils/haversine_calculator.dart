import 'dart:math' as math;

class HaversineCalculator {
  static const double earthRadiusMeters = 6371000.0; // Earth radius in meters

  /// Calculates the great-circle distance between two GPS coordinates in meters.
  static double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Returns true if the user's current coordinate is inside the target geofence radius.
  static bool isInsideGeofence({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
    required double radiusMeters,
  }) {
    final distance = distanceMeters(
      lat1: userLat,
      lon1: userLon,
      lat2: targetLat,
      lon2: targetLon,
    );
    return distance <= radiusMeters;
  }

  /// Formats human-readable distance (e.g. "85 m" or "2.4 km").
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
