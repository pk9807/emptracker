import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'attendance_repository.dart';

class LaravelAttendanceRepository implements AttendanceRepository {
  final ApiClient _api = ApiClient();
  final StreamController<List<AttendanceModel>> _controller =
      StreamController<List<AttendanceModel>>.broadcast();

  LaravelAttendanceRepository() {
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final res = await _api.get('/attendance/summary');
      if (res.isSuccess && res.data is Map) {
        final records = (res.data as Map<String, dynamic>)['records'] as List? ?? [];
        final list = records.map((item) {
          final map = item as Map<String, dynamic>;
          final startTime = DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now();
          final endTime = map['check_out_time'] != null
              ? DateTime.tryParse(map['check_out_time'].toString())
              : null;

          return AttendanceModel(
            id: map['id'].toString(),
            organizationId: 'org_1',
            employeeId: map['user_id'].toString(),
            dateKey: map['date'].toString(),
            startTime: startTime,
            startLocation: AttendanceLocation(
              latitude: (map['check_in_lat'] as num?)?.toDouble() ?? 0.0,
              longitude: (map['check_in_lng'] as num?)?.toDouble() ?? 0.0,
              address: map['check_in_address'] as String?,
            ),
            endTime: endTime,
            endLocation: map['check_out_lat'] != null
                ? AttendanceLocation(
                    latitude: (map['check_out_lat'] as num?)?.toDouble() ?? 0.0,
                    longitude: (map['check_out_lng'] as num?)?.toDouble() ?? 0.0,
                    address: map['check_out_address'] as String?,
                  )
                : null,
            totalDistanceKm: (map['total_distance_km'] as num?)?.toDouble() ?? 0.0,
            status: map['status'] as String? ?? 'PRESENT',
          );
        }).toList();

        _controller.add(List.unmodifiable(list));
      }
    } catch (_) {}
  }

  @override
  Stream<List<AttendanceModel>> streamTodayAttendance(
      String organizationId, String dateKey) {
    _fetchSummary();
    return _controller.stream;
  }

  @override
  Future<AttendanceModel?> getTodayAttendance(
      String employeeId, String dateKey) async {
    try {
      final res = await _api.get('/attendance/today');
      if (res.isSuccess && res.data is Map) {
        final att = (res.data as Map<String, dynamic>)['attendance'];
        if (att != null && att is Map) {
          final map = att as Map<String, dynamic>;
          final startTime = DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now();
          final endTime = map['check_out_time'] != null
              ? DateTime.tryParse(map['check_out_time'].toString())
              : null;

          return AttendanceModel(
            id: map['id'].toString(),
            organizationId: 'org_1',
            employeeId: map['user_id'].toString(),
            dateKey: map['date'].toString(),
            startTime: startTime,
            startLocation: AttendanceLocation(
              latitude: (map['check_in_lat'] as num?)?.toDouble() ?? 0.0,
              longitude: (map['check_in_lng'] as num?)?.toDouble() ?? 0.0,
              address: map['check_in_address'] as String?,
            ),
            endTime: endTime,
            status: map['status'] as String? ?? 'PRESENT',
            totalDistanceKm: (map['total_distance_km'] as num?)?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> startDuty(AttendanceModel attendance) async {
    try {
      await _api.post('/attendance/check-in', body: {
        'latitude': attendance.startLocation.latitude,
        'longitude': attendance.startLocation.longitude,
        'address': attendance.startLocation.address,
      });
      await _fetchSummary();
    } catch (_) {}
  }

  @override
  Future<void> endDuty(String attendanceId, DateTime endTime,
      AttendanceLocation endLocation, int durationMinutes, double totalDistanceKm) async {
    try {
      await _api.post('/attendance/check-out', body: {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
        'address': endLocation.address,
        'total_distance_km': totalDistanceKm,
      });
      await _fetchSummary();
    } catch (_) {}
  }
}
