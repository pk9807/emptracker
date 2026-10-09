import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import '../services/store_locator_engine.dart';

/// High-Performance Interactive Store Locator Widget (Synchronized List & Map View)
class StoreLocatorView extends StatefulWidget {
  final List<ShopModel> shops;
  final double userLatitude;
  final double userLongitude;
  final Function(ShopModel selectedShop)? onShopSelected;
  final Function(ShopModel shop)? onCheckInRequested;

  const StoreLocatorView({
    super.key,
    required this.shops,
    required this.userLatitude,
    required this.userLongitude,
    this.onShopSelected,
    this.onCheckInRequested,
  });

  @override
  State<StoreLocatorView> createState() => _StoreLocatorViewState();
}

class _StoreLocatorViewState extends State<StoreLocatorView> {
  final TextEditingController _searchCtrl = TextEditingController();
  StoreLocatorFilter _filter = const StoreLocatorFilter();
  ShopModel? _selectedShop;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateFilter(StoreLocatorFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locatedShops = StoreLocatorEngine.findNearestShops(
      allShops: widget.shops,
      userLat: widget.userLatitude,
      userLng: widget.userLongitude,
      filter: _filter,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store & Shop Locator'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchCtrl,
                  hintText: 'Search stores by name, address, or code...',
                  prefixIcon: Icons.search,
                  onChanged: (val) {
                    _updateFilter(_filter.copyWith(query: val));
                  },
                ),
                const SizedBox(height: 10),
                // Radius Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRadiusChip('All', null),
                      const SizedBox(width: 8),
                      _buildRadiusChip('< 500m', 500),
                      const SizedBox(width: 8),
                      _buildRadiusChip('< 1 km', 1000),
                      const SizedBox(width: 8),
                      _buildRadiusChip('< 5 km', 5000),
                      const SizedBox(width: 8),
                      _buildRadiusChip('< 10 km', 10000),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Inside Geofence Only'),
                        selected: _filter.onlyInsideGeofence,
                        onSelected: (val) {
                          _updateFilter(_filter.copyWith(onlyInsideGeofence: val));
                        },
                        selectedColor: AppColors.liveGreen.withOpacity(0.2),
                        checkmarkColor: AppColors.liveGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Results Count Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF070B14) : const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${locatedShops.length} Stores Found Nearby',
                  style: AppTypography.bodySmall(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Sorted by Nearest First',
                  style: AppTypography.bodySmall(isDark: isDark),
                ),
              ],
            ),
          ),

          // 3. List of Located Stores
          Expanded(
            child: locatedShops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No stores found matching criteria', style: AppTypography.bodyMedium(isDark: isDark)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: locatedShops.length,
                    itemBuilder: (context, idx) {
                      final item = locatedShops[idx];
                      final isSelected = _selectedShop?.id == item.shop.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DepthCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Store Icon with Geofence Halo
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: item.isInsideGeofence
                                          ? AppColors.liveGreen.withOpacity(0.15)
                                          : AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: item.isInsideGeofence
                                            ? AppColors.liveGreen
                                            : AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: item.isInsideGeofence
                                          ? AppColors.liveGreen
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title & Address
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.shop.name,
                                          style: AppTypography.headingSmall(isDark: isDark),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.shop.address,
                                          style: AppTypography.bodySmall(isDark: isDark),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Distance Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.isInsideGeofence
                                          ? AppColors.liveGreen.withOpacity(0.2)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: item.isInsideGeofence ? AppColors.liveGreen : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      item.formattedDistance,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: item.isInsideGeofence ? AppColors.liveGreen : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Quick Action Chips
                              Row(
                                children: [
                                  if (item.isInsideGeofence)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.liveGreen.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '🎯 INSIDE GEOFENCE',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.liveGreen),
                                      ),
                                    ),
                                  const Spacer(),
                                  // Check-in Button
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('Visit Check-In'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: item.isInsideGeofence ? AppColors.liveGreen : AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    onPressed: () {
                                      if (widget.onCheckInRequested != null) {
                                        widget.onCheckInRequested!(item.shop);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusChip(String label, double? radiusMeters) {
    final isSelected = _filter.maxRadiusMeters == radiusMeters;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter(_filter.copyWith(maxRadiusMeters: selected ? radiusMeters : null));
      },
    );
  }
}
