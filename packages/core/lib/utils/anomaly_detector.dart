import '../constants/app_constants.dart';
import 'haversine_calculator.dart';

class AnomalyResult {
  final bool isSuspicious;
  final String? reason;
  final double calculatedSpeedKmh;

  const AnomalyResult({
    required this.isSuspicious,
    this.reason,
    this.calculatedSpeedKmh = 0.0,
  });

  static const normal = AnomalyResult(isSuspicious: false);
}

class AnomalyDetector {
  /// Evaluates if a new GPS coordinate jump represents an unrealistic anomaly or fake GPS teleportation.
  static AnomalyResult evaluate({
    required double prevLat,
    required double prevLon,
    required DateTime prevTimestamp,
    required double nextLat,
    required double nextLon,
    required DateTime nextTimestamp,
    required double accuracyMeters,
    bool isMocked = false,
  }) {
    if (isMocked) {
      return const AnomalyResult(
        isSuspicious: true,
        reason: 'Mock location flag detected from OS provider.',
      );
    }

    if (accuracyMeters > AppConstants.maxAcceptableAccuracyMeters) {
      return AnomalyResult(
        isSuspicious: true,
        reason: 'Poor GPS accuracy (${accuracyMeters.toStringAsFixed(1)}m > ${AppConstants.maxAcceptableAccuracyMeters}m).',
      );
    }

    final durationSec = nextTimestamp.difference(prevTimestamp).inSeconds;
    if (durationSec <= 0) {
      return const AnomalyResult(
        isSuspicious: true,
        reason: 'Non-monotonic or identical timestamp delta.',
      );
    }

    final distanceMeters = HaversineCalculator.distanceMeters(
      lat1: prevLat,
      lon1: prevLon,
      lat2: nextLat,
      lon2: nextLon,
    );

    final speedMps = distanceMeters / durationSec;
    final speedKmh = speedMps * 3.6;

    if (speedKmh > AppConstants.maxRealisticSpeedKmh) {
      return AnomalyResult(
        isSuspicious: true,
        reason: 'Unrealistic transit speed detected (${speedKmh.toStringAsFixed(1)} km/h).',
        calculatedSpeedKmh: speedKmh,
      );
    }

    return AnomalyResult(
      isSuspicious: false,
      calculatedSpeedKmh: speedKmh,
    );
  }
}
