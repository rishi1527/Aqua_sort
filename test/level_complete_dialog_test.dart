import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/widgets/level_complete_dialog.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
    GameService.instance.setSound(true);
    GameService.instance.setHaptics(true);
  });

  group('LevelCompleteDialog Visuals and Content', () {
    testWidgets('Renders heading, subtitle, stars, stat cards, and buttons', (
      tester,
    ) async {
      int nextLevelCalls = 0;
      int playAgainCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LevelCompleteDialog(
                  level: 3,
                  moves: 12,
                  stars: 3,
                  streak: 4,
                  onNextLevel: () => nextLevelCalls++,
                  onPlayAgain: () => playAgainCalls++,
                ),
              ],
            ),
          ),
        ),
      );

      // Advance entrance animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // 1. Heading & Subtitle
      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);
      expect(
        find.text('Brilliant sorting! Ready for the next challenge?'),
        findsOneWidget,
      );

      // 2. Stars
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));

      // 3. Stat Cards
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('MOVES'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Optimal'), findsOneWidget);
      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('4x'), findsOneWidget);

      // 4. Buttons
      final nextBtn = find.text('NEXT LEVEL');
      final againBtn = find.text('PLAY AGAIN');
      expect(nextBtn, findsOneWidget);
      expect(againBtn, findsOneWidget);

      // Tap NEXT LEVEL
      await tester.tap(nextBtn);
      expect(nextLevelCalls, equals(1));

      // Rapid second tap is blocked by debounce guard
      await tester.tap(nextBtn);
      expect(nextLevelCalls, equals(1));
    });

    testWidgets('Play Again button invokes onPlayAgain callback', (
      tester,
    ) async {
      int playAgainCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LevelCompleteDialog(
                  level: 5,
                  moves: 20,
                  stars: 2,
                  streak: 1,
                  onNextLevel: () {},
                  onPlayAgain: () => playAgainCalls++,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final againBtn = find.text('PLAY AGAIN');
      await tester.tap(againBtn);
      expect(playAgainCalls, equals(1));

      // Rapid second tap is debounced
      await tester.tap(againBtn);
      expect(playAgainCalls, equals(1));
    });

    testWidgets('Final level (100) displays JOURNEY COMPLETE action with default maxLevel', (
      tester,
    ) async {
      int nextCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LevelCompleteDialog(
                  level: 100,
                  moves: 28,
                  stars: 1,
                  streak: 10,
                  onNextLevel: () => nextCalls++,
                  onPlayAgain: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('JOURNEY COMPLETE'), findsOneWidget);
      expect(find.text('NEXT LEVEL'), findsNothing);
      expect(find.text('Cleared'), findsOneWidget);

      await tester.tap(find.text('JOURNEY COMPLETE'));
      expect(nextCalls, equals(1));
    });
  });

  group('LevelCompleteDialog Responsiveness', () {
    for (final size in [
      const Size(320, 568), // Ultra-narrow small device
      const Size(360, 640), // Standard narrow Android
      const Size(412, 915), // Modern Android phone
    ]) {
      testWidgets(
        'Renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size * tester.view.devicePixelRatio;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    LevelCompleteDialog(
                      level: 18,
                      moves: 16,
                      stars: 2,
                      streak: 5,
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

          expect(find.text('LEVEL COMPLETE!'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Full Game Win Flow & Lifecycle Integration', () {
    testWidgets(
      'Level win shows dialog and Next Level advances level cleanly',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        expect(find.text('LEVEL'), findsOneWidget);
        expect(find.text('LEVEL COMPLETE!'), findsNothing);

        // Trigger level win
        state.triggerBottleCelebrationForTest(0, won: true);
        // Also update won = true to show overlay
        // ignore: invalid_use_of_protected_member
        state.setState(() {
          state.won = true;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        // Dialog is visible
        expect(find.text('LEVEL COMPLETE!'), findsOneWidget);
        expect(find.text('NEXT LEVEL'), findsOneWidget);

        // Tap NEXT LEVEL
        await tester.tap(find.text('NEXT LEVEL'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Level advances from 1 to 2, dialog is gone
        expect(find.text('LEVEL COMPLETE!'), findsNothing);
        expect(state.level, equals(2));
        expect(state.moves, equals(0));
        expect(state.won, isFalse);
      },
    );

    testWidgets(
      'Level win shows dialog and Play Again resets current level cleanly',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;

        // Trigger level win
        // ignore: invalid_use_of_protected_member
        state.setState(() {
          state.won = true;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

        // Tap PLAY AGAIN
        await tester.tap(find.text('PLAY AGAIN'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Stays on level 1, moves reset to 0, won is false, dialog gone
        expect(find.text('LEVEL COMPLETE!'), findsNothing);
        expect(state.level, equals(1));
        expect(state.moves, equals(0));
        expect(state.won, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
