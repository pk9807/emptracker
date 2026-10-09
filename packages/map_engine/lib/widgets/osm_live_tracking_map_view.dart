import 'dart:async';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:models/models.dart';
import '../models/map_marker_item.dart';
import '../services/osrm_routing_service.dart';
import '../services/universal_search_service.dart';
import 'employee_quick_card.dart';
import 'google_place_details_panel.dart';

enum OsmTileTheme {
  cartoPositron,
  cartoDarkMatter,
  osmStandard,
  openTopo,
}

class OsmLiveTrackingMapView extends StatefulWidget {
  final List<MapMarkerItem> markers;
  final MapMarkerItem? selectedMarker;
  final ValueChanged<MapMarkerItem>? onMarkerTap;
  final osm.LatLng initialCenter;
  final double initialZoom;
  final bool showGeofenceCircles;
  final bool enableSearch;
  final List<osm.LatLng>? polylinePoints;
  final VoidCallback? onRecenterTap;
  final VoidCallback? onRouteTap;

  const OsmLiveTrackingMapView({
    super.key,
    required this.markers,
    this.selectedMarker,
    this.onMarkerTap,
    this.initialCenter = const osm.LatLng(26.490745, 80.318524), // Default Kanpur
    this.initialZoom = 14.5,
    this.showGeofenceCircles = true,
    this.enableSearch = true,
    this.polylinePoints,
    this.onRecenterTap,
    this.onRouteTap,
  });

  @override
  State<OsmLiveTrackingMapView> createState() => _OsmLiveTrackingMapViewState();
}

class _OsmLiveTrackingMapViewState extends State<OsmLiveTrackingMapView>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late OsmTileTheme _currentTileTheme;
  final TextEditingController _searchCtrl = TextEditingController();
  List<UniversalSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  Marker? _dynamicSearchedMarker;

  MapMarkerItem? _activeSelectedMarker;
  ShopModel? _selectedShop;
  List<osm.LatLng> _activePolyline = [];
  bool _isLoadingRoute = false;

  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _activeSelectedMarker = widget.selectedMarker;
    _activePolyline = widget.polylinePoints ?? [];

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant OsmLiveTrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarker != oldWidget.selectedMarker) {
      setState(() {
        _activeSelectedMarker = widget.selectedMarker;
      });
      if (widget.selectedMarker != null) {
        _mapController.move(
          osm.LatLng(
            widget.selectedMarker!.latitude,
            widget.selectedMarker!.longitude,
          ),
          16.0,
        );
      }
    }
    if (widget.polylinePoints != oldWidget.polylinePoints) {
      setState(() {
        _activePolyline = widget.polylinePoints ?? [];
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _pulseAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    final q = val.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await UniversalSearchService.search(
        query: q,
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

  void _selectSearchResult(UniversalSearchResult item) {
    final target = item.coordinates;

    setState(() {
      _searchResults = [];
      _searchCtrl.text = item.title;

      if (item.type == SearchResultType.onlinePlace || item.type == SearchResultType.coordinates) {
        _dynamicSearchedMarker = Marker(
          point: target,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.staleOrange,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.staleOrange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.place_rounded, color: Colors.white, size: 24),
          ),
        );
      }
    });

    FocusScope.of(context).unfocus();
    _mapController.move(target, 16.5);

    if (item.originalData is MapMarkerItem) {
      final marker = item.originalData as MapMarkerItem;
      setState(() {
        _activeSelectedMarker = marker;
        if (marker.type == MarkerType.shop) {
          if (marker.originalData is ShopModel) {
            _selectedShop = marker.originalData as ShopModel;
          } else {
            _selectedShop = ShopModel(
              id: marker.id,
              organizationId: 'org_main',
              name: marker.title,
              code: 'SHP_${marker.id.hashCode.abs()}',
              address: marker.subtitle ?? 'Kanpur, Uttar Pradesh',
              latitude: marker.latitude,
              longitude: marker.longitude,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }
      });
      widget.onMarkerTap?.call(marker);
    } else {
      setState(() {
        _selectedShop = ShopModel(
          id: 'place_${item.title.hashCode}',
          organizationId: 'org_main',
          name: item.title,
          code: 'LOC_${item.title.hashCode.abs()}',
          address: item.subtitle ?? 'Kanpur, Uttar Pradesh',
          latitude: target.latitude,
          longitude: target.longitude,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  Future<void> _calculateOsrmRouteTo(MapMarkerItem destination) async {
    final employeeMarker = widget.markers.firstWhere(
      (m) => m.type == MarkerType.employee,
      orElse: () => destination,
    );

    if (employeeMarker == destination) return;

    setState(() => _isLoadingRoute = true);

    final origin = osm.LatLng(
      employeeMarker.latitude,
      employeeMarker.longitude,
    );
    final dest = osm.LatLng(
      destination.latitude,
      destination.longitude,
    );

    final result = await OsrmRoutingService.getRoute(origin: origin, destination: dest);

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
        if (result.isSuccess && result.points.isNotEmpty) {
          _activePolyline = result.points;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🛣️ OSRM Route: ${result.distanceKm.toStringAsFixed(1)} km (~${result.durationMinutes.toStringAsFixed(0)} mins)',
          ),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getTileUrl(OsmTileTheme theme, bool isDark) {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  Widget _buildPill(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceElevatedDark : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white12 : Colors.black12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _currentTileTheme = isDark ? OsmTileTheme.cartoDarkMatter : OsmTileTheme.cartoPositron;

    final tileUrl = _getTileUrl(_currentTileTheme, isDark);

    // Build OSM Markers
    final osmMarkers = widget.markers.map((item) {
      final isSelected = _activeSelectedMarker?.id == item.id;
      final isEmployee = item.type == MarkerType.employee;

      return Marker(
        point: osm.LatLng(item.latitude, item.longitude),
        width: isEmployee ? 90 : 80,
        height: isEmployee ? 90 : 80,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _activeSelectedMarker = item;
              if (item.type == MarkerType.shop) {
                if (item.originalData is ShopModel) {
                  _selectedShop = item.originalData as ShopModel;
                } else {
                  _selectedShop = ShopModel(
                    id: item.id,
                    organizationId: 'org_main',
                    name: item.title,
                    code: 'SHP_${item.id.hashCode.abs()}',
                    address: item.subtitle ?? 'Kanpur, Uttar Pradesh',
                    latitude: item.latitude,
                    longitude: item.longitude,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                }
              }
            });
            widget.onMarkerTap?.call(item);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceElevatedDark : Colors.white)
                          .withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // Marker Icon with Pulse for Live Employees
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isEmployee)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Container(
                          width: 44 * _pulseAnim.value,
                          height: 44 * _pulseAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.liveGreen.withValues(alpha: 0.25 / _pulseAnim.value),
                          ),
                        );
                      },
                    ),

                  // Center Pin Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEmployee ? AppColors.liveGreen : AppColors.primary,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: (isEmployee ? AppColors.liveGreen : AppColors.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isEmployee
                          ? ((item.subtitle != null && item.subtitle!.toLowerCase().contains('female'))
                              ? Icons.woman_rounded
                              : Icons.man_rounded)
                          : Icons.storefront_rounded,
                      color: Colors.white,
                      size: isEmployee ? 24 : 19,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (_dynamicSearchedMarker != null) {
      osmMarkers.add(_dynamicSearchedMarker!);
    }

    // Build Circle Geofences around shops
    final osmCircles = widget.showGeofenceCircles
        ? widget.markers.where((m) => m.type == MarkerType.shop).map((shop) {
            final radius = shop.geofenceRadius ?? 100.0;
            return CircleMarker(
              point: osm.LatLng(shop.latitude, shop.longitude),
              radius: radius,
              useRadiusInMeter: true,
              color: AppColors.primary.withValues(alpha: 0.15),
              borderColor: AppColors.primary,
              borderStrokeWidth: 1.5,
            );
          }).toList()
        : <CircleMarker>[];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 19,
            onTap: (_, __) {
              if (_activeSelectedMarker != null) {
                setState(() => _activeSelectedMarker = null);
              }
              if (_searchResults.isNotEmpty) {
                setState(() => _searchResults = []);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'com.fieldforce.emptracker',
              maxZoom: 19,
            ),
            if (osmCircles.isNotEmpty) CircleLayer(circles: osmCircles),
            if (_activePolyline.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _activePolyline,
                    strokeWidth: 4.5,
                    color: AppColors.primary,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            MarkerLayer(markers: osmMarkers),
          ],
        ),

        // Live Place / Nominatim Search Bar
        if (widget.enableSearch)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.surfaceElevatedDark : Colors.white)
                        .withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search shop, Kanpur, gym, or paste Maps link...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchResults = [];
                              _dynamicSearchedMarker = null;
                            });
                          },
                        ),
                      if (_isSearching)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

                // Search Results Dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = _searchResults[i];

                        IconData icon;
                        Color color;
                        switch (item.type) {
                          case SearchResultType.employee:
                            icon = Icons.person_pin_circle;
                            color = AppColors.liveGreen;
                            break;
                          case SearchResultType.shop:
                            icon = Icons.storefront;
                            color = AppColors.primary;
                            break;
                          case SearchResultType.coordinates:
                            icon = Icons.link;
                            color = AppColors.staleOrange;
                            break;
                          default:
                            icon = Icons.place;
                            color = AppColors.primary;
                        }

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: color.withValues(alpha: 0.18),
                            child: Icon(icon, color: color, size: 16),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          trailing: item.formattedDistance != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.isInsideGeofence
                                        ? AppColors.liveGreen.withValues(alpha: 0.18)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: item.isInsideGeofence ? AppColors.liveGreen : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    item.formattedDistance!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: item.isInsideGeofence
                                          ? AppColors.liveGreen
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 12),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

        // Map Control Floating Buttons (Right side)
        Positioned(
          top: 76,
          right: 14,
          child: Column(
            children: [
              // Zoom In
              FloatingActionButton.small(
                heroTag: 'osm_zoom_in',
                backgroundColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                child: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
              ),
              const SizedBox(height: 8),

              // Zoom Out
              FloatingActionButton.small(
                heroTag: 'osm_zoom_out',
                backgroundColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                child: const Icon(Icons.remove, color: AppColors.primary),
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
              ),
              const SizedBox(height: 8),

              // Recenter on Live Employee
              FloatingActionButton.small(
                heroTag: 'osm_recenter',
                backgroundColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                child: const Icon(Icons.my_location_rounded, color: AppColors.liveGreen),
                onPressed: () {
                  if (widget.markers.isNotEmpty) {
                    final firstEmp = widget.markers.firstWhere(
                      (m) => m.type == MarkerType.employee,
                      orElse: () => widget.markers.first,
                    );
                    _mapController.move(
                      osm.LatLng(firstEmp.latitude, firstEmp.longitude),
                      16.0,
                    );
                  }
                  widget.onRecenterTap?.call();
                },
              ),

              // OSRM Route calculate indicator
              if (_isLoadingRoute) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Category Filter Pills (Gyms & Fitness, Restaurants, Hotels, Shops, Parking)
        if (widget.enableSearch && _searchResults.isEmpty && _selectedShop == null)
          Positioned(
            top: 72,
            left: 14,
            right: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPill('🏋️ Gyms & Fitness', () {
                    _searchCtrl.text = 'gym';
                    _onSearchChanged('gym');
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildPill('🍴 Restaurants', () {
                    _searchCtrl.text = 'restaurant';
                    _onSearchChanged('restaurant');
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildPill('🏨 Hotels', () {
                    _searchCtrl.text = 'hotel';
                    _onSearchChanged('hotel');
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildPill('🏬 Shops', () {
                    _searchCtrl.text = 'shop';
                    _onSearchChanged('shop');
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildPill('🅿️ Parking', () {
                    _searchCtrl.text = 'parking';
                    _onSearchChanged('parking');
                  }, isDark),
                ],
              ),
            ),
          ),

        // Google Maps Place Details Card (Matching Screenshot)
        if (_selectedShop != null)
          Positioned(
            top: 14,
            left: 14,
            child: GooglePlaceDetailsPanel(
              shop: _selectedShop!,
              hindiTitle: _selectedShop!.name.contains('Workout')
                  ? 'वर्कआउट जिम & जिम मशीन सप्लायर्स'
                  : null,
              rating: 4.8,
              reviewsCount: 348,
              categoryName: _selectedShop!.name.toLowerCase().contains('gym')
                  ? 'Exercise equipment store'
                  : 'Commercial Store',
              onDirectionsTap: () {
                _calculateOsrmRouteTo(
                  MapMarkerItem(
                    id: _selectedShop!.id,
                    title: _selectedShop!.name,
                    latitude: _selectedShop!.latitude,
                    longitude: _selectedShop!.longitude,
                    type: MarkerType.shop,
                  ),
                );
              },
              onNearbyTap: () {
                _searchCtrl.text = 'near ${_selectedShop!.name}';
                _onSearchChanged(_searchCtrl.text);
              },
              onSendToPhoneTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📱 Dispatched ${_selectedShop!.name} to field team!'),
                    backgroundColor: AppColors.liveGreen,
                  ),
                );
              },
              onClose: () {
                setState(() {
                  _selectedShop = null;
                });
              },
            ),
          ),

        // Selected Employee Bottom Card
        if (_activeSelectedMarker != null &&
            _activeSelectedMarker!.type == MarkerType.employee &&
            _activeSelectedMarker!.originalData is LiveLocationModel)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: EmployeeQuickCard(
              location: _activeSelectedMarker!.originalData as LiveLocationModel,
              isSelected: true,
              onTap: () {},
              onViewRoute: () {
                widget.onRouteTap?.call();
              },
            ),
          ),
      ],
    );
  }
}
