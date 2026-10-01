import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'employee_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository authRepo;
  final EmployeeRepository empRepo;
  final ShopRepository shopRepo;
  final VisitRepository visitRepo;
  final AttendanceRepository attRepo;
  final LocationRepository locRepo;

  const LoginScreen({
    super.key,
    required this.authRepo,
    required this.empRepo,
    required this.shopRepo,
    required this.visitRepo,
    required this.attRepo,
    required this.locRepo,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'rahul.sharma@acme.com');
  final _pwdCtrl = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.authRepo.signInWithEmailPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      );

      final employee = await widget.empRepo.getEmployeeById('emp_001') ??
          EmployeeModel(
            id: 'emp_001',
            userId: user.uid,
            organizationId: user.organizationId,
            name: user.name,
            employeeCode: 'EMP-DEL-01',
            phone: user.phone ?? '+91 98765 43210',
            email: user.email,
            designation: 'Field Sales Officer',
            department: 'FMCG General Trade',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmployeeHomeScreen(
              user: user,
              employee: employee,
              empRepo: widget.empRepo,
              shopRepo: widget.shopRepo,
              visitRepo: widget.visitRepo,
              attRepo: widget.attRepo,
              locRepo: widget.locRepo,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Logo & 3D Badge
                  const Center(
                    child: AppLogoBadge(size: 88),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FieldForce Pro',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium(isDark: isDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Employee Live Tracking & Visit Portal',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(isDark: isDark),
                  ),
                  const SizedBox(height: 36),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.offlineRoseSubtle,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.offlineRose.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.offlineRose, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall(isDark: false)
                                  .copyWith(color: AppColors.offlineRose),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  DepthCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Employee Email or Mobile',
                          hintText: 'name@company.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          controller: _pwdCtrl,
                          label: 'Password',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'SIGN IN TO DUTY',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security,
                          size: 14, color: AppColors.liveGreen),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Secured with Multi-Tenant RBAC & GPS Watermarking',
                          style: AppTypography.bodySmall(isDark: isDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
