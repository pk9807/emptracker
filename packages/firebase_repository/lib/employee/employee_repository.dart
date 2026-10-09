import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';

abstract class EmployeeRepository {
  Stream<List<EmployeeModel>> streamEmployees(String organizationId);
  Future<EmployeeModel?> getEmployeeById(String employeeId);
  Future<void> updateDutyStatus(String employeeId, DutyStatus status);
  Future<void> updateLastLocation(String employeeId, Map<String, dynamic> locationData);
  Future<EmployeeModel> registerEmployee({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? employeeCode,
    String? designation,
    String? department,
  });
}

class MockEmployeeRepository implements EmployeeRepository {
  final List<EmployeeModel> _employees = [
    EmployeeModel(
      id: '2',
      userId: '2',
      organizationId: 'org_acme_fmcg',
      name: 'Rahul Sharma',
      employeeCode: 'EMP-101',
      phone: '+91 98111 22334',
      email: 'rahul@fieldforce.com',
      designation: 'Senior Field Executive',
      department: 'FMCG Sales',
      trackingStatus: DutyStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
    EmployeeModel(
      id: '3',
      userId: '3',
      organizationId: 'org_acme_fmcg',
      name: 'Priya Patel',
      employeeCode: 'EMP-102',
      phone: '+91 98222 33445',
      email: 'priya@fieldforce.com',
      designation: 'Retail Territory Officer',
      department: 'Retail Distribution',
      trackingStatus: DutyStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
  ];

  final StreamController<List<EmployeeModel>> _controller =
      StreamController<List<EmployeeModel>>.broadcast();

  @override
  Stream<List<EmployeeModel>> streamEmployees(String organizationId) {
    Timer.run(() => _controller.add(List.unmodifiable(_employees)));
    return _controller.stream;
  }

  @override
  Future<EmployeeModel?> getEmployeeById(String employeeId) async {
    final match = _employees.where((e) => e.id == employeeId);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> updateDutyStatus(String employeeId, DutyStatus status) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      _employees[index] = _employees[index].copyWith();
      _controller.add(List.unmodifiable(_employees));
    }
  }

  @override
  Future<void> updateLastLocation(
      String employeeId, Map<String, dynamic> locationData) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      _employees[index] = _employees[index].copyWith(
        lastLocation: locationData,
        lastLocationAt: DateTime.now(),
      );
      _controller.add(List.unmodifiable(_employees));
    }
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
    final emp = EmployeeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      organizationId: 'org_acme_fmcg',
      name: name,
      employeeCode: employeeCode ?? 'EMP-${DateTime.now().millisecond}',
      phone: phone ?? '',
      email: email,
      designation: designation ?? 'Field Executive',
      department: department ?? 'Operations',
      trackingStatus: DutyStatus.inactive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _employees.insert(0, emp);
    _controller.add(List.unmodifiable(_employees));
    return emp;
  }
}
