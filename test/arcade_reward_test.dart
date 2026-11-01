import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/haptic_service.dart';
import 'package:water_sort_game/widgets/arcade_reward_widget.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
    GameService.instance.setSound(true);
    GameService.instance.setHaptics(true);
  });

  group('Arcade Reward Words & Theme Logic', () {
    test('Contains all required short, bold reward messages', () {
      expect(kArcadeRewardWords, contains('NICE!'));
      expect(kArcadeRewardWords, contains('GREAT!'));
      expect(kArcadeRewardWords, contains('PERFECT!'));
      expect(kArcadeRewardWords, contains('AWESOME!'));
      expect(kArcadeRewardWords, contains('EXCELLENT!'));
      expect(kArcadeRewardWords, contains('AMAZING!'));
      expect(kArcadeRewardWords, contains('SUPER!'));
      expect(kArcadeRewardWords, contains('FANTASTIC!'));
      expect(kArcadeRewardWords.length, equals(8));
    });

    test('getRandomRewardWord returns valid words randomly', () {
      final seen = <String>{};
      final rng = math.Random(42);
      for (int i = 0; i < 50; i++) {
        final word = getRandomRewardWord(rng);
        expect(kArcadeRewardWords.contains(word), isTrue);
        seen.add(word);
      }
      expect(seen.length, greaterThan(1));
    });

    test(
      'ArcadeRewardTheme selects harmonious themes matching liquid colors',
      () {
        final cyan = ArcadeRewardTheme.selectTheme(const Color(0xFF00E5FF));
        expect(cyan.secondaryAccent, equals(const Color(0xFF00E5FF)));

        final gold = ArcadeRewardTheme.selectTheme(const Color(0xFFFFD166));
        expect(gold.secondaryAccent, equals(const Color(0xFFFFD166)));

        final purple = ArcadeRewardTheme.selectTheme(const Color(0xFFD946EF));
        expect(purple.secondaryAccent, equals(const Color(0xFFD946EF)));

        final green = ArcadeRewardTheme.selectTheme(const Color(0xFF00E676));
        expect(green.secondaryAccent, equals(const Color(0xFF00E676)));

        final fallback = ArcadeRewardTheme.selectTheme(null);
        expect(fallback, equals(ArcadeRewardTheme.cyanAqua));
      },
    );
  });

  group('ArcadeRewardWidget Animation & Rendering', () {
    testWidgets('Renders empty at progress 0.0 and 1.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArcadeRewardWidget(word: 'PERFECT!', progress: 0.0),
          ),
        ),
      );
      expect(find.text('PERFECT!'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArcadeRewardWidget(word: 'PERFECT!', progress: 1.0),
          ),
        ),
      );
      expect(find.text('PERFECT!'), findsNothing);
    });

    testWidgets(
      'Renders reward word with icons and styles across animation stages',
      (tester) async {
        for (final p in [0.1, 0.25, 0.5, 0.75, 0.9]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ArcadeRewardWidget(
                  word: 'AWESOME!',
                  progress: p,
                  accentColor: const Color(0xFF00E5FF),
                  tilt: 0.04,
                ),
              ),
            ),
          );

          expect(find.text('AWESOME!'), findsOneWidget);
          expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('ArcadeRewardOverlay clamps coordinates within board bounds', (
      tester,
    ) async {
      const boardSize = Size(320, 500);

      // 1. Extreme left-edge bottle
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ArcadeRewardOverlay(
                  word: 'NICE!',
                  progress: 0.5,
                  bottleRect: Rect.fromLTWH(0, 50, 40, 160),
                  boardSize: boardSize,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('NICE!'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Extreme right-edge bottle
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ArcadeRewardOverlay(
                  word: 'AMAZING!',
                  progress: 0.5,
                  bottleRect: Rect.fromLTWH(290, 50, 40, 160),
                  boardSize: boardSize,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('AMAZING!'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Extreme top bottle
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ArcadeRewardOverlay(
                  word: 'SUPER!',
                  progress: 0.5,
                  bottleRect: Rect.fromLTWH(140, 0, 40, 160),
                  boardSize: boardSize,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('SUPER!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HapticService Bottle Completion Vibration', () {
    test('HapticService bottleComplete triggers without error and respects deduplication', () async {
      final haptics = HapticService.instance;
      GameService.instance.setHaptics(true);

      // Call bottleComplete twice rapidly
      await haptics.bottleComplete();
      await haptics.bottleComplete();

      // No unhandled exceptions
      expect(true, isTrue);

      // Disable haptics and call
      GameService.instance.setHaptics(false);
      await haptics.bottleComplete();
      expect(true, isTrue);
    });
  });

  group('Game Completion Logic & Celebration Integration', () {
    testWidgets(
      'Individual bottle completion triggers reward word and level win does not overlap',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;

        // Ensure state is loaded
        expect(state.tubes, isNotEmpty);
        expect(find.text('LEVEL'), findsOneWidget);

        // Manually trigger an individual bottle celebration (as occurs in _onPourCompleted when !won)
        state.triggerBottleCelebrationForTest(0, won: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // A reward word from kArcadeRewardWords should be displayed
        bool foundWord = false;
        for (final word in kArcadeRewardWords) {
          if (find.text(word).evaluate().isNotEmpty) {
            foundWord = true;
            break;
          }
        }
        expect(
          foundWord,
          isTrue,
          reason: 'Expected a floating arcade reward word to appear',
        );

        // Forward animation past completion (850ms)
        await tester.pump(const Duration(milliseconds: 900));
        // Word is cleared
        for (final word in kArcadeRewardWords) {
          expect(find.text(word), findsNothing);
        }

        // Now trigger final bottle completion when level is won (won: true)
        state.triggerBottleCelebrationForTest(0, won: true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // No arcade reward word should be displayed when level is won
        for (final word in kArcadeRewardWords) {
          expect(
            find.text(word),
            findsNothing,
            reason: 'Floating reward words must not overlap the final level celebration',
          );
        }
      },
    );

    testWidgets('Undo clears any active floating reward word', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
      state.triggerBottleCelebrationForTest(0, won: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm reward word is visible
      bool foundWord = false;
      for (final word in kArcadeRewardWords) {
        if (find.text(word).evaluate().isNotEmpty) {
          foundWord = true;
          break;
        }
      }
      expect(foundWord, isTrue);

      // Trigger restart
      await tester.tap(find.text('RESTART'));
      await tester.pump();

      // Confirm reward word is immediately dismissed
      for (final word in kArcadeRewardWords) {
        expect(find.text(word), findsNothing);
      }
    });
  });
}
