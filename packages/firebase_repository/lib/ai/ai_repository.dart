import 'package:core/network/api_client.dart';
import 'package:models/models.dart';

abstract class AiRepository {
  Future<AiMessage> sendMessage(
    String message, {
    Map<String, dynamic>? clientContext,
    String? conversationId,
    bool localOnly = false,
  });

  Future<Map<String, dynamic>> confirmAction(String confirmationToken);

  Future<bool> cancelAction(String confirmationToken);

  Future<List<Map<String, dynamic>>> getAvailableTools();

  Future<Map<String, dynamic>?> getAiHealth();
}

class LaravelAiRepository implements AiRepository {
  final ApiClient _client;

  LaravelAiRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<AiMessage> sendMessage(
    String message, {
    Map<String, dynamic>? clientContext,
    String? conversationId,
    bool localOnly = false,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
      if (clientContext != null) 'client_context': clientContext,
      'local_only': localOnly,
    };

    final response = await _client.post('/ai/chat', body: body);

    if (response.isSuccess && response.data is Map) {
      final dataMap = Map<String, dynamic>.from(response.data as Map);
      return AiMessage.fromApiResponse(dataMap);
    }

    if (response.statusCode == 503) {
      return AiMessage.error('AI assistant is temporarily disabled by the administrator.');
    }

    if (response.statusCode == 403) {
      return AiMessage.error('Access restricted: You do not have permission to execute that action.');
    }

    final err = response.message ?? 'Unable to connect to AI engine. Please verify your connection.';
    return AiMessage.error(err);
  }

  @override
  Future<Map<String, dynamic>> confirmAction(String confirmationToken) async {
    final response = await _client.post('/ai/actions/confirm', body: {
      'confirmation_token': confirmationToken,
    });

    if (response.isSuccess && response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }

    throw Exception(response.message ?? 'Failed to execute confirmed action.');
  }

  @override
  Future<bool> cancelAction(String confirmationToken) async {
    final response = await _client.post('/ai/actions/cancel', body: {
      'confirmation_token': confirmationToken,
    });

    return response.isSuccess;
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableTools() async {
    final response = await _client.get('/ai/tools');
    if (response.isSuccess && response.data is Map && response.data['tools'] is List) {
      return List<Map<String, dynamic>>.from(
        (response.data['tools'] as List).map((t) => Map<String, dynamic>.from(t as Map)),
      );
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>?> getAiHealth() async {
    final response = await _client.get('/ai/health');
    if (response.isSuccess && response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return null;
  }
}
