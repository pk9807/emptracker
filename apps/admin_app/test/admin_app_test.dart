import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/main.dart';

void main() {
  testWidgets('Admin App renders command center login screen',
      (WidgetTester tester) async {
    final authRepo = MockAuthRepository();
    final empRepo = MockEmployeeRepository();
    final shopRepo = MockShopRepository();
    final visitRepo = MockVisitRepository();
    final attRepo = MockAttendanceRepository();
    final locRepo = MockLocationRepository();

    await tester.pumpWidget(
      FieldForceAdminApp(
        authRepo: authRepo,
        empRepo: empRepo,
        shopRepo: shopRepo,
        visitRepo: visitRepo,
        attRepo: attRepo,
        locRepo: locRepo,
      ),
    );

    expect(find.text('FieldForce Command Center'), findsOneWidget);
    expect(find.text('LAUNCH DASHBOARD'), findsOneWidget);
  });
}
