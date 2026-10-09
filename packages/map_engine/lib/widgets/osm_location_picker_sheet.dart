import 'dart:async';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import '../services/nominatim_geocoding_service.dart';
import '../services/universal_search_service.dart';

class OsmLocationPickerSheet extends StatefulWidget {
  final osm.LatLng initialPosition;
  final double initialRadius;
  final String? initialAddress;
  final String shopTitle;

  const OsmLocationPickerSheet({
    super.key,
    required this.initialPosition,
    required this.initialRadius,
    this.initialAddress,
    required this.shopTitle,
  });

  @override
  State<OsmLocationPickerSheet> createState() => _OsmLocationPickerSheetState();
}

class _OsmLocationPickerSheetState extends State<OsmLocationPickerSheet> {
  late final MapController _mapController;
  late osm.LatLng _currentLocation;
  late double _currentRadius;
  String _detectedAddress = '';

  final TextEditingController _searchCtrl = TextEditingController();
  List<UniversalSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  final List<Map<String, dynamic>> _quickLocations = [
    {'name': 'Workout Gym & Fitness Kanpur', 'lat': 26.4850, 'lng': 80.3150},
    {'name': 'Kanpur Z Square Mall', 'lat': 26.4725, 'lng': 80.3522},
    {'name': 'Kanpur Tilak Nagar (FF Sports)', 'lat': 26.490745, 'lng': 80.318524},
    {'name': 'Kanpur Kakadeo Trade Hub', 'lat': 26.4812, 'lng': 80.2928},
    {'name': 'Kanpur Company Bagh', 'lat': 26.490963, 'lng': 80.316120},
    {'name': 'Hazratganj Lucknow', 'lat': 26.8467, 'lng': 80.9462},
    {'name': 'Agra Tajganj', 'lat': 27.1752, 'lng': 78.0098},
    {'name': 'Connaught Place Delhi', 'lat': 28.6328, 'lng': 77.2197},
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialPosition;
    _currentRadius = widget.initialRadius;
    _detectedAddress = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await UniversalSearchService.search(query: q);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _reverseGeocode(osm.LatLng pos) async {
    final display = await NominatimGeocodingService.reverseGeocode(pos.latitude, pos.longitude);
    if (display != null && display.isNotEmpty && mounted) {
      setState(() {
        _detectedAddress = display;
      });
    }
  }

  void _onMapTapped(osm.LatLng pos) {
    setState(() {
      _currentLocation = pos;
      _searchResults = [];
    });
    _reverseGeocode(pos);
  }

  void _selectSearchResult(UniversalSearchResult place) {
    final pos = place.coordinates;
    setState(() {
      _currentLocation = pos;
      _detectedAddress = place.subtitle.isNotEmpty ? '${place.title}, ${place.subtitle}' : place.title;
      _searchResults = [];
      _searchCtrl.text = place.title;
    });
    FocusScope.of(context).unfocus();
    _mapController.move(pos, 16.5);
  }

  void _moveToLocation(double lat, double lng, String name) {
    final pos = osm.LatLng(lat, lng);
    setState(() {
      _currentLocation = pos;
      _detectedAddress = name;
      _searchResults = [];
      _searchCtrl.text = name;
    });
    _mapController.move(pos, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Map & Place Search Picker',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Search shop, city, landmark, or paste Google Maps URL',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search city/landmark/gym OR paste Google Maps link...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                  prefixIcon: const Icon(Icons.travel_explore_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          // Quick City Shortcuts
          if (_searchResults.isEmpty)
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _quickLocations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final item = _quickLocations[i];
                  return ActionChip(
                    label: Text(item['name'] as String, style: const TextStyle(fontSize: 11)),
                    avatar: const Icon(Icons.location_city, size: 14),
                    backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                    onPressed: () {
                      _moveToLocation(item['lat'] as double, item['lng'] as double, item['name'] as String);
                    },
                  );
                },
              ),
            ),

          // Map View
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 16.5,
                    minZoom: 3,
                    maxZoom: 19,
                    onTap: (_, pos) => _onMapTapped(pos),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrl,
                      userAgentPackageName: 'com.fieldforce.emptracker',
                      maxZoom: 19,
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentLocation,
                          radius: _currentRadius,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
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
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Search Results Dropdown List Overlay
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = _searchResults[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                            title: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                  ),

                // Live Coordinates Box at bottom of Map
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_currentRadius.toInt()}m Range',
                                style: AppTypography.badge(color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                        if (_detectedAddress.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _detectedAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls (Radius slider + Confirm)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Geofence Radius: ${_currentRadius.toInt()} meters',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '(Auto check-in range)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Slider(
                  value: _currentRadius.clamp(20.0, 500.0),
                  min: 20,
                  max: 500,
                  divisions: 24,
                  label: '${_currentRadius.toInt()}m',
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _currentRadius = val;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text(
                          'Confirm Location',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop({
                            'latitude': _currentLocation.latitude,
                            'longitude': _currentLocation.longitude,
                            'radius': _currentRadius,
                            'address': _detectedAddress,
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
