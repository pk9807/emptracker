import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:map_engine/map_engine.dart';
import 'package:models/models.dart';

class RouteHistoryScreen extends StatefulWidget {
  final String organizationId;
  final EmployeeRepository empRepo;
  final LocationRepository locRepo;

  const RouteHistoryScreen({
    super.key,
    required this.organizationId,
    required this.empRepo,
    required this.locRepo,
  });

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  List<EmployeeModel> _employees = [];
  EmployeeModel? _selectedEmployee;
  List<LocationPointModel> _points = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    widget.empRepo.streamEmployees(widget.organizationId).listen((emps) {
      if (mounted) {
        setState(() {
          _employees = emps;
          if (_employees.isNotEmpty && _selectedEmployee == null) {
            _selectedEmployee = _employees.first;
            _generateMockRoute();
          }
          _isLoading = false;
        });
      }
    });
  }

  void _generateMockRoute() {
    final now = DateTime.now();
    final List<LocationPointModel> pts = [];
    double lat = 28.6328;
    double lon = 77.2197;

    for (int i = 0; i < 20; i++) {
      lat += (i % 2 == 0 ? 0.0012 : -0.0006);
      lon += (i % 3 == 0 ? 0.0015 : -0.0008);
      pts.add(
        LocationPointModel(
          id: 'pt_$i',
          employeeId: _selectedEmployee?.id ?? 'emp_001',
          organizationId: widget.organizationId,
          latitude: lat,
          longitude: lon,
          accuracy: 5.0,
          speed: 18.5 + (i * 1.5),
          heading: 45.0,
          battery: 90 - (i * 2),
          dateKey: DateTimeUtils.getDateKey(now),
          timestamp: now.subtract(Duration(minutes: (20 - i) * 10)),
          createdAt: now.subtract(Duration(minutes: (20 - i) * 10)),
        ),
      );
    }

    setState(() {
      _points = pts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Employee Selector Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Text(
                        'Select Employee:',
                        style: AppTypography.headingSmall(isDark: isDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<EmployeeModel>(
                              value: _selectedEmployee,
                              isExpanded: true,
                              items: _employees
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        '${e.name} (${e.employeeCode})',
                                        style: AppTypography.bodyMedium(
                                            isDark: isDark),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (emp) {
                                if (emp != null) {
                                  setState(() {
                                    _selectedEmployee = emp;
                                    _generateMockRoute();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Route Playback
                Expanded(
                  child: RoutePlaybackView(
                    points: _points,
                    employeeName: _selectedEmployee?.name ?? 'Employee',
                  ),
                ),
              ],
            ),
    );
  }
}
