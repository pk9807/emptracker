import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

class MockAdminAiRepository implements AiRepository {
  @override
  Future<AiMessage> sendMessage(
    String message, {
    Map<String, dynamic>? clientContext,
    String? conversationId,
    bool localOnly = false,
  }) async {
    if (message.toLowerCase().contains('assign')) {
      return AiMessage(
        id: 'mock_write_1',
        sender: AiSender.assistant,
        text: 'Action requires confirmation: Assign shop #1 to Rahul',
        timestamp: DateTime.now(),
        source: 'local_qwen_embedded',
        toolsUsed: const ['assign_employee_shop'],
        requiresConfirmation: true,
        action: 'assign_employee_shop',
        confirmationToken: 'admin_tok_99',
      );
    }

    return AiMessage(
      id: 'mock_admin_1',
      sender: AiSender.assistant,
      text: 'Search query ke anusaar 6 employees mile.',
      timestamp: DateTime.now(),
      source: 'local_qwen_embedded',
      toolsUsed: const ['search_employees'],
      latencyMs: 0.8,
      privacyTier: 'sensitive',
    );
  }

  @override
  Future<Map<String, dynamic>> confirmAction(String confirmationToken) async {
    return {
      'success': true,
      'action': 'assign_employee_shop',
      'message': 'Successfully assigned shop to Rahul Sharma.',
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
  testWidgets('Admin AI Assistant Modal renders properly with prompt chips and responses', (tester) async {
    final mockRepo = MockAdminAiRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantModal(
            isAdmin: true,
            userName: 'FieldForce Master Admin',
            repository: mockRepo,
          ),
        ),
      ),
    );

    // Verify Title and Engine Subtitle
    expect(find.text('FieldForce Admin AI'), findsOneWidget);
    expect(find.textContaining('Local-First Engine'), findsOneWidget);

    // Verify Admin Quick Prompts
    expect(find.text('👥 Active employees list'), findsOneWidget);
    expect(find.text('📍 Live radar locations'), findsOneWidget);

    // Enter query and submit
    await tester.enterText(find.byType(TextField), 'Active employees list');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    // Verify AI response rendered
    expect(find.text('Search query ke anusaar 6 employees mile.'), findsOneWidget);
    expect(find.text('Local Engine'), findsAtLeastNWidgets(1));
  });

  testWidgets('Admin AI Assistant Modal handles 2-step write action confirmation flow', (tester) async {
    final mockRepo = MockAdminAiRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiAssistantModal(
            isAdmin: true,
            userName: 'FieldForce Master Admin',
            repository: mockRepo,
          ),
        ),
      ),
    );

    // Send write action command
    await tester.enterText(find.byType(TextField), 'assign shop 1 to Rahul');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    // Verify confirmation proposal card is rendered
    expect(find.text('2-Step Confirmation Required'), findsOneWidget);
    expect(find.textContaining('assign_employee_shop'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Tap Confirm
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify successful execution badge & updated message
    expect(find.textContaining('Successfully assigned shop to Rahul Sharma.'), findsOneWidget);
    expect(find.text('Action Confirmed & Executed in Database.'), findsOneWidget);
  });
}
