import 'dart:math' as math;
import 'package:core/core.dart';
import 'package:models/models.dart';

/// Filter criteria for Store Locator
class StoreLocatorFilter {
  final String query;
  final double? maxRadiusMeters;
  final bool onlyInsideGeofence;

  const StoreLocatorFilter({
    this.query = '',
    this.maxRadiusMeters,
    this.onlyInsideGeofence = false,
  });

  StoreLocatorFilter copyWith({
    String? query,
    double? maxRadiusMeters,
    bool? onlyInsideGeofence,
  }) {
    return StoreLocatorFilter(
      query: query ?? this.query,
      maxRadiusMeters: maxRadiusMeters ?? this.maxRadiusMeters,
      onlyInsideGeofence: onlyInsideGeofence ?? this.onlyInsideGeofence,
    );
  }
}

/// Store item enriched with computed distance & geofence metadata
class LocatedStoreItem {
  final ShopModel shop;
  final double distanceMeters;
  final bool isInsideGeofence;
  final String formattedDistance;
  final int estimatedWalkingMinutes;
  final int estimatedDrivingMinutes;

  const LocatedStoreItem({
    required this.shop,
    required this.distanceMeters,
    required this.isInsideGeofence,
    required this.formattedDistance,
    required this.estimatedWalkingMinutes,
    required this.estimatedDrivingMinutes,
  });
}

/// Sanitized High-Performance Store Locator Engine (Inspired by storelocatorjs)
class StoreLocatorEngine {
  /// Sanitizes text input to prevent injection, strips scripts, html tags and control characters
  static String sanitizeQuery(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>|[\x00-\x1F\x7F]'), '')
        .trim()
        .toLowerCase();
  }

  /// Validates and sanitizes GPS latitude (-90 to +90)
  static double sanitizeLatitude(double lat) {
    return lat.clamp(-90.0, 90.0);
  }

  /// Validates and sanitizes GPS longitude (-180 to +180)
  static double sanitizeLongitude(double lng) {
    return lng.clamp(-180.0, 180.0);
  }

  /// Validates and clamps search radius (10m to 100,000m)
  static double sanitizeRadius(double radiusMeters) {
    return radiusMeters.clamp(10.0, 100000.0);
  }

  /// Filters, computes distances, and sorts shops nearest to user location
  static List<LocatedStoreItem> findNearestShops({
    required List<ShopModel> allShops,
    required double userLat,
    required double userLng,
    StoreLocatorFilter filter = const StoreLocatorFilter(),
  }) {
    final cleanUserLat = sanitizeLatitude(userLat);
    final cleanUserLng = sanitizeLongitude(userLng);
    final cleanQuery = sanitizeQuery(filter.query);

    final List<LocatedStoreItem> locatedList = [];

    for (final shop in allShops) {
      final cleanShopLat = sanitizeLatitude(shop.latitude);
      final cleanShopLng = sanitizeLongitude(shop.longitude);

      // 1. Text Query Filter
      if (cleanQuery.isNotEmpty) {
        final shopName = shop.name.toLowerCase();
        final shopAddress = shop.address.toLowerCase();
        final shopContact = (shop.contactPerson ?? '').toLowerCase();
        final shopPhone = (shop.phone ?? '').toLowerCase();
        final shopCode = shop.code.toLowerCase();

        final matches = shopName.contains(cleanQuery) ||
            shopAddress.contains(cleanQuery) ||
            shopContact.contains(cleanQuery) ||
            shopPhone.contains(cleanQuery) ||
            shopCode.contains(cleanQuery);

        if (!matches) continue;
      }

      // 2. Compute Distance via Haversine Formula
      final distMeters = HaversineCalculator.distanceMeters(
        lat1: cleanUserLat,
        lon1: cleanUserLng,
        lat2: cleanShopLat,
        lon2: cleanShopLng,
      );

      // 3. Max Radius Filter
      if (filter.maxRadiusMeters != null) {
        final maxR = sanitizeRadius(filter.maxRadiusMeters!);
        if (distMeters > maxR) continue;
      }

      // 4. Geofence Verification
      final radiusLimit = shop.radius > 0 ? shop.radius : 50.0;
      final isInside = distMeters <= radiusLimit;

      if (filter.onlyInsideGeofence && !isInside) {
        continue;
      }

      // Walking (~4.8 km/h = 80 m/min) & Driving (~30 km/h = 500 m/min)
      final walkingMins = math.max(1, (distMeters / 80).round());
      final drivingMins = math.max(1, (distMeters / 500).round());

      locatedList.add(
        LocatedStoreItem(
          shop: shop,
          distanceMeters: distMeters,
          isInsideGeofence: isInside,
          formattedDistance: HaversineCalculator.formatDistance(distMeters),
          estimatedWalkingMinutes: walkingMins,
          estimatedDrivingMinutes: drivingMins,
        ),
      );
    }

    // Sort Nearest First
    locatedList.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return locatedList;
  }

  /// Generates a sanitized Navigation URL for Google Maps / OpenStreetMap
  static String generateDirectionsUrl({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
    String provider = 'google',
  }) {
    final cleanDestLat = sanitizeLatitude(destLat);
    final cleanDestLng = sanitizeLongitude(destLng);

    if (provider == 'osm') {
      if (originLat != null && originLng != null) {
        return 'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=${sanitizeLatitude(originLat)}%2C${sanitizeLongitude(originLng)}%3B$cleanDestLat%2C$cleanDestLng';
      }
      return 'https://www.openstreetmap.org/?mlat=$cleanDestLat&mlon=$cleanDestLng#map=16/$cleanDestLat/$cleanDestLng';
    }

    // Default Google Maps Navigation
    if (originLat != null && originLng != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=${sanitizeLatitude(originLat)},${sanitizeLongitude(originLng)}&destination=$cleanDestLat,$cleanDestLng&travelmode=driving';
    }
    return 'https://www.google.com/maps/search/?api=1&query=$cleanDestLat,$cleanDestLng';
  }
}
