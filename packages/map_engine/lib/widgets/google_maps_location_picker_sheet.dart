import 'dart:async';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/nominatim_geocoding_service.dart';
import '../services/universal_search_service.dart';

class GoogleMapsLocationPickerSheet extends StatefulWidget {
  final LatLng initialPosition;
  final double initialRadius;
  final String? initialAddress;
  final String shopTitle;

  const GoogleMapsLocationPickerSheet({
    super.key,
    required this.initialPosition,
    required this.initialRadius,
    this.initialAddress,
    required this.shopTitle,
  });

  @override
  State<GoogleMapsLocationPickerSheet> createState() => _GoogleMapsLocationPickerSheetState();
}

class _GoogleMapsLocationPickerSheetState extends State<GoogleMapsLocationPickerSheet> {
  GoogleMapController? _mapController;
  late LatLng _currentLocation;
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
    _currentLocation = widget.initialPosition;
    _currentRadius = widget.initialRadius;
    _detectedAddress = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
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

  Future<void> _reverseGeocode(LatLng pos) async {
    final display = await NominatimGeocodingService.reverseGeocode(pos.latitude, pos.longitude);
    if (display != null && display.isNotEmpty && mounted) {
      setState(() {
        _detectedAddress = display;
      });
    }
  }

  void _onMapTapped(LatLng pos) {
    setState(() {
      _currentLocation = pos;
      _searchResults = [];
    });
    _reverseGeocode(pos);
  }

  void _selectSearchResult(UniversalSearchResult place) {
    final pos = LatLng(place.coordinates.latitude, place.coordinates.longitude);
    setState(() {
      _currentLocation = pos;
      _detectedAddress = place.subtitle.isNotEmpty ? '${place.title}, ${place.subtitle}' : place.title;
      _searchResults = [];
      _searchCtrl.text = place.title;
    });
    FocusScope.of(context).unfocus();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16.5));
  }

  void _moveToLocation(double lat, double lng, String name) {
    final pos = LatLng(lat, lng);
    setState(() {
      _currentLocation = pos;
      _detectedAddress = name;
      _searchResults = [];
      _searchCtrl.text = name;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16.0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Shop Location & Geofence (Google Maps)',
                        style: AppTypography.headingMedium(isDark: isDark),
                      ),
                      Text(
                        'Tap anywhere on the Google Map or search address',
                        style: AppTypography.bodySmall(isDark: isDark),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_rounded,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          style: AppTypography.bodyMedium(isDark: isDark),
                          decoration: InputDecoration(
                            hintText: 'Search city, landmark, or paste Google Maps link...',
                            hintStyle: AppTypography.bodySmall(isDark: isDark),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                    ],
                  ),
                ),

                // Quick City Preset Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(
                    children: _quickLocations.map((loc) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: const Icon(Icons.place_rounded, size: 14, color: AppColors.primary),
                          label: Text(loc['name'].toString().split(' ')[0]),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                          backgroundColor:
                              isDark ? AppColors.surfaceDark : AppColors.surfaceElevatedLight,
                          side: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          onPressed: () => _moveToLocation(
                            loc['lat'] as double,
                            loc['lng'] as double,
                            loc['name'] as String,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Google Map View
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 16.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTapped,
                  markers: {
                    Marker(
                      markerId: const MarkerId('picked_shop_pin'),
                      position: _currentLocation,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: widget.shopTitle.isNotEmpty ? widget.shopTitle : 'Shop Location',
                        snippet: '${_currentLocation.latitude.toStringAsFixed(5)}, ${_currentLocation.longitude.toStringAsFixed(5)}',
                      ),
                      onDragEnd: (newPos) {
                        setState(() => _currentLocation = newPos);
                        _reverseGeocode(newPos);
                      },
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('picked_shop_geofence'),
                      center: _currentLocation,
                      radius: _currentRadius,
                      fillColor: AppColors.primary.withValues(alpha: 0.22),
                      strokeColor: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  },
                ),

                // Search Results Overlay
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
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
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_rounded,
                                color: Color(0xFFEF4444), size: 20),
                            title: Text(
                              item.title,
                              style: AppTypography.bodyMedium(isDark: isDark)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(isDark: isDark),
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                  ),

                // Map Pin Center Assist Badge
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.surfaceElevatedDark : Colors.white).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Tap anywhere to move pin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Geofence Radius Slider & Confirm Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Radius control
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Geofence Radius:',
                      style: AppTypography.bodyMedium(isDark: isDark)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentRadius.toInt()} meters',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _currentRadius,
                  min: 20,
                  max: 500,
                  divisions: 48,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _currentRadius = val);
                  },
                ),

                // Selected Coordinates & Address Preview
                if (_detectedAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: AppColors.textTertiaryDark),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _detectedAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(isDark: isDark),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      'Apply Location (${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
          ),
        ],
      ),
    );
  }
}
