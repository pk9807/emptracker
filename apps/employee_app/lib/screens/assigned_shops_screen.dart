import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'visit_execution_screen.dart';

class AssignedShopsScreen extends StatefulWidget {
  final EmployeeModel employee;
  final ShopRepository shopRepo;
  final VisitRepository visitRepo;

  const AssignedShopsScreen({
    super.key,
    required this.employee,
    required this.shopRepo,
    required this.visitRepo,
  });

  @override
  State<AssignedShopsScreen> createState() => _AssignedShopsScreenState();
}

class _AssignedShopsScreenState extends State<AssignedShopsScreen> {
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  final double _userLat = 28.6328;
  final double _userLon = 77.2197;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final shops = await widget.shopRepo.getAssignedShops(widget.employee.id);
    if (mounted) {
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Shops',
            style: AppTypography.headingLarge(isDark: isDark)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? const EmptyStateView(
                  icon: Icons.storefront,
                  title: 'No Assigned Shops',
                  description: 'You have no assigned shops scheduled for today.',
                )
              : ListView.separated(
                  padding: AppSpacing.paddingPage,
                  itemCount: _shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = _shops[index];
                    final distanceMeters = HaversineCalculator.distanceMeters(
                      lat1: _userLat,
                      lon1: _userLon,
                      lat2: shop.latitude,
                      lon2: shop.longitude,
                    );
                    final isInside = distanceMeters <= shop.radius;

                    return DepthCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VisitExecutionScreen(
                              employee: widget.employee,
                              shop: shop,
                              visitRepo: widget.visitRepo,
                              userLat: _userLat,
                              userLon: _userLon,
                              distanceMeters: distanceMeters,
                              isInsideGeofence: isInside,
                            ),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                                child: const Icon(
                                  Icons.store_mall_directory,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name,
                                      style: AppTypography.headingSmall(
                                          isDark: isDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      shop.address,
                                      style: AppTypography.bodySmall(
                                          isDark: isDark),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isInside
                                        ? Icons.check_circle
                                        : Icons.near_me_outlined,
                                    size: 14,
                                    color: isInside
                                        ? AppColors.liveGreen
                                        : AppColors.recentAmber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isInside
                                        ? 'In Geofence (${HaversineCalculator.formatDistance(distanceMeters)})'
                                        : '${HaversineCalculator.formatDistance(distanceMeters)} away',
                                    style: AppTypography.badge(
                                      color: isInside
                                          ? AppColors.liveGreenDark
                                          : AppColors.recentAmber,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Check In',
                                    style: AppTypography.badge(
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
