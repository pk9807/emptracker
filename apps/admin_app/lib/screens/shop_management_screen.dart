import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    widget.shopRepo.streamShops(widget.organizationId).listen((shops) {
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    });
  }

  void _showAddShopDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Geofenced Store/Office'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: nameCtrl, label: 'Store Name'),
            const SizedBox(height: 10),
            CustomTextField(controller: addressCtrl, label: 'Address'),
            const SizedBox(height: 10),
            CustomTextField(
              controller: radiusCtrl,
              label: 'Geofence Radius (meters)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final newShop = ShopModel(
                  id: 'shp_${DateTime.now().millisecondsSinceEpoch}',
                  organizationId: widget.organizationId,
                  name: nameCtrl.text.trim(),
                  code: 'SHP-NEW-01',
                  address: addressCtrl.text.trim(),
                  latitude: 28.6139,
                  longitude: 77.2090,
                  radius: double.tryParse(radiusCtrl.text) ?? 100.0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                widget.shopRepo.addShop(newShop);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save Shop'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Add Shop', style: TextStyle(color: Colors.white)),
        onPressed: _showAddShopDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? const EmptyStateView(
                  icon: Icons.storefront,
                  title: 'No Shops Registered',
                  description: 'Add shop coordinates and geofences for employee visit tracking.',
                )
              : ListView.separated(
                  padding: AppSpacing.paddingPage,
                  itemCount: _shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = _shops[index];

                    return DepthCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                shop.name,
                                style: AppTypography.headingSmall(isDark: isDark),
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
                                  'Radius: ${shop.radius.round()}m',
                                  style: AppTypography.badge(
                                      color: AppColors.primaryDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop.address,
                            style: AppTypography.bodySmall(isDark: isDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'GPS: ${shop.latitude}, ${shop.longitude}',
                            style: AppTypography.codeOrCoordinates(isDark: isDark),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
