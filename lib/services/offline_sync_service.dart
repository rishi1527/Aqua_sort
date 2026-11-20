import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/pending_sync_event.dart';
import 'storage_stub.dart' if (dart.library.io) 'storage_io.dart';

/// Handler typedef for executing a sync event against Firebase.
typedef SyncEventExecutor = Future<bool> Function(PendingSyncEvent event);

/// Service managing persistent offline queue and idempotent synchronization.
///
/// Features:
/// - Durable queue persisted across app restarts.
/// - Deterministic event IDs prevent duplicate rewards.
/// - Retries safely when network is restored.
/// - Keeps failed/error details accessible for diagnostics.
class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService instance = OfflineSyncService._internal();
  factory OfflineSyncService() => instance;
  OfflineSyncService._internal();

  StorageAdapter _storage = getStorageAdapter();
  final List<PendingSyncEvent> _queue = [];
  final List<PendingSyncEvent> _failedEvents = [];
  bool _isProcessing = false;
  SyncEventExecutor? _customExecutor;

  @visibleForTesting
  void setStorageForTesting(StorageAdapter storage) {
    _storage = storage;
  }

  @visibleForTesting
  void setExecutorForTesting(SyncEventExecutor? executor) {
    _customExecutor = executor;
  }

  @visibleForTesting
  void clearForTesting() {
    _queue.clear();
    _failedEvents.clear();
    notifyListeners();
  }

  List<PendingSyncEvent> get pendingEvents => List.unmodifiable(_queue);
  List<PendingSyncEvent> get failedEvents => List.unmodifiable(_failedEvents);
  int get pendingCount => _queue.length;
  bool get isProcessing => _isProcessing;

  /// Loads pending queue from local storage.
  Future<void> initialize() async {
    try {
      final raw = await _storage.load();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> && decoded['pendingEvents'] is List) {
          _queue.clear();
          for (final item in decoded['pendingEvents'] as List) {
            try {
              _queue.add(PendingSyncEvent.fromJson(Map<String, dynamic>.from(item as Map)));
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('OfflineSyncService: Failed to load pending queue: $e');
    }
  }

  /// Enqueues a new sync event.
  ///
  /// Idempotent: If an event with the same `eventId` already exists in the queue,
  /// it is not duplicated.
  Future<void> enqueue(PendingSyncEvent event) async {
    final existingIndex = _queue.indexWhere((e) => e.eventId == event.eventId);
    if (existingIndex >= 0) {
      debugPrint('OfflineSyncService: Event ${event.eventId} already queued. Skipping duplicate.');
      return;
    }

    _queue.add(event);
    await _persistQueue();
    notifyListeners();
  }

  /// Removes an event from the queue after verified backend completion.
  Future<void> remove(String eventId) async {
    _queue.removeWhere((e) => e.eventId == eventId);
    _failedEvents.removeWhere((e) => e.eventId == eventId);
    await _persistQueue();
    notifyListeners();
  }

  /// Records an execution failure for an event, incrementing retry count.
  Future<void> markFailed(String eventId, String errorMessage) async {
    final index = _queue.indexWhere((e) => e.eventId == eventId);
    if (index >= 0) {
      final updated = _queue[index].copyWith(
        retryCount: _queue[index].retryCount + 1,
        lastError: errorMessage,
      );
      _queue[index] = updated;

      // Also maintain in failed list for diagnostics
      final failedIdx = _failedEvents.indexWhere((e) => e.eventId == eventId);
      if (failedIdx >= 0) {
        _failedEvents[failedIdx] = updated;
      } else {
        _failedEvents.add(updated);
      }

      await _persistQueue();
      notifyListeners();
    }
  }

  /// Processes all pending events in FIFO order using the configured executor.
  Future<int> processQueue({SyncEventExecutor? executor}) async {
    if (_isProcessing || _queue.isEmpty) return 0;
    _isProcessing = true;
    notifyListeners();

    final exec = executor ?? _customExecutor;
    if (exec == null) {
      _isProcessing = false;
      notifyListeners();
      return 0;
    }

    int processedCount = 0;
    final List<PendingSyncEvent> snapshot = List.from(_queue);

    for (final event in snapshot) {
      try {
        final success = await exec(event);
        if (success) {
          await remove(event.eventId);
          processedCount++;
        } else {
          await markFailed(event.eventId, 'Execution returned false');
        }
      } catch (e) {
        await markFailed(event.eventId, e.toString());
      }
    }

    _isProcessing = false;
    notifyListeners();
    return processedCount;
  }

  Future<void> _persistQueue() async {
    try {
      final data = {
        'pendingEvents': _queue.map((e) => e.toJson()).toList(),
      };
      await _storage.save(jsonEncode(data));
    } catch (e) {
      debugPrint('OfflineSyncService: Failed to save queue: $e');
    }
  }
}
