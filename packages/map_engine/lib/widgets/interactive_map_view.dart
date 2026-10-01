import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../models/map_marker_item.dart';

class InteractiveMapView extends StatefulWidget {
  final List<MapMarkerItem> markers;
  final MapMarkerItem? selectedMarker;
  final ValueChanged<MapMarkerItem>? onMarkerTap;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final bool is3DMode;

  const InteractiveMapView({
    super.key,
    required this.markers,
    this.selectedMarker,
    this.onMarkerTap,
    this.centerLat = 28.6139,
    this.centerLon = 77.2090,
    this.zoom = 14.0,
    this.is3DMode = true,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}

class _InteractiveMapViewState extends State<InteractiveMapView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        children: [
          // 3D Canvas / Styled Grid Map Background with perspective grid lines
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
              ),
            ),
            child: CustomPaint(
              painter: _GridMapPainter(
                isDark: isDark,
                is3D: widget.is3DMode,
              ),
            ),
          ),

          // Render Animated Map Markers
          ...widget.markers.map((marker) {
            final isSelected = widget.selectedMarker?.id == marker.id;
            // Map lat/lon delta into view percentages around center
            final offsetX = ((marker.longitude - widget.centerLon) * 3500) + 180;
            final offsetY = ((widget.centerLat - marker.latitude) * 3500) + 220;

            return Positioned(
              left: offsetX.clamp(20.0, 320.0),
              top: offsetY.clamp(40.0, 480.0),
              child: GestureDetector(
                onTap: () => widget.onMarkerTap?.call(marker),
                child: _buildMarkerWidget(marker, isSelected, isDark),
              ),
            );
          }),

          // Top Floating Search / Layer Controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: AppSpacing.radiusFull,
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search employees or shops...',
                      style: AppTypography.bodyMedium(isDark: isDark),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.liveGreen.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulseRadarDot(size: 8),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.markers.where((m) => m.liveStatus == TrackingLiveStatus.live).length} LIVE',
                          style: AppTypography.badge(
                              color: AppColors.liveGreenDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerWidget(
      MapMarkerItem marker, bool isSelected, bool isDark) {
    if (marker.type == MarkerType.shop) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.storefront, size: 18, color: Colors.white),
      );
    }

    Color ringColor = AppColors.liveGreen;
    if (marker.liveStatus == TrackingLiveStatus.recent) {
      ringColor = AppColors.recentAmber;
    } else if (marker.liveStatus == TrackingLiveStatus.stale) {
      ringColor = AppColors.staleOrange;
    } else if (marker.liveStatus == TrackingLiveStatus.offline) {
      ringColor = AppColors.offlineRose;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: ringColor, width: isSelected ? 3.0 : 2.0),
            boxShadow: [
              BoxShadow(
                color: ringColor.withOpacity(0.45),
                blurRadius: isSelected ? 16 : 8,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isSelected ? 18 : 14,
            backgroundColor: AppColors.primary,
            child: Text(
              marker.title.isNotEmpty ? marker.title[0] : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xDD0F172A) : const Color(0xEEFFFFFF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            marker.title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _GridMapPainter extends CustomPainter {
  final bool isDark;
  final bool is3D;

  _GridMapPainter({required this.isDark, required this.is3D});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark
          ? const Color(0x1A38BDF8)
          : const Color(0x1A0284C7)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
