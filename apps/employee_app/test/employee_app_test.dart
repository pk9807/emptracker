import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:employee_app/main.dart';

void main() {
  testWidgets('Employee App renders login screen and branding',
      (WidgetTester tester) async {
    final authRepo = MockAuthRepository();
    final empRepo = MockEmployeeRepository();
    final shopRepo = MockShopRepository();
    final visitRepo = MockVisitRepository();
    final attRepo = MockAttendanceRepository();
    final locRepo = MockLocationRepository();

    await tester.pumpWidget(
      FieldForceEmployeeApp(
        authRepo: authRepo,
        empRepo: empRepo,
        shopRepo: shopRepo,
        visitRepo: visitRepo,
        attRepo: attRepo,
        locRepo: locRepo,
      ),
    );

    expect(find.text('FieldForce Pro'), findsOneWidget);
    expect(find.text('SIGN IN TO DUTY'), findsOneWidget);
  });
}
