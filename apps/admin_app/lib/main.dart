import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'screens/admin_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dynamic Laravel REST API Repositories
  final authRepo = LaravelAuthRepository();
  final empRepo = LaravelEmployeeRepository();
  final shopRepo = LaravelShopRepository();
  final visitRepo = LaravelVisitRepository();
  final attRepo = LaravelAttendanceRepository();
  final locRepo = LaravelLocationRepository();

  runApp(
    FieldForceAdminApp(
      authRepo: authRepo,
      empRepo: empRepo,
      shopRepo: shopRepo,
      visitRepo: visitRepo,
      attRepo: attRepo,
      locRepo: locRepo,
    ),
  );
}

class FieldForceAdminApp extends StatelessWidget {
  final AuthRepository authRepo;
  final EmployeeRepository empRepo;
  final ShopRepository shopRepo;
  final VisitRepository visitRepo;
  final AttendanceRepository attRepo;
  final LocationRepository locRepo;

  const FieldForceAdminApp({
    super.key,
    required this.authRepo,
    required this.empRepo,
    required this.shopRepo,
    required this.visitRepo,
    required this.attRepo,
    required this.locRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldForce Admin Command',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: AdminLoginScreen(
        authRepo: authRepo,
        empRepo: empRepo,
        shopRepo: shopRepo,
        visitRepo: visitRepo,
        attRepo: attRepo,
        locRepo: locRepo,
      ),
    );
  }
}
