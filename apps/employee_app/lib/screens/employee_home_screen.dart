import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:location_engine/location_engine.dart';
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';
import 'assigned_shops_screen.dart';
import 'attendance_history_screen.dart';
import 'employee_profile_screen.dart';
import 'tracking_diagnostics_screen.dart';

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
  bool _isLoadingVisits = true;

  @override
  void initState() {
    super.initState();
    _isDutyActive = widget.employee.isWorking;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final visits = await widget.visitRepo.getEmployeeVisits(widget.employee.id);
    if (mounted) {
      setState(() {
        _todayVisits = visits;
        _isLoadingVisits = false;
      });
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
          startLocation: const AttendanceLocation(
            latitude: 28.6328,
            longitude: 77.2197,
            address: 'Connaught Place Base',
          ),
          status: 'WORKING',
        );
        await widget.attRepo.startDuty(att);
        await widget.empRepo.updateDutyStatus(widget.employee.id, DutyStatus.active);

        setState(() {
          _isDutyActive = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Duty started. Background GPS tracking active.'),
            backgroundColor: AppColors.liveGreenDark,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start duty: $e'),
            backgroundColor: AppColors.offlineRose,
          ),
        );
      }
    } else {
      // END DUTY
      await _locationEngine.stopTracking(
        onFlushPendingHistory: (batch) {
          widget.locRepo.appendLocationHistoryBatch(batch);
        },
      );
      await widget.empRepo.updateDutyStatus(widget.employee.id, DutyStatus.inactive);

      setState(() {
        _isDutyActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duty ended successfully. Final route synced.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            value: _isDutyActive ? '±5.2 m' : '--',
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildDutyMetric(
                            icon: Icons.battery_charging_full,
                            label: 'Battery',
                            value: '88%',
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
              const SizedBox(height: 24),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: MetricCounterCard(
                      title: 'Visits Today',
                      value: '${_todayVisits.length}',
                      subtitle: 'Target: 8',
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
              const SizedBox(height: 24),

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
                      title: 'Visit Shop',
                      subtitle: 'Check-In & Proof',
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
