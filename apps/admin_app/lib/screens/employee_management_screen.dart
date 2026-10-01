import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class EmployeeManagementScreen extends StatefulWidget {
  final String organizationId;
  final EmployeeRepository empRepo;

  const EmployeeManagementScreen({
    super.key,
    required this.organizationId,
    required this.empRepo,
  });

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<EmployeeModel> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.empRepo.streamEmployees(widget.organizationId).listen((emps) {
      if (mounted) {
        setState(() {
          _employees = emps;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const EmptyStateView(
                  icon: Icons.people_outline,
                  title: 'No Employees Registered',
                  description: 'Add your first field force agent to begin tracking.',
                )
              : ListView.separated(
                  padding: AppSpacing.paddingPage,
                  itemCount: _employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final emp = _employees[index];

                    return DepthCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0] : 'E',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      emp.name,
                                      style: AppTypography.headingSmall(
                                          isDark: isDark),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${emp.employeeCode})',
                                      style: AppTypography.bodySmall(
                                          isDark: isDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emp.designation} • ${emp.department}',
                                  style:
                                      AppTypography.bodySmall(isDark: isDark),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 12,
                                        color: AppColors.textTertiaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      emp.phone,
                                      style: AppTypography.bodySmall(
                                          isDark: isDark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.fromDutyStatus(emp.trackingStatus),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
