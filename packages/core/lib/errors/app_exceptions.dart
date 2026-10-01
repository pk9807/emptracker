class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class LocationPermissionDeniedException extends AppException {
  const LocationPermissionDeniedException([String message = 'Location permission was denied.'])
      : super(message, code: 'PERMISSION_DENIED');
}

class LocationServiceDisabledException extends AppException {
  const LocationServiceDisabledException([String message = 'GPS location service is disabled on the device.'])
      : super(message, code: 'GPS_DISABLED');
}

class GeofenceBreachedException extends AppException {
  final double distanceMeters;
  final double allowedRadiusMeters;

  GeofenceBreachedException({
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    String? message,
  }) : super(
          message ??
              'You are ${distanceMeters.round()}m away from this shop. Move within ${allowedRadiusMeters.round()}m to check in.',
          code: 'GEOFENCE_BREACH',
        );
}

class MockLocationDetectedException extends AppException {
  const MockLocationDetectedException([String message = 'Mock GPS / Fake location provider detected. Duty check-in rejected.'])
      : super(message, code: 'MOCK_GPS_DETECTED');
}

class NetworkException extends AppException {
  const NetworkException([String message = 'No network connection. Operation queued for offline synchronization.'])
      : super(message, code: 'NETWORK_OFFLINE');
}
