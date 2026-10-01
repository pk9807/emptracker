import 'dart:async';
import 'dart:convert';
import 'package:models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncItemType { dutyAttendance, visitRecord, locationBatch, photoUpload }

enum SyncStatus { pending, inProgress, completed, failed }

class SyncQueueItem {
  final String id;
  final SyncItemType type;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime createdAt;
  final SyncStatus status;
  final String? errorMessage;

  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    this.retryCount = 0,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'errorMessage': errorMessage,
      };

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
        id: map['id'] as String,
        type: SyncItemType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => SyncItemType.visitRecord,
        ),
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['createdAt'].toString()),
        status: SyncStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SyncStatus.pending,
        ),
        errorMessage: map['errorMessage'] as String?,
      );

  SyncQueueItem copyWith({
    int? retryCount,
    SyncStatus? status,
    String? errorMessage,
  }) =>
      SyncQueueItem(
        id: id,
        type: type,
        payload: payload,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class SyncManager {
  static const String _storageKey = 'sync_queue_items_v1';
  final List<SyncQueueItem> _queue = [];
  bool _isProcessing = false;
  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  Stream<int> get pendingCountStream => _pendingCountController.stream;
  int get pendingCount =>
      _queue.where((e) => e.status != SyncStatus.completed).length;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _queue.clear();
    for (final itemStr in raw) {
      try {
        final map = jsonDecode(itemStr) as Map<String, dynamic>;
        _queue.add(SyncQueueItem.fromMap(map));
      } catch (_) {}
    }
    _pendingCountController.add(pendingCount);
  }

  Future<void> enqueue({
    required String id,
    required SyncItemType type,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItem(
      id: id,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    _queue.add(item);
    await _persist();
    _pendingCountController.add(pendingCount);
  }

  Future<void> processQueue({
    required Future<bool> Function(SyncQueueItem item) handler,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pendingItems = _queue
          .where((e) =>
              e.status == SyncStatus.pending || e.status == SyncStatus.failed)
          .toList();

      for (final item in pendingItems) {
        final index = _queue.indexWhere((e) => e.id == item.id);
        if (index == -1) continue;

        _queue[index] = item.copyWith(status: SyncStatus.inProgress);
        await _persist();

        try {
          final success = await handler(item);
          if (success) {
            _queue[index] = _queue[index].copyWith(status: SyncStatus.completed);
          } else {
            _queue[index] = _queue[index].copyWith(
              status: SyncStatus.failed,
              retryCount: item.retryCount + 1,
            );
          }
        } catch (e) {
          _queue[index] = _queue[index].copyWith(
            status: SyncStatus.failed,
            retryCount: item.retryCount + 1,
            errorMessage: e.toString(),
          );
        }
        await _persist();
      }

      // Cleanup completed items
      _queue.removeWhere((e) => e.status == SyncStatus.completed);
      await _persist();
    } finally {
      _isProcessing = false;
      _pendingCountController.add(pendingCount);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _queue.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_storageKey, list);
  }
}
