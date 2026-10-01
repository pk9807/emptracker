import 'dart:async';
import 'package:models/models.dart';

abstract class LocationRepository {
  Stream<List<LiveLocationModel>> streamLiveLocations(String organizationId);
  Future<void> updateLiveLocation(LiveLocationModel location);
  Future<void> appendLocationHistoryBatch(List<LocationPointModel> points);
  Future<List<LocationPointModel>> getEmployeeRouteHistory(String employeeId, String dateKey);
}

class MockLocationRepository implements LocationRepository {
  final Map<String, LiveLocationModel> _liveMap = {
    'emp_001': LiveLocationModel(
      employeeId: 'emp_001',
      organizationId: 'org_acme_fmcg',
      name: 'Rahul Sharma',
      latitude: 28.6328,
      longitude: 77.2197,
      accuracy: 5.2,
      speed: 3.5,
      heading: 120.0,
      battery: 84,
      updatedAt: DateTime.now(),
    ),
    'emp_002': LiveLocationModel(
      employeeId: 'emp_002',
      organizationId: 'org_acme_fmcg',
      name: 'Priya Patel',
      latitude: 28.6514,
      longitude: 77.1907,
      accuracy: 6.8,
      speed: 1.2,
      heading: 45.0,
      battery: 68,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    'emp_003': LiveLocationModel(
      employeeId: 'emp_003',
      organizationId: 'org_acme_fmcg',
      name: 'Amit Kumar',
      latitude: 28.5733,
      longitude: 77.2343,
      accuracy: 12.0,
      battery: 32,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
  };

  final List<LocationPointModel> _history = [];
  final StreamController<List<LiveLocationModel>> _liveController =
      StreamController<List<LiveLocationModel>>.broadcast();

  @override
  Stream<List<LiveLocationModel>> streamLiveLocations(String organizationId) {
    Timer.run(() => _liveController.add(_liveMap.values.toList()));
    return _liveController.stream;
  }

  @override
  Future<void> updateLiveLocation(LiveLocationModel location) async {
    _liveMap[location.employeeId] = location;
    _liveController.add(_liveMap.values.toList());
  }

  @override
  Future<void> appendLocationHistoryBatch(
      List<LocationPointModel> points) async {
    _history.addAll(points);
  }

  @override
  Future<List<LocationPointModel>> getEmployeeRouteHistory(
      String employeeId, String dateKey) async {
    return _history
        .where((p) => p.employeeId == employeeId && p.dateKey == dateKey)
        .toList();
  }
}
