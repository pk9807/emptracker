import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsmPlaceItem {
  final String displayName;
  final String shortName;
  final double latitude;
  final double longitude;
  final String? type;

  OsmPlaceItem({
    required this.displayName,
    required this.shortName,
    required this.latitude,
    required this.longitude,
    this.type,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory OsmPlaceItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final display = json['display_name'] as String? ?? '';
    return OsmPlaceItem(
      displayName: display,
      shortName: name.isNotEmpty ? name : display.split(',').first,
      latitude: double.tryParse(json['lat'].toString()) ?? 0.0,
      longitude: double.tryParse(json['lon'].toString()) ?? 0.0,
      type: json['type'] as String?,
    );
  }
}

class NominatimGeocodingService {
  static const String _searchUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Search places, landmarks, cities, or shops with free Nominatim API
  static Future<List<OsmPlaceItem>> search(String query, {int limit = 6}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_searchUrl?q=${Uri.encodeComponent(q)}&format=json&countrycodes=in&limit=$limit&addressdetails=1',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'EmpTracker-OSM-Geocoding/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((item) => OsmPlaceItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Reverse geocode coordinates to human readable address
  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_reverseUrl?lat=$lat&lon=$lon&format=json',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'EmpTracker-OSM-Geocoding/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['display_name'] as String?;
      }
    } catch (_) {}

    return null;
  }
}
