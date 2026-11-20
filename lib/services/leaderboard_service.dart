import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';
import '../models/pending_sync_event.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'offline_sync_service.dart';

/// Real Firebase Leaderboard Service for AquaSort.
///
/// Features:
/// - Real-time Firestore query for Top 100 global players.
/// - Authenticated player rank calculation.
/// - Enforces 7-day nickname cooldown and 3-15 character format.
/// - Queues offline events via OfflineSyncService.
/// - Resilient error and offline handling.
class LeaderboardService extends ChangeNotifier implements ILeaderboardProvider {
  static final LeaderboardService instance = LeaderboardService._internal();
  factory LeaderboardService() => instance;
  LeaderboardService._internal();

  FirebaseFirestore? _firestore;
  AuthService _auth = AuthService.instance;
  OfflineSyncService _sync = OfflineSyncService.instance;

  LeaderboardStatus _status = LeaderboardStatus.loading;
  List<LeaderboardEntry> _top100 = [];
  String? _lastError;

  String _localNickname = 'AquaMaster#7421';
  String _localAvatarId = 'avatar_droplet';
  DateTime? _nicknameLastChangedAt;
  int? _cachedPlayerRank;

  @visibleForTesting
  void setFirestoreForTesting(FirebaseFirestore? firestore) {
    _firestore = firestore;
  }

  @visibleForTesting
  void setAuthServiceForTesting(AuthService auth) {
    _auth = auth;
  }

  @visibleForTesting
  void setSyncServiceForTesting(OfflineSyncService sync) {
    _sync = sync;
  }

  @override
  @visibleForTesting
  void setStatusForTesting(LeaderboardStatus status) {
    _status = status;
    notifyListeners();
  }

  @visibleForTesting
  void setTop100ForTesting(List<LeaderboardEntry> list) {
    _top100 = List.from(list);
    _status = list.isEmpty ? LeaderboardStatus.empty : LeaderboardStatus.loaded;
    notifyListeners();
  }

  @visibleForTesting
  void setNicknameLastChangedAtForTesting(DateTime? dt) {
    _nicknameLastChangedAt = dt;
    notifyListeners();
  }

  FirebaseFirestore get _effectiveFirestore =>
      _firestore ?? FirebaseFirestore.instance;

  @override
  LeaderboardStatus get status => _status;
  List<LeaderboardEntry> get top100Players => List.unmodifiable(_top100);
  String? get lastError => _lastError;
  String get playerNickname => _localNickname;
  String get playerAvatarId => _localAvatarId;
  DateTime? get nicknameLastChangedAt => _nicknameLastChangedAt;

  /// Initializes the leaderboard service and sets up real-time listener if online.
  Future<void> initialize() async {
    if (!FirebaseService.isInitialized && _firestore == null) {
      _status = LeaderboardStatus.offline;
      notifyListeners();
      return;
    }

    await fetchTop100();
  }

  /// Fetches Top 100 players from Firestore ordered by lifetimeCoinsEarned descending.
  Future<void> fetchTop100() async {
    if (!FirebaseService.isInitialized && _firestore == null) {
      _status = LeaderboardStatus.offline;
      notifyListeners();
      return;
    }

    _status = LeaderboardStatus.loading;
    notifyListeners();

    try {
      final snapshot = await _effectiveFirestore
          .collection('leaderboard')
          .orderBy('lifetimeCoinsEarned', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) {
        _top100 = [];
        _status = LeaderboardStatus.empty;
      } else {
        final List<LeaderboardEntry> entries = [];
        int rankIndex = 1;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final updated = data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : null;
          entries.add(
            LeaderboardEntry(
              rank: rankIndex++,
              uid: data['uid'] as String? ?? doc.id,
              nickname: data['nickname'] as String? ?? 'Anonymous Sorter',
              avatarId: data['avatarId'] as String? ?? 'avatar_droplet',
              lifetimeCoinsEarned:
                  (data['lifetimeCoinsEarned'] as num?)?.toInt() ?? 0,
              updatedAt: updated,
            ),
          );
        }
        _top100 = entries;
        _status = LeaderboardStatus.loaded;
      }
      _lastError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('LeaderboardService: Failed to fetch leaderboard: $e');
      _lastError = e.toString();
      _status = LeaderboardStatus.error;
      notifyListeners();
    }
  }

  /// Calculates and returns the PlayerRankSummary for the current user.
  @override
  PlayerRankSummary getPlayerRankSummary(int localLifetimeCoins) {
    final uid = _auth.currentUid;

    // Check if player is within Top 100 list
    final topIndex = _top100.indexWhere((e) => e.uid == uid);
    if (topIndex >= 0) {
      final topEntry = _top100[topIndex];
      return PlayerRankSummary(
        rank: topEntry.rank,
        nickname: topEntry.nickname,
        avatarId: topEntry.avatarId,
        lifetimeCoinsEarned: topEntry.lifetimeCoinsEarned,
        isTop100: true,
        nicknameLastChangedAt: _nicknameLastChangedAt,
      );
    }

    // Outside Top 100: use cached rank or approximate based on local lifetime coins
    return PlayerRankSummary(
      rank: _cachedPlayerRank,
      nickname: _localNickname,
      avatarId: _localAvatarId,
      lifetimeCoinsEarned: localLifetimeCoins,
      isTop100: false,
      nicknameLastChangedAt: _nicknameLastChangedAt,
    );
  }

  /// Returns Top 100 players list matching LeaderboardScreen's expected signature.
  @override
  List<LeaderboardEntry> getTop100Players() {
    return _top100;
  }

  /// Validates and updates the player's nickname locally and enqueues sync.
  @override
  Future<bool> updateNickname(String newNickname, {String? avatarId}) async {
    final trimmed = newNickname.trim();

    // 1. Validate length: 3 to 15 characters
    if (trimmed.length < 3 || trimmed.length > 15) {
      throw ArgumentError('Nickname must be between 3 and 15 characters.');
    }

    // 2. Validate allowed characters: alphanumeric, spaces, and underscores
    final validCharacters = RegExp(r'^[a-zA-Z0-9 _]+$');
    if (!validCharacters.hasMatch(trimmed)) {
      throw ArgumentError('Nickname contains invalid characters.');
    }

    // 3. Enforce 7-day cooldown
    if (_nicknameLastChangedAt != null) {
      final difference = DateTime.now().difference(_nicknameLastChangedAt!);
      if (difference.inDays < 7) {
        throw StateError(
          'Nickname cooldown active. Please wait ${7 - difference.inDays} more days.',
        );
      }
    }

    _localNickname = trimmed;
    if (avatarId != null) _localAvatarId = avatarId;
    _nicknameLastChangedAt = DateTime.now();
    notifyListeners();

    // Enqueue sync event
    final uid = _auth.currentUid;
    final eventId = 'nickname_${uid}_${_nicknameLastChangedAt!.millisecondsSinceEpoch}';

    await _sync.enqueue(
      PendingSyncEvent(
        eventId: eventId,
        uid: uid,
        type: SyncEventType.nicknameChange,
        payload: {
          'nickname': trimmed,
          'avatarId': _localAvatarId,
        },
        createdAt: DateTime.now(),
      ),
    );

    return true;
  }

  /// Enqueues level completion event for server-side verification and reward.
  Future<void> queueLevelCompletion({
    required int levelId,
    required int movesUsed,
    int? stars,
  }) async {
    final uid = _auth.currentUid;
    final eventId = 'level_${levelId}_$uid';

    await _sync.enqueue(
      PendingSyncEvent(
        eventId: eventId,
        uid: uid,
        type: SyncEventType.levelCompletion,
        payload: {
          'levelId': levelId,
          'movesUsed': movesUsed,
          'stars': stars ?? 3,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Enqueues daily reward claim event for server-side verification and reward.
  Future<void> queueDailyReward({required String calendarDate}) async {
    final uid = _auth.currentUid;
    final eventId = 'daily_${calendarDate}_$uid';

    await _sync.enqueue(
      PendingSyncEvent(
        eventId: eventId,
        uid: uid,
        type: SyncEventType.dailyReward,
        payload: {
          'calendarDate': calendarDate,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Enqueues verified historical progress migration.
  Future<void> queueHistoricalMigration({
    required Set<int> verifiedRewardedLevelIds,
    String? lastDailyClaimDate,
  }) async {
    final uid = _auth.currentUid;
    final eventId = 'migration_$uid';

    await _sync.enqueue(
      PendingSyncEvent(
        eventId: eventId,
        uid: uid,
        type: SyncEventType.historicalMigration,
        payload: {
          'rewardedLevelIds': verifiedRewardedLevelIds.toList(),
          'lastDailyClaimDate': lastDailyClaimDate,
        },
        createdAt: DateTime.now(),
      ),
    );
  }
}
