import 'dart:async';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';

class ShopManagementScreen extends StatefulWidget {
  final String organizationId;
  final ShopRepository shopRepo;

  const ShopManagementScreen({
    super.key,
    required this.organizationId,
    required this.shopRepo,
  });

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subscribeShops();
  }

  void _subscribeShops() {
    widget.shopRepo.streamShops(widget.organizationId).listen((shops) {
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ShopModel> get _filteredShops {
    if (_searchQuery.trim().isEmpty) return _shops;
    final q = _searchQuery.toLowerCase();
    return _shops.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q) ||
          (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
          (s.phone?.toLowerCase().contains(q) ?? false) ||
          s.code.toLowerCase().contains(q);
    }).toList();
  }

  // Opens interactive Map Picker with OpenStreetMap + Nominatim
  Future<Map<String, dynamic>?> _openMapLocationPicker({
    required osm.LatLng initialPosition,
    required double initialRadius,
    String? initialAddress,
    String? shopTitle,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OsmLocationPickerSheet(
        initialPosition: initialPosition,
        initialRadius: initialRadius,
        initialAddress: initialAddress,
        shopTitle: shopTitle ?? 'Pick Shop Location',
      ),
    );
  }

  // Opens interactive Map Picker with Google Maps
  Future<Map<String, dynamic>?> _openGoogleMapLocationPicker({
    required gmaps.LatLng initialPosition,
    required double initialRadius,
    String? initialAddress,
    String? shopTitle,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoogleMapsLocationPickerSheet(
        initialPosition: initialPosition,
        initialRadius: initialRadius,
        initialAddress: initialAddress,
        shopTitle: shopTitle ?? 'Pick Shop Location',
      ),
    );
  }

  void _showShopFormDialog({ShopModel? existingShop}) {
    final isEdit = existingShop != null;
    final nameCtrl = TextEditingController(text: existingShop?.name ?? '');
    final ownerCtrl = TextEditingController(text: existingShop?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: existingShop?.phone ?? '');
    final addressCtrl = TextEditingController(text: existingShop?.address ?? '');

    double lat = existingShop?.latitude != null && existingShop!.latitude != 0.0
        ? existingShop.latitude
        : 26.490745; // Default Kanpur Tilak Nagar
    double lng = existingShop?.longitude != null && existingShop!.longitude != 0.0
        ? existingShop.longitude
        : 80.318524;
    double radius = existingShop?.radius ?? 100.0;
    bool isSearchingAddress = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> searchAddressLocation() async {
              final query = addressCtrl.text.trim();
              if (query.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Please enter an address, Google Maps link, or city')),
                );
                return;
              }

              // Check if query is a Google Maps URL or coordinate
              final parsed = UniversalSearchService.parseGoogleMapsUrlOrCoords(query);
              if (parsed != null) {
                final pLat = parsed['lat'] as double;
                final pLng = parsed['lng'] as double;
                setSheetState(() {
                  lat = pLat;
                  lng = pLng;
                });

                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text('✅ Maps link parsed: ${pLat.toStringAsFixed(5)}, ${pLng.toStringAsFixed(5)}'),
                      backgroundColor: AppColors.liveGreenDark,
                    ),
                  );
                }
                return;
              }

              setSheetState(() => isSearchingAddress = true);
              try {
                final results = await NominatimGeocodingService.search(query, limit: 1);
                if (results.isNotEmpty) {
                  final first = results.first;
                  setSheetState(() {
                    lat = first.latitude;
                    lng = first.longitude;
                    if (first.displayName.isNotEmpty && addressCtrl.text.trim().length < 20) {
                      addressCtrl.text = first.displayName;
                    }
                  });

                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text('📍 Location found: ${first.latitude.toStringAsFixed(4)}, ${first.longitude.toStringAsFixed(4)}'),
                        backgroundColor: AppColors.liveGreenDark,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('No matching location found. Try adding city name.')),
                    );
                  }
                }
              } catch (_) {
              } finally {
                setSheetState(() => isSearchingAddress = false);
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isEdit ? AppColors.primary : AppColors.liveGreen)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEdit ? Icons.edit_location_alt : Icons.add_business_rounded,
                                color: isEdit ? AppColors.primary : AppColors.liveGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Shop / Office' : 'Add New Shop / Office',
                                  style: AppTypography.headingSmall(isDark: isDark),
                                ),
                                Text(
                                  isEdit
                                      ? 'Update store info & OpenStreetMap geofence'
                                      : 'Configure coordinates & live geofence',
                                  style: AppTypography.bodySmall(isDark: isDark),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Form content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        CustomTextField(
                          controller: nameCtrl,
                          label: 'Shop / Office Name',
                          hintText: 'e.g. FF Sports Hub / Workout Gym',
                          prefixIcon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: ownerCtrl,
                                label: 'Owner / Manager',
                                hintText: 'e.g. Ramesh Gupta',
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: phoneCtrl,
                                label: 'Contact Phone',
                                hintText: 'e.g. +91 98111 00011',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Address with Live Search & URL paste support
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Address or Location / City',
                                  style: AppTypography.headingSmall(isDark: isDark).copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                InkWell(
                                  onTap: isSearchingAddress ? null : searchAddressLocation,
                                  child: Row(
                                    children: [
                                      if (isSearchingAddress)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      else
                                        const Icon(Icons.travel_explore, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Search (Nominatim)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSearchingAddress ? Colors.grey : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            CustomTextField(
                              controller: addressCtrl,
                              hintText: 'e.g. 7/17A Parwati Bagla Rd Kanpur, or paste Maps URL',
                              prefixIcon: Icons.location_on_outlined,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.travel_explore, color: AppColors.primary),
                                tooltip: 'Find GPS / Parse Maps URL',
                                onPressed: isSearchingAddress ? null : searchAddressLocation,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Map Connection Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.map_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'OpenStreetMap Geofence Location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySubtle,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${radius.toInt()}m Radius',
                                      style: AppTypography.badge(
                                          color: AppColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceElevatedDark
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Latitude',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.grey),
                                          ),
                                          Text(
                                            lat.toStringAsFixed(6),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceElevatedDark
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Longitude',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.grey),
                                          ),
                                          Text(
                                            lng.toStringAsFixed(6),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Dual Map Connect Buttons (Google Maps & OpenStreetMap)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      icon: const Icon(Icons.pin_drop_rounded, size: 18),
                                      label: const Text(
                                        'Google Maps Pin',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      onPressed: () async {
                                        final result = await _openGoogleMapLocationPicker(
                                          initialPosition: gmaps.LatLng(lat, lng),
                                          initialRadius: radius,
                                          initialAddress: addressCtrl.text.isNotEmpty ? addressCtrl.text : nameCtrl.text,
                                          shopTitle: nameCtrl.text.isNotEmpty
                                              ? nameCtrl.text
                                              : 'Select Shop Location',
                                        );

                                        if (result != null) {
                                          setSheetState(() {
                                            lat = result['latitude'] as double;
                                            lng = result['longitude'] as double;
                                            radius = result['radius'] as double;
                                            final addr = result['address'] as String?;
                                            if (addr != null && addr.isNotEmpty) {
                                              addressCtrl.text = addr;
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        minimumSize: const Size(0, 44),
                                        side: BorderSide(
                                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      icon: const Icon(Icons.travel_explore_rounded, size: 18, color: AppColors.liveGreen),
                                      label: const Text(
                                        'OpenStreetMap',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      onPressed: () async {
                                        final result = await _openMapLocationPicker(
                                          initialPosition: osm.LatLng(lat, lng),
                                          initialRadius: radius,
                                          initialAddress: addressCtrl.text.isNotEmpty ? addressCtrl.text : nameCtrl.text,
                                          shopTitle: nameCtrl.text.isNotEmpty
                                              ? nameCtrl.text
                                              : 'Select Shop Location',
                                        );

                                        if (result != null) {
                                          setSheetState(() {
                                            lat = result['latitude'] as double;
                                            lng = result['longitude'] as double;
                                            radius = result['radius'] as double;
                                            final addr = result['address'] as String?;
                                            if (addr != null && addr.isNotEmpty) {
                                              addressCtrl.text = addr;
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // Radius quick slider
                              Row(
                                children: [
                                  const Text(
                                    'Geofence Radius:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: radius.clamp(20.0, 500.0),
                                      min: 20,
                                      max: 500,
                                      divisions: 24,
                                      label: '${radius.toInt()}m',
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        setSheetState(() {
                                          radius = val;
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
                  ),

                  // Bottom Save Action
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(isEdit ? Icons.check_circle_outline : Icons.add_circle_outline),
                            label: Text(
                              isEdit ? 'Save Changes' : 'Create Shop',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a shop name')),
                                );
                                return;
                              }

                              if (isEdit) {
                                final updated = existingShop.copyWith(
                                  name: nameCtrl.text.trim(),
                                  contactPerson: ownerCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  latitude: lat,
                                  longitude: lng,
                                  radius: radius,
                                  updatedAt: DateTime.now(),
                                );
                                await widget.shopRepo.updateShop(updated);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Shop "${updated.name}" updated successfully!'),
                                      backgroundColor: AppColors.liveGreenDark,
                                    ),
                                  );
                                  Navigator.of(sheetContext).pop();
                                }
                              } else {
                                final newShop = ShopModel(
                                  id: 'shp_${DateTime.now().millisecondsSinceEpoch}',
                                  organizationId: widget.organizationId,
                                  name: nameCtrl.text.trim(),
                                  code: 'SHP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                  address: addressCtrl.text.trim(),
                                  latitude: lat,
                                  longitude: lng,
                                  radius: radius,
                                  contactPerson: ownerCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                                await widget.shopRepo.addShop(newShop);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Shop "${newShop.name}" added successfully!'),
                                      backgroundColor: AppColors.liveGreenDark,
                                    ),
                                  );
                                  Navigator.of(sheetContext).pop();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteShop(ShopModel shop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.offlineRose),
            SizedBox(width: 8),
            Text('Delete Shop?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${shop.name}"?\nThis will remove location geofences and assignment records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.offlineRose,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.shopRepo.deleteShop(shop.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${shop.name}"'),
                    backgroundColor: AppColors.offlineRose,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showShopOnMap(ShopModel shop) {
    _openMapLocationPicker(
      initialPosition: osm.LatLng(shop.latitude, shop.longitude),
      initialRadius: shop.radius,
      initialAddress: shop.address,
      shopTitle: shop.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shops = _filteredShops;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Add Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showShopFormDialog(),
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search shops by name, code, city...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, size: 18, color: AppColors.primaryDark),
                          const SizedBox(width: 6),
                          Text(
                            '${_shops.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : shops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No shops matching "$_searchQuery"'
                                  : 'No Shops Registered',
                              style: AppTypography.headingSmall(isDark: isDark),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap "Add Shop" to create a new store and connect GPS geofence.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: shops.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final shop = shops[index];

                          return DepthCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Code
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.storefront_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shop.name,
                                            style: AppTypography.headingSmall(isDark: isDark),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  shop.code,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.liveGreenSubtle,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.liveGreenDark,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusFull),
                                      ),
                                      child: Text(
                                        'Geofence: ${shop.radius.round()}m',
                                        style: AppTypography.badge(
                                            color: AppColors.primaryDark),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Address
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        shop.address.isNotEmpty ? shop.address : 'No address provided',
                                        style: AppTypography.bodySmall(isDark: isDark),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Contact Info & GPS
                                Row(
                                  children: [
                                    if (shop.contactPerson != null && shop.contactPerson!.isNotEmpty) ...[
                                      const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        shop.contactPerson!,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    if (shop.phone != null && shop.phone!.isNotEmpty) ...[
                                      const Icon(Icons.phone_outlined, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        shop.phone!,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Lat Lng coordinates badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.gps_fixed, size: 13, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'GPS: ${shop.latitude.toStringAsFixed(5)}, ${shop.longitude.toStringAsFixed(5)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                // Action Buttons Row (View Map, Edit, Delete)
                                Row(
                                  children: [
                                    // View on Map
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.map_rounded, size: 16, color: AppColors.primary),
                                      label: const Text(
                                        'View on Map',
                                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _showShopOnMap(shop),
                                    ),
                                    const Spacer(),

                                    // Edit Shop
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.edit_rounded, size: 16),
                                      label: const Text(
                                        'Edit Shop',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _showShopFormDialog(existingShop: shop),
                                    ),
                                    const SizedBox(width: 8),

                                    // Delete Shop
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.offlineRose, size: 20),
                                      tooltip: 'Delete Shop',
                                      onPressed: () => _confirmDeleteShop(shop),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
