import 'dart:async';
import 'package:models/models.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceModel>> streamTodayAttendance(String organizationId, String dateKey);
  Future<AttendanceModel?> getTodayAttendance(String employeeId, String dateKey);
  Future<void> startDuty(AttendanceModel attendance);
  Future<void> endDuty(String attendanceId, DateTime endTime, AttendanceLocation endLocation, int durationMinutes, double totalDistanceKm);
}

class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceModel> _records = [];
  final StreamController<List<AttendanceModel>> _controller =
      StreamController<List<AttendanceModel>>.broadcast();

  @override
  Stream<List<AttendanceModel>> streamTodayAttendance(
      String organizationId, String dateKey) {
    Timer.run(() => _controller.add(List.unmodifiable(_records)));
    return _controller.stream;
  }

  @override
  Future<AttendanceModel?> getTodayAttendance(
      String employeeId, String dateKey) async {
    final match = _records.where(
        (a) => a.employeeId == employeeId && a.dateKey == dateKey);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> startDuty(AttendanceModel attendance) async {
    final index = _records.indexWhere((a) => a.id == attendance.id);
    if (index != -1) {
      _records[index] = attendance;
    } else {
      _records.insert(0, attendance);
    }
    _controller.add(List.unmodifiable(_records));
  }

  @override
  Future<void> endDuty(String attendanceId, DateTime endTime,
      AttendanceLocation endLocation, int durationMinutes, double totalDistanceKm) async {
    final index = _records.indexWhere((a) => a.id == attendanceId);
    if (index != -1) {
      final old = _records[index];
      _records[index] = AttendanceModel(
        id: old.id,
        organizationId: old.organizationId,
        employeeId: old.employeeId,
        dateKey: old.dateKey,
        startTime: old.startTime,
        startLocation: old.startLocation,
        endTime: endTime,
        endLocation: endLocation,
        workingDurationMinutes: durationMinutes,
        totalVisitsCount: old.totalVisitsCount,
        totalDistanceKm: totalDistanceKm,
        status: 'COMPLETED',
      );
      _controller.add(List.unmodifiable(_records));
    }
  }
}
