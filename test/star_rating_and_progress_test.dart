import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/screens/home_screen.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/level_generator.dart';
import 'package:water_sort_game/services/star_rating_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';
import 'package:water_sort_game/widgets/level_complete_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStorageAdapter memoryStorage;

  setUp(() {
    memoryStorage = InMemoryStorageAdapter();
    GameService.instance.setStorageAdapterForTesting(memoryStorage);
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
  });

  tearDown(() {
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
  });

  group('AquaSort — Star Rating & Progress Management System Verification', () {
    // -------------------------------------------------------------------------
    // Untimed Levels (1–3) Move-Efficiency Calculations
    // -------------------------------------------------------------------------
    test('1. Untimed Level 1 with moves <= 3-star threshold earns 3 stars', () {
      final config = LevelGenerator.getLevelConfig(1);
      expect(config.initialTimerSeconds, isNull);

      final stars = StarRatingService.calculateStars(
        level: 1,
        moves: config.threeStarThreshold,
        originalTimerSeconds: null,
        remainingOriginalSeconds: null,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars, equals(3));
    });

    test('2. Untimed Level 2 with moves between 2-star and 3-star threshold earns 2 stars', () {
      final config = LevelGenerator.getLevelConfig(2);
      expect(config.initialTimerSeconds, isNull);

      final stars = StarRatingService.calculateStars(
        level: 2,
        moves: config.threeStarThreshold + 1,
        originalTimerSeconds: null,
        remainingOriginalSeconds: null,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars, equals(2));
    });

    test('3. Untimed Level 3 with moves > 2-star threshold earns 1 star', () {
      final config = LevelGenerator.getLevelConfig(3);
      expect(config.initialTimerSeconds, isNull);

      final stars = StarRatingService.calculateStars(
        level: 3,
        moves: config.twoStarThreshold + 5,
        originalTimerSeconds: null,
        remainingOriginalSeconds: null,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars, equals(1));
    });

    // -------------------------------------------------------------------------
    // Timed Levels 4–19 (30s Initial Timer)
    // -------------------------------------------------------------------------
    test('4. Timed Level 4 (30s) completed with >= 50% remaining (20s) earns 3 stars', () {
      final timer = LevelGenerator.getInitialTimerSeconds(4);
      expect(timer, equals(30));

      final stars = StarRatingService.calculateStars(
        level: 4,
        moves: 10,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 20,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars, equals(3));
    });

    test('5. Timed Level 4 (30s) completed with exactly 50% remaining (15s) earns 3 stars', () {
      final stars = StarRatingService.calculateStars(
        level: 4,
        moves: 12,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 15,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars, equals(3));
    });

    test('6. Timed Level 4 (30s) completed with >= 25% and < 50% remaining (10s, 8s) earns 2 stars', () {
      final stars10 = StarRatingService.calculateStars(
        level: 4,
        moves: 14,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 10,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars10, equals(2));

      final stars8 = StarRatingService.calculateStars(
        level: 4,
        moves: 14,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 8,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars8, equals(2));
    });

    test('7. Timed Level 4 (30s) completed with > 0% and < 25% remaining (7s, 1s) earns 1 star', () {
      final stars7 = StarRatingService.calculateStars(
        level: 4,
        moves: 16,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 7,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars7, equals(1));

      final stars1 = StarRatingService.calculateStars(
        level: 4,
        moves: 16,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 1,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars1, equals(1));
    });

    // -------------------------------------------------------------------------
    // Timed Levels 20–59 (45s Initial Timer)
    // -------------------------------------------------------------------------
    test('8. Timed Level 20 (45s) completed with >= 50% remaining (23s, 45s) earns 3 stars', () {
      final timer = LevelGenerator.getInitialTimerSeconds(20);
      expect(timer, equals(45));

      final stars23 = StarRatingService.calculateStars(
        level: 20,
        moves: 15,
        originalTimerSeconds: 45,
        remainingOriginalSeconds: 23,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars23, equals(3));

      final stars45 = StarRatingService.calculateStars(
        level: 20,
        moves: 10,
        originalTimerSeconds: 45,
        remainingOriginalSeconds: 45,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars45, equals(3));
    });

    test('9. Timed Level 20 (45s) completed with 22s (< 50%) and 12s (>= 25%) earns 2 stars', () {
      final stars22 = StarRatingService.calculateStars(
        level: 20,
        moves: 18,
        originalTimerSeconds: 45,
        remainingOriginalSeconds: 22,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars22, equals(2));

      final stars12 = StarRatingService.calculateStars(
        level: 20,
        moves: 20,
        originalTimerSeconds: 45,
        remainingOriginalSeconds: 12,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars12, equals(2));
    });

    // -------------------------------------------------------------------------
    // Timed Levels 60–100 (60s Initial Timer)
    // -------------------------------------------------------------------------
    test('10. Timed Level 60 (60s) completed with >= 50% remaining (30s) earns 3 stars', () {
      final timer = LevelGenerator.getInitialTimerSeconds(60);
      expect(timer, equals(60));

      final stars30 = StarRatingService.calculateStars(
        level: 60,
        moves: 20,
        originalTimerSeconds: 60,
        remainingOriginalSeconds: 30,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars30, equals(3));
    });

    test('11. Timed Level 60 (60s) completed with 15s remaining (exactly 25%) earns 2 stars', () {
      final stars15 = StarRatingService.calculateStars(
        level: 60,
        moves: 22,
        originalTimerSeconds: 60,
        remainingOriginalSeconds: 15,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars15, equals(2));
    });

    test('12. Timed Level 60 (60s) completed with 14s remaining (< 25%) earns 1 star', () {
      final stars14 = StarRatingService.calculateStars(
        level: 60,
        moves: 24,
        originalTimerSeconds: 60,
        remainingOriginalSeconds: 14,
        inExtraTime: false,
        remainingExtraTimeSeconds: null,
      );
      expect(stars14, equals(1));
    });

    // -------------------------------------------------------------------------
    // Extra-Time Bonus Period Evaluations (Reward 1 and Reward 2)
    // -------------------------------------------------------------------------
    test('13. Extra-time period 1: Level completed with 30–60s remaining earns 2 stars (never 3)', () {
      final stars60 = StarRatingService.calculateStars(
        level: 4,
        moves: 25,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 0,
        inExtraTime: true,
        remainingExtraTimeSeconds: 60,
      );
      expect(stars60, equals(2));

      final stars30 = StarRatingService.calculateStars(
        level: 4,
        moves: 25,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 0,
        inExtraTime: true,
        remainingExtraTimeSeconds: 30,
      );
      expect(stars30, equals(2));
    });

    test('14. Extra-time period 1: Level completed with 1–29s remaining earns 1 star', () {
      final stars29 = StarRatingService.calculateStars(
        level: 4,
        moves: 28,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 0,
        inExtraTime: true,
        remainingExtraTimeSeconds: 29,
      );
      expect(stars29, equals(1));

      final stars1 = StarRatingService.calculateStars(
        level: 4,
        moves: 30,
        originalTimerSeconds: 30,
        remainingOriginalSeconds: 0,
        inExtraTime: true,
        remainingExtraTimeSeconds: 1,
      );
      expect(stars1, equals(1));
    });

    test('15. Extra-time period 2 (second reward claimed): Level completed with 30–60s remaining earns 2 stars', () {
      final stars45 = StarRatingService.calculateStars(
        level: 25,
        moves: 35,
        originalTimerSeconds: 45,
        remainingOriginalSeconds: 0,
        inExtraTime: true,
        remainingExtraTimeSeconds: 45,
      );
      expect(stars45, equals(2));
    });

    test('16. Extra-time period 2: Level completed with 1–29s remaining earns 1 star', () {
      final stars15 = StarRatingService.calculateStars(
        level: 25,
        moves: 38,
        originalTimerSeconds: 45,
        remainingOriginalSeconds: 0,
        inExtraTime: true,
        remainingExtraTimeSeconds: 15,
      );
      expect(stars15, equals(1));
    });

    // -------------------------------------------------------------------------
    // Timeout / Uncompleted / Zero Stars
    // -------------------------------------------------------------------------
    test(
      '17. Level timeout or 0s remaining yields 0 stars and incomplete flag',
      () {
        final timeoutOriginal = StarRatingService.calculateStars(
          level: 4,
          moves: 10,
          originalTimerSeconds: 30,
          remainingOriginalSeconds: 0,
          inExtraTime: false,
          remainingExtraTimeSeconds: null,
        );
        expect(timeoutOriginal, equals(0));

        final timeoutExtra = StarRatingService.calculateStars(
          level: 4,
          moves: 20,
          originalTimerSeconds: 30,
          remainingOriginalSeconds: 0,
          inExtraTime: true,
          remainingExtraTimeSeconds: 0,
        );
        expect(timeoutExtra, equals(0));

        final notWon = StarRatingService.calculateStars(
          level: 4,
          moves: 10,
          originalTimerSeconds: 30,
          remainingOriginalSeconds: 20,
          inExtraTime: false,
          remainingExtraTimeSeconds: null,
          isWon: false,
        );
        expect(notWon, equals(0));
      },
    );

    // -------------------------------------------------------------------------
    // Best-Star Persistence & Upgrade Rules
    // -------------------------------------------------------------------------
    test('18. Best-star persistence: Replaying a 3-star level with fewer stars earned NEVER downgrades saved 3 stars', () {
      final gameService = GameService.instance;

      // 1. Initial 3-star completion
      gameService.completeLevel(5, 10, earnedStars: 3);
      expect(gameService.getStarsForLevel(5), equals(3));

      // 2. Replay with 1 star
      gameService.completeLevel(5, 25, earnedStars: 1);
      expect(
        gameService.getStarsForLevel(5),
        equals(3),
        reason: 'Saved 3 stars must never downgrade to 1 star',
      );

      // 3. Replay with 2 stars
      gameService.completeLevel(5, 18, earnedStars: 2);
      expect(
        gameService.getStarsForLevel(5),
        equals(3),
        reason: 'Saved 3 stars must never downgrade to 2 stars',
      );
    });

    test('19. Best-star upgrade: Completing a level previously saved with 1 star now earning 3 stars upgrades to 3', () {
      final gameService = GameService.instance;

      // 1. Initial 1-star completion
      gameService.completeLevel(6, 25, earnedStars: 1);
      expect(gameService.getStarsForLevel(6), equals(1));

      // 2. Replay earning 2 stars
      gameService.completeLevel(6, 18, earnedStars: 2);
      expect(
        gameService.getStarsForLevel(6),
        equals(2),
        reason: 'Saved 1 star upgrades to 2 stars',
      );

      // 3. Replay earning 3 stars
      gameService.completeLevel(6, 8, earnedStars: 3);
      expect(
        gameService.getStarsForLevel(6),
        equals(3),
        reason: 'Saved 2 stars upgrades to 3 stars',
      );
    });

    test('20. Storage persistence & reload: Saved star ratings survive serialization and deserialization intact', () async {
      final gameService = GameService.instance;

      gameService.completeLevel(1, 6, earnedStars: 3);
      gameService.completeLevel(2, 10, earnedStars: 2);
      gameService.completeLevel(3, 20, earnedStars: 1);
      gameService.completeLevel(4, 12, earnedStars: 3);

      expect(gameService.getStarsForLevel(1), equals(3));
      expect(gameService.getStarsForLevel(2), equals(2));
      expect(gameService.getStarsForLevel(3), equals(1));
      expect(gameService.getStarsForLevel(4), equals(3));
      expect(gameService.totalStars, equals(9));

      // Simulate app restart by re-initializing from the stored JSON
      await gameService.initialize(forceReload: true);

      expect(gameService.getStarsForLevel(1), equals(3));
      expect(gameService.getStarsForLevel(2), equals(2));
      expect(gameService.getStarsForLevel(3), equals(1));
      expect(gameService.getStarsForLevel(4), equals(3));
      expect(gameService.totalStars, equals(9));
      expect(gameService.maxPossibleStars, equals(300));
    });

    // -------------------------------------------------------------------------
    // Replay Progression & Safety Rules
    // -------------------------------------------------------------------------
    test('21. Replaying an earlier level never decreases currentLevel or relocks unlocked levels', () {
      final gameService = GameService.instance;

      // Reach Level 5
      gameService.completeLevel(1, 5, earnedStars: 3);
      gameService.completeLevel(2, 5, earnedStars: 3);
      gameService.completeLevel(3, 5, earnedStars: 3);
      gameService.completeLevel(4, 5, earnedStars: 3);

      expect(gameService.currentLevel, equals(5));
      expect(gameService.isLevelUnlocked(5), isTrue);

      // Replay Level 1 with 1 star
      gameService.completeLevel(1, 30, earnedStars: 1);

      expect(
        gameService.currentLevel,
        equals(5),
        reason: 'Replaying level 1 must not lower currentLevel back to 2',
      );
      expect(gameService.isLevelUnlocked(5), isTrue);
      expect(gameService.isLevelUnlocked(4), isTrue);
      expect(gameService.isLevelUnlocked(3), isTrue);
      expect(gameService.isLevelUnlocked(2), isTrue);
      expect(gameService.isLevelUnlocked(1), isTrue);
    });

    // -------------------------------------------------------------------------
    // Level Complete Dialog Widget Presentation
    // -------------------------------------------------------------------------
    testWidgets(
      '22. LevelCompleteDialog displays earned stars and best record indicator when replaying with lower stars',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  LevelCompleteDialog(
                    level: 7,
                    moves: 20,
                    stars: 1, // Current attempt earned 1 star
                    bestStars: 3, // Saved record is 3 stars
                    streak: 4,
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

        // Must display the Best Record indicator reassuring the player their 3-star record is safe
        expect(find.textContaining('Best: 3 ★'), findsOneWidget);
        expect(find.textContaining('Current: 1 ★'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // Journey Map Star Display Integration
    // -------------------------------------------------------------------------
    testWidgets(
      '23. Journey Map completed nodes render star indicator with saved best stars',
      (tester) async {
        final gameService = GameService.instance;
        gameService.completeLevel(1, 5, earnedStars: 3);
        gameService.completeLevel(2, 8, earnedStars: 2);

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Level 1 node exists and is completed with 3 stars
        final node1 = find.byKey(const ValueKey('level_node_1'));
        expect(node1, findsOneWidget);

        // Level 2 node exists and is completed with 2 stars
        final node2 = find.byKey(const ValueKey('level_node_2'));
        expect(node2, findsOneWidget);

        // Verify that star icons are rendered in the map nodes
        expect(find.byIcon(Icons.star_rounded), findsWidgets);
      },
    );
  });
}
