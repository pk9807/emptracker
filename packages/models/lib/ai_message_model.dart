import 'package:equatable/equatable.dart';

enum AiSender {
  user,
  assistant,
  system,
}

class AiMessage extends Equatable {
  final String id;
  final AiSender sender;
  final String text;
  final DateTime timestamp;
  final String? source;
  final List<String> toolsUsed;
  final Map<String, dynamic>? data;
  final double latencyMs;
  final String? privacyTier;
  final bool isError;
  final bool requiresConfirmation;
  final String? action;
  final String? confirmationToken;
  final Map<String, dynamic>? proposalData;
  final bool isConfirmed;
  final bool isCancelled;
  final List<Map<String, dynamic>> entities;
  final Map<String, dynamic>? mapAction;

  const AiMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.source,
    this.toolsUsed = const [],
    this.data,
    this.latencyMs = 0.0,
    this.privacyTier,
    this.isError = false,
    this.requiresConfirmation = false,
    this.action,
    this.confirmationToken,
    this.proposalData,
    this.isConfirmed = false,
    this.isCancelled = false,
    this.entities = const [],
    this.mapAction,
  });

  factory AiMessage.user(String text) {
    return AiMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      sender: AiSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  factory AiMessage.fromApiResponse(Map<String, dynamic> json) {
    final tools = <String>[];
    if (json['tools_used'] is List) {
      for (final t in json['tools_used']) {
        tools.add(t.toString());
      }
    }

    Map<String, dynamic>? dataMap;
    if (json['data'] is Map) {
      dataMap = Map<String, dynamic>.from(json['data']);
    }

    final meta = json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null;
    final privacy = meta != null && meta.containsKey('privacy_tier') ? meta['privacy_tier']?.toString() : null;

    final type = json['type']?.toString();
    final isErr = type == 'error';
    final reqConf = json['requires_confirmation'] == true || type == 'action_confirmation';
    final actionName = json['action']?.toString();

    String? token;
    Map<String, dynamic>? proposal;
    final entitiesList = <Map<String, dynamic>>[];
    Map<String, dynamic>? mapAct;

    if (dataMap != null) {
      token = dataMap['confirmation_token']?.toString();
      proposal = dataMap;

      if (dataMap['entities'] is List) {
        for (final e in dataMap['entities']) {
          if (e is Map) {
            entitiesList.add(Map<String, dynamic>.from(e));
          }
        }
      }

      if (dataMap['map_action'] is Map) {
        mapAct = Map<String, dynamic>.from(dataMap['map_action']);
      }
    }

    return AiMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      sender: AiSender.assistant,
      text: json['message']?.toString() ?? '',
      timestamp: DateTime.now(),
      source: json['source']?.toString(),
      toolsUsed: tools,
      data: dataMap,
      latencyMs: (json['latency_ms'] as num?)?.toDouble() ?? 0.0,
      privacyTier: privacy,
      isError: isErr,
      requiresConfirmation: reqConf,
      action: actionName,
      confirmationToken: token,
      proposalData: proposal,
      entities: entitiesList,
      mapAction: mapAct,
    );
  }

  factory AiMessage.error(String errorText) {
    return AiMessage(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}',
      sender: AiSender.assistant,
      text: errorText,
      timestamp: DateTime.now(),
      isError: true,
      source: 'system',
    );
  }

  AiMessage copyWith({
    String? id,
    AiSender? sender,
    String? text,
    DateTime? timestamp,
    String? source,
    List<String>? toolsUsed,
    Map<String, dynamic>? data,
    double? latencyMs,
    String? privacyTier,
    bool? isError,
    bool? requiresConfirmation,
    String? action,
    String? confirmationToken,
    Map<String, dynamic>? proposalData,
    bool? isConfirmed,
    bool? isCancelled,
    List<Map<String, dynamic>>? entities,
    Map<String, dynamic>? mapAction,
  }) {
    return AiMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      toolsUsed: toolsUsed ?? this.toolsUsed,
      data: data ?? this.data,
      latencyMs: latencyMs ?? this.latencyMs,
      privacyTier: privacyTier ?? this.privacyTier,
      isError: isError ?? this.isError,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      action: action ?? this.action,
      confirmationToken: confirmationToken ?? this.confirmationToken,
      proposalData: proposalData ?? this.proposalData,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isCancelled: isCancelled ?? this.isCancelled,
      entities: entities ?? this.entities,
      mapAction: mapAction ?? this.mapAction,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sender,
        text,
        timestamp,
        source,
        toolsUsed,
        latencyMs,
        isError,
        requiresConfirmation,
        action,
        confirmationToken,
        isConfirmed,
        isCancelled,
        entities,
        mapAction,
      ];
}
