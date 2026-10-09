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
  final _emailCtrl = TextEditingController(text: 'rahul@fieldforce.com');
  final _pwdCtrl = TextEditingController(text: 'Emp@123456');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Uri.base.queryParameters['autologin'] == '1' ||
          Uri.base.queryParameters['autologin'] == 'true' ||
          Uri.base.queryParameters['auto_duty'] == '1') {
        _handleLogin();
      }
    });
  }

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

      final employee = await widget.empRepo.getEmployeeById(user.uid) ??
          await widget.empRepo.getEmployeeById('emp_001') ??
          EmployeeModel(
            id: user.uid.isNotEmpty ? user.uid : 'emp_001',
            userId: user.uid,
            organizationId: user.organizationId,
            name: user.name,
            employeeCode: 'EMP-101',
            phone: user.phone ?? '+91 98111 22334',
            email: user.email,
            designation: 'Senior Field Executive',
            department: 'Field Operations',
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
                          hintText: 'rahul@fieldforce.com',
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _showServerSettingsDialog,
                                icon: const Icon(Icons.settings_ethernet, size: 16),
                                label: const Text('Server Settings', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _loginOfflineMode,
                                icon: const Icon(Icons.offline_bolt, size: 16),
                                label: const Text('Offline Demo Mode', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
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

  void _loginOfflineMode() {
    final offlineUser = UserModel(
      uid: '2',
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : 'rahul@fieldforce.com',
      name: 'Rahul Sharma',
      role: UserRole.employee,
      organizationId: 'org_acme_fmcg',
      employeeId: 'EMP-101',
      phone: '+91 98111 22334',
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final offlineEmp = EmployeeModel(
      id: '2',
      userId: '2',
      organizationId: 'org_acme_fmcg',
      name: 'Rahul Sharma',
      employeeCode: 'EMP-101',
      phone: '+91 98111 22334',
      email: 'rahul@fieldforce.com',
      designation: 'Senior Field Executive',
      department: 'FMCG Sales',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EmployeeHomeScreen(
          user: offlineUser,
          employee: offlineEmp,
          empRepo: widget.empRepo,
          shopRepo: widget.shopRepo,
          visitRepo: widget.visitRepo,
          attRepo: widget.attRepo,
          locRepo: widget.locRepo,
        ),
      ),
    );
  }

  void _showServerSettingsDialog() {
    final currentUrl = ApiClient().baseUrl;
    final ctrl = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Backend Server API URL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify your Laravel REST API endpoint:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'http://192.168.0.108/...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Quick Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi (192.168.0.108)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://192.168.0.108/emptracker/backend/public/index.php/api',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://10.0.2.2/emptracker/backend/public/index.php/api',
                ),
                ActionChip(
                  label: const Text('Localhost (Web)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://localhost/emptracker/backend/public/index.php/api',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiClient().setBaseUrl(ctrl.text.trim());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server URL updated to: ${ctrl.text.trim()}')),
              );
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }
}
