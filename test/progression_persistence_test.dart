import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/screens/home_screen.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GameService.instance.setStorageAdapterForTesting(InMemoryStorageAdapter());
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
  });

  tearDown(() {
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
  });

  group('AquaSort — Level Progression and Synchronization Verification', () {
    test('1. Starting a new game begins at Level 1, and completing Level 1 unlocks Level 2', () {
      final gameService = GameService.instance;
      expect(gameService.currentLevel, equals(1));
      expect(gameService.isLevelUnlocked(1), isTrue);
      expect(gameService.isLevelUnlocked(2), isFalse);

      // Complete Level 1 in 4 moves
      gameService.completeLevel(1, 4);

      expect(gameService.completedLevels.contains(1), isTrue);
      expect(gameService.currentLevel, equals(2));
      expect(gameService.isLevelUnlocked(2), isTrue);
      expect(gameService.isLevelUnlocked(3), isFalse);
    });

    test('2. Completing Level 2 unlocks Level 3', () {
      final gameService = GameService.instance;
      gameService.completeLevel(1, 4);
      expect(gameService.currentLevel, equals(2));

      // Complete Level 2 in 6 moves
      gameService.completeLevel(2, 6);

      expect(gameService.completedLevels.contains(2), isTrue);
      expect(gameService.currentLevel, equals(3));
      expect(gameService.isLevelUnlocked(3), isTrue);
      expect(gameService.isLevelUnlocked(4), isFalse);
    });

    testWidgets(
      '3. Completing a level updates the map displayed progress and Play button',
      (WidgetTester tester) async {
        final gameService = GameService.instance;
        expect(gameService.currentLevel, equals(1));

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Initially at Level 1: potion badge on Play button displays '1'
        expect(find.text('1'), findsAtLeastNWidgets(1));

        // Complete Level 1 via service
        gameService.completeLevel(1, 4);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Level 2 is now the current unlocked level
        expect(gameService.currentLevel, equals(2));

        // Potion badge on Play button must display '2'
        expect(find.text('2'), findsAtLeastNWidgets(1));

        // Level node 2 must now exist and be selected
        final node2Finder = find.byKey(const ValueKey('level_node_2'));
        expect(node2Finder, findsOneWidget);
      },
    );

    test(
      '4. Saved progress survives service reinitialization via storage adapter',
      () async {
        final mockStorage = InMemoryStorageAdapter();
        final gameService = GameService.instance;
        gameService.setStorageAdapterForTesting(mockStorage);
        gameService.resetProgress();

        gameService.completeLevel(1, 4);
        gameService.completeLevel(2, 6);
        gameService.completeLevel(3, 8);
        expect(gameService.currentLevel, equals(4));

        final raw = await mockStorage.load();
        expect(raw, isNotNull);
        final Map<String, dynamic> data = jsonDecode(raw!);
        expect(data['currentLevel'], equals(4));
        expect(data['completedLevels'], containsAll([1, 2, 3]));

        // Calling initialize() reloads from storage and maintains current progress
        await gameService.initialize(forceReload: true);
        expect(gameService.currentLevel, equals(4));
        expect(gameService.completedLevels.contains(3), isTrue);
      },
    );

    test('5. Replaying an earlier level does not reduce the highest unlocked level', () {
      final gameService = GameService.instance;
      // Advance to Level 5
      for (int lvl = 1; lvl <= 4; lvl++) {
        gameService.completeLevel(lvl, 5);
      }
      expect(gameService.currentLevel, equals(5));

      // Replay Level 1 and complete it again
      gameService.completeLevel(1, 3);

      // Current level and highest unlocked level must remain 5
      expect(gameService.currentLevel, equals(5));
      expect(gameService.isLevelUnlocked(5), isTrue);
      expect(gameService.isLevelUnlocked(6), isFalse);
    });

    test('6. Completing Level 100 does not unlock Level 101', () {
      final gameService = GameService.instance;
      // Complete all 99 levels
      for (int lvl = 1; lvl <= 99; lvl++) {
        gameService.completeLevel(lvl, 5);
      }
      expect(gameService.currentLevel, equals(100));
      expect(gameService.isLevelUnlocked(100), isTrue);

      // Complete Level 100
      gameService.completeLevel(100, 10);

      // Current level must be capped at 100
      expect(gameService.currentLevel, equals(100));
      expect(gameService.completedLevels.contains(100), isTrue);
      expect(gameService.isLevelUnlocked(100), isTrue);

      // Level 101 must NEVER be unlocked
      expect(gameService.isLevelUnlocked(101), isFalse);
    });

    testWidgets(
      '7. Navigating between Map and gameplay does not reset progress',
      (WidgetTester tester) async {
        final gameService = GameService.instance;
        gameService.completeLevel(1, 4);
        expect(gameService.currentLevel, equals(2));

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the Play button to launch gameplay
        final playButtonFinder = find.text('Play');
        expect(playButtonFinder, findsOneWidget);
        await tester.tap(playButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // WaterSortScreen is now open at Level 2
        expect(find.byType(WaterSortScreen), findsOneWidget);
        final waterSortState =
            tester.state(find.byType(WaterSortScreen)) as dynamic;
        expect(waterSortState.level, equals(2));

        // Pop back to HomeScreen
        final navigator =
            tester.state(find.byType(Navigator)) as NavigatorState;
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Progress is still Level 2
        expect(gameService.currentLevel, equals(2));
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });

  group('AquaSort — Level Selection and Navigation Verification', () {
    testWidgets('1. Selecting Level 5 and pressing Play opens Level 5', (
      WidgetTester tester,
    ) async {
      final gameService = GameService.instance;
      for (int i = 1; i <= 4; i++) {
        gameService.completeLevel(i, 4);
      }
      expect(gameService.currentLevel, equals(5));
      expect(gameService.isLevelUnlocked(5), isTrue);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      final node5Finder = find.byKey(const ValueKey('level_node_5'));
      expect(node5Finder, findsOneWidget);
      await tester.tap(node5Finder);
      await tester.pump(const Duration(milliseconds: 100));

      final playButtonFinder = find.text('Play');
      await tester.tap(playButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WaterSortScreen), findsOneWidget);
      final waterSortState =
          tester.state(find.byType(WaterSortScreen)) as dynamic;
      expect(waterSortState.level, equals(5));
    });

    testWidgets(
      '2. Selecting Level 10 and pressing Play opens Level 10, if unlocked',
      (WidgetTester tester) async {
        final gameService = GameService.instance;
        for (int i = 1; i <= 9; i++) {
          gameService.completeLevel(i, 4);
        }
        expect(gameService.currentLevel, equals(10));
        expect(gameService.isLevelUnlocked(10), isTrue);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final node10Finder = find.byKey(const ValueKey('level_node_10'));
        expect(node10Finder, findsOneWidget);
        await tester.tap(node10Finder);
        await tester.pump(const Duration(milliseconds: 100));

        final playButtonFinder = find.text('Play');
        await tester.tap(playButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(WaterSortScreen), findsOneWidget);
        final waterSortState =
            tester.state(find.byType(WaterSortScreen)) as dynamic;
        expect(waterSortState.level, equals(10));
      },
    );

    testWidgets('3. Selecting Level 1 still opens Level 1', (
      WidgetTester tester,
    ) async {
      final gameService = GameService.instance;
      expect(gameService.currentLevel, equals(1));

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      final node1Finder = find.byKey(const ValueKey('level_node_1'));
      expect(node1Finder, findsOneWidget);
      await tester.tap(node1Finder);
      await tester.pump(const Duration(milliseconds: 100));

      final playButtonFinder = find.text('Play');
      await tester.tap(playButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WaterSortScreen), findsOneWidget);
      final waterSortState =
          tester.state(find.byType(WaterSortScreen)) as dynamic;
      expect(waterSortState.level, equals(1));
    });

    testWidgets('4. A locked level cannot be opened', (
      WidgetTester tester,
    ) async {
      final gameService = GameService.instance;
      expect(gameService.currentLevel, equals(1));
      expect(gameService.isLevelUnlocked(5), isFalse);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      final node5Finder = find.byKey(const ValueKey('level_node_5'));
      expect(node5Finder, findsOneWidget);
      await tester.tap(node5Finder);
      await tester.pump(const Duration(milliseconds: 100));

      // SnackBar with lock feedback is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Complete Level 4 first to unlock Level 5!'),
        findsOneWidget,
      );

      // Pressing Play opens current unlocked level (1), not locked level (5)
      final playButtonFinder = find.text('Play');
      await tester.tap(playButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WaterSortScreen), findsOneWidget);
      final waterSortState =
          tester.state(find.byType(WaterSortScreen)) as dynamic;
      expect(waterSortState.level, equals(1));
    });

    testWidgets(
      '5. Returning from gameplay does not reset the map selection unexpectedly',
      (WidgetTester tester) async {
        final gameService = GameService.instance;
        for (int i = 1; i <= 4; i++) {
          gameService.completeLevel(i, 4);
        }
        expect(gameService.currentLevel, equals(5));

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Player explicitly selects Level 3 to replay it
        final node3Finder = find.byKey(const ValueKey('level_node_3'));
        expect(node3Finder, findsOneWidget);
        await tester.tap(node3Finder);
        await tester.pump(const Duration(milliseconds: 100));

        // Launch gameplay at Level 3
        final playButtonFinder = find.text('Play');
        await tester.tap(playButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(WaterSortScreen), findsOneWidget);
        final waterSortState =
            tester.state(find.byType(WaterSortScreen)) as dynamic;
        expect(waterSortState.level, equals(3));

        // Player backs out to HomeScreen without completing Level 3
        final navigator =
            tester.state(find.byType(Navigator)) as NavigatorState;
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // The selection on the map must remain Level 3, not unexpectedly reset
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('3'), findsAtLeastNWidgets(1));
      },
    );
  });
}
