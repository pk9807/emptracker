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

  void _showAddEmployeeDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Emp@123456');
    final phoneCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final desigCtrl = TextEditingController(text: 'Field Executive');
    final deptCtrl = TextEditingController(text: 'Sales & Marketing');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Register New Employee',
                      style: AppTypography.headingMedium(
                        isDark: Theme.of(ctx).brightness == Brightness.dark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Employee Code',
                          hintText: 'EMP-106',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: desigCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Designation',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: deptCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              emailCtrl.text.trim().isEmpty ||
                              passCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields'),
                              ),
                            );
                            return;
                          }

                          setSheetState(() => isSubmitting = true);
                          try {
                            await widget.empRepo.registerEmployee(
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              employeeCode: codeCtrl.text.trim().isNotEmpty
                                  ? codeCtrl.text.trim()
                                  : null,
                              designation: desigCtrl.text.trim(),
                              department: deptCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Employee registered successfully on Laravel backend!'),
                                  backgroundColor: AppColors.liveGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.offlineRose,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add, color: Colors.white),
                  label: Text(
                    isSubmitting ? 'Registering...' : 'Register Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Employee',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const EmptyStateView(
                  icon: Icons.people_outline,
                  title: 'No Employees Registered',
                  description:
                      'Add your first field force agent to begin tracking.',
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
