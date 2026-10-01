import 'package:equatable/equatable.dart';

class DiagnosticsReport extends Equatable {
  final bool isLocationPermissionGranted;
  final bool isPreciseLocationEnabled;
  final bool isBackgroundLocationGranted;
  final bool isGpsServiceEnabled;
  final bool isBatteryOptimizationIgnored;
  final bool isNetworkConnected;
  final bool isMockLocationDetected;

  const DiagnosticsReport({
    required this.isLocationPermissionGranted,
    required this.isPreciseLocationEnabled,
    required this.isBackgroundLocationGranted,
    required this.isGpsServiceEnabled,
    required this.isBatteryOptimizationIgnored,
    required this.isNetworkConnected,
    this.isMockLocationDetected = false,
  });

  bool get isHealthy =>
      isLocationPermissionGranted &&
      isPreciseLocationEnabled &&
      isGpsServiceEnabled &&
      !isMockLocationDetected;

  @override
  List<Object?> get props => [
        isLocationPermissionGranted,
        isPreciseLocationEnabled,
        isBackgroundLocationGranted,
        isGpsServiceEnabled,
        isBatteryOptimizationIgnored,
        isNetworkConnected,
        isMockLocationDetected,
      ];
}

class TrackingDiagnosticsService {
  Future<DiagnosticsReport> runFullDiagnostics() async {
    // In production, queries platform permission channels & BatteryManager
    await Future.delayed(const Duration(milliseconds: 300));
    return const DiagnosticsReport(
      isLocationPermissionGranted: true,
      isPreciseLocationEnabled: true,
      isBackgroundLocationGranted: true,
      isGpsServiceEnabled: true,
      isBatteryOptimizationIgnored: true,
      isNetworkConnected: true,
      isMockLocationDetected: false,
    );
  }
}
