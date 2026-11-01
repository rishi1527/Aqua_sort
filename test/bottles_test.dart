import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/models/bottle_model.dart';
import 'package:water_sort_game/screens/bottles_screen.dart';
import 'package:water_sort_game/services/game_service.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
  });

  group('BottlesScreen 20 Designs & Selection Verification', () {
    testWidgets(
      'renders header, removes Shop button, and renders 20 bottle designs without overflow at 320 logical pixels wide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pumpAndSettle();

        // Header check
        expect(find.text('Bottles'), findsOneWidget);
        expect(find.text('Choose your style'), findsOneWidget);
        expect(find.text('20 Designs'), findsOneWidget);
        expect(find.byIcon(Icons.science_rounded), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

        // Separate Shop button must NOT be present
        expect(find.text('Shop'), findsNothing);

        // First bottle visible
        expect(find.text('Classic Tube'), findsOneWidget);
        expect(find.text('EQUIPPED'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly without overflow at 360 logical pixels wide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Bottles'), findsOneWidget);
        expect(find.text('Choose your style'), findsOneWidget);
        expect(find.text('20 Designs'), findsOneWidget);
        expect(find.text('Shop'), findsNothing);
      },
    );

    testWidgets(
      'renders cleanly without overflow at 412 logical pixels wide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Bottles'), findsOneWidget);
        expect(find.text('Choose your style'), findsOneWidget);
        expect(find.text('20 Designs'), findsOneWidget);
        expect(find.text('Shop'), findsNothing);
      },
    );

    testWidgets(
      'all 20 bottle designs exist and can be scrolled into view',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pumpAndSettle();

        expect(BottleStyle.allBottles.length, equals(20));

        final expectedNames = [
          'Classic Tube',
          'Conical Flask',
          'Curvy Bottle',
          'Square Bottle',
          'Round Bottle',
          'Triangle Bottle',
          'Wave Bottle',
          'Hexagon Bottle',
          'Heart Bottle',
          'Star Bottle',
          'Spiral Bottle',
          'Gourd Bottle',
          'Diamond Bottle',
          'Ribbed Bottle',
          'Wave Edge Bottle',
          'Potion Bottle',
          'Elegant Bottle',
          'Drop Bottle',
          'Cat Bottle',
          'Moon Bottle',
        ];

        for (final name in expectedNames) {
          final itemFinder = find.text(name);
          await tester.scrollUntilVisible(
            itemFinder,
            300.0,
            scrollable: find.byType(Scrollable),
          );
          expect(itemFinder, findsOneWidget);
        }
      },
    );

    testWidgets(
      'tapping an unselected bottle equips it directly and updates GameService',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: BottlesScreen()));
        await tester.pumpAndSettle();

        final gameService = GameService.instance;
        expect(gameService.selectedBottleId, equals('classic_tube'));

        // Tap Conical Flask
        final conicalFlaskFinder = find.text('Conical Flask');
        expect(conicalFlaskFinder, findsOneWidget);
        await tester.tap(conicalFlaskFinder);
        await tester.pumpAndSettle();

        // Must update equipped bottle in GameService
        expect(gameService.selectedBottleId, equals('conical_flask'));
        expect(gameService.currentBottle.name, equals('Conical Flask'));

        // Tap Curvy Bottle (also on screen)
        final curvyBottleFinder = find.text('Curvy Bottle');
        expect(curvyBottleFinder, findsOneWidget);
        await tester.tap(curvyBottleFinder);
        await tester.pumpAndSettle();

        expect(gameService.selectedBottleId, equals('curvy_bottle'));
        expect(gameService.currentBottle.name, equals('Curvy Bottle'));

        // Scroll to Square Bottle
        final squareBottleFinder = find.text('Square Bottle');
        expect(squareBottleFinder, findsOneWidget);
        await tester.tap(squareBottleFinder);
        await tester.pumpAndSettle();

        expect(gameService.selectedBottleId, equals('square_bottle'));
        expect(gameService.currentBottle.name, equals('Square Bottle'));
      },
    );
  });
}
