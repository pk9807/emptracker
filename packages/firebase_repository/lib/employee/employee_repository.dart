import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';

abstract class EmployeeRepository {
  Stream<List<EmployeeModel>> streamEmployees(String organizationId);
  Future<EmployeeModel?> getEmployeeById(String employeeId);
  Future<void> updateDutyStatus(String employeeId, DutyStatus status);
  Future<void> updateLastLocation(String employeeId, Map<String, dynamic> locationData);
}

class MockEmployeeRepository implements EmployeeRepository {
  final List<EmployeeModel> _employees = [
    EmployeeModel(
      id: 'emp_001',
      userId: 'usr_emp_001',
      organizationId: 'org_acme_fmcg',
      name: 'Rahul Sharma',
      employeeCode: 'EMP-DEL-01',
      phone: '+91 98765 43210',
      email: 'rahul.sharma@acme.com',
      designation: 'Senior Sales Officer',
      department: 'FMCG Distribution',
      trackingStatus: DutyStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
    EmployeeModel(
      id: 'emp_002',
      userId: 'usr_emp_002',
      organizationId: 'org_acme_fmcg',
      name: 'Priya Patel',
      employeeCode: 'EMP-DEL-02',
      phone: '+91 98111 22233',
      email: 'priya.patel@acme.com',
      designation: 'Territory Executive',
      department: 'Modern Trade',
      trackingStatus: DutyStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
    EmployeeModel(
      id: 'emp_003',
      userId: 'usr_emp_003',
      organizationId: 'org_acme_fmcg',
      name: 'Amit Kumar',
      employeeCode: 'EMP-DEL-03',
      phone: '+91 98222 33344',
      email: 'amit.kumar@acme.com',
      designation: 'Field Officer',
      department: 'General Trade',
      trackingStatus: DutyStatus.inactive,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
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
      _employees[index] = EmployeeModel(
        id: _employees[index].id,
        userId: _employees[index].userId,
        organizationId: _employees[index].organizationId,
        name: _employees[index].name,
        employeeCode: _employees[index].employeeCode,
        phone: _employees[index].phone,
        email: _employees[index].email,
        designation: _employees[index].designation,
        department: _employees[index].department,
        trackingStatus: status,
        lastLocation: _employees[index].lastLocation,
        lastLocationAt: _employees[index].lastLocationAt,
        createdAt: _employees[index].createdAt,
        updatedAt: DateTime.now(),
      );
      _controller.add(List.unmodifiable(_employees));
    }
  }

  @override
  Future<void> updateLastLocation(
      String employeeId, Map<String, dynamic> locationData) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      _employees[index] = EmployeeModel(
        id: _employees[index].id,
        userId: _employees[index].userId,
        organizationId: _employees[index].organizationId,
        name: _employees[index].name,
        employeeCode: _employees[index].employeeCode,
        phone: _employees[index].phone,
        email: _employees[index].email,
        designation: _employees[index].designation,
        department: _employees[index].department,
        trackingStatus: _employees[index].trackingStatus,
        lastLocation: locationData,
        lastLocationAt: DateTime.now(),
        createdAt: _employees[index].createdAt,
        updatedAt: DateTime.now(),
      );
      _controller.add(List.unmodifiable(_employees));
    }
  }
}
