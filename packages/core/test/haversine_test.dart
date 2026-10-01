import 'package:test/test.dart';
import 'package:core/core.dart';

void main() {
  group('HaversineCalculator Tests', () {
    test('Calculates distance between two Delhi landmarks correctly', () {
      // Connaught Place (28.6328, 77.2197) to India Gate (28.6129, 77.2295) ~2.4km
      final distance = HaversineCalculator.distanceMeters(
        lat1: 28.6328,
        lon1: 77.2197,
        lat2: 28.6129,
        lon2: 77.2295,
      );
      expect(distance, greaterThan(2200));
      expect(distance, lessThan(2500));
      final formatted = HaversineCalculator.formatDistance(distance);
      expect(formatted.endsWith('km'), isTrue);
    });

    test('Geofence check passes inside radius and fails outside', () {
      final inside = HaversineCalculator.isInsideGeofence(
        userLat: 28.6328,
        userLon: 77.2197,
        targetLat: 28.6330,
        targetLon: 77.2199,
        radiusMeters: 100.0,
      );
      expect(inside, isTrue);

      final outside = HaversineCalculator.isInsideGeofence(
        userLat: 28.6328,
        userLon: 77.2197,
        targetLat: 28.6129,
        targetLon: 77.2295,
        radiusMeters: 500.0,
      );
      expect(outside, isFalse);
    });
  });

  group('AnomalyDetector Tests', () {
    test('Flags mock location provider', () {
      final res = AnomalyDetector.evaluate(
        prevLat: 28.61,
        prevLon: 77.20,
        prevTimestamp: DateTime(2026, 10, 1, 10, 0, 0),
        nextLat: 28.62,
        nextLon: 77.21,
        nextTimestamp: DateTime(2026, 10, 1, 10, 0, 20),
        accuracyMeters: 10.0,
        isMocked: true,
      );
      expect(res.isSuspicious, isTrue);
      expect(res.reason, contains('Mock location'));
    });

    test('Flags impossible speed spike (e.g. 500 km/h jump)', () {
      final res = AnomalyDetector.evaluate(
        prevLat: 28.6139,
        prevLon: 77.2090,
        prevTimestamp: DateTime(2026, 10, 1, 10, 0, 0),
        nextLat: 28.7139, // ~11 km away in 10 seconds = ~3960 km/h
        nextLon: 77.2090,
        nextTimestamp: DateTime(2026, 10, 1, 10, 0, 10),
        accuracyMeters: 8.0,
      );
      expect(res.isSuspicious, isTrue);
      expect(res.reason, contains('Unrealistic transit speed'));
    });
  });
}
