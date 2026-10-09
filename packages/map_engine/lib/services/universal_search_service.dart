import 'dart:convert';
import 'package:core/core.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/map_marker_item.dart';

enum SearchResultType {
  shop,
  employee,
  onlinePlace,
  coordinates,
  googleSuggestion,
}

class UniversalSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final SearchResultType type;
  final double? distanceMeters;
  final String? formattedDistance;
  final bool isInsideGeofence;
  final dynamic originalData;

  const UniversalSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.distanceMeters,
    this.formattedDistance,
    this.isInsideGeofence = false,
    this.originalData,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  UniversalSearchResult copyWithDistance({
    required double distanceMeters,
    required String formattedDistance,
    bool isInsideGeofence = false,
  }) {
    return UniversalSearchResult(
      id: id,
      title: title,
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
      type: type,
      distanceMeters: distanceMeters,
      formattedDistance: formattedDistance,
      isInsideGeofence: isInsideGeofence,
      originalData: originalData,
    );
  }
}

class UniversalSearchService {
  // 1. Universal Google Maps URL & Coordinates Regex Parser
  static Map<String, dynamic>? parseGoogleMapsUrlOrCoords(String input) {
    if (input.trim().isEmpty) return null;
    final text = input.trim();

    // Pattern 1: Google Maps center coordinates @lat,lng e.g. @26.4785737,80.3101676,15z
    final atPattern = RegExp(r'@([-\d\.]+),([-\d\.]+)');
    final atMatch = atPattern.firstMatch(text);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        return {'lat': lat, 'lng': lng, 'title': 'Google Maps Pinned Location'};
      }
    }

    // Pattern 2: Directions / Place destination pin !2d(lng)!2d(lat)
    final dPattern = RegExp(r'!2d([-\d\.]+)!2d([-\d\.]+)');
    final dMatches = dPattern.allMatches(text).toList();
    if (dMatches.isNotEmpty) {
      final lastMatch = dMatches.last;
      final lng = double.tryParse(lastMatch.group(1)!);
      final lat = double.tryParse(lastMatch.group(2)!);
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        return {'lat': lat, 'lng': lng, 'title': 'Google Maps Destination Pin'};
      }
    }

    // Pattern 3: Standard !3d(lat)!4d(lng)
    final match3d4d = RegExp(r'!3d([-\d\.]+)!4d([-\d\.]+)').allMatches(text).toList();
    if (match3d4d.isNotEmpty) {
      final lastMatch = match3d4d.last;
      final lat = double.tryParse(lastMatch.group(1)!);
      final lng = double.tryParse(lastMatch.group(2)!);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'title': 'Google Maps Location'};
      }
    }

    // Pattern 4: ?q=lat,lng or ?ll=lat,lng
    final qMatch = RegExp(r'[?&](?:q|ll)=([-\d\.]+),([-\d\.]+)').firstMatch(text);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'title': 'Pinned Coordinates'};
      }
    }

    // Pattern 5: Raw comma-separated numbers: "26.490745, 80.318524"
    final rawMatch = RegExp(r'^([-\d\.]+)\s*,\s*([-\d\.]+)$').firstMatch(text);
    if (rawMatch != null) {
      final lat = double.tryParse(rawMatch.group(1)!);
      final lng = double.tryParse(rawMatch.group(2)!);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'title': 'GPS Coordinates ($lat, $lng)'};
      }
    }

    return null;
  }

  // 2. Perform Unified Multi-Source Search (Multi-Token Fuzzy Matching + Nearby Proximity)
  static Future<List<UniversalSearchResult>> search({
    required String query,
    List<MapMarkerItem> localMarkers = const [],
    double? userLat,
    double? userLng,
    int maxResults = 10,
  }) async {
    final q = query.trim();

    // If query is empty and user coordinates exist, return Nearby Places automatically (Google Maps style)
    if (q.isEmpty) {
      if (userLat != null && userLng != null && localMarkers.isNotEmpty) {
        final List<UniversalSearchResult> nearbyList = [];
        for (final marker in localMarkers) {
          final distMeters = HaversineCalculator.distanceMeters(
            lat1: userLat,
            lon1: userLng,
            lat2: marker.latitude,
            lon2: marker.longitude,
          );
          final isInside = distMeters <= (marker.geofenceRadius ?? 50.0);

          nearbyList.add(
            UniversalSearchResult(
              id: marker.id,
              title: marker.title,
              subtitle: marker.subtitle ?? (marker.type == MarkerType.employee ? 'Live Staff' : 'Nearby Store'),
              latitude: marker.latitude,
              longitude: marker.longitude,
              type: marker.type == MarkerType.employee ? SearchResultType.employee : SearchResultType.shop,
              distanceMeters: distMeters,
              formattedDistance: HaversineCalculator.formatDistance(distMeters),
              isInsideGeofence: isInside,
              originalData: marker,
            ),
          );
        }
        nearbyList.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
        return nearbyList.take(maxResults).toList();
      }
      return [];
    }

    final List<UniversalSearchResult> results = [];

    // Check if input is a direct Google Maps URL or Coordinates
    final parsed = parseGoogleMapsUrlOrCoords(q);
    if (parsed != null) {
      final lat = parsed['lat'] as double;
      final lng = parsed['lng'] as double;
      final title = parsed['title'] as String;
      double? dist;
      String? fmtDist;
      if (userLat != null && userLng != null) {
        dist = HaversineCalculator.distanceMeters(lat1: userLat, lon1: userLng, lat2: lat, lon2: lng);
        fmtDist = HaversineCalculator.formatDistance(dist);
      }
      return [
        UniversalSearchResult(
          id: 'parsed_coords_${lat}_$lng',
          title: title,
          subtitle: 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
          latitude: lat,
          longitude: lng,
          type: SearchResultType.coordinates,
          distanceMeters: dist,
          formattedDistance: fmtDist,
        ),
      ];
    }

    final lowerQ = q.toLowerCase();
    final tokens = lowerQ.split(RegExp(r'\s+')).where((t) => t.length > 1).toList();

    // 1. Multi-Token Fuzzy Matching on Local System Markers (Shops, Gyms & Live Staff)
    final List<Map<String, dynamic>> scoredMarkers = [];
    for (final marker in localMarkers) {
      final title = marker.title.toLowerCase();
      final subtitle = marker.subtitle?.toLowerCase() ?? '';
      final fullText = '$title $subtitle';

      int matchScore = 0;
      if (fullText.contains(lowerQ)) {
        matchScore += 100; // Exact full phrase match
      } else {
        for (final token in tokens) {
          if (fullText.contains(token)) {
            matchScore += 25;
          }
        }
      }

      if (matchScore > 0) {
        double? dist;
        String? fmtDist;
        bool isInside = false;
        if (userLat != null && userLng != null) {
          dist = HaversineCalculator.distanceMeters(
            lat1: userLat,
            lon1: userLng,
            lat2: marker.latitude,
            lon2: marker.longitude,
          );
          fmtDist = HaversineCalculator.formatDistance(dist);
          isInside = dist <= (marker.geofenceRadius ?? 50.0);
        }

        scoredMarkers.add({
          'marker': marker,
          'score': matchScore,
          'dist': dist,
          'fmtDist': fmtDist,
          'isInside': isInside,
        });
      }
    }

    // Sort scored markers by score descending, then distance ascending
    scoredMarkers.sort((a, b) {
      final scoreDiff = (b['score'] as int).compareTo(a['score'] as int);
      if (scoreDiff != 0) return scoreDiff;
      if (a['dist'] != null && b['dist'] != null) {
        return (a['dist'] as double).compareTo(b['dist'] as double);
      }
      return 0;
    });

    for (final sm in scoredMarkers) {
      final marker = sm['marker'] as MapMarkerItem;
      results.add(
        UniversalSearchResult(
          id: marker.id,
          title: marker.title,
          subtitle: marker.subtitle ?? (marker.type == MarkerType.employee ? 'Live Employee' : 'Registered Store/Gym'),
          latitude: marker.latitude,
          longitude: marker.longitude,
          type: marker.type == MarkerType.employee ? SearchResultType.employee : SearchResultType.shop,
          distanceMeters: sm['dist'] as double?,
          formattedDistance: sm['fmtDist'] as String?,
          isInsideGeofence: sm['isInside'] as bool,
          originalData: marker,
        ),
      );
    }

    // 2. Fetch Photon Komoot / OSM Places with Location Biasing
    final defaultLat = userLat ?? 26.4832;
    final defaultLng = userLng ?? 80.3184;

    try {
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&lat=$defaultLat&lon=$defaultLng&limit=6',
      );
      final res = await http.get(photonUrl, headers: {'User-Agent': 'EmpTrackerApp/1.0'}).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final features = (data['features'] as List?) ?? [];

        for (final item in features) {
          final props = item['properties'] as Map<String, dynamic>;
          final geom = item['geometry'] as Map<String, dynamic>;
          final coords = geom['coordinates'] as List;

          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();

          final name = props['name'] as String? ?? '';
          final street = props['street'] as String? ?? '';
          final city = props['city'] as String? ?? props['district'] as String? ?? '';
          final state = props['state'] as String? ?? '';
          final country = props['country'] as String? ?? '';

          final List<String> subParts = [];
          if (street.isNotEmpty && street != name) subParts.add(street);
          if (city.isNotEmpty) subParts.add(city);
          if (state.isNotEmpty) subParts.add(state);
          if (country.isNotEmpty) subParts.add(country);

          final displayTitle = name.isNotEmpty ? name : (street.isNotEmpty ? street : city);
          final displaySubtitle = subParts.join(', ');

          if (displayTitle.isNotEmpty) {
            final isDuplicate = results.any((r) =>
                (r.latitude - lat).abs() < 0.0001 && (r.longitude - lng).abs() < 0.0001);

            if (!isDuplicate) {
              double? dist;
              String? fmtDist;
              if (userLat != null && userLng != null) {
                dist = HaversineCalculator.distanceMeters(lat1: userLat, lon1: userLng, lat2: lat, lon2: lng);
                fmtDist = HaversineCalculator.formatDistance(dist);
              }

              results.add(
                UniversalSearchResult(
                  id: 'photon_${props['osm_id'] ?? '${lat}_$lng'}',
                  title: displayTitle,
                  subtitle: displaySubtitle.isNotEmpty ? displaySubtitle : 'Location in $state, $country',
                  latitude: lat,
                  longitude: lng,
                  type: SearchResultType.onlinePlace,
                  distanceMeters: dist,
                  formattedDistance: fmtDist,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    // 3. Smart Fallback: Pin Search Query at Admin / Current GPS Location
    if (results.isEmpty) {
      results.add(
        UniversalSearchResult(
          id: 'custom_pin_${DateTime.now().millisecondsSinceEpoch}',
          title: '📍 Pin "$q" at Current Location',
          subtitle: 'Lat: ${defaultLat.toStringAsFixed(6)}, Lng: ${defaultLng.toStringAsFixed(6)} (Kanpur Region)',
          latitude: defaultLat,
          longitude: defaultLng,
          type: SearchResultType.onlinePlace,
          distanceMeters: 0,
          formattedDistance: '0 m away',
        ),
      );
    }

    return results.take(maxResults).toList();
  }
}
