import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/screens/home_screen.dart';
import 'package:water_sort_game/services/game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen Journey Map Layout & Responsiveness Verification', () {
    testWidgets(
      'HUD, Play button, and 3-tab bar render without overflow on compact screen (640 height)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Top HUD
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

        // Floating Play button
        expect(find.text('Play'), findsOneWidget);

        // 3-tab bottom navigation
        expect(find.text('Shop'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);

        // Zero exceptions / zero overflows
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Journey Map screen uses NeverScrollableScrollPhysics on outer PageView and provides SingleChildScrollView on Journey Map',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 728);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Verify elements
        expect(find.text('Play'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Shop'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);

        // Map tab PageView uses NeverScrollableScrollPhysics (non-scrollable outer page view)
        final pageView = tester.widget<PageView>(find.byType(PageView));
        expect(pageView.physics, isA<NeverScrollableScrollPhysics>());

        // Map area uses dedicated SingleChildScrollView for vertical scrolling
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Responsive layout distribution: Play button floats above bottom navigation on standard screen (844 height)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final playFinder = find.text('Play');
        final mapTabFinder = find.text('Map');

        expect(playFinder, findsOneWidget);
        expect(mapTabFinder, findsOneWidget);

        final playRect = tester.getRect(playFinder);
        final mapTabRect = tester.getRect(mapTabFinder);

        // Play button floats above bottom navigation bar
        expect(playRect.bottom, lessThan(mapTabRect.top + 30.0));

        // Zero exceptions / zero overflows
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Renders cleanly on short 500px screen without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(500, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Play'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Consecutive level nodes maintain >= 115px center-to-center distance and >= 35px visible gap with zero overlap on standard phone (844 height)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Collect all rendered level node keys
        final nodeFinders = <int, Rect>{};
        for (int lvl = 1; lvl <= 10; lvl++) {
          final finder = find.byKey(ValueKey('level_node_$lvl'));
          if (finder.evaluate().isNotEmpty) {
            nodeFinders[lvl] = tester.getRect(finder);
          }
        }

        // Must render at least 5 nodes
        expect(nodeFinders.length, greaterThanOrEqualTo(5));

        final sortedLevels = nodeFinders.keys.toList()..sort();
        for (int i = 0; i < sortedLevels.length - 1; i++) {
          final lvl1 = sortedLevels[i];
          final lvl2 = sortedLevels[i + 1];
          final rect1 = nodeFinders[lvl1]!;
          final rect2 = nodeFinders[lvl2]!;

          // Center-to-center distance
          final double dx = rect2.center.dx - rect1.center.dx;
          final double dy = rect2.center.dy - rect1.center.dy;
          final double centerDist = math.sqrt(dx * dx + dy * dy);

          // Edge-to-edge gap accounting for half-extents
          final double r1 = math.max(rect1.width, rect1.height) / 2.0;
          final double r2 = math.max(rect2.width, rect2.height) / 2.0;
          final double edgeGap = centerDist - (r1 + r2);

          // Verify consistent, generous spacing matching Screenshot 2
          expect(
            centerDist,
            greaterThanOrEqualTo(115.0),
            reason:
                'Level $lvl1 and Level $lvl2 center distance ($centerDist px) must be >= 115px',
          );
          expect(
            edgeGap,
            greaterThanOrEqualTo(35.0),
            reason:
                'Level $lvl1 and Level $lvl2 edge gap ($edgeGap px) must be >= 35px',
          );
          expect(
            rect1.overlaps(rect2),
            isFalse,
            reason:
                'Level $lvl1 and Level $lvl2 rects must never touch or overlap',
          );
        }
      },
    );

    testWidgets(
      'Levels 6 and 7 have ample spacing and never touch or overlap when selected',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Set player progress to Level 7 by completing Levels 1 to 6
        final game = GameService.instance;
        game.resetProgress();
        for (int i = 1; i <= 6; i++) {
          game.completeLevel(i, 5);
        }

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        final node6Finder = find.byKey(const ValueKey('level_node_6'));
        final node7Finder = find.byKey(const ValueKey('level_node_7'));

        expect(node6Finder, findsOneWidget);
        expect(node7Finder, findsOneWidget);

        final rect6 = tester.getRect(node6Finder);
        final rect7 = tester.getRect(node7Finder);

        final double dx = rect7.center.dx - rect6.center.dx;
        final double dy = rect7.center.dy - rect6.center.dy;
        final double centerDist = math.sqrt(dx * dx + dy * dy);
        final double edgeGap =
            centerDist - (rect6.width / 2.0 + rect7.width / 2.0);

        expect(centerDist, greaterThanOrEqualTo(115.0));
        expect(edgeGap, greaterThanOrEqualTo(35.0));
        expect(rect6.overlaps(rect7), isFalse);

        // Reset game progress back to initial
        game.resetProgress();
      },
    );

    testWidgets(
      'Level Journey Map is vertically scrollable up and down across all 100 levels',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Initial state at Level 1: Level 1 and Level 100 both exist in the 100-level map
        expect(find.byKey(const ValueKey('level_node_1')), findsOneWidget);
        expect(find.byKey(const ValueKey('level_node_100')), findsOneWidget);

        // Verify SingleChildScrollView exists
        final scrollFinder = find.byType(SingleChildScrollView);
        expect(scrollFinder, findsOneWidget);

        // Scroll upward towards higher levels
        await tester.drag(scrollFinder, const Offset(0, 500));
        await tester.pump(const Duration(milliseconds: 50));

        // Scroll downward towards lower levels
        await tester.drag(scrollFinder, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
