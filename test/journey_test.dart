import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/screens/journey_screen.dart';
import 'package:water_sort_game/services/game_service.dart';

void main() {
  group('JourneyScreen Layout & Responsiveness', () {
    testWidgets(
      'renders all chapter cards on narrow 360x640 screen without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));

        // Verify header
        expect(find.text('Journey'), findsOneWidget);
        expect(find.text('Explore your progress'), findsOneWidget);

        // Verify each chapter card renders exactly once (no duplicates)
        expect(find.text('Chapter 1: Tranquil Waters'), findsOneWidget);
        expect(find.text('Chapter 2: Coral Lagoon'), findsOneWidget);
        expect(find.text('Chapter 3: Bioluminescent Abyss'), findsOneWidget);

        // Verify level-range labels are present and visible
        expect(find.text('Lv 1 - 10'), findsOneWidget);
        expect(find.text('Lv 11 - 20'), findsOneWidget);
        expect(find.text('Lv 21 - 30'), findsOneWidget);

        // Scroll down to check chapters 4 and 5
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();

        expect(find.text('Chapter 4: Crystal Fjord'), findsOneWidget);
        expect(find.text('Chapter 5: Celestial Tide'), findsOneWidget);
        expect(find.text('Lv 31 - 40'), findsOneWidget);
        expect(find.text('Lv 41 - 50'), findsOneWidget);

        // Scroll down further to check Chapter 6
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(find.text('Chapter 6: Mystic Caverns'), findsOneWidget);
        expect(find.text('Lv 51 - 60'), findsOneWidget);

        // Scroll to the bottom to check Chapter 10
        await tester.drag(find.byType(ListView), const Offset(0, -1400));
        await tester.pump();

        expect(find.text('Chapter 10: Infinity Ocean'), findsOneWidget);
        expect(find.text('Lv 91 - 100'), findsOneWidget);
      },
    );

    testWidgets('renders on ultra-narrow 320x568 screen without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));

      expect(find.byType(JourneyScreen), findsOneWidget);

      // Chapter 1 is in view initially
      expect(find.text('Chapter 1: Tranquil Waters'), findsOneWidget);
      expect(find.text('Lv 1 - 10'), findsOneWidget);

      // Scroll down to bring Chapter 3 into view on short screen
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pump();

      expect(find.text('Chapter 3: Bioluminescent Abyss'), findsOneWidget);
      expect(find.text('Lv 21 - 30'), findsOneWidget);

      // Ensure level-range label is positioned to the right of chapter title
      final titleTopLeft = tester.getTopLeft(
        find.text('Chapter 3: Bioluminescent Abyss'),
      );
      final labelTopLeft = tester.getTopLeft(find.text('Lv 21 - 30'));
      expect(labelTopLeft.dx, greaterThan(titleTopLeft.dx));
    });

    testWidgets('renders on standard 412x915 screen without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));

      expect(find.byType(JourneyScreen), findsOneWidget);
      expect(find.text('Chapter 3: Bioluminescent Abyss'), findsOneWidget);
      expect(find.text('Lv 21 - 30'), findsOneWidget);
    });
  });

  group('Temporary Testing Unlock Mode', () {
    test(
      'All 100 levels are unlocked when debugUnlockAllLevels is enabled',
      () {
        final gameService = GameService.instance;
        gameService.setDebugUnlockAllLevels(true);
        addTearDown(() => gameService.setDebugUnlockAllLevels(false));
        expect(GameService.debugUnlockAllLevels, isTrue);

        for (int lvl = 1; lvl <= 100; lvl++) {
          expect(gameService.isLevelUnlocked(lvl), isTrue);
        }
        expect(gameService.isLevelUnlocked(101), isFalse);
      },
    );

    test(
      'Completed levels and stars are not automatically awarded by unlock flag',
      () {
        final gameService = GameService.instance;
        // Saved completed levels remains unchanged
        expect(gameService.completedLevels.contains(100), isFalse);
        expect(gameService.getStarsForLevel(100), equals(0));
      },
    );

    testWidgets('Every level is directly selectable from JourneyScreen', (
      WidgetTester tester,
    ) async {
      final gameService = GameService.instance;
      gameService.setDebugUnlockAllLevels(true);
      addTearDown(() => gameService.setDebugUnlockAllLevels(false));

      await tester.pumpWidget(const MaterialApp(home: JourneyScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Level 5 should be directly unlocked and selectable without lock icon
      final level5Finder = find.text('5');
      expect(level5Finder, findsOneWidget);

      await tester.tap(level5Finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify WaterSortScreen is launched at Level 5
      expect(find.byType(WaterSortScreen), findsOneWidget);
      final waterSortState =
          tester.state(find.byType(WaterSortScreen)) as dynamic;
      expect(waterSortState.level, equals(5));
    });

    test(
      'Disabling debugUnlockAllLevels restores normal progression checks',
      () {
        final gameService = GameService.instance;
        addTearDown(() => gameService.setDebugUnlockAllLevels(false));

        gameService.setDebugUnlockAllLevels(false);
        expect(gameService.isDebugUnlockAllLevelsEnabled, isFalse);

        // Level 1 is always unlocked
        expect(gameService.isLevelUnlocked(1), isTrue);
        // High levels (e.g. 100) are locked unless completed
        if (!gameService.completedLevels.contains(99) &&
            gameService.currentLevel < 100) {
          expect(gameService.isLevelUnlocked(100), isFalse);
        }
        expect(gameService.isLevelUnlocked(101), isFalse);
      },
    );
  });
}
