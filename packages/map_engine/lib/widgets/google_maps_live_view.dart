import 'dart:async';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:models/models.dart';
import '../models/map_marker_item.dart';
import '../services/google_map_marker_renderer.dart';
import '../services/osrm_routing_service.dart';
import '../services/universal_search_service.dart';
import 'employee_quick_card.dart';
import 'google_place_details_panel.dart';

enum GoogleMapThemeMode {
  standard,
  darkCyberpunk,
  satellite,
  terrain,
}

class GoogleMapsLiveView extends StatefulWidget {
  final List<MapMarkerItem> markers;
  final MapMarkerItem? selectedMarker;
  final ValueChanged<MapMarkerItem>? onMarkerTap;
  final LatLng initialCenter;
  final double initialZoom;
  final bool showGeofenceCircles;
  final bool enableSearch;
  final Set<Polyline>? polylines;
  final VoidCallback? onRecenterTap;
  final VoidCallback? onRouteTap;

  const GoogleMapsLiveView({
    super.key,
    required this.markers,
    this.selectedMarker,
    this.onMarkerTap,
    this.initialCenter = const LatLng(26.490745, 80.318524), // Default Kanpur
    this.initialZoom = 14.5,
    this.showGeofenceCircles = true,
    this.enableSearch = true,
    this.polylines,
    this.onRecenterTap,
    this.onRouteTap,
  });

  @override
  State<GoogleMapsLiveView> createState() => _GoogleMapsLiveViewState();
}

class _GoogleMapsLiveViewState extends State<GoogleMapsLiveView> {
  GoogleMapController? _mapController;
  GoogleMapThemeMode _currentTheme = GoogleMapThemeMode.darkCyberpunk;
  bool _trafficEnabled = false;
  bool _is3DTilt = true;

  final TextEditingController _searchCtrl = TextEditingController();
  List<UniversalSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  Marker? _dynamicSearchedMarker;

  MapMarkerItem? _activeSelectedMarker;
  Set<Marker> _renderedMarkers = {};
  bool _isRenderingMarkers = false;
  Set<Polyline> _routePolylines = {};

  Future<void> _calculateDirectionsTo(LatLng dest) async {
    final origin = widget.initialCenter;
    final res = await OsrmRoutingService.getRoute(
      origin: ll.LatLng(origin.latitude, origin.longitude),
      destination: ll.LatLng(dest.latitude, dest.longitude),
    );

    if (res.isSuccess) {
      final googlePoints = res.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('directions_route_line'),
            points: googlePoints,
            color: const Color(0xFF2563EB),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      });

      double minLat = origin.latitude;
      double maxLat = origin.latitude;
      double minLng = origin.longitude;
      double maxLng = origin.longitude;
      for (final p in googlePoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          80,
        ),
      );
    }
  }

  static const String _darkMapStyleJson = '''[
  {"elementType": "geometry", "stylers": [{"color": "#1e293b"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#94a3b8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0f172a"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#cbd5e1"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#64748b"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#14532d"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#4ade80"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#334155"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1e293b"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#cbd5e1"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#4f46e5"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#3730a3"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f8fafc"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1e293b"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#a5b4fc"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f172a"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#38bdf8"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#020617"}]}
]''';

  @override
  void initState() {
    super.initState();
    _activeSelectedMarker = widget.selectedMarker;
    _searchCtrl.addListener(_onSearchChanged);
    _buildCustomMarkers();
  }

  @override
  void didUpdateWidget(covariant GoogleMapsLiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarker != oldWidget.selectedMarker) {
      setState(() {
        _activeSelectedMarker = widget.selectedMarker;
      });
      if (widget.selectedMarker != null) {
        _animateToMarker(widget.selectedMarker!);
      }
    }
    if (widget.markers != oldWidget.markers || widget.selectedMarker != oldWidget.selectedMarker) {
      _buildCustomMarkers();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await UniversalSearchService.search(
        query: query,
        localMarkers: widget.markers,
        userLat: widget.initialCenter.latitude,
        userLng: widget.initialCenter.longitude,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _buildCustomMarkers() async {
    if (_isRenderingMarkers) return;
    _isRenderingMarkers = true;

    final markers = <Marker>{};
    final isDark = _currentTheme == GoogleMapThemeMode.darkCyberpunk;

    for (final item in widget.markers) {
      final isSelected = _activeSelectedMarker?.id == item.id;
      final customIcon = await GoogleMapMarkerRenderer.getCustomMarker(
        item: item,
        isSelected: isSelected,
        isDark: isDark,
      );

      markers.add(
        Marker(
          markerId: MarkerId(item.id),
          position: LatLng(item.latitude, item.longitude),
          icon: customIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: isSelected ? 20 : (item.type == MarkerType.employee ? 10 : 2),
          infoWindow: InfoWindow(
            title: item.title,
            snippet: item.subtitle,
            onTap: () => _handleMarkerSelection(item),
          ),
          onTap: () => _handleMarkerSelection(item),
        ),
      );
    }

    if (_dynamicSearchedMarker != null) {
      markers.add(_dynamicSearchedMarker!);
    }

    if (mounted) {
      setState(() {
        _renderedMarkers = markers;
        _isRenderingMarkers = false;
      });
    }
  }

  void _handleMarkerSelection(MapMarkerItem item) {
    setState(() {
      _activeSelectedMarker = item;
    });
    _animateToMarker(item);
    widget.onMarkerTap?.call(item);
    _buildCustomMarkers();
  }

  void _animateToMarker(MapMarkerItem marker) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(marker.latitude, marker.longitude),
          zoom: 17.0,
          tilt: _is3DTilt ? 45.0 : 0.0,
          bearing: marker.heading ?? 0.0,
        ),
      ),
    );
  }

  void _animateToLocation(LatLng pos, {double zoom = 16.5}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: zoom,
          tilt: _is3DTilt ? 45.0 : 0.0,
        ),
      ),
    );
  }

  void _fitBoundsAll() {
    if (widget.markers.isEmpty) {
      _animateToLocation(widget.initialCenter);
      return;
    }

    if (widget.markers.length == 1) {
      _animateToMarker(widget.markers.first);
      return;
    }

    double minLat = widget.markers.first.latitude;
    double maxLat = widget.markers.first.latitude;
    double minLng = widget.markers.first.longitude;
    double maxLng = widget.markers.first.longitude;

    for (final m in widget.markers) {
      if (m.latitude < minLat) minLat = m.latitude;
      if (m.latitude > maxLat) maxLat = m.latitude;
      if (m.longitude < minLng) minLng = m.longitude;
      if (m.longitude > maxLng) maxLng = m.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  void _selectSearchResult(UniversalSearchResult item) async {
    final target = LatLng(item.coordinates.latitude, item.coordinates.longitude);

    final searchPin = await GoogleMapMarkerRenderer.getSearchPin();

    setState(() {
      _searchResults = [];
      _searchCtrl.text = item.title;

      if (item.type == SearchResultType.onlinePlace || item.type == SearchResultType.coordinates) {
        _dynamicSearchedMarker = Marker(
          markerId: const MarkerId('dynamic_search_result'),
          position: target,
          icon: searchPin,
          zIndexInt: 50,
          infoWindow: InfoWindow(
            title: item.title,
            snippet: item.subtitle,
          ),
        );
      } else if (item.originalData is MapMarkerItem) {
        _activeSelectedMarker = item.originalData as MapMarkerItem;
      }
    });

    FocusScope.of(context).unfocus();
    _animateToLocation(target, zoom: 17.0);
    _buildCustomMarkers();
  }

  Set<Circle> _buildGeofenceCircles() {
    if (!widget.showGeofenceCircles) return {};

    final circles = <Circle>{};
    for (final item in widget.markers) {
      if (item.type == MarkerType.shop && item.geofenceRadius != null) {
        final isSelected = _activeSelectedMarker?.id == item.id;
        circles.add(
          Circle(
            circleId: CircleId('geo_${item.id}'),
            center: LatLng(item.latitude, item.longitude),
            radius: item.geofenceRadius!,
            fillColor: (isSelected ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                .withValues(alpha: isSelected ? 0.28 : 0.15),
            strokeColor: isSelected ? const Color(0xFF10B981) : const Color(0xFF6366F1),
            strokeWidth: isSelected ? 3 : 2,
          ),
        );
      }
    }
    return circles;
  }

  void _applyMapTheme(GoogleMapThemeMode theme) {
    setState(() {
      _currentTheme = theme;
    });

    if (theme == GoogleMapThemeMode.darkCyberpunk) {
      _mapController?.setMapStyle(_darkMapStyleJson);
    } else {
      _mapController?.setMapStyle(null);
    }
    _buildCustomMarkers();
  }

  MapType _getGoogleMapType() {
    switch (_currentTheme) {
      case GoogleMapThemeMode.satellite:
        return MapType.hybrid;
      case GoogleMapThemeMode.terrain:
        return MapType.terrain;
      default:
        return MapType.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeEmployees =
        widget.markers.where((m) => m.type == MarkerType.employee && m.liveStatus == TrackingLiveStatus.live).length;

    return Stack(
      children: [
        // 1. Core Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom: widget.initialZoom,
            tilt: _is3DTilt ? 45.0 : 0.0,
          ),
          mapType: _getGoogleMapType(),
          trafficEnabled: _trafficEnabled,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          buildingsEnabled: true,
          markers: _renderedMarkers,
          circles: _buildGeofenceCircles(),
          polylines: {...(widget.polylines ?? {}), ..._routePolylines},
          onMapCreated: (controller) {
            _mapController = controller;
            if (_currentTheme == GoogleMapThemeMode.darkCyberpunk) {
              controller.setMapStyle(_darkMapStyleJson);
            }
          },
          onTap: (_) {
            FocusScope.of(context).unfocus();
            setState(() {
              _searchResults = [];
              _activeSelectedMarker = null;
            });
            _buildCustomMarkers();
          },
        ),

        // 2. Top Universal Live Search Bar, Category Chips & Autocomplete
        if (widget.enableSearch)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevatedDark.withValues(alpha: 0.94)
                        : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(
                        Icons.search_rounded,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: AppTypography.bodyMedium(isDark: isDark),
                          decoration: InputDecoration(
                            hintText: 'Search Workout Gym, Shops, Kanpur...',
                            hintStyle: AppTypography.bodyMedium(
                              isDark: isDark,
                            ).copyWith(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchResults = [];
                              _dynamicSearchedMarker = null;
                            });
                            _buildCustomMarkers();
                          },
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),

                // Top Category Filter Chips (Google Maps Header Style)
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTopCategoryChip('🏋️ Gyms & Fitness', () {
                        _searchCtrl.text = 'Workout Gym Kanpur';
                      }, isDark),
                      const SizedBox(width: 8),
                      _buildTopCategoryChip('🍴 Restaurants', () {
                        _searchCtrl.text = 'Restaurants';
                      }, isDark),
                      const SizedBox(width: 8),
                      _buildTopCategoryChip('🏨 Hotels', () {
                        _searchCtrl.text = 'Hotels';
                      }, isDark),
                      const SizedBox(width: 8),
                      _buildTopCategoryChip('🏬 Shops', () {
                        _searchCtrl.text = 'Shop';
                      }, isDark),
                      const SizedBox(width: 8),
                      _buildTopCategoryChip('🅿️ Parking', () {
                        _searchCtrl.text = 'Parking';
                      }, isDark),
                    ],
                  ),
                ),

                // Search Results Dropdown List
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      itemBuilder: (context, idx) {
                        final item = _searchResults[idx];
                        IconData icon;
                        Color iconColor;
                        switch (item.type) {
                          case SearchResultType.employee:
                            icon = Icons.person_pin_circle_rounded;
                            iconColor = AppColors.liveGreen;
                            break;
                          case SearchResultType.shop:
                            icon = Icons.storefront_rounded;
                            iconColor = AppColors.primary;
                            break;
                          case SearchResultType.coordinates:
                            icon = Icons.gps_fixed_rounded;
                            iconColor = const Color(0xFFF59E0B);
                            break;
                          case SearchResultType.onlinePlace:
                          case SearchResultType.googleSuggestion:
                            icon = Icons.location_on_rounded;
                            iconColor = const Color(0xFFEF4444);
                            break;
                        }

                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: iconColor, size: 18),
                          ),
                          title: Text(
                            item.title,
                            style: AppTypography.bodyMedium(isDark: isDark)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          trailing: item.formattedDistance != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isInsideGeofence
                                        ? AppColors.liveGreen.withValues(alpha: 0.18)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: item.isInsideGeofence ? AppColors.liveGreen : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    item.formattedDistance!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: item.isInsideGeofence
                                          ? AppColors.liveGreen
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

        // 3. Left-Side Floating Google Place Details Card (Matching Google Maps Screenshot)
        if (_activeSelectedMarker != null && _activeSelectedMarker!.type == MarkerType.shop)
          Positioned(
            left: 16,
            top: 80,
            bottom: 20,
            child: SingleChildScrollView(
              child: GooglePlaceDetailsPanel(
                shop: _activeSelectedMarker!.originalData is ShopModel
                    ? _activeSelectedMarker!.originalData as ShopModel
                    : ShopModel(
                        id: _activeSelectedMarker!.id,
                        organizationId: 'org_main',
                        name: _activeSelectedMarker!.title,
                        code: 'SHOP-PIN',
                        address: _activeSelectedMarker!.subtitle ?? 'Kanpur, Uttar Pradesh',
                        latitude: _activeSelectedMarker!.latitude,
                        longitude: _activeSelectedMarker!.longitude,
                        radius: _activeSelectedMarker!.geofenceRadius ?? 100.0,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                hindiTitle: _activeSelectedMarker!.title.toLowerCase().contains('gym')
                    ? 'वर्कआउट जिम & जिम मशीन सप्लायर्स'
                    : null,
                categoryName: _activeSelectedMarker!.title.toLowerCase().contains('gym')
                    ? 'Exercise equipment store'
                    : 'Registered Retail Shop',
                heroImageUrl: _activeSelectedMarker!.title.toLowerCase().contains('gym')
                    ? 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=800&auto=format&fit=crop'
                    : null,
                onDirectionsTap: () {
                  _calculateDirectionsTo(
                    LatLng(_activeSelectedMarker!.latitude, _activeSelectedMarker!.longitude),
                  );
                },
                onNearbyTap: () {
                  _searchCtrl.text = 'Nearby';
                },
                onSendToPhoneTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📲 Shop location sent to Employee Field App!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onClose: () {
                  setState(() {
                    _activeSelectedMarker = null;
                    _routePolylines = {};
                  });
                  _buildCustomMarkers();
                },
              ),
            ),
          ),

        // 4. Selected Employee Quick Card (Bottom)
        if (_activeSelectedMarker != null &&
            _activeSelectedMarker!.type == MarkerType.employee &&
            _activeSelectedMarker!.originalData is LiveLocationModel)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: EmployeeQuickCard(
              location: _activeSelectedMarker!.originalData as LiveLocationModel,
              isSelected: true,
              onViewRoute: () {
                widget.onRouteTap?.call();
              },
              onTap: () {},
            ),
          ),

        // 5. Right Side Floating Control Panel (Theme, Traffic, 3D, Recenter)
        Positioned(
          right: 16,
          top: widget.enableSearch ? 80 : 16,
          child: Column(
            children: [
              // Theme Mode Selector
              _buildControlButton(
                icon: _currentTheme == GoogleMapThemeMode.darkCyberpunk
                    ? Icons.dark_mode_rounded
                    : (_currentTheme == GoogleMapThemeMode.satellite
                        ? Icons.satellite_alt_rounded
                        : Icons.light_mode_rounded),
                tooltip: 'Map Theme',
                isDark: isDark,
                isActive: _currentTheme == GoogleMapThemeMode.darkCyberpunk,
                onTap: () {
                  if (_currentTheme == GoogleMapThemeMode.darkCyberpunk) {
                    _applyMapTheme(GoogleMapThemeMode.standard);
                  } else if (_currentTheme == GoogleMapThemeMode.standard) {
                    _applyMapTheme(GoogleMapThemeMode.satellite);
                  } else {
                    _applyMapTheme(GoogleMapThemeMode.darkCyberpunk);
                  }
                },
              ),
              const SizedBox(height: 8),

              // Traffic Layer Toggle
              _buildControlButton(
                icon: Icons.traffic_rounded,
                tooltip: 'Live Traffic',
                isDark: isDark,
                isActive: _trafficEnabled,
                activeColor: AppColors.liveGreen,
                onTap: () {
                  setState(() => _trafficEnabled = !_trafficEnabled);
                },
              ),
              const SizedBox(height: 8),

              // 3D Perspective Tilt Toggle
              _buildControlButton(
                icon: Icons.view_in_ar_rounded,
                tooltip: '3D Tilt Perspective',
                isDark: isDark,
                isActive: _is3DTilt,
                activeColor: AppColors.primary,
                onTap: () {
                  setState(() => _is3DTilt = !_is3DTilt);
                  if (_activeSelectedMarker != null) {
                    _animateToMarker(_activeSelectedMarker!);
                  }
                },
              ),
              const SizedBox(height: 8),

              // Fit All Fleet Bounds
              _buildControlButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: 'Center Fleet',
                isDark: isDark,
                onTap: _fitBoundsAll,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive
        ? (activeColor ?? AppColors.primary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: (isDark ? AppColors.surfaceElevatedDark : Colors.white).withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive
                ? (activeColor ?? AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildShopQuickCard({
    required MapMarkerItem marker,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  marker.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  marker.subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                if (marker.geofenceRadius != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Geofence: ${marker.geofenceRadius!.toInt()}m radius',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.liveGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              setState(() => _activeSelectedMarker = null);
              _buildCustomMarkers();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryChip(String label, VoidCallback onTap, bool isDark) {
    return Material(
      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
