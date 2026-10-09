import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'visit_repository.dart';

class LaravelVisitRepository implements VisitRepository {
  final ApiClient _api = ApiClient();
  final StreamController<List<VisitModel>> _controller =
      StreamController<List<VisitModel>>.broadcast();

  LaravelVisitRepository() {
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    try {
      final res = await _api.get('/visits');
      if (res.isSuccess && res.data is List) {
        final list = (res.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          return VisitModel(
            id: map['id'].toString(),
            organizationId: 'org_1',
            employeeId: map['user_id'].toString(),
            employeeName: map['employee_name'] as String? ?? 'Employee',
            shopId: map['shop_id'].toString(),
            shopName: map['shop_name'] as String? ?? 'Shop',
            checkInTime: DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now(),
            checkInLocation: VisitLocationProof(
              latitude: (map['check_in_lat'] as num?)?.toDouble() ?? 0.0,
              longitude: (map['check_in_lng'] as num?)?.toDouble() ?? 0.0,
              accuracy: 5.0,
              distanceFromShop: (map['distance_from_shop_meters'] as num?)?.toDouble() ?? 0.0,
            ),
            checkOutTime: map['check_out_time'] != null
                ? DateTime.tryParse(map['check_out_time'].toString())
                : null,
            checkOutLocation: map['check_out_lat'] != null
                ? VisitLocationProof(
                    latitude: (map['check_out_lat'] as num?)?.toDouble() ?? 0.0,
                    longitude: (map['check_out_lng'] as num?)?.toDouble() ?? 0.0,
                    accuracy: 5.0,
                    distanceFromShop: 0.0,
                  )
                : null,
            notes: map['notes'] as String?,
            orderValue: (map['order_amount'] as num?)?.toDouble() ?? 0.0,
            status: map['status'] == 'COMPLETED' ? VisitStatus.completed : VisitStatus.checkedIn,
          );
        }).toList();

        _controller.add(List.unmodifiable(list));
      }
    } catch (_) {}
  }

  @override
  Stream<List<VisitModel>> streamVisits(String organizationId) {
    _fetchVisits();
    return _controller.stream;
  }

  @override
  Future<List<VisitModel>> getEmployeeVisits(String employeeId,
      {String? dateKey}) async {
    try {
      final res = await _api.get('/visits', queryParams: dateKey != null ? {'date': dateKey} : null);
      if (res.isSuccess && res.data is List) {
        return (res.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          return VisitModel(
            id: map['id'].toString(),
            organizationId: 'org_1',
            employeeId: map['user_id'].toString(),
            employeeName: map['employee_name'] as String? ?? 'Employee',
            shopId: map['shop_id'].toString(),
            shopName: map['shop_name'] as String? ?? 'Shop',
            checkInTime: DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now(),
            checkInLocation: VisitLocationProof(
              latitude: (map['check_in_lat'] as num?)?.toDouble() ?? 0.0,
              longitude: (map['check_in_lng'] as num?)?.toDouble() ?? 0.0,
              accuracy: 5.0,
              distanceFromShop: (map['distance_from_shop_meters'] as num?)?.toDouble() ?? 0.0,
            ),
            checkOutTime: map['check_out_time'] != null
                ? DateTime.tryParse(map['check_out_time'].toString())
                : null,
            notes: map['notes'] as String?,
            orderValue: (map['order_amount'] as num?)?.toDouble() ?? 0.0,
            status: map['status'] == 'COMPLETED' ? VisitStatus.completed : VisitStatus.checkedIn,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> submitVisit(VisitModel visit) async {
    try {
      await _api.post('/visits/check-in', body: {
        'shop_id': visit.shopId,
        'latitude': visit.checkInLocation.latitude,
        'longitude': visit.checkInLocation.longitude,
        'purpose': 'ROUTINE_VISIT',
        'notes': visit.notes,
      });
      await _fetchVisits();
    } catch (_) {}
  }

  @override
  Future<void> checkOutVisit(String visitId,
      VisitLocationProof checkOutLocation, int durationMinutes) async {
    try {
      await _api.post('/visits/$visitId/check-out', body: {
        'latitude': checkOutLocation.latitude,
        'longitude': checkOutLocation.longitude,
        'outcome': 'ORDER_PLACED',
      });
      await _fetchVisits();
    } catch (_) {}
  }
}
