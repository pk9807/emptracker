import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getUserProfile(String uid);
}

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();

  MockAuthRepository({UserModel? initialUser}) {
    _currentUser = initialUser;
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (password.length < 6) {
      throw const AppException('Password must be at least 6 characters.');
    }

    final isEmployee = email.toLowerCase().contains('emp') ||
        email.toLowerCase().contains('rahul');

    final user = UserModel(
      uid: isEmployee ? 'usr_emp_001' : 'usr_admin_001',
      email: email,
      name: isEmployee ? 'Rahul Sharma' : 'Rajesh Verma (Admin)',
      role: isEmployee ? UserRole.employee : UserRole.admin,
      organizationId: 'org_acme_fmcg',
      employeeId: isEmployee ? 'emp_001' : null,
      phone: '+91 98765 43210',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    return _currentUser;
  }
}
