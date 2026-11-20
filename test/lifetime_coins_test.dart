import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/rewarded_ad_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';

class FailingStorageAdapter implements StorageAdapter {
  String? _data;
  bool shouldFail = false;

  FailingStorageAdapter([this._data]);

  @override
  Future<String?> load() async => _data;

  @override
  Future<void> save(String data) async {
    if (shouldFail) {
      throw Exception('Simulated disk I/O failure');
    }
    _data = data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStorageAdapter memoryStorage;

  setUp(() {
    memoryStorage = InMemoryStorageAdapter();
    GameService.instance.setStorageAdapterForTesting(memoryStorage);
    GameService.instance.disableMidnightTimerForTesting();
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
    GameService.instance.resetNowProviderForTesting();
    RewardedAdService.instance.resetProviderForTesting();
  });

  tearDown(() {
    GameService.instance.setStorageAdapterForTesting(memoryStorage);
    GameService.instance.cancelMidnightTimerForTesting();
    GameService.instance.resetProgress();
    GameService.instance.resetNowProviderForTesting();
    GameService.instance.setDebugUnlockAllLevels(false);
    RewardedAdService.instance.resetProviderForTesting();
  });

  group('AquaSort — Lifetime Earned Coins Tracking Verification', () {
    test('1. Initial lifetime coins = 0 for a genuinely new player', () {
      final service = GameService.instance;
      expect(service.coins, equals(0));
      expect(service.lifetimeEarnedCoins, equals(0));
    });

    test(
      '2. First-time level completion adds 50 to both coins and lifetime coins',
      () {
        final service = GameService.instance;
        expect(service.coins, equals(0));
        expect(service.lifetimeEarnedCoins, equals(0));

        final awarded = service.completeLevel(1, 5);
        expect(awarded, equals(50));
        expect(service.coins, equals(50));
        expect(service.lifetimeEarnedCoins, equals(50));
        expect(service.rewardedLevelIds.contains(1), isTrue);
      },
    );

    test(
      '3. Replaying a completed level adds 0 to coins and 0 to lifetime coins',
      () {
        final service = GameService.instance;
        service.completeLevel(1, 5);
        expect(service.coins, equals(50));
        expect(service.lifetimeEarnedCoins, equals(50));

        // Replay level 1
        final replayAwarded = service.completeLevel(1, 4);
        expect(replayAwarded, equals(0));
        expect(service.coins, equals(50));
        expect(service.lifetimeEarnedCoins, equals(50));
      },
    );

    test('4. Daily reward adds 30 to both coins and lifetime coins', () async {
      final service = GameService.instance;
      expect(service.canClaimDailyReward(), isTrue);

      final success = await service.claimDailyReward();
      expect(success, isTrue);
      expect(service.coins, equals(30));
      expect(service.lifetimeEarnedCoins, equals(30));

      // Attempting to claim again today returns false and does not increment
      final repeatClaim = await service.claimDailyReward();
      expect(repeatClaim, isFalse);
      expect(service.coins, equals(30));
      expect(service.lifetimeEarnedCoins, equals(30));
    });

    test('5. Spending coins decreases current coins but NEVER decreases lifetime coins', () async {
      final service = GameService.instance;
      // Complete 4 levels to earn 200 coins
      service.completeLevel(1, 5);
      service.completeLevel(2, 5);
      service.completeLevel(3, 5);
      service.completeLevel(4, 5);
      expect(service.coins, equals(200));
      expect(service.lifetimeEarnedCoins, equals(200));

      // Spend 25 coins on a hint
      final hintBought = await service.purchaseHint();
      expect(hintBought, isTrue);
      expect(service.coins, equals(175));
      expect(service.lifetimeEarnedCoins, equals(200)); // Still 200!

      // Generic spendCoins(50)
      final spent = service.spendCoins(50);
      expect(spent, isTrue);
      expect(service.coins, equals(125));
      expect(service.lifetimeEarnedCoins, equals(200)); // Still 200!
    });

    test('6. Generic positive addCoins increments lifetime coins by the actual amount', () {
      final service = GameService.instance;
      service.addCoins(100);
      expect(service.coins, equals(100));
      expect(service.lifetimeEarnedCoins, equals(100));

      service.addCoins(75);
      expect(service.coins, equals(175));
      expect(service.lifetimeEarnedCoins, equals(175));
    });

    test(
      '7. Invalid or non-positive additions do not increase lifetime coins',
      () {
        final service = GameService.instance;
        service.addCoins(50);
        expect(service.coins, equals(50));
        expect(service.lifetimeEarnedCoins, equals(50));

        service.addCoins(0);
        expect(service.coins, equals(50));
        expect(service.lifetimeEarnedCoins, equals(50));

        service.addCoins(-25);
        expect(service.coins, equals(50));
        expect(service.lifetimeEarnedCoins, equals(50));
      },
    );

    test('8. Failed storage operations do not leave incorrect lifetime values (rollback)', () async {
      final failingStorage = FailingStorageAdapter();
      GameService.instance.setStorageAdapterForTesting(failingStorage);

      // Start with known state
      GameService.instance.setCoinsForTesting(100);
      GameService.instance.setLifetimeCoinsForTesting(100);

      // Simulate disk write failure on claimDailyReward
      failingStorage.shouldFail = true;
      final dailyResult = await GameService.instance.claimDailyReward();
      expect(dailyResult, isFalse);
      expect(GameService.instance.coins, equals(100));
      expect(GameService.instance.lifetimeEarnedCoins, equals(100));

      // Simulate disk write failure on claimLevelCompletionReward
      final levelResult = await GameService.instance.claimLevelCompletionReward(
        5,
      );
      expect(levelResult, equals(0));
      expect(GameService.instance.coins, equals(100));
      expect(GameService.instance.lifetimeEarnedCoins, equals(100));
      expect(GameService.instance.rewardedLevelIds.contains(5), isFalse);

      failingStorage.shouldFail = false;
      GameService.instance.setStorageAdapterForTesting(memoryStorage);
    });

    test('9. Existing save migration uses the approved baseline max(currentCoins, rewardedLevelIds.length * 50)', () async {
      // Case A: Level coins (10 * 50 = 500) > current coins (200 after spending)
      final legacySaveA = jsonEncode({
        'currentLevel': 11,
        'completedLevels': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'rewardedLevelIds': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'coins': 200,
        'economyV2MigrationDone': true,
      });

      final storageA = InMemoryStorageAdapter();
      await storageA.save(legacySaveA);
      final serviceA = GameService.instance;
      serviceA.setStorageAdapterForTesting(storageA);
      await serviceA.initialize(forceReload: true);

      expect(serviceA.coins, equals(200));
      // Baseline = max(200, 10 * 50 = 500) = 500
      expect(serviceA.lifetimeEarnedCoins, equals(500));

      // Case B: Current coins (650 from daily rewards) > level coins (2 * 50 = 100)
      final legacySaveB = jsonEncode({
        'currentLevel': 3,
        'completedLevels': [1, 2],
        'rewardedLevelIds': [1, 2],
        'coins': 650,
        'economyV2MigrationDone': true,
      });

      final storageB = InMemoryStorageAdapter();
      await storageB.save(legacySaveB);
      final serviceB = GameService.instance;
      serviceB.setStorageAdapterForTesting(storageB);
      await serviceB.initialize(forceReload: true);

      expect(serviceB.coins, equals(650));
      // Baseline = max(650, 2 * 50 = 100) = 650
      expect(serviceB.lifetimeEarnedCoins, equals(650));
    });

    test('10. Saving and reloading preserves lifetime coins', () async {
      final storage = InMemoryStorageAdapter();
      final service = GameService.instance;
      service.setStorageAdapterForTesting(storage);

      // Earn coins through level 1 & 2
      service.completeLevel(1, 5); // +50
      service.completeLevel(2, 5); // +50
      service.addCoins(100); // +100
      service.spendCoins(75); // -75
      expect(service.coins, equals(125));
      expect(service.lifetimeEarnedCoins, equals(200));

      // Reload from storage
      await service.initialize(forceReload: true);
      expect(service.coins, equals(125));
      expect(service.lifetimeEarnedCoins, equals(200));

      // Verify JSON saved to storage contains the field
      final savedData =
          jsonDecode(await storage.load() ?? '{}') as Map<String, dynamic>;
      expect(savedData['coins'], equals(125));
      expect(savedData['lifetimeEarnedCoins'], equals(200));
    });

    test('11. Repeated migration does not double-count', () async {
      final legacySave = jsonEncode({
        'currentLevel': 5,
        'completedLevels': [1, 2, 3, 4],
        'rewardedLevelIds': [1, 2, 3, 4],
        'coins': 200,
        'economyV2MigrationDone': true,
      });

      final storage = InMemoryStorageAdapter();
      await storage.save(legacySave);
      final service = GameService.instance;
      service.setStorageAdapterForTesting(storage);

      // First load (triggers migration: baseline = max(200, 200) = 200)
      await service.initialize(forceReload: true);
      expect(service.coins, equals(200));
      expect(service.lifetimeEarnedCoins, equals(200));

      // Spend 50 coins (coins = 150, lifetime = 200)
      service.spendCoins(50);
      expect(service.coins, equals(150));
      expect(service.lifetimeEarnedCoins, equals(200));

      // Second load (must load lifetimeEarnedCoins = 200, not recalculate from coins=150)
      await service.initialize(forceReload: true);
      expect(service.coins, equals(150));
      expect(service.lifetimeEarnedCoins, equals(200)); // NOT reset or changed!

      // Third load
      await service.initialize(forceReload: true);
      expect(service.coins, equals(150));
      expect(service.lifetimeEarnedCoins, equals(200));
    });
  });
}
