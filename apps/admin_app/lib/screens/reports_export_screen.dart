import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';

class ReportsExportScreen extends StatefulWidget {
  final String organizationId;
  final EmployeeRepository empRepo;
  final VisitRepository visitRepo;
  final AttendanceRepository attRepo;

  const ReportsExportScreen({
    super.key,
    required this.organizationId,
    required this.empRepo,
    required this.visitRepo,
    required this.attRepo,
  });

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  String _selectedReportType = 'Daily Visit Audit Log';
  bool _isGenerating = false;

  final List<String> _reportTypes = [
    'Daily Visit Audit Log',
    'Monthly Attendance Timesheet',
    'Field Force Distance & GPS Log',
    'Order Value & Store Penetration',
  ];

  Future<void> _handleExport(String format) async {
    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📄 Exported "$_selectedReportType" ($format format) successfully.',
          ),
          backgroundColor: AppColors.liveGreenDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Configuration Card
            DepthCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURE REPORT',
                    style: AppTypography.badge(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: InputDecoration(
                      labelText: 'Report Type',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    items: _reportTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                style: AppTypography.bodyMedium(
                                    isDark: isDark)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReportType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'From Date',
                          hintText: '2026-10-01',
                          prefixIcon: Icons.calendar_today,
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'To Date',
                          hintText: '2026-10-01',
                          prefixIcon: Icons.calendar_today,
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'EXPORT CSV',
                          icon: Icons.table_chart,
                          isLoading: _isGenerating,
                          onPressed: () => _handleExport('CSV'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryButton(
                          text: 'EXPORT PDF',
                          icon: Icons.picture_as_pdf,
                          onPressed: () => _handleExport('PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Export History Table
            Text(
              'RECENT EXPORT AUDIT LOGS',
              style: AppTypography.badge(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 12),
            DepthCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildAuditTile(
                    title: 'Daily_Visits_20261001.csv',
                    size: '48.2 KB • 142 records',
                    time: '10 min ago',
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildAuditTile(
                    title: 'Monthly_Attendance_September.pdf',
                    size: '1.2 MB • Executive Summary',
                    time: 'Yesterday',
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

  Widget _buildAuditTile({
    required String title,
    required String size,
    required String time,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.file_present, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headingSmall(isDark: isDark)),
                const SizedBox(height: 2),
                Text(size, style: AppTypography.bodySmall(isDark: isDark)),
              ],
            ),
          ),
          Text(time, style: AppTypography.bodySmall(isDark: isDark)),
        ],
      ),
    );
  }
}
