import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';

class AttendanceAnalyticsScreen extends StatelessWidget {
  final String organizationId;
  final AttendanceRepository attRepo;

  const AttendanceAnalyticsScreen({
    super.key,
    required this.organizationId,
    required this.attRepo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics Metric Cards Grid
            Row(
              children: [
                Expanded(
                  child: MetricCounterCard(
                    title: 'Total Field Force',
                    value: '24',
                    subtitle: 'Active Personnel',
                    icon: Icons.people_alt,
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCounterCard(
                    title: 'On Duty Now',
                    value: '18',
                    subtitle: '75% Attendance',
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.liveGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCounterCard(
                    title: 'Total Visits',
                    value: '142',
                    subtitle: 'Avg 7.8 / rep',
                    icon: Icons.storefront,
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCounterCard(
                    title: 'Avg Work Hours',
                    value: '8.4h',
                    subtitle: 'Target: 8.0h',
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Attendance Distribution Card
            Text(
              'TODAY ATTENDANCE SUMMARY',
              style: AppTypography.badge(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 12),
            DepthCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProgressRow(
                    label: 'Present & Working',
                    count: 18,
                    total: 24,
                    color: AppColors.liveGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressRow(
                    label: 'On Break / Paused',
                    count: 3,
                    total: 24,
                    color: AppColors.recentAmber,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressRow(
                    label: 'Absent / Off Duty',
                    count: 3,
                    total: 24,
                    color: AppColors.offlineRose,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int count,
    required int total,
    required Color color,
    required bool isDark,
  }) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.headingSmall(isDark: isDark)),
            Text(
              '$count / $total (${(ratio * 100).round()}%)',
              style: AppTypography.bodySmall(isDark: isDark)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
