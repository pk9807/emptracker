import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'employee_repository.dart';

class LaravelEmployeeRepository implements EmployeeRepository {
  final ApiClient _api = ApiClient();
  final StreamController<List<EmployeeModel>> _controller =
      StreamController<List<EmployeeModel>>.broadcast();
  Timer? _pollingTimer;

  LaravelEmployeeRepository() {
    _startPolling();
  }

  void _startPolling() {
    _fetchEmployees();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _fetchEmployees();
    });
  }

  Future<void> _fetchEmployees() async {
    try {
      final res = await _api.get('/employees');
      if (res.isSuccess && res.data is List) {
        final list = (res.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          final isOnDuty = map['is_on_duty'] as bool? ?? false;
          return EmployeeModel(
            id: map['id'].toString(),
            userId: map['id'].toString(),
            organizationId: 'org_1',
            name: map['name'] as String? ?? '',
            employeeCode: map['employee_code'] as String? ?? '',
            phone: map['phone'] as String? ?? '',
            email: map['email'] as String? ?? '',
            photoUrl: map['avatar'] as String?,
            designation: map['designation'] as String? ?? 'Field Officer',
            department: map['department'] as String? ?? 'Sales',
            active: map['is_active'] as bool? ?? true,
            trackingStatus: isOnDuty ? DutyStatus.active : DutyStatus.inactive,
            lastLocation: map['live_location'] as Map<String, dynamic>?,
            lastLocationAt: map['live_location'] != null
                ? DateTime.tryParse(map['live_location']['last_ping_at'].toString())
                : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();

        _controller.add(List.unmodifiable(list));
      }
    } catch (_) {}
  }

  @override
  Stream<List<EmployeeModel>> streamEmployees(String organizationId) {
    _fetchEmployees();
    return _controller.stream;
  }

  @override
  Future<EmployeeModel?> getEmployeeById(String employeeId) async {
    final res = await _api.get('/employees/$employeeId');
    if (res.isSuccess && res.data is Map) {
      final map = res.data as Map<String, dynamic>;
      return EmployeeModel.fromMap(map);
    }
    return null;
  }

  @override
  Future<void> updateDutyStatus(String employeeId, DutyStatus status) async {
    await _fetchEmployees();
  }

  @override
  Future<void> updateLastLocation(
      String employeeId, Map<String, dynamic> locationData) async {
    await _fetchEmployees();
  }

  @override
  Future<EmployeeModel> registerEmployee({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? employeeCode,
    String? designation,
    String? department,
  }) async {
    final res = await _api.post('/employees', body: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'employee_code': employeeCode,
      'designation': designation,
      'department': department,
    });

    if (res.isSuccess && res.data != null) {
      final map = res.data as Map<String, dynamic>;
      await _fetchEmployees();
      return EmployeeModel(
        id: map['id'].toString(),
        userId: map['id'].toString(),
        organizationId: 'org_1',
        name: map['name'] as String,
        employeeCode: map['employee_code'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String,
        designation: map['designation'] as String? ?? '',
        department: map['department'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      throw AppException(res.message ?? 'Failed to register employee');
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
