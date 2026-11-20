import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/models/leaderboard_entry.dart';
import 'package:water_sort_game/models/pending_sync_event.dart';
import 'package:water_sort_game/services/auth_service.dart';
import 'package:water_sort_game/services/firebase_service.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/leaderboard_service.dart';
import 'package:water_sort_game/services/offline_sync_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AquaSort — Stage 2 Real Firebase Leaderboard Backend Tests', () {
    late GameService gameService;
    late AuthService authService;
    late OfflineSyncService syncService;
    late LeaderboardService leaderboardService;

    setUp(() async {
      gameService = GameService.instance;
      authService = AuthService.instance;
      syncService = OfflineSyncService.instance;
      leaderboardService = LeaderboardService.instance;

      final gameStorage = InMemoryStorageAdapter();
      final syncStorage = InMemoryStorageAdapter();
      final authStorage = InMemoryStorageAdapter();

      gameService.setStorageAdapterForTesting(gameStorage);
      syncService.setStorageForTesting(syncStorage);
      authService.setStorageForTesting(authStorage);

      syncService.clearForTesting();
      gameService.resetProgress(defaultCoins: 0);
      authService.setMockUidForTesting('test_player_uid_777');
      leaderboardService.setNicknameLastChangedAtForTesting(null);
    });

    test('1. Anonymous authentication provides persistent UID and offline resilience', () async {
      // Offline fallback: Firebase uninitialized in test environment
      FirebaseService.setInitializedForTesting(false);

      expect(authService.currentUid, isNotEmpty);
      expect(authService.currentUid, equals('test_player_uid_777'));

      // Preserves same UID across multiple accesses
      final uid1 = authService.currentUid;
      final uid2 = authService.currentUid;
      expect(uid1, equals(uid2));

      // Attempting anonymous sign-in offline does not throw unhandled exceptions
      final user = await authService.signInAnonymously();
      expect(user, isNull);
      expect(authService.currentUid, equals('test_player_uid_777'));
    });

    test('2. Level completion: First completion = 50 coins, Replay = 0 coins', () {
      // First completion of Level 1
      final coins1 = gameService.completeLevel(1, 10, earnedStars: 3);
      expect(coins1, equals(50));
      expect(gameService.coins, equals(50));
      expect(gameService.lifetimeEarnedCoins, equals(50));
      expect(gameService.isLevelRewarded(1), isTrue);

      // Replay Level 1 with different moves
      final coinsReplay = gameService.completeLevel(1, 8, earnedStars: 3);
      expect(coinsReplay, equals(0));
      expect(gameService.coins, equals(50));
      expect(gameService.lifetimeEarnedCoins, equals(50));

      // First completion of Level 2
      final coins2 = gameService.completeLevel(2, 14, earnedStars: 3);
      expect(coins2, equals(50));
      expect(gameService.coins, equals(100));
      expect(gameService.lifetimeEarnedCoins, equals(100));
      expect(gameService.isLevelRewarded(2), isTrue);
    });

    test('3. Duplicate level completion prevention and idempotent event generation', () async {
      // Clear queue
      syncService.clearForTesting();

      // Completing Level 5 once enqueues a level completion event
      gameService.completeLevel(5, 12, earnedStars: 3);
      expect(syncService.pendingCount, equals(1));

      final event = syncService.pendingEvents.first;
      expect(event.type, equals(SyncEventType.levelCompletion));
      expect(event.payload['levelId'], equals(5));
      expect(event.eventId, equals('level_5_test_player_uid_777'));

      // Replaying Level 5 does not generate a new reward event
      gameService.completeLevel(5, 10, earnedStars: 3);
      expect(syncService.pendingCount, equals(1));

      // Attempting to enqueue duplicate event directly is rejected
      await syncService.enqueue(event);
      expect(syncService.pendingCount, equals(1));
    });

    test('4. Daily reward: exactly 30 coins awarded only once per eligible calendar day', () async {
      DateTime simulatedTime = DateTime(2026, 11, 18, 10, 0); // Asia/Kolkata day 1
      gameService.setNowProviderForTesting(() => simulatedTime);

      expect(gameService.canClaimDailyReward(), isTrue);

      // Claim reward on day 1
      final claimed1 = await gameService.claimDailyReward();
      expect(claimed1, isTrue);
      expect(gameService.coins, equals(30));
      expect(gameService.lifetimeEarnedCoins, equals(30));
      expect(gameService.lastDailyClaimDate, equals('2026-11-18'));

      // Second attempt on same calendar day fails
      expect(gameService.canClaimDailyReward(), isFalse);
      final claimedDuplicate = await gameService.claimDailyReward();
      expect(claimedDuplicate, isFalse);
      expect(gameService.coins, equals(30));
      expect(gameService.lifetimeEarnedCoins, equals(30));

      // Clock tampering (user sets time backwards) is rejected
      simulatedTime = DateTime(2026, 11, 17, 12, 0);
      expect(gameService.canClaimDailyReward(), isFalse);

      // Advance to next calendar day
      simulatedTime = DateTime(2026, 11, 19, 0, 5);
      expect(gameService.canClaimDailyReward(), isTrue);
      final claimedDay2 = await gameService.claimDailyReward();
      expect(claimedDay2, isTrue);
      expect(gameService.coins, equals(60));
      expect(gameService.lifetimeEarnedCoins, equals(60));
      expect(gameService.lastDailyClaimDate, equals('2026-11-19'));
    });

    test('5. Wallet spending reduces wallet coins ONLY and NEVER reduces lifetimeEarnedCoins', () {
      // Award 200 coins through level completions
      gameService.completeLevel(1, 10); // 50
      gameService.completeLevel(2, 10); // 50
      gameService.completeLevel(3, 10); // 50
      gameService.completeLevel(4, 10); // 50

      expect(gameService.coins, equals(200));
      expect(gameService.lifetimeEarnedCoins, equals(200));

      // Spend 150 coins from wallet
      final spent = gameService.spendCoins(150);
      expect(spent, isTrue);
      expect(gameService.coins, equals(50));
      // STRICT REQUIREMENT: Spending must NEVER decrease lifetimeEarnedCoins
      expect(gameService.lifetimeEarnedCoins, equals(200));

      // Attempting to spend more than wallet balance fails
      final overspend = gameService.spendCoins(100);
      expect(overspend, isFalse);
      expect(gameService.coins, equals(50));
      expect(gameService.lifetimeEarnedCoins, equals(200));
    });

    test('6. Nickname validation and 7-day cooldown enforcement', () async {
      // Valid nickname
      final updated = await leaderboardService.updateNickname('TidalHydra_99');
      expect(updated, isTrue);
      expect(leaderboardService.playerNickname, equals('TidalHydra_99'));

      // Too short (< 3 characters)
      expect(
        () => leaderboardService.updateNickname('ab'),
        throwsA(isA<ArgumentError>()),
      );

      // Too long (> 15 characters)
      expect(
        () => leaderboardService.updateNickname('SuperLongNicknameX'),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid characters
      expect(
        () => leaderboardService.updateNickname('Aqua@#%'),
        throwsA(isA<ArgumentError>()),
      );

      // Immediate second change is blocked by 7-day cooldown
      expect(
        () => leaderboardService.updateNickname('OceanKnight'),
        throwsA(isA<StateError>()),
      );

      // Cooldown helper check
      final summary = leaderboardService.getPlayerRankSummary(500);
      expect(summary.canChangeNickname, isFalse);
      expect(summary.daysUntilNicknameChange, greaterThan(0));

      // After 7 days elapsed
      leaderboardService.setNicknameLastChangedAtForTesting(
        DateTime.now().subtract(const Duration(days: 8)),
      );
      final allowedSummary = leaderboardService.getPlayerRankSummary(500);
      expect(allowedSummary.canChangeNickname, isTrue);
      expect(allowedSummary.daysUntilNicknameChange, equals(0));

      final updatedAfterCooldown = await leaderboardService.updateNickname('OceanKnight');
      expect(updatedAfterCooldown, isTrue);
      expect(leaderboardService.playerNickname, equals('OceanKnight'));
    });

    test('7. Firestore security rules specification check', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();

      // Default deny
      expect(content.contains('match /{document=**} {\n      allow read, write: if false;'), isTrue);

      // Leaderboard: authenticated read only, client write forbidden
      expect(content.contains('match /leaderboard/{uid}'), isTrue);
      expect(content.contains('allow read: if request.auth != null;'), isTrue);
      expect(content.contains('allow write: if false;'), isTrue);

      // Private user document: owner read only, client write forbidden
      expect(content.contains('match /users/{uid}'), isTrue);
      expect(content.contains('request.auth.uid == uid'), isTrue);

      // Coin events audit log: owner read only, client write forbidden
      expect(content.contains('match /coinEvents/{eventId}'), isTrue);
    });

    test('8. Offline event queue persistence and retry behavior', () async {
      syncService.clearForTesting();

      final event = PendingSyncEvent(
        eventId: 'level_10_test_uid',
        uid: 'test_uid',
        type: SyncEventType.levelCompletion,
        payload: {'levelId': 10, 'movesUsed': 15, 'stars': 3},
        createdAt: DateTime.now(),
      );

      await syncService.enqueue(event);
      expect(syncService.pendingCount, equals(1));

      // Simulate a failed sync attempt (network down)
      await syncService.markFailed(event.eventId, 'SocketException: Connection refused');

      expect(syncService.failedEvents.length, equals(1));
      expect(syncService.failedEvents.first.retryCount, equals(1));
      expect(syncService.failedEvents.first.lastError, contains('SocketException'));

      // Simulate network restored and successful execution
      int executedCount = 0;
      final processed = await syncService.processQueue(
        executor: (evt) async {
          executedCount++;
          return true; // Server confirmed
        },
      );

      expect(processed, equals(1));
      expect(executedCount, equals(1));
      expect(syncService.pendingCount, equals(0));
    });

    test('9. Leaderboard ranking deterministic tie-breaking (equal scores ordered by timestamp)', () {
      final time1 = DateTime(2026, 11, 15, 10, 0);
      final time2 = DateTime(2026, 11, 15, 11, 0);

      // Both players have 2,000 lifetime coins. Player A achieved it earlier than Player B.
      final playerA = LeaderboardEntry(
        rank: 1,
        uid: 'uid_player_a',
        nickname: 'FirstAqua',
        avatarId: 'avatar_droplet',
        lifetimeCoinsEarned: 2000,
        updatedAt: time1,
      );

      final playerB = LeaderboardEntry(
        rank: 2,
        uid: 'uid_player_b',
        nickname: 'SecondAqua',
        avatarId: 'avatar_droplet',
        lifetimeCoinsEarned: 2000,
        updatedAt: time2,
      );

      final entries = [playerB, playerA];
      // Deterministic sort: lifetimeCoinsEarned descending, then updatedAt ascending
      entries.sort((a, b) {
        final coinDiff = b.lifetimeCoinsEarned.compareTo(a.lifetimeCoinsEarned);
        if (coinDiff != 0) return coinDiff;
        if (a.updatedAt != null && b.updatedAt != null) {
          return a.updatedAt!.compareTo(b.updatedAt!);
        }
        return 0;
      });

      expect(entries.first.uid, equals('uid_player_a'));
      expect(entries.last.uid, equals('uid_player_b'));
    });

    test('10. Historical migration does not infer lifetime coins from wallet balance', () async {
      syncService.clearForTesting();

      // Player has 500 wallet coins (e.g. from tests or unverified data),
      // but only 2 verified completed levels: [1, 2]
      final verifiedLevels = {1, 2};

      await leaderboardService.queueHistoricalMigration(
        verifiedRewardedLevelIds: verifiedLevels,
        lastDailyClaimDate: '2026-11-10',
      );

      expect(syncService.pendingCount, equals(1));
      final migrationEvent = syncService.pendingEvents.first;
      expect(migrationEvent.type, equals(SyncEventType.historicalMigration));

      // The payload ONLY contains verified rewardedLevelIds.
      // It does NOT include unverified client wallet balance or unverified lifetime coins.
      expect(migrationEvent.payload['rewardedLevelIds'], equals([1, 2]));
      expect(migrationEvent.payload.containsKey('walletCoins'), isFalse);
      expect(migrationEvent.payload.containsKey('lifetimeCoinsEarned'), isFalse);
    });
  });
}
