import 'package:test/test.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';

void main() {
  group('Models Serialization Tests', () {
    test('UserModel round-trip serialization', () {
      final user = UserModel(
        uid: 'u123',
        email: 'alex@acme.com',
        name: 'Alex Johnson',
        role: UserRole.admin,
        organizationId: 'org_acme',
        createdAt: DateTime(2026, 10, 1, 9, 0),
        updatedAt: DateTime(2026, 10, 1, 9, 0),
      );

      final map = user.toMap();
      final fromMap = UserModel.fromMap(map);

      expect(fromMap.uid, 'u123');
      expect(fromMap.email, 'alex@acme.com');
      expect(fromMap.isAdmin, isTrue);
      expect(fromMap.organizationId, 'org_acme');
    });

    test('LiveLocationModel live status computation', () {
      final now = DateTime.now();
      final liveLoc = LiveLocationModel(
        employeeId: 'emp_99',
        organizationId: 'org_acme',
        name: 'Rahul',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        battery: 90,
        updatedAt: now.subtract(const Duration(seconds: 25)),
      );

      expect(liveLoc.isLive, isTrue);
      expect(liveLoc.liveStatus, TrackingLiveStatus.live);

      final staleLoc = LiveLocationModel(
        employeeId: 'emp_99',
        organizationId: 'org_acme',
        name: 'Rahul',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        battery: 90,
        updatedAt: now.subtract(const Duration(minutes: 8)),
      );
      expect(staleLoc.liveStatus, TrackingLiveStatus.stale);
    });

    test('VisitModel round-trip serialization', () {
      final visit = VisitModel(
        id: 'v_101',
        organizationId: 'org_acme',
        employeeId: 'emp_99',
        employeeName: 'Rahul',
        shopId: 'shop_202',
        shopName: 'Super Mart',
        checkInTime: DateTime(2026, 10, 1, 10, 15),
        checkInLocation: const VisitLocationProof(
          latitude: 28.6328,
          longitude: 77.2197,
          accuracy: 6.0,
          distanceFromShop: 18.5,
        ),
        notes: 'Stock verified',
        orderValue: 5000.0,
      );

      final map = visit.toMap();
      final fromMap = VisitModel.fromMap(map);

      expect(fromMap.id, 'v_101');
      expect(fromMap.employeeName, 'Rahul');
      expect(fromMap.checkInLocation.distanceFromShop, 18.5);
      expect(fromMap.notes, 'Stock verified');
    });
  });
}
