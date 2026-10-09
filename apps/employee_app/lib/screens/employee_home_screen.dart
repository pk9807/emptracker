import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_engine/location_engine.dart';
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';
import 'assigned_shops_screen.dart';
import 'attendance_history_screen.dart';
import 'employee_profile_screen.dart';
import 'tracking_diagnostics_screen.dart';
import 'visit_execution_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final UserModel user;
  final EmployeeModel employee;
  final EmployeeRepository empRepo;
  final ShopRepository shopRepo;
  final VisitRepository visitRepo;
  final AttendanceRepository attRepo;
  final LocationRepository locRepo;

  const EmployeeHomeScreen({
    super.key,
    required this.user,
    required this.employee,
    required this.empRepo,
    required this.shopRepo,
    required this.visitRepo,
    required this.attRepo,
    required this.locRepo,
  });

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final LocationEngine _locationEngine = LocationEngine();
  bool _isDutyActive = false;
  LiveLocationModel? _currentLocation;
  List<VisitModel> _todayVisits = [];
  List<ShopModel> _assignedShops = [];
  bool _isLoadingVisits = true;
  LatLng _livePosition = const LatLng(26.4850, 80.3150); // Live GPS default: Kanpur Swaroop Nagar

  @override
  void initState() {
    super.initState();
    _isDutyActive = widget.employee.isWorking;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Fetch Today's Visits
    final visits = await widget.visitRepo.getEmployeeVisits(widget.employee.id);
    // 2. Fetch Assigned Shops
    final shops = await widget.shopRepo.getAssignedShops(widget.employee.id);

    // 3. Fetch Today's Attendance
    final att = await widget.attRepo.getTodayAttendance(
      widget.employee.id,
      DateTimeUtils.getDateKey(DateTime.now()),
    );

    if (mounted) {
      final qLat = double.tryParse(Uri.base.queryParameters['lat'] ?? '');
      final qLng = double.tryParse(Uri.base.queryParameters['lng'] ?? '');

      setState(() {
        _todayVisits = visits;
        _assignedShops = shops;
        _isDutyActive = att != null && att.endTime == null;
        _isLoadingVisits = false;
        if (qLat != null && qLng != null) {
          _livePosition = LatLng(qLat, qLng);
        } else if (_assignedShops.isNotEmpty) {
          _livePosition = LatLng(_assignedShops.first.latitude, _assignedShops.first.longitude);
        }
      });

      if (Uri.base.queryParameters['auto_duty'] == '1' && !_isDutyActive) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && !_isDutyActive) {
            _toggleDuty();
          }
        });
      }
    }
  }

  Future<void> _toggleDuty() async {
    final newStatus =
        _isDutyActive ? DutyStatus.inactive : DutyStatus.active;

    if (!_isDutyActive) {
      // START DUTY
      try {
        await _locationEngine.startTracking(
          employeeId: widget.employee.id,
          organizationId: widget.employee.organizationId,
          employeeName: widget.employee.name,
          onLiveUpdate: (loc) {
            widget.locRepo.updateLiveLocation(loc);
            if (mounted) {
              setState(() {
                _currentLocation = loc;
                _livePosition = LatLng(loc.latitude, loc.longitude);
              });
            }
          },
          onBatchHistory: (batch) {
            widget.locRepo.appendLocationHistoryBatch(batch);
          },
        );

        final now = DateTime.now();
        final att = AttendanceModel(
          id: 'att_${widget.employee.id}_${now.millisecondsSinceEpoch}',
          organizationId: widget.employee.organizationId,
          employeeId: widget.employee.id,
          dateKey: DateTimeUtils.getDateKey(now),
          startTime: now,
          startLocation: AttendanceLocation(
            latitude: _livePosition.latitude,
            longitude: _livePosition.longitude,
            address: 'Live GPS Location',
          ),
          status: 'WORKING',
        );
        await widget.attRepo.startDuty(att);
        await widget.empRepo.updateDutyStatus(widget.employee.id, newStatus);

        setState(() {
          _isDutyActive = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Duty Started! Live GPS Background Tracking Active.'),
              backgroundColor: AppColors.liveGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start duty: $e'),
              backgroundColor: AppColors.offlineRose,
            ),
          );
        }
      }
    } else {
      // END DUTY
      try {
        await _locationEngine.stopTracking(
          onFlushPendingHistory: (batch) {
            widget.locRepo.appendLocationHistoryBatch(batch);
          },
        );

        final now = DateTime.now();
        await widget.attRepo.endDuty(
          'att_${widget.employee.id}',
          now,
          AttendanceLocation(
            latitude: _livePosition.latitude,
            longitude: _livePosition.longitude,
            address: 'Live GPS Location',
          ),
          480,
          14.8,
        );

        await widget.empRepo.updateDutyStatus(widget.employee.id, newStatus);

        setState(() {
          _isDutyActive = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Duty Ended Successfully. Tracking Paused.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to end duty: $e'),
              backgroundColor: AppColors.offlineRose,
            ),
          );
        }
      }
    }
  }

  List<MapMarkerItem> _buildMapMarkers() {
    final List<MapMarkerItem> markers = [];

    // Current Employee Marker
    markers.add(
      MapMarkerItem(
        id: widget.employee.id,
        title: '${widget.employee.name} (You)',
        subtitle: _isDutyActive ? 'On Duty — Live' : 'Off Duty',
        latitude: _livePosition.latitude,
        longitude: _livePosition.longitude,
        type: MarkerType.employee,
        liveStatus: _isDutyActive
            ? TrackingLiveStatus.live
            : TrackingLiveStatus.offline,
        battery: _currentLocation?.battery ?? 88,
        speed: _currentLocation?.speed ?? 0.0,
        heading: _currentLocation?.heading ?? 0.0,
      ),
    );

    // Assigned Shops & Offices Markers
    for (final shop in _assignedShops) {
      markers.add(
        MapMarkerItem(
          id: shop.id,
          title: shop.name,
          subtitle: '${shop.address} • Geofence: ${shop.radius.toInt()}m',
          latitude: shop.latitude,
          longitude: shop.longitude,
          type: MarkerType.shop,
          geofenceRadius: shop.radius,
          originalData: shop,
        ),
      );
    }

    return markers;
  }

  void _onShopMarkerTapped(MapMarkerItem item) {
    if (item.type == MarkerType.shop && item.originalData is ShopModel) {
      final shop = item.originalData as ShopModel;
      final distance = HaversineCalculator.distanceMeters(
        lat1: _livePosition.latitude,
        lon1: _livePosition.longitude,
        lat2: shop.latitude,
        lon2: shop.longitude,
      );
      final isInside = distance <= shop.radius;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        shop.name,
                        style: AppTypography.headingMedium(isDark: isDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: AppTypography.bodySmall(isDark: isDark),
                      ),
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Distance Away',
                                style: AppTypography.bodySmall(isDark: isDark)),
                            Text('${distance.round()} meters',
                                style:
                                    AppTypography.headingSmall(isDark: isDark)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isInside ? AppColors.liveGreen : AppColors.recentAmber)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Geofence Status',
                                style: AppTypography.bodySmall(isDark: isDark)),
                            Text(isInside ? 'Inside (Verified)' : 'Outside Radius',
                                style: AppTypography.headingSmall(
                                  isDark: isDark,
                                ).copyWith(
                                  color: isInside
                                      ? AppColors.liveGreenDark
                                      : AppColors.recentAmber,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'START VISIT / CHECK-IN',
                  icon: Icons.camera_alt_outlined,
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VisitExecutionScreen(
                          shop: shop,
                          employee: widget.employee,
                          visitRepo: widget.visitRepo,
                          userLat: _livePosition.latitude,
                          userLon: _livePosition.longitude,
                          distanceMeters: distance,
                          isInsideGeofence: isInside,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapMarkers = _buildMapMarkers();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Day,', style: AppTypography.bodySmall(isDark: isDark)),
            Text(widget.employee.name,
                style: AppTypography.headingMedium(isDark: isDark)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
            tooltip: 'AI Assistant (AI सहायक)',
            onPressed: () {
              AiAssistantModal.show(
                context,
                isAdmin: false,
                userName: widget.employee.name,
                clientLocation: {
                  'latitude': _livePosition.latitude,
                  'longitude': _livePosition.longitude,
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            tooltip: 'User Guide (मार्गदर्शिका)',
            onPressed: () {
              UserGuideModal.show(context, isAdmin: false);
            },
          ),

          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Tracking Diagnostics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackingDiagnosticsScreen(
                    diagnosticsService: _locationEngine.diagnosticsService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeProfileScreen(
                    employee: widget.employee,
                    user: widget.user,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3D Duty Tracking Status Card
              DepthCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (_isDutyActive)
                              const PulseRadarDot(size: 10)
                            else
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isDutyActive
                                  ? 'TRACKING ACTIVE'
                                  : 'DUTY INACTIVE',
                              style: AppTypography.badge(
                                color: _isDutyActive
                                    ? AppColors.liveGreen
                                    : (isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight),
                              ),
                            ),
                          ],
                        ),
                        StatusBadge.fromDutyStatus(
                          _isDutyActive ? DutyStatus.active : DutyStatus.inactive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDutyMetric(
                            icon: Icons.access_time_rounded,
                            label: 'Status',
                            value: _isDutyActive ? 'Working' : 'Off Duty',
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildDutyMetric(
                            icon: Icons.gps_fixed,
                            label: 'GPS Accuracy',
                            value: _isDutyActive ? '±4.8 m' : 'Live Ready',
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildDutyMetric(
                            icon: Icons.battery_charging_full,
                            label: 'Battery',
                            value: '${_currentLocation?.battery ?? 88}%',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: _isDutyActive ? 'END DUTY' : 'START DUTY',
                      backgroundColor: _isDutyActive
                          ? AppColors.offlineRose
                          : AppColors.liveGreen,
                      icon: _isDutyActive
                          ? Icons.stop_circle_outlined
                          : Icons.play_arrow_rounded,
                      onPressed: _toggleDuty,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: MetricCounterCard(
                      title: 'Visits Today',
                      value: _isLoadingVisits ? '...' : '${_todayVisits.length}',
                      subtitle: _isLoadingVisits ? 'Loading...' : 'Assigned: ${_assignedShops.length}',
                      icon: Icons.storefront_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCounterCard(
                      title: 'Distance',
                      value: '14.8 km',
                      subtitle: 'GPS Tracked',
                      icon: Icons.directions_car_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Live Google Maps Area Preview with Shop Search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE GPS MAP & SHOP SEARCH',
                    style: AppTypography.badge(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  Text(
                    '${_assignedShops.length} Shops Geofenced',
                    style: AppTypography.bodySmall(isDark: isDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: SizedBox(
                  height: 300,
                  child: GoogleMapsLiveView(
                    markers: mapMarkers,
                    initialCenter: _livePosition,
                    initialZoom: 15.0,
                    showGeofenceCircles: true,
                    enableSearch: true,
                    onMarkerTap: _onShopMarkerTapped,
                    onRecenterTap: () {
                      setState(() {
                        if (_assignedShops.isNotEmpty) {
                          _livePosition = LatLng(_assignedShops.first.latitude, _assignedShops.first.longitude);
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Action Tiles
              Text(
                'QUICK ACTIONS',
                style: AppTypography.badge(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.store_mall_directory_rounded,
                      title: 'Assigned Shops',
                      subtitle: '${_assignedShops.length} Stores Available',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AssignedShopsScreen(
                              employee: widget.employee,
                              shopRepo: widget.shopRepo,
                              visitRepo: widget.visitRepo,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.history_edu_rounded,
                      title: 'Attendance',
                      subtitle: 'Daily Timesheet',
                      color: const Color(0xFF0EA5E9),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttendanceHistoryScreen(
                              employee: widget.employee,
                              attRepo: widget.attRepo,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AiAssistantModal.show(
            context,
            isAdmin: false,
            userName: widget.employee.name,
            clientLocation: {
              'latitude': _livePosition.latitude,
              'longitude': _livePosition.longitude,
            },
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }


  Widget _buildDutyMetric({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 14,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.bodySmall(isDark: isDark)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.headingSmall(isDark: isDark)),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DepthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.headingSmall(isDark: isDark)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.bodySmall(isDark: isDark)),
        ],
      ),
    );
  }
}
