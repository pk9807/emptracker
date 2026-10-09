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
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final double _userLat = 26.490745;
  final double _userLon = 80.318524;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  List<ShopModel> get _filteredShops {
    if (_searchQuery.trim().isEmpty) return _shops;
    final q = _searchQuery.toLowerCase();
    return _shops.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayShops = _filteredShops;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Shops',
            style: AppTypography.headingLarge(isDark: isDark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search shops, Kanpur, or locality...',
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
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayShops.isEmpty
              ? EmptyStateView(
                  icon: Icons.storefront,
                  title: _searchQuery.isNotEmpty ? 'No Matching Shops' : 'No Assigned Shops',
                  description: _searchQuery.isNotEmpty
                      ? 'No shops matching "$_searchQuery".'
                      : 'You have no assigned shops scheduled for today.',
                )
              : ListView.separated(
                  padding: AppSpacing.paddingPage,
                  itemCount: displayShops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = displayShops[index];
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
