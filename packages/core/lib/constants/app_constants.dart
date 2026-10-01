class AppConstants {
  static const String appName = 'FieldForce Pro';
  static const String appVersion = '1.0.0+1';

  // Geofence defaults in meters
  static const double defaultGeofenceRadiusMeters = 100.0;
  static const double strictGeofenceRadiusMeters = 50.0;
  static const double wideGeofenceRadiusMeters = 200.0;

  // Adaptive location sampling thresholds
  static const int stationaryIntervalSec = 60;
  static const int walkingIntervalSec = 30;
  static const int inTransitIntervalSec = 15;

  static const double stationaryDistanceFilterM = 25.0;
  static const double walkingDistanceFilterM = 15.0;
  static const double inTransitDistanceFilterM = 30.0;

  // Live status thresholds (in seconds)
  static const int liveThresholdSec = 60;
  static const int recentThresholdSec = 300; // 5 min
  static const int staleThresholdSec = 900; // 15 min

  // Anomaly thresholds
  static const double maxRealisticSpeedKmh = 160.0; // Above this is suspicious jump
  static const double maxAcceptableAccuracyMeters = 100.0;
}
