import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

class MockEmployeeAiRepository implements AiRepository {
  @override
  Future<AiMessage> sendMessage(
    String message, {
    Map<String, dynamic>? clientContext,
    String? conversationId,
    bool localOnly = false,
  }) async {
    if (message.toLowerCase().contains('note')) {
      return AiMessage(
        id: 'mock_emp_write_1',
        sender: AiSender.assistant,
        text: 'Action requires confirmation: Add urgent note for shop #13',
        timestamp: DateTime.now(),
        source: 'local_qwen_embedded',
        toolsUsed: const ['add_shop_urgent_note'],
        requiresConfirmation: true,
        action: 'add_shop_urgent_note',
        confirmationToken: 'emp_tok_42',
      );
    }

    return AiMessage(
      id: 'mock_emp_1',
      sender: AiSender.assistant,
      text: 'Aaj aapke kul 5 shops assigned hain. 0 completed, 5 pending.',
      timestamp: DateTime.now(),
      source: 'local_qwen_embedded',
      toolsUsed: const ['get_today_route'],
      latencyMs: 0.5,
      privacyTier: 'sensitive',
    );
  }

  @override
  Future<Map<String, dynamic>> confirmAction(String confirmationToken) async {
    return {
      'success': true,
      'action': 'add_shop_urgent_note',
      'message': 'Urgent note successfully recorded.',
    };
  }

  @override
  Future<bool> cancelAction(String confirmationToken) async => true;

  @override
  Future<List<Map<String, dynamic>>> getAvailableTools() async => [];

  @override
  Future<Map<String, dynamic>?> getAiHealth() async => {'ai_enabled': true};
}

void main() {
  testWidgets('Employee AI Assistant Modal renders employee prompts and handles query', (tester) async {
    final mockRepo = MockEmployeeAiRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantModal(
            isAdmin: false,
            userName: 'Rahul Sharma',
            repository: mockRepo,
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('FieldForce Employee AI'), findsOneWidget);

    // Verify Employee Quick Prompts
    expect(find.text('📍 Mere aaj ke shops'), findsOneWidget);
    expect(find.text('🕒 Meri attendance status'), findsOneWidget);

    // Send question
    await tester.enterText(find.byType(TextField), 'Mere aaj ke shops');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    // Verify Assistant response
    expect(find.text('Aaj aapke kul 5 shops assigned hain. 0 completed, 5 pending.'), findsOneWidget);
  });

  testWidgets('Employee AI Assistant handles write action proposal and confirmation', (tester) async {
    final mockRepo = MockEmployeeAiRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantModal(
            isAdmin: false,
            userName: 'Rahul Sharma',
            repository: mockRepo,
          ),
        ),
      ),
    );

    // Send urgent note command
    await tester.enterText(find.byType(TextField), 'Add note for shop 13: Order cheque ready');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    // Verify proposal card
    expect(find.text('2-Step Confirmation Required'), findsOneWidget);
    expect(find.textContaining('add_shop_urgent_note'), findsOneWidget);

    // Tap confirm
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify confirmed message
    expect(find.textContaining('Urgent note successfully recorded.'), findsOneWidget);
    expect(find.text('Action Confirmed & Executed in Database.'), findsOneWidget);
  });
}
