import 'package:flutter_test/flutter_test.dart';
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';

void main() {
  group('StoreLocatorEngine Sanitization & Calculation Tests', () {
    test('sanitizes input query removing HTML and control characters', () {
      final query = '<script>alert("hack")</script> Connaught Place  ';
      final cleaned = StoreLocatorEngine.sanitizeQuery(query);
      expect(cleaned, 'connaught place');
    });

    test('clamps invalid latitudes and longitudes', () {
      expect(StoreLocatorEngine.sanitizeLatitude(95.0), 90.0);
      expect(StoreLocatorEngine.sanitizeLatitude(-120.0), -90.0);
      expect(StoreLocatorEngine.sanitizeLongitude(200.0), 180.0);
      expect(StoreLocatorEngine.sanitizeLongitude(-250.0), -180.0);
    });

    test('calculates nearest stores and sorts ascending distance', () {
      final shops = [
        ShopModel(
          id: 'shop_1',
          organizationId: 'org_1',
          code: 'SH-01',
          name: 'CP Mega Store',
          address: 'Connaught Place, Delhi',
          latitude: 28.6328,
          longitude: 77.2197,
          radius: 50.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ShopModel(
          id: 'shop_2',
          organizationId: 'org_1',
          code: 'SH-02',
          name: 'Noida Hub',
          address: 'Sector 62, Noida',
          latitude: 28.6280,
          longitude: 77.3649,
          radius: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // User location at Connaught Place
      final results = StoreLocatorEngine.findNearestShops(
        allShops: shops,
        userLat: 28.6328,
        userLng: 77.2197,
      );

      expect(results.length, 2);
      expect(results.first.shop.name, 'CP Mega Store');
      expect(results.first.isInsideGeofence, isTrue);
      expect(results.last.shop.name, 'Noida Hub');
      expect(results.last.isInsideGeofence, isFalse);
    });

    test('generates valid directions URL', () {
      final url = StoreLocatorEngine.generateDirectionsUrl(
        destLat: 28.6328,
        destLng: 77.2197,
        originLat: 28.6300,
        originLng: 77.2100,
      );
      expect(url.contains('https://www.google.com/maps/dir/'), isTrue);
      expect(url.contains('origin=28.63,77.21'), isTrue);
    });
  });
}
