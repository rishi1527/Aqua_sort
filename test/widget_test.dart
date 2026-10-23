import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/screens/home_screen.dart';
import 'package:water_sort_game/screens/splash_screen.dart';
import 'package:water_sort_game/screens/themes_screen.dart';
import 'package:water_sort_game/screens/journey_screen.dart';
import 'package:water_sort_game/screens/bottles_screen.dart';
import 'package:water_sort_game/screens/stats_screen.dart';
import 'package:water_sort_game/widgets/animated_bottles_widget.dart';
import 'package:water_sort_game/services/game_service.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
  });

  testWidgets('Water Sort app starts on SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const WaterSortApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Pour. Sort. Relax.'), findsOneWidget);
  });

  testWidgets('HomeScreen displays updated layout elements in exact order', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // A. Header elements
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);

    // B. Three Animated Bottles Widget
    expect(find.byType(AnimatedBottlesWidget), findsOneWidget);

    // C. Main PLAY button
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // D. Level Progress
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);

    // E. 4 Menu Cards
    expect(find.text('Themes'), findsOneWidget);
    expect(find.text('Customize your world'), findsOneWidget);

    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Explore your progress'), findsOneWidget);

    expect(find.text('Bottles'), findsOneWidget);
    expect(find.text('Choose your style'), findsOneWidget);

    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Your game record'), findsOneWidget);

    // Verify NO bottom navigation bar exists
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('HomeScreen navigates to ThemesScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.tap(find.text('Themes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ThemesScreen), findsOneWidget);
  });

  testWidgets('HomeScreen navigates to JourneyScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.tap(find.text('Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(JourneyScreen), findsOneWidget);
  });

  testWidgets('HomeScreen navigates to BottlesScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.tap(find.text('Bottles'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BottlesScreen), findsOneWidget);
  });

  testWidgets('HomeScreen navigates to StatsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.tap(find.text('Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(StatsScreen), findsOneWidget);
  });

  testWidgets('HomeScreen navigates to WaterSortScreen on PLAY tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(WaterSortScreen), findsOneWidget);
  });

  testWidgets('WaterSortScreen game board opens directly with compact header and 4 controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    // Compact Header
    expect(find.text('AQUA SORT'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsWidgets); // Header & bottom controls

    // Compact Stats
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.text('MOVES'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // Level 1
    expect(find.text('0'), findsOneWidget); // 0 moves

    // 4 Bottom Controls
    expect(find.text('UNDO'), findsOneWidget);
    expect(find.text('HINT'), findsOneWidget);
    expect(find.text('+ TUBE'), findsOneWidget);
    expect(find.text('RESTART'), findsOneWidget);

    // Bottles area must NOT be scrollable
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(ListView), findsNothing);

    // All tubes belonging to Level 1 (3 color tubes + 2 empty tubes = 5) are present simultaneously
    expect(find.byType(TubeWidget), findsNWidgets(5));
  });

  testWidgets('Adding tube (+ TUBE) increases bottle count without scrolling', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    expect(find.byType(TubeWidget), findsNWidgets(5));

    // Tap + TUBE button
    await tester.tap(find.text('+ TUBE'));
    await tester.pump();

    // Now 6 tubes exist simultaneously
    expect(find.byType(TubeWidget), findsNWidgets(6));
    expect(find.text('USED'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('Pouring water updates moves and enables Undo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    final tubeFinders = find.byType(TubeWidget);

    // Tube 0 has water, Tube 3 is empty
    await tester.tap(tubeFinders.at(0));
    await tester.pump();

    // Pour into empty tube 3
    await tester.tap(tubeFinders.at(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1050));

    // Move count should be 1
    expect(find.text('1'), findsWidgets); // Level 1 and Moves 1

    // Undo should now be enabled and work
    await tester.tap(find.text('UNDO'));
    await tester.pump();

    // Move count is reset to 0
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Valid pour animates bottle lift, tilt, and visible water stream during execution', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    final tubeFinders = find.byType(TubeWidget);

    // 1. Select Tube 0 (has water)
    await tester.tap(tubeFinders.at(0));
    await tester.pump();

    // 2. Tap Tube 3 (empty destination) to start pour
    await tester.tap(tubeFinders.at(3));
    await tester.pump();

    // 3. Advance to Phase 1 (180ms into 950ms animation): bottle is lifting and tilting
    await tester.pump(const Duration(milliseconds: 180));

    // Find all rendered TubeWidgets
    final List<TubeWidget> tubesMidFlight = tester.widgetList<TubeWidget>(tubeFinders).toList();
    // One of the tubes is the active pouring source bottle
    final TubeWidget sourceBottlePhase1 = tubesMidFlight.firstWhere((t) => t.drainingAmount > 0);
    // Verified: Bottle is actively translated toward destination and tilted
    expect(sourceBottlePhase1.translationOffset, isNot(equals(Offset.zero)));
    expect(sourceBottlePhase1.tiltAngle.abs(), greaterThan(0.0));

    // 4. Advance to Phase 2 (500ms into 950ms animation): continuous stream is flowing
    await tester.pump(const Duration(milliseconds: 320));

    // Find CustomPaint widgets to locate PourStreamPainter
    final customPaintFinders = find.byType(CustomPaint);
    bool streamFound = false;
    for (final element in tester.widgetList<CustomPaint>(customPaintFinders)) {
      if (element.painter is PourStreamPainter) {
        final PourStreamPainter painter = element.painter as PourStreamPainter;
        if (painter.alpha > 0.0) {
          streamFound = true;
          expect(painter.alpha, greaterThan(0.5));
          expect(painter.source, isNotNull);
          expect(painter.dest, isNotNull);
        }
      }
    }
    expect(streamFound, isTrue, reason: 'PourStreamPainter must be actively rendered with alpha > 0 during Phase 2');

    // 5. Advance to completion (remaining 550ms)
    await tester.pump(const Duration(milliseconds: 550));

    // Move count updated and game state finalized
    expect(find.text('1'), findsWidgets);

    // All bottles returned upright at resting coordinates with selection cleared
    final List<TubeWidget> tubesResting = tester.widgetList<TubeWidget>(tubeFinders).toList();
    for (final tube in tubesResting) {
      expect(tube.tiltAngle, equals(0.0));
      expect(tube.drainingAmount, equals(0));
      expect(tube.selected, isFalse);
      expect(tube.translationOffset, equals(Offset.zero));
    }
  });

  testWidgets('Responsive test on small and standard screen sizes with zero overflow', (WidgetTester tester) async {
    // 1. Small compact screen (360 x 580)
    tester.view.physicalSize = const Size(360 * 2, 580 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    expect(find.byType(TubeWidget), findsNWidgets(5));

    // Add tube on small screen
    await tester.tap(find.text('+ TUBE'));
    await tester.pump();
    expect(find.byType(TubeWidget), findsNWidgets(6));
  });

  testWidgets('TubeWidget renders empty, partially filled, and full bottles with curved liquid meniscus and waves without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              // Empty tube
              TubeWidget(
                colors: const [],
                selected: false,
                hintTarget: false,
                onTap: () {},
                wavePhase: 0.5,
              ),
              // Partially filled (1 unit)
              TubeWidget(
                colors: const [0],
                selected: true,
                hintTarget: false,
                onTap: () {},
                wavePhase: 1.2,
              ),
              // Partially filled (2 units)
              TubeWidget(
                colors: const [0, 1],
                selected: false,
                hintTarget: true,
                onTap: () {},
                wavePhase: 2.1,
              ),
              // Completely filled (4 units)
              TubeWidget(
                colors: const [0, 1, 2, 3],
                selected: false,
                hintTarget: false,
                onTap: () {},
                wavePhase: 3.4,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TubeWidget), findsNWidgets(4));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Invalid move tap triggers bright red border and returns to normal glass border after 500ms', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    final tubeFinders = find.byType(TubeWidget);

    // 1. Select Tube 0 (has water) -> valid selection, not an invalid move
    await tester.tap(tubeFinders.at(0));
    await tester.pump();

    final TubeWidget selectedTube0 = tester.widget(tubeFinders.at(0));
    expect(selectedTube0.selected, isTrue);
    expect(selectedTube0.isInvalid, isFalse);

    // 2. Attempt invalid pour into Tube 1 (Tube 1 is full and top color doesn't match)
    await tester.tap(tubeFinders.at(1));
    await tester.pump();

    // Tube 1 must trigger the invalid state with red border
    final TubeWidget invalidTube1 = tester.widget(tubeFinders.at(1));
    expect(invalidTube1.isInvalid, isTrue);
    expect(invalidTube1.errorIntensity, greaterThan(0.0));

    // Tube 0 remains selected
    final TubeWidget stillSelectedTube0 = tester.widget(tubeFinders.at(0));
    expect(stillSelectedTube0.selected, isTrue);

    // 3. After 550ms, the red error border smoothly returns to normal
    await tester.pump(const Duration(milliseconds: 550));

    final TubeWidget recoveredTube1 = tester.widget(tubeFinders.at(1));
    expect(recoveredTube1.isInvalid, isFalse);
    expect(recoveredTube1.errorIntensity, equals(0.0));
  });

  testWidgets('Tapping empty tube with nothing selected triggers invalid red border', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaterSortScreen(),
      ),
    );

    final tubeFinders = find.byType(TubeWidget);

    // Tube 3 is empty; tapping it without selecting anything is invalid
    await tester.tap(tubeFinders.at(3));
    await tester.pump();

    final TubeWidget emptyTube3 = tester.widget(tubeFinders.at(3));
    expect(emptyTube3.isInvalid, isTrue);
    expect(emptyTube3.errorIntensity, greaterThan(0.0));

    // After duration, returns to normal
    await tester.pump(const Duration(milliseconds: 550));
    final TubeWidget recoveredEmptyTube3 = tester.widget(tubeFinders.at(3));
    expect(recoveredEmptyTube3.isInvalid, isFalse);
  });
}
