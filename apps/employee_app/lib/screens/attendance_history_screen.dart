import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final EmployeeModel employee;
  final AttendanceRepository attRepo;

  const AttendanceHistoryScreen({
    super.key,
    required this.employee,
    required this.attRepo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockRecords = [
      AttendanceModel(
        id: 'att_01',
        organizationId: employee.organizationId,
        employeeId: employee.id,
        dateKey: '2026-10-01',
        startTime: DateTime(2026, 10, 1, 9, 5),
        startLocation: const AttendanceLocation(
          latitude: 26.4850,
          longitude: 80.3150,
          address: 'Workout Gym Swaroop Nagar, Kanpur',
        ),
        endTime: DateTime(2026, 10, 1, 18, 10),
        endLocation: const AttendanceLocation(
          latitude: 26.4907,
          longitude: 80.3185,
          address: 'Tilak Nagar Hub, Kanpur',
        ),
        workingDurationMinutes: 545,
        totalVisitsCount: 6,
        totalDistanceKm: 18.4,
        status: 'COMPLETED',
      ),
      AttendanceModel(
        id: 'att_02',
        organizationId: employee.organizationId,
        employeeId: employee.id,
        dateKey: '2026-09-30',
        startTime: DateTime(2026, 9, 30, 9, 15),
        startLocation: const AttendanceLocation(
          latitude: 26.4850,
          longitude: 80.3150,
          address: 'Workout Gym Swaroop Nagar, Kanpur',
        ),
        endTime: DateTime(2026, 9, 30, 17, 45),
        endLocation: const AttendanceLocation(
          latitude: 26.4725,
          longitude: 80.3522,
          address: 'Z Square Mall Base, Kanpur',
        ),
        workingDurationMinutes: 510,
        totalVisitsCount: 8,
        totalDistanceKm: 22.1,
        status: 'COMPLETED',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Log',
            style: AppTypography.headingLarge(isDark: isDark)),
      ),
      body: ListView.separated(
        padding: AppSpacing.paddingPage,
        itemCount: mockRecords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final att = mockRecords[index];

          return DepthCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      att.dateKey,
                      style: AppTypography.headingSmall(isDark: isDark),
                    ),
                    StatusBadge.fromDutyStatus(DutyStatus.active),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clock In',
                              style: AppTypography.bodySmall(isDark: isDark)),
                          const SizedBox(height: 2),
                          Text(
                            DateTimeUtils.formatTime(att.startTime),
                            style: AppTypography.headingSmall(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clock Out',
                              style: AppTypography.bodySmall(isDark: isDark)),
                          const SizedBox(height: 2),
                          Text(
                            att.endTime != null
                                ? DateTimeUtils.formatTime(att.endTime!)
                                : '--',
                            style: AppTypography.headingSmall(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hours',
                              style: AppTypography.bodySmall(isDark: isDark)),
                          const SizedBox(height: 2),
                          Text(
                            '${(att.workingDurationMinutes / 60).toStringAsFixed(1)}h',
                            style: AppTypography.headingSmall(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visits: ${att.totalVisitsCount}',
                      style: AppTypography.bodySmall(isDark: isDark),
                    ),
                    Text(
                      'Distance: ${att.totalDistanceKm} km',
                      style: AppTypography.bodySmall(isDark: isDark),
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
