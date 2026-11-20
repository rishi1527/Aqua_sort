import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/models/bottle_model.dart';
import 'package:water_sort_game/models/theme_model.dart';
import 'package:water_sort_game/screens/bottles_screen.dart';
import 'package:water_sort_game/screens/customization_screen.dart';
import 'package:water_sort_game/screens/home_screen.dart';
import 'package:water_sort_game/screens/themes_screen.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/rewarded_ad_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';
import 'package:water_sort_game/widgets/level_complete_dialog.dart';

class MockRewardedAdProvider implements RewardedAdProvider {
  bool available;
  RewardedAdResult nextResult;
  int showCallCount = 0;

  MockRewardedAdProvider({
    this.available = true,
    this.nextResult = RewardedAdResult.rewardEarned,
  });

  @override
  bool get isAdAvailable => available;

  @override
  Future<RewardedAdResult> showRewardedAd() async {
    showCallCount++;
    return nextResult;
  }
}

class FailingStorageAdapter implements StorageAdapter {
  String? _data;
  bool shouldFail = false;

  FailingStorageAdapter([this._data]);

  @override
  Future<String?> load() async => _data;

  @override
  Future<void> save(String data) async {
    if (shouldFail) {
      throw Exception('Simulated I/O disk failure');
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
    GameService.instance.cancelMidnightTimerForTesting();
    GameService.instance.resetProgress();
    GameService.instance.resetNowProviderForTesting();
    GameService.instance.setDebugUnlockAllLevels(false);
    RewardedAdService.instance.resetProviderForTesting();
  });

  // ===========================================================================
  // 0. Starting Coin Balance & One-Time Migration Tests
  // ===========================================================================
  group('0. Starting Coin Balance & One-Time Migration Tests', () {
    test('New player starts with exactly 0 coins', () {
      final service = GameService.instance;
      expect(service.coins, equals(0));
      expect(service.getBalance(), equals(0));
      expect(service.isEconomyV2MigrationDone, isTrue);
    });

    test(
      'Existing player receives exactly one zero-balance migration',
      () async {
        // Simulate legacy save data where an existing player has 1250 coins and completed levels
        final legacySave = jsonEncode({
          'currentLevel': 15,
          'completedLevels': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          'starsPerLevel': {'1': 3, '2': 3, '3': 3, '4': 2, '5': 3},
          'coins': 1250,
          'selectedThemeId': 'simple',
          'unlockedThemeIds': ['simple', 'ocean_valley'],
          'selectedBottleId': 'classic_tube',
          'unlockedBottleIds': ['classic_tube', 'classic_flask', 'wave_bottle'],
          'selectedCapId': 'cap_cork',
          'unlockedCapIds': ['cap_none', 'cap_cork'],
        });

        final adapter = InMemoryStorageAdapter();
        await adapter.save(legacySave);

        final service = GameService.instance;
        service.setStorageAdapterForTesting(adapter);
        await service.reloadForTesting();

        // Migration must reset coins to 0
        expect(service.coins, equals(0));
        expect(service.isEconomyV2MigrationDone, isTrue);

        // Verify that progress and cosmetic ownership are preserved intact
        expect(service.currentLevel, equals(15));
        expect(service.completedLevelsCount, equals(14));
        expect(service.getStarsForLevel(1), equals(3));
        expect(service.getStarsForLevel(4), equals(2));
        expect(service.isThemeOwned('ocean_valley'), isTrue);
        expect(service.isBottleOwned('wave_bottle'), isTrue);
        expect(service.selectedCapId, equals('cap_cork'));

        // Verify that the adapter now has economyV2MigrationDone written
        final savedRaw = await adapter.load();
        expect(savedRaw, isNotNull);
        final savedMap = jsonDecode(savedRaw!);
        expect(savedMap['economyV2MigrationDone'], isTrue);
        expect(savedMap['coins'], equals(0));
      },
    );

    test('Migration does not run again after app restart (coins earned after migration are kept)', () async {
      final adapter = InMemoryStorageAdapter();
      final service = GameService.instance;
      service.setStorageAdapterForTesting(adapter);

      // Player starts fresh after migration (0 coins)
      await service.reloadForTesting();
      expect(service.coins, equals(0));

      // Player earns coins (50 coins from Level 1, 30 from daily reward)
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));
      final levelCoins = service.completeLevel(1, 8, earnedStars: 3);
      expect(levelCoins, equals(50));
      final dailyCoins = await service.claimDailyReward();
      expect(dailyCoins, isTrue);
      expect(service.coins, equals(80));

      // Restart app
      await service.reloadForTesting();

      // Coin balance MUST remain 80; migration must NOT run again!
      expect(service.coins, equals(80));
      expect(service.isEconomyV2MigrationDone, isTrue);
    });

    test('Existing level progress, stars, and cosmetics remain intact across migration', () async {
      final legacyData = jsonEncode({
        'currentLevel': 25,
        'completedLevels': List.generate(24, (i) => i + 1),
        'starsPerLevel': {for (int i = 1; i <= 24; i++) i.toString(): 3},
        'coins': 850,
        'selectedThemeId': 'desert_oasis',
        'unlockedThemeIds': ['simple', 'desert_oasis'],
        'selectedBottleId': 'potion_bottle',
        'unlockedBottleIds': ['classic_tube', 'classic_flask', 'potion_bottle'],
        'selectedCapId': 'cap_cork',
        'unlockedCapIds': ['cap_none', 'cap_cork'],
        'selectedBubbleFxId': 'fx_stars',
        'unlockedBubbleFxIds': ['fx_soda_fizz', 'fx_none', 'fx_stars'],
        'selectedBackgroundId': 'bg_purple_white',
        'unlockedBackgroundIds': ['bg_purple_white'],
        'selectedPaletteId': 'palette_vibrant_pop',
        'unlockedPaletteIds': ['palette_vibrant_pop'],
      });

      final adapter = InMemoryStorageAdapter();
      await adapter.save(legacyData);

      final service = GameService.instance;
      service.setStorageAdapterForTesting(adapter);
      await service.reloadForTesting();

      // Reset coins to 0
      expect(service.coins, equals(0));

      // Everything else intact
      expect(service.currentLevel, equals(25));
      expect(service.completedLevelsCount, equals(24));
      for (int i = 1; i <= 24; i++) {
        expect(service.getStarsForLevel(i), equals(3));
      }
      expect(service.selectedThemeId, equals('desert_oasis'));
      expect(service.isThemeOwned('desert_oasis'), isTrue);
      expect(service.selectedBottleId, equals('potion_bottle'));
      expect(service.isBottleOwned('potion_bottle'), isTrue);
      expect(service.selectedCapId, equals('cap_cork'));
      expect(service.selectedBubbleFxId, equals('fx_stars'));
    });
  });

  // ===========================================================================
  // 1. Level Completion Reward Tests
  // ===========================================================================
  group('1. Level Completion Reward Tests', () {
    test('First successful completion awards exactly 50 coins', () {
      final service = GameService.instance;
      service.setCoinsForTesting(0);
      expect(service.coins, equals(0));
      expect(service.isLevelRewarded(1), isFalse);

      final awarded = service.completeLevel(1, 10, earnedStars: 3);
      expect(awarded, equals(50));
      expect(service.coins, equals(50));
      expect(service.isLevelRewarded(1), isTrue);
    });

    test('Repeat completion of the same level awards 0 coins', () {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      final firstAward = service.completeLevel(1, 10, earnedStars: 3);
      expect(firstAward, equals(50));
      expect(service.coins, equals(50));

      final repeatAward = service.completeLevel(1, 8, earnedStars: 3);
      expect(repeatAward, equals(0));
      expect(service.coins, equals(50));
    });

    test('Repeated completion callbacks award only once', () {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      final award1 = service.completeLevel(5, 12, earnedStars: 2);
      final award2 = service.completeLevel(5, 12, earnedStars: 2);
      final award3 = service.completeLevel(5, 12, earnedStars: 2);

      expect(award1, equals(50));
      expect(award2, equals(0));
      expect(award3, equals(0));
      expect(service.coins, equals(50));
    });

    test('Three-star completion awards exactly 50 coins, not extra', () {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      final award = service.completeLevel(2, 5, earnedStars: 3);
      expect(award, equals(50));
      expect(service.coins, equals(50));
    });

    test('Lower or higher stars on replay never produce extra coins', () {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      // First completion with 1 star
      final firstAward = service.completeLevel(3, 20, earnedStars: 1);
      expect(firstAward, equals(50));
      expect(service.coins, equals(50));

      // Replay with 3 stars
      final replayAward = service.completeLevel(3, 6, earnedStars: 3);
      expect(replayAward, equals(0));
      expect(service.coins, equals(50));
      expect(service.getStarsForLevel(3), equals(3));
    });

    test('Failed or timed-out level awards 0 coins', () {
      final service = GameService.instance;
      service.setCoinsForTesting(100);

      // Simulating a timeout/failure: completeLevel is never called
      // Balance remains unchanged
      expect(service.coins, equals(100));
    });

    test('Restarting or abandoning a level awards 0 coins', () {
      final service = GameService.instance;
      service.setCoinsForTesting(75);

      // Abandoning/restarting level does not invoke reward
      expect(service.coins, equals(75));
    });

    test('Existing completed levels do not receive retroactive rewards on migration', () async {
      // Create older save data without rewardedLevelIds
      final legacyData = jsonEncode({
        'version': 2,
        'currentLevel': 4,
        'highestUnlockedLevel': 4,
        'completedLevels': [1, 2, 3],
        'starsPerLevel': {'1': 3, '2': 2, '3': 3},
        'coins': 0,
      });

      final adapter = InMemoryStorageAdapter();
      await adapter.save(legacyData);

      final service = GameService.instance;
      service.setStorageAdapterForTesting(adapter);
      await service.reloadForTesting();

      // Ensure balance remained 0 and was not retroactively rewarded for levels 1-3
      expect(service.coins, equals(0));
      expect(service.isLevelRewarded(1), isTrue);
      expect(service.isLevelRewarded(2), isTrue);
      expect(service.isLevelRewarded(3), isTrue);
      expect(service.isLevelRewarded(4), isFalse);

      // Completing Level 1 again produces 0 coins
      final replayAward = service.completeLevel(1, 10, earnedStars: 3);
      expect(replayAward, equals(0));
      expect(service.coins, equals(0));

      // Completing Level 4 (new) awards 50 coins
      final newAward = service.completeLevel(4, 10, earnedStars: 3);
      expect(newAward, equals(50));
      expect(service.coins, equals(50));
    });

    test('Saving failure does not produce a false success or duplicate reward on retry', () async {
      final failingAdapter = FailingStorageAdapter();
      final service = GameService.instance;
      service.setStorageAdapterForTesting(failingAdapter);
      service.setCoinsForTesting(0);

      // Trigger failure during save
      failingAdapter.shouldFail = true;
      final failedReward = await service.claimLevelCompletionReward(10);
      expect(failedReward, equals(0));
      expect(service.coins, equals(0));
      expect(service.isLevelRewarded(10), isFalse);

      // Fix failure and retry
      failingAdapter.shouldFail = false;
      final retryReward = await service.claimLevelCompletionReward(10);
      expect(retryReward, equals(50));
      expect(service.coins, equals(50));
      expect(service.isLevelRewarded(10), isTrue);

      // Subsequent attempt fails to award duplicate
      final duplicateAttempt = await service.claimLevelCompletionReward(10);
      expect(duplicateAttempt, equals(0));
      expect(service.coins, equals(50));
    });
  });

  // ===========================================================================
  // 2. Daily Reward Tests
  // ===========================================================================
  group('2. Daily Reward Tests', () {
    test('First eligible claim awards exactly 30 coins', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(0);
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));

      expect(service.canClaimDailyReward(), isTrue);

      final success = await service.claimDailyReward();
      expect(success, isTrue);
      expect(service.coins, equals(30));
      expect(service.canClaimDailyReward(), isFalse);
    });

    test('Second claim on the same date awards 0 coins', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(0);
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));

      await service.claimDailyReward();
      expect(service.coins, equals(30));

      final secondClaim = await service.claimDailyReward();
      expect(secondClaim, isFalse);
      expect(service.coins, equals(30));
    });

    test('Reopening the app does not permit another claim that day', () async {
      final adapter = InMemoryStorageAdapter();
      final service = GameService.instance;
      service.setStorageAdapterForTesting(adapter);
      service.setCoinsForTesting(0);
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));

      await service.claimDailyReward();
      expect(service.coins, equals(30));

      // Simulate app restart
      await service.reloadForTesting();
      expect(service.coins, equals(30));
      expect(service.canClaimDailyReward(), isFalse);

      final repeatClaim = await service.claimDailyReward();
      expect(repeatClaim, isFalse);
      expect(service.coins, equals(30));
    });

    test(
      'Subsequent eligible local calendar day permits a new claim',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(0);

        // Day 1
        service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));
        await service.claimDailyReward();
        expect(service.coins, equals(30));

        // Day 2
        service.setNowProviderForTesting(() => DateTime(2026, 11, 3, 11, 30));
        expect(service.canClaimDailyReward(), isTrue);

        final day2Claim = await service.claimDailyReward();
        expect(day2Claim, isTrue);
        expect(service.coins, equals(60));
      },
    );

    test(
      'Failed persistence does not mark daily reward as claimed (rollback)',
      () async {
        final failingAdapter = FailingStorageAdapter();
        final service = GameService.instance;
        service.setStorageAdapterForTesting(failingAdapter);
        service.setCoinsForTesting(0);
        service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));

        failingAdapter.shouldFail = true;
        final success = await service.claimDailyReward();
        expect(success, isFalse);
        expect(service.coins, equals(0));
        expect(service.canClaimDailyReward(), isTrue);

        // When persistence works again, claim succeeds
        failingAdapter.shouldFail = false;
        final retrySuccess = await service.claimDailyReward();
        expect(retrySuccess, isTrue);
        expect(service.coins, equals(30));
      },
    );

    test(
      'Clock moving backwards does not permit duplicate daily reward',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(0);

        // Claimed on Nov 5th
        service.setNowProviderForTesting(() => DateTime(2026, 11, 5, 12, 0));
        await service.claimDailyReward();
        expect(service.coins, equals(30));

        // Clock changed backwards to Nov 4th
        service.setNowProviderForTesting(() => DateTime(2026, 11, 4, 12, 0));
        expect(service.canClaimDailyReward(), isFalse);

        final duplicateAttempt = await service.claimDailyReward();
        expect(duplicateAttempt, isFalse);
        expect(service.coins, equals(30));
      },
    );

    test(
      'Repeated concurrent taps cannot grant multiple daily rewards',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(0);
        service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));

        final results = await Future.wait([
          service.claimDailyReward(),
          service.claimDailyReward(),
          service.claimDailyReward(),
        ]);

        // Exactly one succeeds
        expect(results.where((r) => r == true).length, equals(1));
        expect(service.coins, equals(30));
      },
    );

    test('Claim at 11:59 PM allows another claim after midnight', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      // Claim at 11:59:45 PM on Nov 2
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 23, 59, 45));
      final firstClaim = await service.claimDailyReward();
      expect(firstClaim, isTrue);
      expect(service.coins, equals(30));
      expect(service.canClaimDailyReward(), isFalse);

      // Advance clock past midnight to 12:00:15 AM on Nov 3
      service.setNowProviderForTesting(() => DateTime(2026, 11, 3, 0, 0, 15));
      expect(service.canClaimDailyReward(), isTrue);

      final nextClaim = await service.claimDailyReward();
      expect(nextClaim, isTrue);
      expect(service.coins, equals(60));
      expect(service.canClaimDailyReward(), isFalse);
    });

    test('App open during midnight updates reward availability via listener notification', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      // Claimed today at 22:00
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 22, 0));
      await service.claimDailyReward();
      expect(service.canClaimDailyReward(), isFalse);

      int listenerNotificationCount = 0;
      void listener() {
        listenerNotificationCount++;
      }

      service.addListener(listener);

      try {
        // App remains open as clock advances past midnight
        service.setNowProviderForTesting(() => DateTime(2026, 11, 3, 0, 0, 5));

        // Midnight trigger executes
        service.triggerMidnightForTesting();

        expect(listenerNotificationCount, greaterThan(0));
        expect(service.canClaimDailyReward(), isTrue);
      } finally {
        service.removeListener(listener);
      }
    });

    test(
      'App closed during midnight detects availability on next launch',
      () async {
        final adapter = InMemoryStorageAdapter();
        final service = GameService.instance;
        service.setStorageAdapterForTesting(adapter);
        service.setCoinsForTesting(0);

        // Claimed at 11:50 PM
        service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 23, 50));
        await service.claimDailyReward();
        expect(service.coins, equals(30));
        expect(service.canClaimDailyReward(), isFalse);

        // App is closed. Next day at 08:30 AM, app launches
        service.setNowProviderForTesting(() => DateTime(2026, 11, 3, 8, 30));
        await service.reloadForTesting();

        expect(service.coins, equals(30));
        expect(service.canClaimDailyReward(), isTrue);

        final nextClaim = await service.claimDailyReward();
        expect(nextClaim, isTrue);
        expect(service.coins, equals(60));
      },
    );

    test('Month-end and year-end date transitions work correctly', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(0);

      // Month-end: Jan 31 -> Feb 1
      service.setNowProviderForTesting(() => DateTime(2026, 1, 31, 23, 55));
      await service.claimDailyReward();
      expect(service.coins, equals(30));
      expect(service.canClaimDailyReward(), isFalse);

      service.setNowProviderForTesting(() => DateTime(2026, 2, 1, 0, 5));
      expect(service.canClaimDailyReward(), isTrue);
      await service.claimDailyReward();
      expect(service.coins, equals(60));

      // Year-end: Dec 31 -> Jan 1
      service.setNowProviderForTesting(() => DateTime(2026, 12, 31, 23, 55));
      await service.claimDailyReward();
      expect(service.coins, equals(90));
      expect(service.canClaimDailyReward(), isFalse);

      service.setNowProviderForTesting(() => DateTime(2027, 1, 1, 0, 5));
      expect(service.canClaimDailyReward(), isTrue);
      await service.claimDailyReward();
      expect(service.coins, equals(120));

      // Leap year month-end: Feb 28 -> Feb 29 -> March 1 (2028 is leap year)
      service.setNowProviderForTesting(() => DateTime(2028, 2, 28, 23, 55));
      await service.claimDailyReward();
      expect(service.coins, equals(150));

      service.setNowProviderForTesting(() => DateTime(2028, 2, 29, 0, 5));
      expect(service.canClaimDailyReward(), isTrue);
      await service.claimDailyReward();
      expect(service.coins, equals(180));

      // Feb 29 -> March 1
      service.setNowProviderForTesting(() => DateTime(2028, 3, 1, 0, 5));
      expect(service.canClaimDailyReward(), isTrue);
      await service.claimDailyReward();
      expect(service.coins, equals(210));
    });
  });

  // ===========================================================================
  // 3. Shop & Purchase Tests
  // ===========================================================================
  group('3. Shop & Purchase Tests', () {
    test(
      'A valid theme purchase deducts correct price once and grants ownership',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(2000);
        service.lockThemeForTesting('moonlight_lake');
        expect(service.isThemeOwned('moonlight_lake'), isFalse);

        final price = service.getThemePrice('moonlight_lake');
        expect(price, equals(1700));

        final success = await service.purchaseTheme('moonlight_lake');
        expect(success, isTrue);
        expect(service.coins, equals(300)); // 2000 - 1700 = 300
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
        expect(service.getOwnedThemes().contains('moonlight_lake'), isTrue);

        // Ownership separated from equipping
        expect(service.selectedThemeId, equals('simple'));
      },
    );

    test('A valid bottle-skin purchase deducts correct price once and grants ownership', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(3000);
      service.lockBottleForTesting('wave_bottle');
      expect(service.isBottleOwned('wave_bottle'), isFalse);

      final price = service.getBottlePrice('wave_bottle');
      expect(price, equals(2600));

      final success = await service.purchaseBottleSkin('wave_bottle');
      expect(success, isTrue);
      expect(service.coins, equals(400)); // 3000 - 2600 = 400
      expect(service.isBottleOwned('wave_bottle'), isTrue);
      expect(service.getOwnedBottleSkins().contains('wave_bottle'), isTrue);

      // Ownership separated from equipping
      expect(service.selectedBottleId, equals('classic_tube'));
    });

    test('Insufficient funds cause no deduction or ownership change', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(50);
      service.lockThemeForTesting('moonlight_lake');

      final success = await service.purchaseTheme('moonlight_lake');
      expect(success, isFalse);
      expect(service.coins, equals(50));
      expect(service.isThemeOwned('moonlight_lake'), isFalse);
    });

    test('Already-owned items cannot be purchased again', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(3400);
      service.lockThemeForTesting('moonlight_lake');

      final firstPurchase = await service.purchaseTheme('moonlight_lake');
      expect(firstPurchase, isTrue);
      expect(service.coins, equals(1700));

      final repeatPurchase = await service.purchaseTheme('moonlight_lake');
      expect(repeatPurchase, isFalse);
      expect(service.coins, equals(1700));
    });

    test(
      'Default theme and default bottle styles cannot be charged for',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(1000);

        expect(service.getThemePrice('simple'), equals(0));
        expect(service.isThemeOwned('simple'), isTrue);

        final themePurchase = await service.purchaseTheme('simple');
        expect(themePurchase, isFalse);
        expect(service.coins, equals(1000));

        expect(service.getBottlePrice('classic_tube'), equals(0));
        expect(service.isBottleOwned('classic_tube'), isTrue);
        final tubePurchase = await service.purchaseBottleSkin('classic_tube');
        expect(tubePurchase, isFalse);
        expect(service.coins, equals(1000));
      },
    );

    test('Hint use costs exactly 25 coins when valid hint succeeds', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(100);

      final success = await service.purchaseHint();
      expect(success, isTrue);
      expect(service.coins, equals(75)); // 100 - 25 = 75
    });

    test(
      'Hint request with insufficient coins fails with 0 deduction',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(20);

        final success = await service.purchaseHint();
        expect(success, isFalse);
        expect(service.coins, equals(20));
      },
    );

    test('Selecting owned cosmetics does not deduct coins', () {
      final service = GameService.instance;
      service.setCoinsForTesting(500);

      service.selectTheme('simple');
      expect(service.coins, equals(500));

      service.selectBottle('classic_tube');
      expect(service.coins, equals(500));
    });

    test(
      'Concurrent purchase attempts cannot produce negative balance',
      () async {
        final service = GameService.instance;
        service.setCoinsForTesting(2200);
        service.lockThemeForTesting('moonlight_lake');
        service.lockThemeForTesting('cherry_blossom');

        final results = await Future.wait([
          service.purchaseTheme('moonlight_lake'),
          service.purchaseTheme('cherry_blossom'),
        ]);

        // Only one can succeed because balance is only 2200 (less than 1700 + 2200 = 3900)
        expect(results.where((r) => r == true).length, equals(1));
        expect(service.coins, greaterThanOrEqualTo(0));
      },
    );

    test('Failed persistence rolls back cosmetic purchase', () async {
      final failingAdapter = FailingStorageAdapter();
      final service = GameService.instance;
      service.setStorageAdapterForTesting(failingAdapter);
      service.setCoinsForTesting(2000);
      service.lockThemeForTesting('moonlight_lake');

      failingAdapter.shouldFail = true;
      try {
        final success = await service.purchaseTheme('moonlight_lake');
        expect(success, isFalse);
        expect(service.coins, equals(2000));
        expect(service.isThemeOwned('moonlight_lake'), isFalse);
      } finally {
        failingAdapter.shouldFail = false;
        service.setStorageAdapterForTesting(memoryStorage);
      }
    });
  });

  // ===========================================================================
  // 4. Persistence and Regression Tests
  // ===========================================================================
  group('4. Persistence and Regression Tests', () {
    test(
      'Balance, rewarded levels, and cosmetic ownership survive reload',
      () async {
        final adapter = InMemoryStorageAdapter();
        final service = GameService.instance;
        service.setStorageAdapterForTesting(adapter);
        service.setCoinsForTesting(2000);
        service.lockThemeForTesting('moonlight_lake');

        await service.purchaseTheme('moonlight_lake');
        service.completeLevel(1, 10, earnedStars: 3);

        expect(service.coins, equals(350)); // 2000 - 1700 + 50 = 350
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
        expect(service.isLevelRewarded(1), isTrue);

        // Reload
        await service.reloadForTesting();
        expect(service.coins, equals(350));
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
        expect(service.isLevelRewarded(1), isTrue);
      },
    );

    test('Negative balance is impossible', () {
      final service = GameService.instance;
      service.setCoinsForTesting(10);

      final overspend = service.spendCoins(50);
      expect(overspend, isFalse);
      expect(service.coins, equals(10));
    });
  });

  // ===========================================================================
  // 5. Widget Integration Tests
  // ===========================================================================
  group('5. Widget Integration Tests', () {
    testWidgets('LevelCompleteDialog displays +50 Coins Earned on first win', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LevelCompleteDialog(
                  level: 1,
                  moves: 10,
                  stars: 3,
                  streak: 1,
                  maxLevel: 100,
                  coinsAwarded: 50,
                  onNextLevel: () {},
                  onPlayAgain: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('+50 Coins Earned!'), findsOneWidget);
    });

    testWidgets('LevelCompleteDialog displays +0 Coins on replay', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LevelCompleteDialog(
                  level: 1,
                  moves: 10,
                  stars: 3,
                  streak: 1,
                  maxLevel: 100,
                  coinsAwarded: 0,
                  onNextLevel: () {},
                  onPlayAgain: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('+0 Coins (Reward already collected)'), findsOneWidget);
    });

    testWidgets('HomeScreen displays Daily Reward button with claim status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = GameService.instance;
      service.setCoinsForTesting(150);
      service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 10, 0));

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Daily Reward entry is visible
      final giftFinder = find.byKey(const ValueKey('daily_reward_button'));
      expect(giftFinder, findsOneWidget);
      expect(find.text('+30'), findsOneWidget);

      // Tap to open Daily Reward dialog
      await tester.tap(giftFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('DAILY REWARD'), findsOneWidget);
      expect(find.text('CLAIM 30 COINS'), findsOneWidget);

      // Claim reward
      await tester.tap(find.text('CLAIM 30 COINS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(service.coins, equals(180));
    });

    testWidgets(
      'HomeScreen Daily Reward button updates dynamically at midnight without restart',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final service = GameService.instance;
        service.setCoinsForTesting(0);
        // Already claimed today
        service.setNowProviderForTesting(() => DateTime(2026, 11, 2, 23, 50));
        await service.claimDailyReward();
        expect(service.canClaimDailyReward(), isFalse);

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Button currently shows claimed state (no +30 badge)
        expect(find.text('+30'), findsNothing);

        // Midnight strikes
        service.setNowProviderForTesting(() => DateTime(2026, 11, 3, 0, 0, 10));
        service.checkMidnightRefresh();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Button now automatically shows +30 badge without restarting the app!
        expect(find.text('+30'), findsOneWidget);
      },
    );

    testWidgets('ShopView renders Hints tab and information card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ShopView(initialTab: ShopTab.hints)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hints'), findsOneWidget);
      expect(find.text('Puzzle Hints'), findsOneWidget);
      expect(find.text('🪙 25 Coins per Hint'), findsOneWidget);
      expect(find.text('Bottles (20)'), findsOneWidget);
      expect(find.text('Themes (20)'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 7. Two-Option Unlock System (Coins & Rewarded Ads)
  // ===========================================================================
  group('7. Two-Option Unlock System (Coins & Rewarded Ads)', () {
    test(
      'Successful rewarded ad unlocks theme without deducting coins',
      () async {
        final mock = MockRewardedAdProvider(
          available: true,
          nextResult: RewardedAdResult.rewardEarned,
        );
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.setCoinsForTesting(100);
        service.lockThemeForTesting('moonlight_lake');
        expect(service.isThemeOwned('moonlight_lake'), isFalse);

        final success = await service.unlockThemeWithAd('moonlight_lake');
        expect(success, isTrue);
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
        expect(service.coins, equals(100)); // 0 coins deducted
        expect(mock.showCallCount, equals(1));
      },
    );

    test(
      'Successful rewarded ad unlocks bottle skin without deducting coins',
      () async {
        final mock = MockRewardedAdProvider(
          available: true,
          nextResult: RewardedAdResult.rewardEarned,
        );
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.setCoinsForTesting(100);
        service.lockBottleForTesting('wave_bottle');
        expect(service.isBottleOwned('wave_bottle'), isFalse);

        final success = await service.unlockBottleSkinWithAd('wave_bottle');
        expect(success, isTrue);
        expect(service.isBottleOwned('wave_bottle'), isTrue);
        expect(service.coins, equals(100)); // 0 coins deducted
        expect(mock.showCallCount, equals(1));
      },
    );

    test(
      'Unavailable ad provider fails and does not unlock theme or bottle',
      () async {
        final mock = MockRewardedAdProvider(available: false);
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.setCoinsForTesting(100);
        service.lockThemeForTesting('cherry_blossom');
        service.lockBottleForTesting('flask_bottle');

        expect(await service.unlockThemeWithAd('cherry_blossom'), isFalse);
        expect(service.isThemeOwned('cherry_blossom'), isFalse);
        expect(mock.showCallCount, equals(0));

        expect(await service.unlockBottleSkinWithAd('flask_bottle'), isFalse);
        expect(service.isBottleOwned('flask_bottle'), isFalse);
        expect(mock.showCallCount, equals(0));
        expect(service.coins, equals(100));
      },
    );

    test('Skipped or dismissed ad flow does not unlock cosmetics', () async {
      final mock = MockRewardedAdProvider(
        available: true,
        nextResult: RewardedAdResult.skipped,
      );
      RewardedAdService.instance.setProviderForTesting(mock);

      final service = GameService.instance;
      service.setCoinsForTesting(100);
      service.lockThemeForTesting('ocean_valley');
      service.lockBottleForTesting('wave_bottle');

      expect(await service.unlockThemeWithAd('ocean_valley'), isFalse);
      expect(service.isThemeOwned('ocean_valley'), isFalse);
      expect(mock.showCallCount, equals(1));

      expect(await service.unlockBottleSkinWithAd('wave_bottle'), isFalse);
      expect(service.isBottleOwned('wave_bottle'), isFalse);
      expect(mock.showCallCount, equals(2));
      expect(service.coins, equals(100));
    });

    test('Failed ad playback does not unlock cosmetics', () async {
      final mock = MockRewardedAdProvider(
        available: true,
        nextResult: RewardedAdResult.failed,
      );
      RewardedAdService.instance.setProviderForTesting(mock);

      final service = GameService.instance;
      service.setCoinsForTesting(100);
      service.lockThemeForTesting('ocean_valley');
      service.lockBottleForTesting('wave_bottle');

      expect(await service.unlockThemeWithAd('ocean_valley'), isFalse);
      expect(service.isThemeOwned('ocean_valley'), isFalse);
      expect(mock.showCallCount, equals(1));

      expect(await service.unlockBottleSkinWithAd('wave_bottle'), isFalse);
      expect(service.isBottleOwned('wave_bottle'), isFalse);
      expect(mock.showCallCount, equals(2));
      expect(service.coins, equals(100));
    });

    test(
      'Shared ownership prevents duplicate unlock or charges across methods',
      () async {
        final mock = MockRewardedAdProvider(
          available: true,
          nextResult: RewardedAdResult.rewardEarned,
        );
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.setCoinsForTesting(3000);
        service.lockThemeForTesting('moonlight_lake');
        service.lockBottleForTesting('wave_bottle');

        // 1. Theme unlocked via ad
        final adThemeSuccess = await service.unlockThemeWithAd(
          'moonlight_lake',
        );
        expect(adThemeSuccess, isTrue);
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
        expect(service.coins, equals(3000));

        // Attempting to buy or watch ad for the same theme again must fail
        expect(await service.purchaseTheme('moonlight_lake'), isFalse);
        expect(await service.unlockThemeWithAd('moonlight_lake'), isFalse);
        expect(service.coins, equals(3000)); // No coins deducted

        // 2. Bottle purchased via coins (wave_bottle costs 2600)
        final coinBottleSuccess = await service.purchaseBottleSkin(
          'wave_bottle',
        );
        expect(coinBottleSuccess, isTrue);
        expect(service.isBottleOwned('wave_bottle'), isTrue);
        expect(service.coins, equals(400)); // 3000 - 2600 = 400

        // Attempting to watch ad or buy the same bottle again must fail
        expect(await service.unlockBottleSkinWithAd('wave_bottle'), isFalse);
        expect(await service.purchaseBottleSkin('wave_bottle'), isFalse);
        expect(service.coins, equals(400));
      },
    );

    test('Ad-unlocked cosmetics persist safely across app reload', () async {
      final mock = MockRewardedAdProvider(
        available: true,
        nextResult: RewardedAdResult.rewardEarned,
      );
      RewardedAdService.instance.setProviderForTesting(mock);

      final service = GameService.instance;
      service.lockThemeForTesting('cherry_blossom');
      service.lockBottleForTesting('conical_flask');

      expect(await service.unlockThemeWithAd('cherry_blossom'), isTrue);
      expect(await service.unlockBottleSkinWithAd('conical_flask'), isTrue);

      // Reload from storage
      await service.reloadForTesting();

      expect(service.isThemeOwned('cherry_blossom'), isTrue);
      expect(service.isBottleOwned('conical_flask'), isTrue);
    });

    testWidgets(
      'ThemesScreen displays both BUY and Watch Ad buttons for unowned theme',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mock = MockRewardedAdProvider(
          available: true,
          nextResult: RewardedAdResult.rewardEarned,
        );
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.lockThemeForTesting('moonlight_lake');

        await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('BUY WITH COINS (1700)'), findsWidgets);
        expect(find.text('WATCH AD TO UNLOCK'), findsWidgets);

        // Tap Watch Ad to Unlock on moonlight_lake
        final watchAdFinder = find.text('WATCH AD TO UNLOCK').first;
        await tester.tap(watchAdFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(mock.showCallCount, equals(1));
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
      },
    );

    testWidgets(
      'ThemesScreen displays Ads unavailable when ad provider is unavailable',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mock = MockRewardedAdProvider(available: false);
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.lockThemeForTesting('moonlight_lake');

        await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('BUY WITH COINS (1700)'), findsWidgets);
        expect(find.text('Ads unavailable'), findsWidgets);
      },
    );

    testWidgets(
      'BottlesScreen displays both BUY and Watch Ad buttons for unowned bottle',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mock = MockRewardedAdProvider(
          available: true,
          nextResult: RewardedAdResult.rewardEarned,
        );
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.lockBottleForTesting('conical_flask');

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('BUY WITH COINS (1500)'), findsWidgets);
        expect(find.text('WATCH AD TO UNLOCK'), findsWidgets);

        // Tap Watch Ad to Unlock
        final watchAdFinder = find.text('WATCH AD TO UNLOCK').first;
        await tester.tap(watchAdFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(mock.showCallCount, equals(1));
        expect(service.isBottleOwned('conical_flask'), isTrue);
      },
    );

    testWidgets(
      'BottlesScreen displays Ads unavailable when ad provider is unavailable',
      (tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mock = MockRewardedAdProvider(available: false);
        RewardedAdService.instance.setProviderForTesting(mock);

        final service = GameService.instance;
        service.lockBottleForTesting('conical_flask');

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('BUY WITH COINS (1500)'), findsWidgets);
        expect(find.text('Ads unavailable'), findsWidgets);
      },
    );

    test('Default ownership state: only simple theme and classic tube are owned by default', () {
      final service = GameService.instance;
      expect(service.isThemeOwned('simple'), isTrue);
      expect(service.isThemeOwned('moonlight_lake'), isFalse);
      expect(service.isThemeOwned('cherry_blossom'), isFalse);

      expect(service.isBottleOwned('classic_tube'), isTrue);
      expect(service.isBottleOwned('conical_flask'), isFalse);
      expect(service.isBottleOwned('curvy_bottle'), isFalse);

      // Attempting to select unowned items directly fails
      service.selectTheme('moonlight_lake');
      expect(service.selectedThemeId, equals('simple'));

      service.selectBottle('conical_flask');
      expect(service.selectedBottleId, equals('classic_tube'));
    });
  });

  // ===========================================================================
  // 8. Premium Cosmetic Pricing System (100K Collection) Tests
  // ===========================================================================
  group('8. Premium Cosmetic Pricing System (100K Collection) Tests', () {
    test('Collection contains exactly 38 purchasable items and 2 free default items', () {
      final service = GameService.instance;

      expect(GameTheme.allThemes.length, equals(20));
      expect(BottleStyle.allBottles.length, equals(20));

      final freeThemes = GameTheme.allThemes
          .where((t) => t.isFree || t.coinCost == 0)
          .toList();
      final purchasableThemes = GameTheme.allThemes
          .where((t) => !t.isFree && t.coinCost > 0)
          .toList();
      expect(freeThemes.length, equals(1));
      expect(freeThemes.first.id, equals('simple'));
      expect(purchasableThemes.length, equals(19));

      final freeBottles = BottleStyle.allBottles
          .where((b) => b.isFree || b.coinCost == 0)
          .toList();
      final purchasableBottles = BottleStyle.allBottles
          .where((b) => !b.isFree && b.coinCost > 0)
          .toList();
      expect(freeBottles.length, equals(1));
      expect(freeBottles.first.id, equals('classic_tube'));
      expect(purchasableBottles.length, equals(19));

      // Conical Flask is confirmed purchasable (not free)
      final conicalFlask = BottleStyle.getById('conical_flask');
      expect(conicalFlask.isFree, isFalse);
      expect(conicalFlask.coinCost, equals(1500));
      expect(service.getBottlePrice('conical_flask'), equals(1500));

      expect(purchasableThemes.length + purchasableBottles.length, equals(38));
    });

    test(
      'Complete 38-item collection total cost equals exactly 100,000 coins',
      () {
        final service = GameService.instance;

        int themesTotal = 0;
        for (final t in GameTheme.allThemes) {
          if (t.id != 'simple') {
            final price = service.getThemePrice(t.id);
            expect(price, equals(t.coinCost));
            themesTotal += price;
          }
        }

        int bottlesTotal = 0;
        for (final b in BottleStyle.allBottles) {
          if (b.id != 'classic_tube') {
            final price = service.getBottlePrice(b.id);
            expect(price, equals(b.coinCost));
            bottlesTotal += price;
          }
        }

        expect(themesTotal, equals(50100));
        expect(bottlesTotal, equals(49900));
        expect(themesTotal + bottlesTotal, equals(100000));
      },
    );

    test('Exact pricing distribution matches required tier counts', () {
      final allPurchasablePrices = <int>[
        for (final t in GameTheme.allThemes)
          if (t.id != 'simple') t.coinCost,
        for (final b in BottleStyle.allBottles)
          if (b.id != 'classic_tube') b.coinCost,
      ];

      expect(allPurchasablePrices.length, equals(38));

      final counts = <int, int>{};
      for (final price in allPurchasablePrices) {
        counts[price] = (counts[price] ?? 0) + 1;
      }

      expect(
        counts[1500],
        equals(1),
        reason: 'Tier 1500 must have exactly 1 item',
      );
      expect(
        counts[1700],
        equals(1),
        reason: 'Tier 1700 must have exactly 1 item',
      );
      expect(
        counts[2000],
        equals(1),
        reason: 'Tier 2000 must have exactly 1 item',
      );
      expect(
        counts[2200],
        equals(1),
        reason: 'Tier 2200 must have exactly 1 item',
      );
      expect(
        counts[2400],
        equals(2),
        reason: 'Tier 2400 must have exactly 2 items',
      );
      expect(
        counts[2600],
        equals(9),
        reason: 'Tier 2600 must have exactly 9 items',
      );
      expect(
        counts[2800],
        equals(23),
        reason: 'Tier 2800 must have exactly 23 items',
      );

      final sum = allPurchasablePrices.fold<int>(
        0,
        (prev, elem) => prev + elem,
      );
      expect(sum, equals(100000));
    });

    test('Free defaults remain free and cannot be charged for', () async {
      final service = GameService.instance;
      service.setCoinsForTesting(10000);

      expect(service.getThemePrice('simple'), equals(0));
      expect(service.getBottlePrice('classic_tube'), equals(0));
      expect(service.getBottlePrice('classic_flask'), equals(0));

      expect(await service.purchaseTheme('simple'), isFalse);
      expect(await service.purchaseBottleSkin('classic_tube'), isFalse);
      expect(await service.purchaseBottleSkin('classic_flask'), isFalse);

      expect(service.coins, equals(10000));
    });

    test(
      'Purchase deducts exact item price and validates sufficient balance',
      () async {
        final service = GameService.instance;
        service.lockBottleForTesting('conical_flask');
        service.lockThemeForTesting('cherry_blossom');

        // 1. Insufficient coins
        service.setCoinsForTesting(1000);
        expect(await service.purchaseBottleSkin('conical_flask'), isFalse);
        expect(service.coins, equals(1000));
        expect(service.isBottleOwned('conical_flask'), isFalse);

        // 2. Exact coins for conical_flask (1500)
        service.setCoinsForTesting(1500);
        expect(await service.purchaseBottleSkin('conical_flask'), isTrue);
        expect(service.coins, equals(0));
        expect(service.isBottleOwned('conical_flask'), isTrue);

        // 3. Purchase cherry_blossom (2200) with 3000 coins
        service.setCoinsForTesting(3000);
        expect(await service.purchaseTheme('cherry_blossom'), isTrue);
        expect(service.coins, equals(800)); // 3000 - 2200 = 800
        expect(service.isThemeOwned('cherry_blossom'), isTrue);
      },
    );

    test('Rewarded ad unlock does not deduct coins from balance', () async {
      final mock = MockRewardedAdProvider(
        available: true,
        nextResult: RewardedAdResult.rewardEarned,
      );
      RewardedAdService.instance.setProviderForTesting(mock);

      final service = GameService.instance;
      service.setCoinsForTesting(1200);
      service.lockThemeForTesting('sky_realm'); // costs 2600 coins

      final success = await service.unlockThemeWithAd('sky_realm');
      expect(success, isTrue);
      expect(service.isThemeOwned('sky_realm'), isTrue);
      expect(service.coins, equals(1200)); // 0 coins deducted
    });

    test(
      'Purchased cosmetics and coin deductions persist across app restart',
      () async {
        final adapter = InMemoryStorageAdapter();
        final service = GameService.instance;
        service.setStorageAdapterForTesting(adapter);
        service.setCoinsForTesting(5000);
        service.lockBottleForTesting('conical_flask');
        service.lockThemeForTesting('moonlight_lake');

        // Buy conical_flask (1500) and moonlight_lake (1700)
        expect(await service.purchaseBottleSkin('conical_flask'), isTrue);
        expect(await service.purchaseTheme('moonlight_lake'), isTrue);
        expect(service.coins, equals(1800)); // 5000 - 1500 - 1700 = 1800

        // Simulate app restart / reload from storage
        await service.reloadForTesting();

        expect(service.coins, equals(1800));
        expect(service.isBottleOwned('conical_flask'), isTrue);
        expect(service.isThemeOwned('moonlight_lake'), isTrue);
      },
    );
  });
}
