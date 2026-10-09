import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';

abstract class VisitRepository {
  Stream<List<VisitModel>> streamVisits(String organizationId);
  Future<List<VisitModel>> getEmployeeVisits(String employeeId, {String? dateKey});
  Future<void> submitVisit(VisitModel visit);
  Future<void> checkOutVisit(String visitId, VisitLocationProof checkOutLocation, int durationMinutes);
}

class MockVisitRepository implements VisitRepository {
  final List<VisitModel> _visits = [
    VisitModel(
      id: 'vst_001',
      organizationId: 'org_acme_fmcg',
      employeeId: 'emp_001',
      employeeName: 'Rahul Sharma',
      shopId: 'shp_001',
      shopName: 'Workout Gym & Fitness Center',
      checkInTime: DateTime.now().subtract(const Duration(hours: 3)),
      checkInLocation: const VisitLocationProof(
        latitude: 26.4850,
        longitude: 80.3150,
        accuracy: 4.5,
        distanceFromShop: 12.0,
      ),
      checkOutTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 25)),
      checkOutLocation: const VisitLocationProof(
        latitude: 26.4850,
        longitude: 80.3150,
        accuracy: 4.5,
        distanceFromShop: 12.0,
      ),
      durationMinutes: 35,
      notes: 'Delivered 10 crates of Energy Drink. Collected invoice signature.',
      orderValue: 12500.0,
      status: VisitStatus.completed,
    ),
  ];

  final StreamController<List<VisitModel>> _controller =
      StreamController<List<VisitModel>>.broadcast();

  @override
  Stream<List<VisitModel>> streamVisits(String organizationId) {
    Timer.run(() => _controller.add(List.unmodifiable(_visits)));
    return _controller.stream;
  }

  @override
  Future<List<VisitModel>> getEmployeeVisits(String employeeId,
      {String? dateKey}) async {
    return _visits.where((v) => v.employeeId == employeeId).toList();
  }

  @override
  Future<void> submitVisit(VisitModel visit) async {
    final index = _visits.indexWhere((v) => v.id == visit.id);
    if (index != -1) {
      _visits[index] = visit;
    } else {
      _visits.insert(0, visit);
    }
    _controller.add(List.unmodifiable(_visits));
  }

  @override
  Future<void> checkOutVisit(String visitId,
      VisitLocationProof checkOutLocation, int durationMinutes) async {
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _visits[index] = _visits[index].copyWith(
        checkOutTime: DateTime.now(),
        checkOutLocation: checkOutLocation,
        durationMinutes: durationMinutes,
        status: VisitStatus.completed,
      );
      _controller.add(List.unmodifiable(_visits));
    }
  }
}
