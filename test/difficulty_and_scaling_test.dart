import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/level_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GameService.instance.resetProgress();
  });

  group('AquaSort — 100-Level Progressive Difficulty', () {
    test('1. Every level 1..100 has a valid config and bottle count between 5 and 12', () {
      for (int level = 1; level <= 100; level++) {
        final config = LevelGenerator.getLevelConfig(level);
        expect(config.level, equals(level));
        expect(config.bottleCount, greaterThanOrEqualTo(5));
        expect(config.bottleCount, lessThanOrEqualTo(12));
        expect(config.emptyCount, equals(2));
        expect(config.colorCount, equals(config.bottleCount - 2));
      }
    });

    test('2. Bottle counts are monotonically non-decreasing and never jump by 2 or more', () {
      int prevBottles = LevelGenerator.getBottleCount(1);
      expect(prevBottles, equals(5));

      for (int level = 2; level <= 100; level++) {
        final int currentBottles = LevelGenerator.getBottleCount(level);
        expect(
          currentBottles,
          greaterThanOrEqualTo(prevBottles),
          reason:
              'Level $level bottles ($currentBottles) decreased from level ${level - 1} ($prevBottles)',
        );
        expect(
          currentBottles - prevBottles,
          lessThanOrEqualTo(1),
          reason:
              'Level $level bottles jumped by more than 1 from level ${level - 1}',
        );
        prevBottles = currentBottles;
      }
      expect(prevBottles, equals(12));
    });

    test('3. Difficulty tiers map correctly across all 100 levels', () {
      // Levels 1–10: Easy (5–7 bottles, 3–5 colors)
      for (int l = 1; l <= 10; l++) {
        final config = LevelGenerator.getLevelConfig(l);
        expect(config.tier, equals(DifficultyTier.easy));
        expect(config.tierName, equals('Easy'));
        expect(config.chapterTitle, contains('Chapter 1'));
        expect(config.bottleCount, inInclusiveRange(5, 7));
      }

      // Levels 11–20: Medium (7–8 bottles, 5–6 colors)
      for (int l = 11; l <= 20; l++) {
        final config = LevelGenerator.getLevelConfig(l);
        expect(config.tier, equals(DifficultyTier.medium));
        expect(config.tierName, equals('Medium'));
        expect(config.chapterTitle, contains('Chapter 2'));
        expect(config.bottleCount, inInclusiveRange(7, 8));
      }

      // Levels 21–30: Hard (9–10 bottles, 7–8 colors)
      for (int l = 21; l <= 30; l++) {
        final config = LevelGenerator.getLevelConfig(l);
        expect(config.tier, equals(DifficultyTier.hard));
        expect(config.tierName, equals('Hard'));
        expect(config.chapterTitle, contains('Chapter 3'));
        expect(config.bottleCount, inInclusiveRange(9, 10));
      }

      // Levels 31–40: Very Hard (10–11 bottles, 8–9 colors)
      for (int l = 31; l <= 40; l++) {
        final config = LevelGenerator.getLevelConfig(l);
        expect(config.tier, equals(DifficultyTier.veryHard));
        expect(config.tierName, equals('Very Hard'));
        expect(config.chapterTitle, contains('Chapter 4'));
        expect(config.bottleCount, inInclusiveRange(10, 11));
      }

      // Levels 41–50: Expert (11–12 bottles, 9–10 colors)
      for (int l = 41; l <= 50; l++) {
        final config = LevelGenerator.getLevelConfig(l);
        expect(config.tier, equals(DifficultyTier.expert));
        expect(config.tierName, equals('Expert'));
        expect(config.chapterTitle, contains('Chapter 5'));
        expect(config.bottleCount, inInclusiveRange(11, 12));
      }

      // Levels 51–100: Expert Chapters 6..10 (12 bottles, 10 colors)
      for (int l = 51; l <= 100; l++) {
        final config = LevelGenerator.getLevelConfig(l);
        expect(config.tier, equals(DifficultyTier.expert));
        expect(config.tierName, equals('Expert'));
        final expectedChapter = ((l - 1) ~/ 10) + 1;
        expect(config.chapterTitle, contains('Chapter $expectedChapter'));
        expect(config.bottleCount, equals(12));
        expect(config.colorCount, equals(10));
      }
    });

    test('4. Star thresholds scale dynamically with target moves', () {
      final configL1 = LevelGenerator.getLevelConfig(1);
      final configL50 = LevelGenerator.getLevelConfig(50);
      final configL100 = LevelGenerator.getLevelConfig(100);

      expect(
        configL1.threeStarThreshold,
        lessThan(configL50.threeStarThreshold),
      );
      expect(configL1.twoStarThreshold, lessThan(configL50.twoStarThreshold));

      // Level 1 target is 7 moves
      expect(configL1.threeStarThreshold, equals(13));
      expect(configL1.twoStarThreshold, equals(23));

      // Level 50 target is 31 moves
      expect(configL50.threeStarThreshold, equals(37));
      expect(configL50.twoStarThreshold, equals(47));

      // Level 100 target is 36 moves
      expect(configL100.targetMoves, equals(36));
      expect(configL100.threeStarThreshold, equals(42));
      expect(configL100.twoStarThreshold, equals(52));
    });
  });

  group('AquaSort — Mathematical Consistency & Valid Water Distribution', () {
    test('5. Water capacity, empty bottles, and color distribution are 100% mathematically consistent', () {
      for (int level = 1; level <= 100; level++) {
        final tubes = LevelGenerator.getLevel(level);
        final config = LevelGenerator.getLevelConfig(level);

        // Check bottle count
        expect(tubes.length, equals(config.bottleCount));

        // Exactly 2 empty tubes
        final emptyTubes = tubes.where((t) => t.isEmpty).toList();
        expect(
          emptyTubes.length,
          equals(2),
          reason: 'Level $level must have exactly 2 empty tubes',
        );

        // Exactly colorCount filled tubes
        final filledTubes = tubes.where((t) => t.isNotEmpty).toList();
        expect(filledTubes.length, equals(config.colorCount));

        // Every filled tube has capacity 4
        for (final tube in filledTubes) {
          expect(
            tube.length,
            equals(4),
            reason: 'Level $level tube length must equal capacity 4',
          );
        }

        // Each color appears exactly 4 times in the puzzle
        final colorCounts = <int, int>{};
        for (final tube in filledTubes) {
          for (final color in tube) {
            colorCounts[color] = (colorCounts[color] ?? 0) + 1;
            // Color index must be within palette range (0..9)
            expect(color, greaterThanOrEqualTo(0));
            expect(color, lessThan(waterColors.length));
          }
        }

        expect(colorCounts.length, equals(config.colorCount));
        for (final entry in colorCounts.entries) {
          expect(
            entry.value,
            equals(4),
            reason:
                'Level $level: Color ${entry.key} appeared ${entry.value} times instead of 4',
          );
        }

        // No tube starts already complete (all 4 units identical)
        for (int i = 0; i < filledTubes.length; i++) {
          final isAlreadyComplete = filledTubes[i].every(
            (c) => c == filledTubes[i].first,
          );
          expect(
            isAlreadyComplete,
            isFalse,
            reason: 'Level $level tube $i starts already complete!',
          );
        }
      }
    });

    test('6. WaterColors palette has 10 distinct, non-null colors for up to 10-color levels', () {
      expect(waterColors.length, equals(10));
      final colorHexes = waterColors.map((c) => c.toARGB32()).toSet();
      expect(
        colorHexes.length,
        equals(10),
        reason: 'All 10 water colors must be distinct',
      );
    });
  });

  group('AquaSort — Puzzle Solvability & Level 100 Finality', () {
    test('7. Sample levels across all chapters are verified solvable by WaterSortSolver', () {
      // Test Level 1 (Easy start)
      final movesL1 = WaterSortSolver.solve(LevelGenerator.getLevel(1));
      expect(movesL1, isNotNull);
      expect(movesL1!, inInclusiveRange(4, 12));

      // Test Level 10 (Easy milestone)
      final movesL10 = WaterSortSolver.solve(LevelGenerator.getLevel(10));
      expect(movesL10, isNotNull);
      expect(movesL10!, greaterThan(0));

      // Test Level 20 (Medium milestone)
      final movesL20 = WaterSortSolver.solve(LevelGenerator.getLevel(20));
      expect(movesL20, isNotNull);
      expect(movesL20!, greaterThan(0));

      // Test Level 30 (Hard milestone)
      final movesL30 = WaterSortSolver.solve(LevelGenerator.getLevel(30));
      expect(movesL30, isNotNull);
      expect(movesL30!, greaterThan(0));

      // Test Level 40 (Very Hard milestone)
      final movesL40 = WaterSortSolver.solve(LevelGenerator.getLevel(40));
      expect(movesL40, isNotNull);
      expect(movesL40!, greaterThan(0));

      // Test Level 50 (Chapter 5 milestone)
      final movesL50 = WaterSortSolver.solve(LevelGenerator.getLevel(50));
      expect(movesL50, isNotNull);
      expect(movesL50!, greaterThan(0));

      // Test Level 75 (Chapter 8 milestone)
      final movesL75 = WaterSortSolver.solve(LevelGenerator.getLevel(75));
      expect(movesL75, isNotNull);
      expect(movesL75!, greaterThan(0));

      // Test Level 100 (Final Level 100)
      final movesL100 = WaterSortSolver.solve(LevelGenerator.getLevel(100));
      expect(movesL100, isNotNull);
      expect(movesL100!, greaterThan(0));
    });

    test('8. Level 100 is the final level: completing it caps at 100 and does NOT unlock Level 101', () {
      final gameService = GameService.instance;
      gameService.resetProgress();
      gameService.setDebugUnlockAllLevels(false);

      // Verify Level 101 is not unlocked
      expect(gameService.isLevelUnlocked(101), isFalse);

      // Complete levels up to 100
      for (int lvl = 1; lvl < 100; lvl++) {
        gameService.completeLevel(lvl, 20);
        expect(gameService.currentLevel, equals(lvl + 1));
      }

      // At level 100
      expect(gameService.currentLevel, equals(100));
      expect(gameService.isLevelUnlocked(100), isTrue);
      expect(gameService.isLevelUnlocked(101), isFalse);

      // Complete level 100
      gameService.completeLevel(100, 30);

      // Current level must remain 100 (NOT 101)
      expect(gameService.currentLevel, equals(100));
      expect(gameService.completedLevels.contains(100), isTrue);
      expect(gameService.completedLevelsCount, equals(100));
      expect(gameService.isLevelUnlocked(101), isFalse);

      // Even with debugUnlockAllLevels enabled, Level 101 must remain false
      gameService.setDebugUnlockAllLevels(true);
      expect(gameService.isLevelUnlocked(100), isTrue);
      expect(gameService.isLevelUnlocked(101), isFalse);
    });
  });

  group('AquaSort — Responsive Bottle Scaling & Layouts', () {
    Future<void> pumpScreenWithSize(
      WidgetTester tester,
      Size size,
      int level,
    ) async {
      tester.view.physicalSize = Size(size.width * 2, size.height * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        MaterialApp(
          home: WaterSortScreen(
            key: ValueKey('level_$level'),
            initialLevel: level,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      '9. Narrow screen (320px wide): Renders 12-bottle Expert Level 100 without overflow',
      (WidgetTester tester) async {
        await pumpScreenWithSize(tester, const Size(320, 640), 100);

        // Verify no RenderFlex overflow error occurred
        expect(tester.takeException(), isNull);

        // Verify all 12 tubes are rendered
        for (int i = 0; i < 12; i++) {
          expect(find.byKey(ValueKey('tube_$i')), findsOneWidget);
        }

        // Verify tier badge is displayed
        expect(find.text('EXPERT'), findsOneWidget);
        expect(find.text('LEVEL'), findsOneWidget);
        expect(find.text('100'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Standard screen (360px wide): Renders 12-bottle Expert Level 50 without overflow',
      (WidgetTester tester) async {
        await pumpScreenWithSize(tester, const Size(360, 740), 50);

        expect(tester.takeException(), isNull);
        for (int i = 0; i < 12; i++) {
          expect(find.byKey(ValueKey('tube_$i')), findsOneWidget);
        }
        expect(find.text('EXPERT'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Wide screen (412px wide): Renders 12-bottle Expert Level 100 with comfortable proportions',
      (WidgetTester tester) async {
        await pumpScreenWithSize(tester, const Size(412, 915), 100);

        expect(tester.takeException(), isNull);
        for (int i = 0; i < 12; i++) {
          expect(find.byKey(ValueKey('tube_$i')), findsOneWidget);
        }
        expect(find.text('EXPERT'), findsOneWidget);
        expect(find.text('100'), findsOneWidget);
      },
    );

    testWidgets(
      '12. Renders Easy (5 bottles), Medium (8 bottles), Hard (10 bottles) seamlessly',
      (WidgetTester tester) async {
        // Level 1: 5 bottles (Easy)
        await pumpScreenWithSize(tester, const Size(360, 640), 1);
        expect(tester.takeException(), isNull);
        expect(find.text('EASY'), findsOneWidget);
        expect(find.byKey(const ValueKey('tube_4')), findsOneWidget);
        expect(find.byKey(const ValueKey('tube_5')), findsNothing);

        // Level 15: 8 bottles (Medium)
        await pumpScreenWithSize(tester, const Size(360, 640), 15);
        expect(tester.takeException(), isNull);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.byKey(const ValueKey('tube_7')), findsOneWidget);
        expect(find.byKey(const ValueKey('tube_8')), findsNothing);

        // Level 30: 10 bottles (Hard)
        await pumpScreenWithSize(tester, const Size(360, 640), 30);
        expect(tester.takeException(), isNull);
        expect(find.text('HARD'), findsOneWidget);
        expect(find.byKey(const ValueKey('tube_9')), findsOneWidget);
        expect(find.byKey(const ValueKey('tube_10')), findsNothing);
      },
    );
  });

  group('AquaSort — Bottle Selection & Pouring at Scaled Bottle Sizes', () {
    testWidgets(
      '13. Bottle tap selection, deselect, and pouring work smoothly on 12-bottle board',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const MaterialApp(home: WaterSortScreen(initialLevel: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;

        // Select Tube 0
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump(const Duration(milliseconds: 50));

        expect(state.selectedTubeForTest, equals(0));

        // Tap Tube 0 again to deselect
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump(const Duration(milliseconds: 50));

        expect(state.selectedTubeForTest, isNull);

        // Select Tube 0 and pour into empty Tube 10
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump(const Duration(milliseconds: 50));
        expect(state.selectedTubeForTest, equals(0));

        await tester.tap(find.byKey(const ValueKey('tube_10')));
        await tester.pump(const Duration(milliseconds: 50));

        // Pouring animation initiated
        expect(state.isPouringForTest, isTrue);

        // Advance animation through completion (~950ms pour controller)
        await tester.pump(const Duration(milliseconds: 1100));
        expect(state.isPouringForTest, isFalse);
      },
    );
  });
}
