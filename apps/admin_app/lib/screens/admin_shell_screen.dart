import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'attendance_analytics_screen.dart';
import 'employee_management_screen.dart';
import 'live_tracking_map_screen.dart';
import 'reports_export_screen.dart';
import 'route_history_screen.dart';
import 'shop_management_screen.dart';
import 'visit_management_screen.dart';

class AdminShellScreen extends StatefulWidget {
  final UserModel user;
  final AuthRepository authRepo;
  final EmployeeRepository empRepo;
  final ShopRepository shopRepo;
  final VisitRepository visitRepo;
  final AttendanceRepository attRepo;
  final LocationRepository locRepo;

  const AdminShellScreen({
    super.key,
    required this.user,
    required this.authRepo,
    required this.empRepo,
    required this.shopRepo,
    required this.visitRepo,
    required this.attRepo,
    required this.locRepo,
  });

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Live Tracking 3D Map',
    'Field Employees',
    'Shops & Geofences',
    'Visits & Proof Audit',
    'Attendance Analytics',
    'Route History',
    'Reports & Export',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 800;

    final pages = [
      LiveTrackingMapScreen(
        organizationId: widget.user.organizationId,
        locRepo: widget.locRepo,
        empRepo: widget.empRepo,
        shopRepo: widget.shopRepo,
      ),
      EmployeeManagementScreen(
        organizationId: widget.user.organizationId,
        empRepo: widget.empRepo,
      ),
      ShopManagementScreen(
        organizationId: widget.user.organizationId,
        shopRepo: widget.shopRepo,
      ),
      VisitManagementScreen(
        organizationId: widget.user.organizationId,
        visitRepo: widget.visitRepo,
      ),
      AttendanceAnalyticsScreen(
        organizationId: widget.user.organizationId,
        attRepo: widget.attRepo,
      ),
      RouteHistoryScreen(
        organizationId: widget.user.organizationId,
        empRepo: widget.empRepo,
        locRepo: widget.locRepo,
      ),
      ReportsExportScreen(
        organizationId: widget.user.organizationId,
        empRepo: widget.empRepo,
        visitRepo: widget.visitRepo,
        attRepo: widget.attRepo,
      ),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // Left Desktop Sidebar
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.radar,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FieldForce',
                                style: AppTypography.headingSmall(isDark: isDark)),
                            Text('Admin Command',
                                style: AppTypography.bodySmall(isDark: isDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      children: [
                        _buildNavTile(
                            0, Icons.map_outlined, 'Live Tracking Map'),
                        _buildNavTile(
                            1, Icons.people_alt_outlined, 'Employees'),
                        _buildNavTile(
                            2, Icons.storefront_outlined, 'Shops & Geofences'),
                        _buildNavTile(
                            3, Icons.verified_outlined, 'Visits & Proof'),
                        _buildNavTile(
                            4, Icons.bar_chart_outlined, 'Attendance'),
                        _buildNavTile(
                            5, Icons.route_outlined, 'Route History'),
                        _buildNavTile(
                            6, Icons.file_download_outlined, 'Reports Export'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0]
                                : 'A',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.name,
                                  style: AppTypography.headingSmall(
                                      isDark: isDark)),
                              Text('Org Admin',
                                  style: AppTypography.bodySmall(
                                      isDark: isDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right Main Content
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_titles[_selectedIndex],
                      style: AppTypography.headingLarge(isDark: isDark)),
                ),
                body: pages[_selectedIndex],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Bottom Navigation
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex],
            style: AppTypography.headingLarge(isDark: isDark)),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _selectedIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Employees',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shops',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        tileColor: isSelected
            ? AppColors.primary.withOpacity(0.12)
            : Colors.transparent,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        title: Text(
          label,
          style: AppTypography.headingSmall(isDark: isDark).copyWith(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
