import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isSuccess;
  final String? errorMessage;

  OsrmRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isSuccess,
    this.errorMessage,
  });

  double get distanceKm => distanceMeters / 1000.0;
  double get durationMinutes => durationSeconds / 60.0;
}

class OsrmRoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Calculate real-road driving route between origin and destination using OSRM
  static Future<OsrmRouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final coordinates = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final url = Uri.parse('$_baseUrl/$coordinates?overview=full&geometries=geojson');

      final response = await http.get(
        url,
        headers: {'User-Agent': 'EmpTracker-OSM-Router/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0] as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final rawCoords = geometry['coordinates'] as List;

          final List<LatLng> latLngList = rawCoords.map((c) {
            final pair = c as List;
            final lng = (pair[0] as num).toDouble();
            final lat = (pair[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;

          return OsrmRouteResult(
            points: latLngList,
            distanceMeters: distance,
            durationSeconds: duration,
            isSuccess: true,
          );
        }
      }

      return OsrmRouteResult(
        points: [origin, destination],
        distanceMeters: 0,
        durationSeconds: 0,
        isSuccess: false,
        errorMessage: 'Route calculation returned status: ${response.statusCode}',
      );
    } catch (e) {
      return OsrmRouteResult(
        points: [origin, destination],
        distanceMeters: 0,
        durationSeconds: 0,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Calculate multi-stop route between multiple waypoints
  static Future<OsrmRouteResult> getMultiStopRoute({
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.length < 2) {
      return OsrmRouteResult(
        points: waypoints,
        distanceMeters: 0,
        durationSeconds: 0,
        isSuccess: true,
      );
    }

    try {
      final coordString = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = Uri.parse('$_baseUrl/$coordString?overview=full&geometries=geojson');

      final response = await http.get(
        url,
        headers: {'User-Agent': 'EmpTracker-OSM-Router/1.0'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0] as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final rawCoords = geometry['coordinates'] as List;

          final List<LatLng> latLngList = rawCoords.map((c) {
            final pair = c as List;
            return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
          }).toList();

          return OsrmRouteResult(
            points: latLngList,
            distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0.0,
            durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0.0,
            isSuccess: true,
          );
        }
      }
    } catch (_) {}

    return OsrmRouteResult(
      points: waypoints,
      distanceMeters: 0,
      durationSeconds: 0,
      isSuccess: false,
    );
  }
}
