import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('StatusBadge renders correctly for LIVE status',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusBadge.fromTrackingStatus(TrackingLiveStatus.live),
        ),
      ),
    );

    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('PrimaryButton renders and responds to tap',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'START DUTY',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('START DUTY'), findsOneWidget);
    await tester.tap(find.text('START DUTY'));
    expect(tapped, isTrue);
  });

  testWidgets('GlassCard and DepthCard render children smoothly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GlassCard(child: Text('Glass Card Content')),
              DepthCard(child: Text('Depth Card Content')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Glass Card Content'), findsOneWidget);
    expect(find.text('Depth Card Content'), findsOneWidget);
  });
}
