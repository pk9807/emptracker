library location_engine;

import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'diagnostics/tracking_diagnostics_service.dart';
import 'foreground/tracking_foreground_service.dart';

export 'diagnostics/tracking_diagnostics_service.dart';
export 'foreground/tracking_foreground_service.dart';

class LocationEngine {
  final TrackingForegroundService _foregroundService =
      TrackingForegroundService();
  final TrackingDiagnosticsService _diagnosticsService =
      TrackingDiagnosticsService();

  bool _isTracking = false;
  LiveLocationModel? _currentLocation;
  LocationPointModel? _lastPoint;
  final List<LocationPointModel> _pointBuffer = [];

  final StreamController<LiveLocationModel> _locationStreamController =
      StreamController<LiveLocationModel>.broadcast();
  final StreamController<bool> _trackingStatusController =
      StreamController<bool>.broadcast();

  bool get isTracking => _isTracking;
  LiveLocationModel? get currentLocation => _currentLocation;
  Stream<LiveLocationModel> get locationStream =>
      _locationStreamController.stream;
  Stream<bool> get trackingStatusStream => _trackingStatusController.stream;

  TrackingForegroundService get foregroundService => _foregroundService;
  TrackingDiagnosticsService get diagnosticsService => _diagnosticsService;

  Future<void> startTracking({
    required String employeeId,
    required String organizationId,
    required String employeeName,
    required Function(LiveLocationModel) onLiveUpdate,
    required Function(List<LocationPointModel>) onBatchHistory,
  }) async {
    if (_isTracking) return;

    final diagnostics = await _diagnosticsService.runFullDiagnostics();
    if (!diagnostics.isHealthy) {
      throw const LocationPermissionDeniedException(
          'Location diagnostics failed. Verify GPS and permissions.');
    }

    _isTracking = true;
    _trackingStatusController.add(true);

    await _foregroundService.startService(
      employeeName: employeeName,
      notificationTitle: 'Duty Tracking Active',
      notificationBody: 'Your live route is being recorded for field operations.',
    );

    // Initial seed location (e.g. Swaroop Nagar, Kanpur)
    _currentLocation = LiveLocationModel(
      employeeId: employeeId,
      organizationId: organizationId,
      name: employeeName,
      latitude: 26.4850,
      longitude: 80.3150,
      accuracy: 5.0,
      speed: 0.0,
      heading: 0.0,
      altitude: 126.0,
      battery: 88,
      updatedAt: DateTime.now(),
    );

    _locationStreamController.add(_currentLocation!);
    onLiveUpdate(_currentLocation!);
  }

  void recordLocationUpdate({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    required double heading,
    required int battery,
    required Function(LiveLocationModel) onLiveUpdate,
    required Function(List<LocationPointModel>) onBatchHistory,
  }) {
    if (!_isTracking || _currentLocation == null) return;

    final now = DateTime.now();

    // Anomaly evaluation against previous point
    AnomalyResult anomaly = AnomalyResult.normal;
    if (_lastPoint != null) {
      anomaly = AnomalyDetector.evaluate(
        prevLat: _lastPoint!.latitude,
        prevLon: _lastPoint!.longitude,
        prevTimestamp: _lastPoint!.timestamp,
        nextLat: latitude,
        nextLon: longitude,
        nextTimestamp: now,
        accuracyMeters: accuracy,
      );
    }

    final updatedLive = LiveLocationModel(
      employeeId: _currentLocation!.employeeId,
      organizationId: _currentLocation!.organizationId,
      name: _currentLocation!.name,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      altitude: _currentLocation!.altitude,
      battery: battery,
      updatedAt: now,
    );

    _currentLocation = updatedLive;
    _locationStreamController.add(updatedLive);
    onLiveUpdate(updatedLive);

    final point = LocationPointModel(
      id: 'pt_${now.millisecondsSinceEpoch}',
      employeeId: _currentLocation!.employeeId,
      organizationId: _currentLocation!.organizationId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      battery: battery,
      dateKey: DateTimeUtils.getDateKey(now),
      isSuspicious: anomaly.isSuspicious,
      timestamp: now,
      createdAt: now,
    );

    _lastPoint = point;
    _pointBuffer.add(point);

    if (_pointBuffer.length >= 10) {
      onBatchHistory(List.unmodifiable(_pointBuffer));
      _pointBuffer.clear();
    }
  }

  Future<void> stopTracking({
    required Function(List<LocationPointModel>) onFlushPendingHistory,
  }) async {
    _isTracking = false;
    _trackingStatusController.add(false);
    await _foregroundService.stopService();

    if (_pointBuffer.isNotEmpty) {
      onFlushPendingHistory(List.unmodifiable(_pointBuffer));
      _pointBuffer.clear();
    }
  }
}
