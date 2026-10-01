import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final EmployeeModel employee;
  final UserModel user;

  const EmployeeProfileScreen({
    super.key,
    required this.employee,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Profile',
            style: AppTypography.headingLarge(isDark: isDark)),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Column(
          children: [
            // Profile Card
            DepthCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      employee.name.isNotEmpty ? employee.name[0] : 'E',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    employee.name,
                    style: AppTypography.headingLarge(isDark: isDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee.designation} • ${employee.department}',
                    style: AppTypography.bodyMedium(isDark: isDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      employee.employeeCode,
                      style: AppTypography.codeOrCoordinates(isDark: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Details
            DepthCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildDetailTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: employee.email,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildDetailTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: employee.phone,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildDetailTile(
                    icon: Icons.business_outlined,
                    label: 'Organization',
                    value: employee.organizationId,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildDetailTile(
                    icon: Icons.phone_android_outlined,
                    label: 'App Version',
                    value: '1.0.0+1 (Production Build)',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SecondaryButton(
              text: 'SIGN OUT OF DUTY',
              icon: Icons.logout,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall(isDark: isDark)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.headingSmall(isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
