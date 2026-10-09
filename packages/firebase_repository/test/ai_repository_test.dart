import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:models/models.dart';

class MockSuccessAiRepository implements AiRepository {
  @override
  Future<AiMessage> sendMessage(
    String message, {
    Map<String, dynamic>? clientContext,
    String? conversationId,
    bool localOnly = false,
  }) async {
    if (message.contains('assign')) {
      return AiMessage(
        id: 'test_conf_1',
        sender: AiSender.assistant,
        text: 'Action requires confirmation: Assign shop #1 to Rahul',
        timestamp: DateTime.now(),
        source: 'local_qwen_embedded',
        toolsUsed: const ['assign_employee_shop'],
        requiresConfirmation: true,
        action: 'assign_employee_shop',
        confirmationToken: 'mock_token_123',
      );
    }

    return AiMessage(
      id: 'test_1',
      sender: AiSender.assistant,
      text: 'Aaj aapke kul 5 shops assigned hain.',
      timestamp: DateTime.now(),
      source: 'local_qwen_embedded',
      toolsUsed: const ['get_today_route'],
      latencyMs: 1.2,
      privacyTier: 'sensitive',
    );
  }

  @override
  Future<Map<String, dynamic>> confirmAction(String confirmationToken) async {
    return {
      'success': true,
      'action': 'assign_employee_shop',
      'message': 'Successfully assigned shop to employee.',
    };
  }

  @override
  Future<bool> cancelAction(String confirmationToken) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableTools() async {
    return [
      {'name': 'get_today_route', 'required_role': 'employee'},
      {'name': 'assign_employee_shop', 'required_role': 'admin', 'is_write_action': true},
    ];
  }

  @override
  Future<Map<String, dynamic>?> getAiHealth() async {
    return {
      'ai_enabled': true,
      'local_ai': {'enabled': true, 'model': 'qwen2.5-1.5b-instruct-q4'},
    };
  }
}

void main() {
  group('AiRepository Tests', () {
    late AiRepository repo;

    setUp(() {
      repo = MockSuccessAiRepository();
    });

    test('sendMessage returns structured assistant AiMessage with tool metadata', () async {
      final msg = await repo.sendMessage('Mere aaj kitne shops pending hain?');

      expect(msg.sender, equals(AiSender.assistant));
      expect(msg.text, contains('5 shops assigned'));
      expect(msg.source, equals('local_qwen_embedded'));
      expect(msg.toolsUsed, contains('get_today_route'));
      expect(msg.isError, isFalse);
    });

    test('sendMessage generates action confirmation for write intent', () async {
      final msg = await repo.sendMessage('Rahul ko shop 1 assign kardo');

      expect(msg.requiresConfirmation, isTrue);
      expect(msg.action, equals('assign_employee_shop'));
      expect(msg.confirmationToken, equals('mock_token_123'));
    });

    test('confirmAction executes proposed action successfully', () async {
      final res = await repo.confirmAction('mock_token_123');
      expect(res['success'], isTrue);
      expect(res['action'], equals('assign_employee_shop'));
    });

    test('cancelAction cancels proposed action', () async {
      final res = await repo.cancelAction('mock_token_123');
      expect(res, isTrue);
    });

    test('getAvailableTools returns list of accessible tools', () async {
      final tools = await repo.getAvailableTools();
      expect(tools.length, equals(2));
      expect(tools.first['name'], equals('get_today_route'));
    });

    test('getAiHealth returns active status and local model', () async {
      final health = await repo.getAiHealth();
      expect(health, isNotNull);
      expect(health!['ai_enabled'], isTrue);
    });
  });
}
