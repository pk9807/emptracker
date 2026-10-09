import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'location_repository.dart';

class LaravelLocationRepository implements LocationRepository {
  final ApiClient _api = ApiClient();
  final StreamController<List<LiveLocationModel>> _liveController =
      StreamController<List<LiveLocationModel>>.broadcast();
  Timer? _radarTimer;
  List<LiveLocationModel> _cachedLiveLocations = [];

  LaravelLocationRepository() {
    _startRadarPolling();
  }

  void _startRadarPolling() {
    _fetchLiveRadar();
    _radarTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchLiveRadar();
    });
  }

  Future<void> _fetchLiveRadar() async {
    try {
      final res = await _api.get('/location/live-radar');
      if (res.isSuccess && res.data is List) {
        final list = (res.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          return LiveLocationModel(
            employeeId: map['employee_id'].toString(),
            organizationId: 'org_1',
            name: map['name'] as String? ?? 'Employee',
            photoUrl: map['avatar'] as String?,
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
            accuracy: (map['accuracy'] as num?)?.toDouble() ?? 5.0,
            speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
            heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
            altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
            battery: (map['battery_level'] as num?)?.toInt() ?? 100,
            network: 'CELLULAR',
            isMockLocation: map['is_mocked'] as bool? ?? false,
            updatedAt: map['last_ping_at'] != null
                ? DateTime.tryParse(map['last_ping_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();

        _cachedLiveLocations = list;
        _liveController.add(List.unmodifiable(list));
      }
    } catch (_) {}
  }

  @override
  Stream<List<LiveLocationModel>> streamLiveLocations(String organizationId) {
    if (_cachedLiveLocations.isNotEmpty) {
      Timer.run(() => _liveController.add(List.unmodifiable(_cachedLiveLocations)));
    } else {
      _fetchLiveRadar();
    }
    return _liveController.stream;
  }

  @override
  Future<void> updateLiveLocation(LiveLocationModel location) async {
    try {
      await _api.post('/location/ping', body: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'speed': location.speed,
        'heading': location.heading,
        'altitude': location.altitude,
        'battery_level': location.battery,
        'is_mocked': location.isMockLocation,
        'recorded_at': location.updatedAt.toIso8601String(),
      });
      _fetchLiveRadar();
    } catch (_) {}
  }

  @override
  Future<void> appendLocationHistoryBatch(
      List<LocationPointModel> points) async {
    try {
      final list = points.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'speed': p.speed,
        'heading': p.heading,
        'accuracy': p.accuracy,
        'battery_level': p.battery,
        'recorded_at': p.timestamp.toIso8601String(),
      }).toList();

      await _api.post('/location/batch', body: {'locations': list});
    } catch (_) {}
  }

  @override
  Future<List<LocationPointModel>> getEmployeeRouteHistory(
      String employeeId, String dateKey) async {
    try {
      final res = await _api.get('/location/history/$employeeId', queryParams: {'date': dateKey});
      if (res.isSuccess && res.data is List) {
        final List<LocationPointModel> list = (res.data as List).map<LocationPointModel>((item) {
          final map = item as Map<String, dynamic>;
          final timestamp = map['recorded_at'] != null
              ? DateTime.tryParse(map['recorded_at'].toString()) ?? DateTime.now()
              : DateTime.now();

          return LocationPointModel(
            id: '${employeeId}_${timestamp.millisecondsSinceEpoch}',
            employeeId: employeeId,
            organizationId: 'org_1',
            dateKey: dateKey,
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
            accuracy: (map['accuracy'] as num?)?.toDouble() ?? 5.0,
            speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
            heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
            altitude: 0.0,
            battery: (map['battery_level'] as num?)?.toInt() ?? 100,
            timestamp: timestamp,
            createdAt: timestamp,
          );
        }).toList();
        return list;
      }
    } catch (_) {}
    return <LocationPointModel>[];
  }

  void dispose() {
    _radarTimer?.cancel();
  }
}
