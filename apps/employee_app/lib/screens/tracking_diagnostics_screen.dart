import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:location_engine/location_engine.dart';

class TrackingDiagnosticsScreen extends StatefulWidget {
  final TrackingDiagnosticsService diagnosticsService;

  const TrackingDiagnosticsScreen({
    super.key,
    required this.diagnosticsService,
  });

  @override
  State<TrackingDiagnosticsScreen> createState() =>
      _TrackingDiagnosticsScreenState();
}

class _TrackingDiagnosticsScreenState extends State<TrackingDiagnosticsScreen> {
  DiagnosticsReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });
    final report = await widget.diagnosticsService.runFullDiagnostics();
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Diagnostics',
            style: AppTypography.headingLarge(isDark: isDark)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Health Overview Card
                  DepthCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _report!.isHealthy
                                ? AppColors.liveGreenSubtle
                                : AppColors.recentAmberSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _report!.isHealthy
                                ? Icons.verified_user
                                : Icons.warning_amber_rounded,
                            color: _report!.isHealthy
                                ? AppColors.liveGreenDark
                                : AppColors.recentAmber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _report!.isHealthy
                                    ? 'Device System Healthy'
                                    : 'Action Required',
                                style: AppTypography.headingMedium(
                                    isDark: isDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _report!.isHealthy
                                    ? 'All background GPS and power settings optimal.'
                                    : 'Please resolve restricted settings below.',
                                style:
                                    AppTypography.bodySmall(isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'SYSTEM CHECKS',
                    style: AppTypography.badge(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DepthCard(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _buildCheckTile(
                          icon: Icons.location_on_outlined,
                          title: 'Location Permission',
                          subtitle: 'Allows app to record duty coordinates',
                          isPassed: _report!.isLocationPermissionGranted,
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildCheckTile(
                          icon: Icons.gps_fixed,
                          title: 'Precise GPS Accuracy',
                          subtitle: 'High-precision sensor enabled',
                          isPassed: _report!.isPreciseLocationEnabled,
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildCheckTile(
                          icon: Icons.layers_outlined,
                          title: 'Background Location',
                          subtitle: 'Tracks route when app is minimized',
                          isPassed: _report!.isBackgroundLocationGranted,
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildCheckTile(
                          icon: Icons.battery_saver,
                          title: 'Battery Optimization Whitelist',
                          subtitle: 'Prevents OEM Android from killing service',
                          isPassed: _report!.isBatteryOptimizationIgnored,
                          isDark: isDark,
                        ),
                        const Divider(height: 1),
                        _buildCheckTile(
                          icon: Icons.security,
                          title: 'Mock GPS Anomaly Check',
                          subtitle: 'Zero fake location providers active',
                          isPassed: !_report!.isMockLocationDetected,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SecondaryButton(
                    text: 'RE-RUN DIAGNOSTICS',
                    icon: Icons.refresh,
                    onPressed: _runDiagnostics,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCheckTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPassed,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headingSmall(isDark: isDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall(isDark: isDark)),
              ],
            ),
          ),
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            color: isPassed ? AppColors.liveGreen : AppColors.offlineRose,
            size: 22,
          ),
        ],
      ),
    );
  }
}
