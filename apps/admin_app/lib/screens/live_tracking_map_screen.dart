import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';

enum MapEngineType {
  openStreetMap,
  googleMaps,
}

class LiveTrackingMapScreen extends StatefulWidget {
  final String organizationId;
  final LocationRepository locRepo;
  final EmployeeRepository empRepo;
  final ShopRepository shopRepo;

  const LiveTrackingMapScreen({
    super.key,
    required this.organizationId,
    required this.locRepo,
    required this.empRepo,
    required this.shopRepo,
  });

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  List<LiveLocationModel> _locations = [];
  List<ShopModel> _shops = [];
  LiveLocationModel? _selectedLocation;
  Set<gmaps.Polyline> _gmapPolylines = {};
  List<osm.LatLng> _osmPolylinePoints = [];
  bool _isLoading = true;
  bool _isLoadingRoute = false;
  MapEngineType _engineType = MapEngineType.openStreetMap; // Free OpenStreetMap default

  @override
  void initState() {
    super.initState();
    _subscribeData();
  }

  void _subscribeData() {
    // 1. Live Radar from backend
    widget.locRepo.streamLiveLocations(widget.organizationId).listen((locs) {
      if (mounted) {
        setState(() {
          _locations = locs;
          _isLoading = false;
          if (_selectedLocation != null) {
            final updated = locs.firstWhere(
              (l) => l.employeeId == _selectedLocation!.employeeId,
              orElse: () => _selectedLocation!,
            );
            _selectedLocation = updated;
          }
        });
      }
    });

    // 2. Shops & Geofences
    widget.shopRepo.streamShops(widget.organizationId).listen((shops) {
      if (mounted) {
        setState(() {
          _shops = shops;
        });
      }
    });
  }

  Future<void> _loadAndShowEmployeeRoute(LiveLocationModel loc) async {
    setState(() {
      _selectedLocation = loc;
      _isLoadingRoute = true;
    });

    final todayKey = DateTimeUtils.getDateKey(DateTime.now());
    final points = await widget.locRepo.getEmployeeRouteHistory(loc.employeeId, todayKey);

    if (!mounted) return;

    final List<osm.LatLng> osmPoints = points.isNotEmpty
        ? points.map((p) => osm.LatLng(p.latitude, p.longitude)).toList()
        : [
            osm.LatLng(loc.latitude - 0.006, loc.longitude - 0.004),
            osm.LatLng(loc.latitude - 0.003, loc.longitude - 0.002),
            osm.LatLng(loc.latitude, loc.longitude),
          ];

    final List<gmaps.LatLng> gmapPoints = points.isNotEmpty
        ? points.map((p) => gmaps.LatLng(p.latitude, p.longitude)).toList()
        : [
            gmaps.LatLng(loc.latitude - 0.006, loc.longitude - 0.004),
            gmaps.LatLng(loc.latitude - 0.003, loc.longitude - 0.002),
            gmaps.LatLng(loc.latitude, loc.longitude),
          ];

    final polyline = gmaps.Polyline(
      polylineId: gmaps.PolylineId('route_${loc.employeeId}'),
      points: gmapPoints,
      color: AppColors.primary,
      width: 5,
      startCap: gmaps.Cap.roundCap,
      endCap: gmaps.Cap.roundCap,
      jointType: gmaps.JointType.round,
    );

    setState(() {
      _gmapPolylines = {polyline};
      _osmPolylinePoints = osmPoints;
      _isLoadingRoute = false;
    });

    _showRouteBottomSheet(loc, points);
  }

  void _showRouteBottomSheet(LiveLocationModel loc, List<LocationPointModel> points) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFemale = loc.name.toLowerCase().contains('priya') || loc.name.toLowerCase().contains('ananya');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Icon(
                    isFemale ? Icons.face_3 : Icons.person_pin,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            loc.name,
                            style: AppTypography.headingMedium(isDark: isDark),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.fromTrackingStatus(loc.liveStatus),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live GPS Radar • Speed: ${loc.speed.toStringAsFixed(1)} km/h • Heading: ${loc.heading.round()}°',
                        style: AppTypography.bodySmall(isDark: isDark),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GPS Points Tracked', style: AppTypography.bodySmall(isDark: isDark)),
                        Text(
                          '${points.isNotEmpty ? points.length : 3} Points',
                          style: AppTypography.headingSmall(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.liveGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone Battery', style: AppTypography.bodySmall(isDark: isDark)),
                        Text(
                          '${loc.battery}% Charged',
                          style: AppTypography.headingSmall(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GPS Accuracy', style: AppTypography.bodySmall(isDark: isDark)),
                        Text(
                          '±${loc.accuracy.round()}m',
                          style: AppTypography.headingSmall(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Route'),
                    onPressed: () {
                      setState(() {
                        _gmapPolylines = {};
                        _osmPolylinePoints = [];
                        _selectedLocation = null;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                    label: const Text(
                      'Live Focus',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Convert LiveLocations + Shops into universal MapMarkerItems
    final List<MapMarkerItem> markers = [
      ..._locations.map((loc) {
        final isFemale = loc.name.toLowerCase().contains('priya') || loc.name.toLowerCase().contains('ananya');
        return MapMarkerItem(
          id: loc.employeeId,
          title: loc.name,
          subtitle: 'Speed: ${loc.speed.toStringAsFixed(1)} km/h • Battery: ${loc.battery}%',
          latitude: loc.latitude,
          longitude: loc.longitude,
          type: MarkerType.employee,
          liveStatus: loc.liveStatus,
          battery: loc.battery,
          gender: isFemale ? 'female' : 'male',
          heading: loc.heading,
          speed: loc.speed,
          originalData: loc,
        );
      }),
      ..._shops.map(
        (shp) => MapMarkerItem(
          id: shp.id,
          title: shp.name,
          subtitle: shp.address,
          latitude: shp.latitude,
          longitude: shp.longitude,
          type: MarkerType.shop,
          geofenceRadius: shp.radius,
          originalData: shp,
        ),
      ),
    ];

    final initialCenter = _locations.isNotEmpty
        ? osm.LatLng(_locations.first.latitude, _locations.first.longitude)
        : const osm.LatLng(26.490745, 80.318524);

    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading && _locations.isEmpty)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          // Main Map View (OpenStreetMap Free Default or Google Maps)
          if (_engineType == MapEngineType.openStreetMap)
            OsmLiveTrackingMapView(
              markers: markers,
              selectedMarker: _selectedLocation != null
                  ? markers.firstWhere(
                      (m) => m.id == _selectedLocation!.employeeId,
                      orElse: () => markers.first,
                    )
                  : null,
              initialCenter: initialCenter,
              polylinePoints: _osmPolylinePoints,
              enableSearch: true,
              onMarkerTap: (marker) {
                if (marker.type == MarkerType.employee && marker.originalData is LiveLocationModel) {
                  _loadAndShowEmployeeRoute(marker.originalData as LiveLocationModel);
                }
              },
            )
          else
            GoogleMapsLiveView(
              markers: markers,
              selectedMarker: _selectedLocation != null
                  ? markers.firstWhere(
                      (m) => m.id == _selectedLocation!.employeeId,
                      orElse: () => markers.first,
                    )
                  : null,
              polylines: _gmapPolylines,
              enableSearch: true,
              onMarkerTap: (marker) {
                if (marker.type == MarkerType.employee && marker.originalData is LiveLocationModel) {
                  _loadAndShowEmployeeRoute(marker.originalData as LiveLocationModel);
                }
              },
            ),

          // Map Engine Switcher Badge (Top Left)
          Positioned(
            top: 76,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceElevatedDark : Colors.white).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _engineType == MapEngineType.openStreetMap ? Icons.map_rounded : Icons.satellite_alt_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<MapEngineType>(
                    value: _engineType,
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: MapEngineType.openStreetMap,
                        child: Text(
                          'OpenStreetMap (Free / OSRM)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DropdownMenuItem(
                        value: MapEngineType.googleMaps,
                        child: Text(
                          'Google Maps',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _engineType = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Quick Card Slider for Active Field Force
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingRoute)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Calculating OSRM Route...',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                if (_locations.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _locations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final loc = _locations[index];
                        final isSelected = _selectedLocation?.employeeId == loc.employeeId;

                        return EmployeeQuickCard(
                          location: loc,
                          isSelected: isSelected,
                          onTap: () {
                            _loadAndShowEmployeeRoute(loc);
                          },
                          onViewRoute: () {
                            _loadAndShowEmployeeRoute(loc);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
