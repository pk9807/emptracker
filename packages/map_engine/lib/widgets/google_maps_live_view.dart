import 'dart:math' as math;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_marker_item.dart';

class GoogleMapsLiveView extends StatefulWidget {
  final List<MapMarkerItem> markers;
  final MapMarkerItem? selectedMarker;
  final ValueChanged<MapMarkerItem>? onMarkerTap;
  final LatLng initialCenter;
  final double initialZoom;
  final bool showGeofenceCircles;

  const GoogleMapsLiveView({
    super.key,
    required this.markers,
    this.selectedMarker,
    this.onMarkerTap,
    this.initialCenter = const LatLng(28.6328, 77.2197), // New Delhi Connaught Place
    this.initialZoom = 14.0,
    this.showGeofenceCircles = true,
  });

  @override
  State<GoogleMapsLiveView> createState() => _GoogleMapsLiveViewState();
}

class _GoogleMapsLiveViewState extends State<GoogleMapsLiveView> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  bool _is3DTilt = true;
  double _currentZoom = 14.0;

  @override
  void didUpdateWidget(covariant GoogleMapsLiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarker != null &&
        widget.selectedMarker != oldWidget.selectedMarker &&
        _mapController != null) {
      _animateToMarker(widget.selectedMarker!);
    }
  }

  void _animateToMarker(MapMarkerItem marker) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(marker.latitude, marker.longitude),
          zoom: 16.5,
          tilt: _is3DTilt ? 45.0 : 0.0,
          bearing: 30.0,
        ),
      ),
    );
  }

  void _toggle3DTilt() {
    setState(() {
      _is3DTilt = !_is3DTilt;
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: widget.selectedMarker != null
                ? LatLng(widget.selectedMarker!.latitude,
                    widget.selectedMarker!.longitude)
                : widget.initialCenter,
            zoom: _currentZoom,
            tilt: _is3DTilt ? 45.0 : 0.0,
          ),
        ),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  Set<Marker> _buildGoogleMarkers() {
    return widget.markers.map((item) {
      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
      if (item.type == MarkerType.employee) {
        if (item.liveStatus == TrackingLiveStatus.live) {
          icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen);
        } else if (item.liveStatus == TrackingLiveStatus.recent) {
          icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange);
        } else {
          icon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed);
        }
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      }

      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.type == MarkerType.employee
              ? 'Status: ${item.liveStatus?.label ?? "LIVE"} | Battery: ${item.battery ?? 80}%'
              : (item.subtitle ?? 'Geofenced Location'),
        ),
        icon: icon,
        onTap: () => widget.onMarkerTap?.call(item),
      );
    }).toSet();
  }

  Set<Circle> _buildGeofenceCircles() {
    if (!widget.showGeofenceCircles) return {};

    return widget.markers
        .where((m) => m.type == MarkerType.shop)
        .map(
          (shop) => Circle(
            circleId: CircleId('geo_${shop.id}'),
            center: LatLng(shop.latitude, shop.longitude),
            radius: 100.0, // 100m geofence radius
            fillColor: const Color(0x332563EB),
            strokeColor: AppColors.primary,
            strokeWidth: 2,
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Real Google Map Engine Component with Fallback to Stylized Vector Radar
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom: widget.initialZoom,
            tilt: _is3DTilt ? 45.0 : 0.0,
          ),
          mapType: _currentMapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          buildingsEnabled: true,
          markers: _buildGoogleMarkers(),
          circles: _buildGeofenceCircles(),
          onMapCreated: (ctrl) {
            _mapController = ctrl;
          },
          onCameraMove: (pos) {
            _currentZoom = pos.zoom;
          },
        ),

        // Top Floating Search Bar & Live Radar Pill
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
                    'Search Google Maps live telemetry...',
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

        // Floating Map Controls (3D Mode, Layer Switcher, Recenter GPS)
        Positioned(
          right: 16,
          bottom: 150,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingControl(
                icon: _is3DTilt ? Icons.view_in_ar : Icons.layers,
                tooltip: _is3DTilt ? '3D Tilt Active' : 'Flat 2D View',
                isActive: _is3DTilt,
                onTap: _toggle3DTilt,
              ),
              const SizedBox(height: 10),
              _buildFloatingControl(
                icon: _currentMapType == MapType.hybrid
                    ? Icons.satellite_alt
                    : Icons.map,
                tooltip: 'Toggle Satellite / Streets',
                isActive: _currentMapType == MapType.hybrid,
                onTap: _toggleMapType,
              ),
              const SizedBox(height: 10),
              _buildFloatingControl(
                icon: Icons.my_location,
                tooltip: 'Recenter Map',
                isActive: false,
                onTap: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: widget.initialCenter,
                        zoom: 15.0,
                        tilt: _is3DTilt ? 45.0 : 0.0,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingControl({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}
