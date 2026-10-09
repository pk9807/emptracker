import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'auth_repository.dart';

class LaravelAuthRepository implements AuthRepository {
  final ApiClient _api = ApiClient();
  UserModel? _currentUser;
  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();

  LaravelAuthRepository() {
    // Optionally restore token
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
    final response = await _api.post('/auth/login', body: {
      'email': email.trim(),
      'password': password.trim(),
    });

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      _api.setAuthToken(token);

      final roleStr = (userData['role'] as String?)?.toLowerCase() ?? 'employee';
      final role = (roleStr == 'admin' || roleStr == 'superadmin' || roleStr == 'manager') ? UserRole.admin : UserRole.employee;

      final activeVal = userData['is_active'];
      final isActive = activeVal == null || activeVal == true || activeVal == 1 || activeVal == '1';

      final user = UserModel(
        uid: userData['id']?.toString() ?? '1',
        email: userData['email']?.toString() ?? email,
        name: userData['name']?.toString() ?? 'User',
        phone: userData['phone']?.toString(),
        photoUrl: userData['avatar']?.toString(),
        role: role,
        organizationId: 'org_1',
        employeeId: userData['employee_code']?.toString(),
        active: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = user;
      _controller.add(user);
      return user;
    } else {
      throw AppException(response.message ?? 'Authentication failed');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    _api.setAuthToken(null);
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final res = await _api.get('/auth/me');
    if (res.isSuccess && res.data != null) {
      final userData = (res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
      final roleStr = (userData['role'] as String?)?.toLowerCase() ?? 'employee';
      final role = (roleStr == 'admin' || roleStr == 'superadmin' || roleStr == 'manager') ? UserRole.admin : UserRole.employee;

      final activeVal = userData['is_active'];
      final isActive = activeVal == null || activeVal == true || activeVal == 1 || activeVal == '1';

      return UserModel(
        uid: userData['id']?.toString() ?? uid,
        email: userData['email']?.toString() ?? '',
        name: userData['name']?.toString() ?? '',
        phone: userData['phone']?.toString(),
        photoUrl: userData['avatar']?.toString(),
        role: role,
        organizationId: 'org_1',
        employeeId: userData['employee_code']?.toString(),
        active: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return _currentUser;
  }
}
