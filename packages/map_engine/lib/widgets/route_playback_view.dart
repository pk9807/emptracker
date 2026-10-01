import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class RoutePlaybackView extends StatefulWidget {
  final List<LocationPointModel> points;
  final String employeeName;

  const RoutePlaybackView({
    super.key,
    required this.points,
    required this.employeeName,
  });

  @override
  State<RoutePlaybackView> createState() => _RoutePlaybackViewState();
}

class _RoutePlaybackViewState extends State<RoutePlaybackView> {
  int _currentStep = 0;
  bool _isPlaying = false;

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.points.isEmpty) {
      return const EmptyStateView(
        icon: Icons.alt_route,
        title: 'No Route History Found',
        description: 'No GPS points recorded for this employee on the selected date.',
      );
    }

    final currentPt = widget.points[_currentStep.clamp(0, widget.points.length - 1)];

    return Column(
      children: [
        // Map Track Visualization
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.route, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Route Polyline: ${widget.points.length} GPS Points Recorded',
                        style: AppTypography.headingSmall(isDark: isDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Playback Step ${_currentStep + 1} of ${widget.points.length}',
                        style: AppTypography.bodySmall(isDark: isDark),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time: ${DateTimeUtils.formatTime(currentPt.timestamp)}',
                              style: AppTypography.bodySmall(isDark: isDark).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Speed: ${currentPt.speed.toStringAsFixed(1)} km/h | Acc: ±${currentPt.accuracy.round()}m',
                              style: AppTypography.bodySmall(isDark: isDark),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle : Icons.play_circle,
                            size: 36,
                            color: AppColors.primary,
                          ),
                          onPressed: _togglePlay,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Slider scrubber
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Slider(
            value: _currentStep.toDouble(),
            min: 0.0,
            max: (widget.points.length - 1).toDouble().clamp(0.0, 9999.0),
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _currentStep = val.round();
              });
            },
          ),
        ),
      ],
    );
  }
}
