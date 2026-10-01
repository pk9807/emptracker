import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeData();
  }

  void _subscribeData() {
    widget.locRepo.streamLiveLocations(widget.organizationId).listen((locs) {
      if (mounted) {
        setState(() {
          _locations = locs;
          _isLoading = false;
        });
      }
    });

    widget.shopRepo.streamShops(widget.organizationId).listen((shops) {
      if (mounted) {
        setState(() {
          _shops = shops;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Convert LiveLocations + Shops into MapMarkerItems
    final List<MapMarkerItem> markers = [
      ..._locations.map(
        (loc) => MapMarkerItem(
          id: loc.employeeId,
          title: loc.name,
          latitude: loc.latitude,
          longitude: loc.longitude,
          type: MarkerType.employee,
          liveStatus: loc.liveStatus,
          battery: loc.battery,
          originalData: loc,
        ),
      ),
      ..._shops.map(
        (shp) => MapMarkerItem(
          id: shp.id,
          title: shp.name,
          subtitle: shp.address,
          latitude: shp.latitude,
          longitude: shp.longitude,
          type: MarkerType.shop,
          originalData: shp,
        ),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen 3D Map View
          InteractiveMapView(
            markers: markers,
            selectedMarker: _selectedLocation != null
                ? markers.firstWhere(
                    (m) => m.id == _selectedLocation!.employeeId,
                    orElse: () => markers.first,
                  )
                : null,
            onMarkerTap: (marker) {
              if (marker.type == MarkerType.employee &&
                  marker.originalData is LiveLocationModel) {
                setState(() {
                  _selectedLocation =
                      marker.originalData as LiveLocationModel;
                });
              }
            },
          ),

          // Bottom Quick Card Slider for Active Field Force
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _locations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final loc = _locations[index];
                  final isSelected =
                      _selectedLocation?.employeeId == loc.employeeId;

                  return EmployeeQuickCard(
                    location: loc,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedLocation = loc;
                      });
                    },
                    onViewRoute: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Viewing route history for ${loc.name}'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
