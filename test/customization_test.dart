import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/models/bottle_model.dart';
import 'package:water_sort_game/models/customization_models.dart';
import 'package:water_sort_game/screens/customization_screen.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/widgets/bottle_geometry.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
  });

  group('Customization Models & Economy Logic', () {
    test('GameService initializes with default selections and 1,250 coins', () {
      final service = GameService.instance;
      expect(service.coins, equals(1250));
      expect(service.selectedBottleId, equals('classic_tube'));
      expect(service.selectedCapId, equals('cap_none'));
      expect(service.selectedBubbleFxId, equals('fx_soda_fizz'));
      expect(service.selectedBackgroundId, equals('bg_purple_white'));
      expect(service.selectedThemeId, equals('simple'));
      expect(service.selectedPaletteId, equals('palette_vibrant_pop'));
    });

    test('All 20 bottle styles are registered and have valid geometry', () {
      expect(BottleStyle.allBottles.length, equals(20));
      for (final bottle in BottleStyle.allBottles) {
        final geometry = BottleGeometry(bottle.shape);
        const testSize = Size(48, 160);
        final outer = geometry.getOuterPath(testSize);
        final cavity = geometry.getCavityPath(testSize);
        final anchor = geometry.getCapAnchor(testSize);
        final topCavityY = geometry.getTopCavityY(testSize);
        final bottomY = geometry.getBottomY(testSize);

        expect(outer.getBounds().isEmpty, isFalse);
        expect(cavity.getBounds().isEmpty, isFalse);
        expect(anchor.isEmpty, isFalse);
        expect(topCavityY, greaterThan(0.0));
        expect(bottomY, greaterThan(topCavityY));
      }
    });

    test('All 8 bottle caps and painters operate without errors', () {
      expect(BottleCapStyle.allCaps.length, equals(8));
      for (final cap in BottleCapStyle.allCaps) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        BottleCapPainter.paintCap(
          canvas: canvas,
          anchor: const Rect.fromLTWH(10, 10, 30, 10),
          capType: cap.type,
          gemColor: cap.gemColor,
        );
        final pic = recorder.endRecording();
        expect(pic, isNotNull);
      }
    });

    test('All 8 bubble effects render without errors', () {
      expect(BubbleFxStyle.allEffects.length, equals(8));
      for (final fx in BubbleFxStyle.allEffects) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        BubbleFxPainter.paintFx(
          canvas: canvas,
          liquidRect: const Rect.fromLTWH(5, 20, 38, 120),
          fxType: fx.type,
          animationValue: 0.5,
        );
        final pic = recorder.endRecording();
        expect(pic, isNotNull);
      }
    });

    test('All 8 backgrounds paint properly', () {
      expect(BackgroundStyle.allBackgrounds.length, equals(8));
      for (final bg in BackgroundStyle.allBackgrounds) {
        expect(bg.gradientColors.length, greaterThanOrEqualTo(2));
      }
    });

    test('All 8 color palettes contain distinguishable colors and deterministic fallback', () {
      expect(ColorPaletteStyle.allPalettes.length, equals(8));
      final service = GameService.instance;
      service.addCoins(10000);

      for (final palette in ColorPaletteStyle.allPalettes) {
        service.unlockPaletteWithCoins(palette.id);
        service.selectPalette(palette.id);
        expect(service.selectedPaletteId, equals(palette.id));

        for (int i = 0; i < palette.colors.length; i++) {
          final color = service.getLiquidColor(i);
          expect(color, equals(palette.colors[i]));
        }

        // Out of bounds fallback returns a valid color without throwing
        final fallbackColor = service.getLiquidColor(999);
        expect(fallbackColor, isNotNull);
      }
    });

    test(
      'Coin spending validates balances and prevents duplicate deductions',
      () {
        final service = GameService.instance;
        expect(service.coins, equals(1250));

        // spend 250 coins
        final spent = service.spendCoins(250);
        expect(spent, isTrue);
        expect(service.coins, equals(1000));

        // Attempt to spend more than available
        final overspend = service.spendCoins(5000);
        expect(overspend, isFalse);
        expect(service.coins, equals(1000)); // balance unchanged
      },
    );

    test('Unlocking with coins adds item to unlocked set', () {
      final service = GameService.instance;
      expect(service.unlockedCapIds.contains('cap_amethyst'), isFalse);

      final success = service.unlockCapWithCoins('cap_amethyst');
      expect(success, isTrue);
      expect(service.unlockedCapIds.contains('cap_amethyst'), isTrue);
      expect(service.coins, equals(950)); // 1250 - 300 = 950

      // Already unlocked returns true without double charging
      final alreadyUnlocked = service.unlockCapWithCoins('cap_amethyst');
      expect(alreadyUnlocked, isTrue);
      expect(service.coins, equals(950));
    });
  });

  group('CustomizationScreen Blank Shop Verification', () {
    testWidgets(
      'Renders header with back button and coins, without category tabs or shop items',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: CustomizationScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Header is rendered
        expect(find.text('Customization'), findsOneWidget);
        expect(find.text('Personalize your gameplay'), findsOneWidget);
        expect(find.text('1,250'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

        // Verify category tabs row is completely absent
        expect(find.text('Tubes'), findsNothing);
        expect(find.text('Bottle Caps'), findsNothing);
        expect(find.text('Bubble FX'), findsNothing);
        expect(find.text('Backgrounds'), findsNothing);
        expect(find.text('Themes'), findsNothing);
        expect(find.text('Color Palettes'), findsNothing);

        // Verify shop controls, item grids, and reward bar are completely absent
        expect(find.text('Free Coins  🪙 +150'), findsNothing);
        expect(find.byType(GridView), findsNothing);
        expect(find.text('Classic Flask'), findsNothing);
        expect(find.text('No Cap'), findsNothing);
        expect(find.text('Soda Fizz'), findsNothing);
        expect(find.text('Royal Amethyst'), findsNothing);
      },
    );

    testWidgets(
      'Opens successfully with initialTab argument without throwing',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: CustomizationScreen(initialTab: CustomizationTab.caps),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(CustomizationScreen), findsOneWidget);
        expect(find.byType(GridView), findsNothing);
        expect(find.text('Bottle Caps'), findsNothing);
      },
    );
  });
}
