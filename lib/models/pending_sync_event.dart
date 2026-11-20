import 'package:flutter/foundation.dart';

/// Represents the type of reward or progress event to synchronize.
enum SyncEventType {
  levelCompletion,
  dailyReward,
  nicknameChange,
  historicalMigration,
}

/// Represents an idempotent event pending synchronization with Firebase backend.
@immutable
class PendingSyncEvent {
  final String eventId;
  final String uid;
  final SyncEventType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  const PendingSyncEvent({
    required this.eventId,
    required this.uid,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  PendingSyncEvent copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return PendingSyncEvent(
      eventId: eventId,
      uid: uid,
      type: type,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'uid': uid,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory PendingSyncEvent.fromJson(Map<String, dynamic> json) {
    return PendingSyncEvent(
      eventId: json['eventId'] as String,
      uid: json['uid'] as String,
      type: SyncEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncEventType.levelCompletion,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSyncEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          uid == other.uid;

  @override
  int get hashCode => eventId.hashCode ^ uid.hashCode;
}
