import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TubeWidget getTubeWidget(WidgetTester tester, int i) {
    return tester.widget<TubeWidget>(
      find.descendant(
        of: find.byKey(ValueKey('tube_$i')),
        matching: find.byType(TubeWidget),
      ),
    );
  }

  group('AquaSort — Lock Completed Bottles', () {
    testWidgets('1. Completed bottle cannot be selected as a source', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state(find.byType(WaterSortScreen)) as dynamic;

      // Set up: Tube 0 is completed [0, 0, 0, 0], Tube 1 is incomplete [1, 1], Tube 2 is empty []
      state.setTubesForTest(<List<int>>[
        <int>[0, 0, 0, 0],
        <int>[1, 1],
        <int>[],
      ]);
      await tester.pump();

      expect(state.isBottleCompleteForTest(0), isTrue);
      expect(state.isBottleCompleteForTest(1), isFalse);

      // Attempt to tap the completed bottle 0
      await tester.tap(find.byKey(const ValueKey('tube_0')));
      await tester.pump();

      // Bottle 0 cannot be selected as source
      expect(state.selectedTubeForTest, isNull);
      final TubeWidget tube0 = getTubeWidget(tester, 0);
      expect(tube0.selected, isFalse);
      expect(tube0.isInvalid, isTrue);

      // Repeated taps on completed bottle still do not select it
      await tester.tap(find.byKey(const ValueKey('tube_0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tube_0')));
      await tester.pump();
      expect(state.selectedTubeForTest, isNull);

      // canPour from completed bottle must always return false
      expect(state.canPour(0, 2), isFalse);
    });

    testWidgets(
      '2. Incomplete bottle remains selectable as source and destination',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        state.setTubesForTest(<List<int>>[
          <int>[0, 0, 0, 0], // Complete
          <int>[1, 1], // Incomplete
          <int>[1], // Incomplete destination
        ]);
        await tester.pump();

        // Tap incomplete tube 1 -> successfully selects as source
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        expect(state.selectedTubeForTest, equals(1));
        final TubeWidget tube1 = getTubeWidget(tester, 1);
        expect(tube1.selected, isTrue);

        // Tapping incomplete destination tube 2 allows pour
        expect(state.canPour(1, 2), isTrue);
      },
    );

    testWidgets(
      '3. Bottles containing multiple colors are not treated as complete even when full',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        // Tube 0 has 4 segments (capacity full) but mixed colors: [0, 0, 1, 1]
        state.setTubesForTest(<List<int>>[
          <int>[0, 0, 1, 1],
          <int>[],
        ]);
        await tester.pump();

        expect(state.isBottleCompleteForTest(0), isFalse);

        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();

        // Tube 0 is selectable because it is not complete!
        expect(state.selectedTubeForTest, equals(0));
        final TubeWidget tube0 = getTubeWidget(tester, 0);
        expect(tube0.selected, isTrue);
      },
    );

    testWidgets(
      '4. Completed bottle is recalculated correctly after undo and restart',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        // Start: Tube 0 has [0, 0, 0], Tube 1 has [0], Tube 2 has [1]
        state.setTubesForTest(<List<int>>[
          <int>[0, 0, 0],
          <int>[0],
          <int>[1],
        ]);
        await tester.pump();

        expect(state.isBottleCompleteForTest(0), isFalse);

        // Pour Tube 1 into Tube 0 -> completes Tube 0!
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();

        // Advance through pour animation (950ms)
        await tester.pump(const Duration(milliseconds: 1000));

        // Tube 0 is now [0, 0, 0, 0] (Complete and locked!)
        expect(state.isBottleCompleteForTest(0), isTrue);
        expect(state.canPour(0, 2), isFalse);

        // Tap Tube 0 -> cannot be selected as source
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        expect(state.selectedTubeForTest, isNull);

        // Now call Undo
        state.undoMove();
        await tester.pump();

        // After Undo, Tube 0 is [0, 0, 0] (incomplete again!)
        expect(state.isBottleCompleteForTest(0), isFalse);

        // Tube 0 must be unlocked and selectable again
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        expect(state.selectedTubeForTest, equals(0));
        final TubeWidget unlockedTube0 = getTubeWidget(tester, 0);
        expect(unlockedTube0.selected, isTrue);

        // Deselect Tube 0
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();

        // Complete Tube 0 again
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        expect(state.isBottleCompleteForTest(0), isTrue);

        // Call Restart
        state.restartLevel();
        await tester.pump();

        // After restart, Tube 0 is back to starting incomplete state and unlocked
        expect(state.isBottleCompleteForTest(0), isFalse);
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        expect(state.selectedTubeForTest, equals(0));
      },
    );
  });

  group('AquaSort — Responsive Multi-Move Input During Pouring', () {
    testWidgets(
      '5. Pre-selecting next source during pour animates lift and persists selection',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        state.setTubesForTest(<List<int>>[
          <int>[0, 0], // Tube 0
          <int>[0], // Tube 1
          <int>[1, 1], // Tube 2
          <int>[1], // Tube 3
        ]);
        await tester.pump();

        // Start pour: 0 -> 1
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        expect(state.isPouringForTest, isTrue);

        // Advance partially into the pour (300ms)
        await tester.pump(const Duration(milliseconds: 300));
        expect(state.isPouringForTest, isTrue);

        // While pouring, tap resting Tube 2
        await tester.tap(find.byKey(const ValueKey('tube_2')));
        await tester.pump();

        // Tube 2 is queued as next source and immediately rendered as selected (lifted)
        expect(state.queuedSourceForTest, equals(2));
        final TubeWidget queuedTube2 = getTubeWidget(tester, 2);
        expect(queuedTube2.selected, isTrue);

        // Complete the first pour (advance remaining 700ms)
        await tester.pump(const Duration(milliseconds: 700));
        expect(state.isPouringForTest, isFalse);

        // After first pour completes, Tube 2 seamlessly becomes active selectedTube!
        expect(state.selectedTubeForTest, equals(2));
        final TubeWidget activeTube2 = getTubeWidget(tester, 2);
        expect(activeTube2.selected, isTrue);

        // Tapping destination Tube 3 executes second move immediately
        await tester.tap(find.byKey(const ValueKey('tube_3')));
        await tester.pump();
        expect(state.isPouringForTest, isTrue);

        // Complete second pour
        await tester.pump(const Duration(milliseconds: 1000));
        expect(state.isPouringForTest, isFalse);
      },
    );

    testWidgets(
      '6. Queueing both source and destination during pour executes next move automatically',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        state.setTubesForTest(<List<int>>[
          <int>[0], // Tube 0
          <int>[0], // Tube 1
          <int>[1], // Tube 2
          <int>[1], // Tube 3
        ]);
        await tester.pump();

        // Start pour 0 -> 1
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();
        expect(state.isPouringForTest, isTrue);

        // While pouring 0 -> 1, queue move 2 -> 3
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byKey(const ValueKey('tube_2'))); // queued source
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_3'))); // queued dest
        await tester.pump();

        expect(state.queuedSourceForTest, equals(2));
        expect(state.queuedDestForTest, equals(3));

        // Advance 0 -> 1 pour to completion
        await tester.pump(const Duration(milliseconds: 750));

        // Pour 2 -> 3 automatically triggered upon state update!
        expect(state.isPouringForTest, isTrue);

        // Advance 2 -> 3 pour to completion
        await tester.pump(const Duration(milliseconds: 1000));
        expect(state.isPouringForTest, isFalse);

        // State is completely intact and moves counter reflects 2 moves
        expect(state.moves, equals(2));
      },
    );

    testWidgets(
      '7. Deselection of queued source during pour resets queue safely',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        state.setTubesForTest(<List<int>>[
          <int>[0],
          <int>[0],
          <int>[1],
          <int>[1],
        ]);
        await tester.pump();

        // Start pour 0 -> 1
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 250));

        // Tap Tube 2 (queues source)
        await tester.tap(find.byKey(const ValueKey('tube_2')));
        await tester.pump();
        expect(state.queuedSourceForTest, equals(2));

        // Tap Tube 2 again (deselects queued source)
        await tester.tap(find.byKey(const ValueKey('tube_2')));
        await tester.pump();
        expect(state.queuedSourceForTest, isNull);

        // Let pour finish
        await tester.pump(const Duration(milliseconds: 750));
        expect(state.isPouringForTest, isFalse);
        expect(state.selectedTubeForTest, isNull);
      },
    );

    testWidgets(
      '8. Queued move is safely cancelled if destination becomes invalid',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        // Tube 0 has [0, 0], Tube 1 has [0, 0] (Tube 1 will become full with 4 units!)
        // Tube 2 has [0]
        state.setTubesForTest(<List<int>>[
          <int>[0, 0],
          <int>[0, 0],
          <int>[0],
        ]);
        await tester.pump();

        // Start pour 0 -> 1
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 250));

        // Player queues move Tube 2 -> Tube 1
        await tester.tap(find.byKey(const ValueKey('tube_2')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        expect(state.queuedSourceForTest, equals(2));
        expect(state.queuedDestForTest, equals(1));

        // Let pour 0 -> 1 finish. Tube 1 is now full [0, 0, 0, 0] and complete!
        await tester.pump(const Duration(milliseconds: 750));

        // Move 2 -> 1 is invalid because Tube 1 is full.
        // It must safely cancel and not start an invalid pour!
        expect(state.isPouringForTest, isFalse);
        expect(state.selectedTubeForTest, isNull);
        expect(state.queuedSourceForTest, isNull);
        expect(state.queuedDestForTest, isNull);

        // Tube 2 water remains intact [0]
        expect(state.tubes[2], equals([0]));
      },
    );

    testWidgets(
      '9. Rapid duplicate taps do not duplicate moves or corrupt state',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        state.setTubesForTest(<List<int>>[
          <int>[0],
          <int>[0],
          <int>[1],
          <int>[1],
        ]);
        await tester.pump();

        // Start pour 0 -> 1
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 200));

        // Rapidly tap Tube 2 (source), then tap Tube 3 four times (destination)
        await tester.tap(find.byKey(const ValueKey('tube_2')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_3')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_3')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_3')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_3')));
        await tester.pump();

        expect(state.queuedSourceForTest, equals(2));
        expect(state.queuedDestForTest, equals(3));

        // Advance through first pour
        await tester.pump(const Duration(milliseconds: 800));

        // Second pour starts exactly once
        expect(state.isPouringForTest, isTrue);

        // Advance through second pour
        await tester.pump(const Duration(milliseconds: 1000));
        expect(state.isPouringForTest, isFalse);

        // Total moves must be exactly 2
        expect(state.moves, equals(2));
      },
    );

    testWidgets(
      '10. Level completion after final move clears queue and does not execute pending moves',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state(find.byType(WaterSortScreen)) as dynamic;
        // Setup board where pouring 0 -> 1 wins the entire level
        state.setTubesForTest(<List<int>>[
          <int>[0], // Tube 0
          <int>[0, 0, 0], // Tube 1
          <int>[1, 1, 1, 1], // Tube 2 (already complete)
        ]);
        await tester.pump();

        // Start final winning pour 0 -> 1
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tube_1')));
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 200));

        // Attempt to queue a move during the winning pour
        await tester.tap(find.byKey(const ValueKey('tube_0')));
        await tester.pump();

        // Complete the winning pour
        await tester.pump(const Duration(milliseconds: 800));

        // Won state is true!
        expect(state.won, isTrue);
        // Queued selections are cleared
        expect(state.queuedSourceForTest, isNull);
        expect(state.queuedDestForTest, isNull);
        expect(state.selectedTubeForTest, isNull);
      },
    );
  });
}
