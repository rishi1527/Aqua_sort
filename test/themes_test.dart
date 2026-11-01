import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/models/theme_model.dart';
import 'package:water_sort_game/screens/themes_screen.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';
import 'package:water_sort_game/widgets/background_painter.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
  });

  group('20 Themes Model & Asset Verification', () {
    test('GameTheme contains all 20 themes with valid attributes', () {
      expect(GameTheme.allThemes.length, equals(20));
      for (final theme in GameTheme.allThemes) {
        expect(theme.id.isNotEmpty, isTrue);
        expect(theme.name.isNotEmpty, isTrue);
        expect(theme.description.isNotEmpty, isTrue);
        expect(theme.isFree, isTrue);
        expect(theme.requiredLevel, equals(1));
        expect(theme.coinCost, equals(0));
      }
    });

    test(
      'All 20 high-resolution theme images exist and load via rootBundle',
      () async {
        for (final theme in GameTheme.allThemes) {
          final assetPath = theme.assetPath;
          final byteData = await rootBundle.load(assetPath);
          expect(
            byteData.lengthInBytes,
            greaterThan(100000),
            reason: '$assetPath must be a high-resolution asset',
          );
        }
      },
    );

    test(
      'All 20 themes have correct canonical asset paths registered in model',
      () {
        expect(GameTheme.allThemes.length, equals(20));
        for (final theme in GameTheme.allThemes) {
          expect(
            theme.assetPath,
            equals('assets/images/themes/${theme.id}.png'),
            reason: '${theme.name} must reference its canonical png asset path',
          );
        }
      },
    );

    test('The 7 previously missing themes all exist and load valid high-resolution PNGs', () async {
      const sevenThemes = [
        'desert_oasis.png',
        'night_city.png',
        'northern_lights.png',
        'spring_meadow.png',
        'floating_islands.png',
        'mystic_library.png',
        'galaxy_space.png',
      ];

      for (final filename in sevenThemes) {
        final assetPath = 'assets/images/themes/$filename';
        final byteData = await rootBundle.load(assetPath);
        expect(
          byteData.lengthInBytes,
          greaterThan(500000),
          reason: '$assetPath must be present on disk and loadable',
        );
      }
    });

    test('GameTheme.getById returns correct theme or default fallback', () {
      final simple = GameTheme.getById('simple');
      expect(simple.name, equals('Simple'));
      expect(simple.assetPath, equals('assets/images/themes/simple.png'));

      final royalCastle = GameTheme.getById('royal_castle');
      expect(
        royalCastle.id,
        equals('simple'),
        reason: 'Legacy royal_castle ID must fall back to simple',
      );

      final moonlight = GameTheme.getById('moonlight_lake');
      expect(moonlight.name, equals('Moonlight Lake'));
      expect(
        moonlight.assetPath,
        equals('assets/images/themes/moonlight_lake.png'),
      );

      final unknown = GameTheme.getById('unknown_theme_xyz');
      expect(unknown.id, equals('simple'));
    });
  });

  group('GameService Theme Management', () {
    test('Initializes with simple default and unlocks all 20 themes', () {
      final service = GameService.instance;
      expect(service.selectedThemeId, equals('simple'));
      expect(service.currentTheme.name, equals('Simple'));

      for (final theme in GameTheme.allThemes) {
        expect(
          service.unlockedThemeIds.contains(theme.id),
          isTrue,
          reason: '${theme.id} should be unlocked by default',
        );
      }
      expect(service.unlockedThemeIds.contains('royal_castle'), isFalse);
    });

    test('selectTheme equips theme immediately and notifies listeners', () {
      final service = GameService.instance;
      bool notified = false;
      void listener() => notified = true;
      service.addListener(listener);

      service.selectTheme('cherry_blossom');
      expect(service.selectedThemeId, equals('cherry_blossom'));
      expect(service.currentTheme.name, equals('Cherry Blossom'));
      expect(notified, isTrue);

      service.removeListener(listener);
    });

    test('selectTheme maps royal_castle to simple safely', () {
      final service = GameService.instance;
      service.selectTheme('moonlight_lake');
      expect(service.selectedThemeId, equals('moonlight_lake'));

      service.selectTheme('royal_castle');
      expect(service.selectedThemeId, equals('simple'));
      expect(service.currentTheme.name, equals('Simple'));
    });
  });

  group('ThemesScreen Layout & Responsiveness', () {
    testWidgets(
      'renders responsive ThemesScreen without overflow at 320 logical pixels wide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
        await tester.pump();

        expect(find.text('Themes'), findsOneWidget);
        expect(find.text('Customize your world'), findsOneWidget);
        expect(find.text('Simple'), findsOneWidget);
        expect(find.text('Royal Castle'), findsNothing);
        expect(find.text('Moonlight Lake'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders responsive ThemesScreen without overflow at 360 logical pixels wide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
        await tester.pump();

        expect(find.text('Themes'), findsOneWidget);
        expect(find.text('Simple'), findsOneWidget);
        expect(find.text('Royal Castle'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders responsive ThemesScreen without overflow at 412 logical pixels wide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
        await tester.pump();

        expect(find.text('Themes'), findsOneWidget);
        expect(find.text('Simple'), findsOneWidget);
        expect(find.text('Royal Castle'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tapping a theme in ThemesScreen equips it immediately', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = GameService.instance;
      expect(service.selectedThemeId, equals('simple'));

      await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
      await tester.pump();

      // Find Moonlight Lake card and tap it
      await tester.tap(find.text('Moonlight Lake'));
      await tester.pumpAndSettle();

      expect(service.selectedThemeId, equals('moonlight_lake'));
    });
  });

  group('Gameplay Screen Theme Background Integration', () {
    testWidgets('GameBackgroundWidget renders Image.asset for selected theme', (
      WidgetTester tester,
    ) async {
      final theme = GameTheme.getById('simple');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GameBackgroundWidget(theme: theme)),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(
        (imageWidget.image as AssetImage).assetName,
        equals('assets/images/themes/simple.png'),
      );
    });

    testWidgets('WaterSortScreen updates theme background dynamically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));
      await tester.pump();

      // Default is simple
      var imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      var imageWidget = tester.widget<Image>(imageFinder);
      expect(
        (imageWidget.image as AssetImage).assetName,
        equals('assets/images/themes/simple.png'),
      );

      // Switch to sunset_beach
      GameService.instance.selectTheme('sunset_beach');
      await tester.pump();

      imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      imageWidget = tester.widget<Image>(imageFinder);
      expect(
        (imageWidget.image as AssetImage).assetName,
        equals('assets/images/themes/sunset_beach.png'),
      );

      // Verify each of the 7 previously missing themes updates WaterSortScreen background:
      final sevenThemeIds = [
        'desert_oasis',
        'night_city',
        'northern_lights',
        'spring_meadow',
        'floating_islands',
        'mystic_library',
        'galaxy_space',
      ];

      for (final id in sevenThemeIds) {
        GameService.instance.selectTheme(id);
        await tester.pump();

        imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        imageWidget = tester.widget<Image>(imageFinder);
        expect(
          (imageWidget.image as AssetImage).assetName,
          equals('assets/images/themes/$id.png'),
          reason:
              'Theme $id must render its exact background asset on WaterSortScreen',
        );
      }
    });

    testWidgets(
      'ThemesScreen renders theme image cards with ZERO placeholder icons',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ThemesScreen()));
        await tester.pump();

        // Must find zero placeholder palette icons on theme cards
        expect(find.byIcon(Icons.palette_outlined), findsNothing);

        // Images are actively rendered in the grid
        expect(find.byType(Image), findsWidgets);
      },
    );
  });

  group('AquaSort — Simple Theme & Royal Castle Removal Verification', () {
    test('1. Simple is the default theme for a new player', () {
      final service = GameService.instance;
      expect(service.selectedThemeId, equals('simple'));
      expect(service.currentTheme.id, equals('simple'));
      expect(service.currentTheme.name, equals('Simple'));
    });

    test(
      '2. Simple is available without unlocking (free, level 1, 0 coins)',
      () {
        final simpleTheme = GameTheme.getById('simple');
        expect(simpleTheme.isFree, isTrue);
        expect(simpleTheme.requiredLevel, equals(1));
        expect(simpleTheme.coinCost, equals(0));
        expect(
          GameService.instance.unlockedThemeIds.contains('simple'),
          isTrue,
        );
      },
    );

    test('3. Royal Castle does not appear in the theme list', () {
      expect(GameTheme.allThemes.any((t) => t.id == 'royal_castle'), isFalse);
      expect(
        GameTheme.allThemes.any((t) => t.name.toLowerCase().contains('royal')),
        isFalse,
      );
      expect(
        GameTheme.allThemes.any((t) => t.name.toLowerCase().contains('castle')),
        isFalse,
      );
    });

    test(
      '4. A saved Royal Castle selection migrates safely to Simple',
      () async {
        final service = GameService.instance;
        final memory = InMemoryStorageAdapter();
        service.setStorageAdapterForTesting(memory);

        // Prepare save data with royal_castle as selected theme
        final saveData = {
          'currentLevel': 7,
          'completedLevels': [1, 2, 3, 4, 5, 6],
          'starsPerLevel': {'1': 3, '2': 2, '3': 3, '4': 2, '5': 3, '6': 1},
          'coins': 1500,
          'selectedThemeId': 'royal_castle',
          'unlockedThemeIds': ['royal_castle', 'moonlight_lake', 'simple'],
        };
        await memory.save(jsonEncode(saveData));

        // Reload
        await service.initialize(forceReload: true);

        expect(service.selectedThemeId, equals('simple'));
        expect(service.currentTheme.name, equals('Simple'));
        expect(service.unlockedThemeIds.contains('royal_castle'), isFalse);
        expect(service.unlockedThemeIds.contains('simple'), isTrue);
      },
    );

    test('5. Other valid saved themes remain selected upon reload', () async {
      final service = GameService.instance;
      final memory = InMemoryStorageAdapter();
      service.setStorageAdapterForTesting(memory);

      final saveData = {
        'currentLevel': 5,
        'selectedThemeId': 'sunset_beach',
        'unlockedThemeIds': ['sunset_beach', 'simple'],
      };
      await memory.save(jsonEncode(saveData));

      await service.initialize(forceReload: true);

      expect(service.selectedThemeId, equals('sunset_beach'));
      expect(service.currentTheme.name, equals('Sunset Beach'));
    });

    test('6. Existing stars, level progress, and achievements remain unchanged during migration', () async {
      final service = GameService.instance;
      final memory = InMemoryStorageAdapter();
      service.setStorageAdapterForTesting(memory);

      final saveData = {
        'currentLevel': 12,
        'completedLevels': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        'starsPerLevel': {'1': 3, '2': 3, '3': 3, '11': 2},
        'coins': 2350,
        'bestStreak': 8,
        'currentStreak': 3,
        'selectedThemeId': 'royal_castle',
      };
      await memory.save(jsonEncode(saveData));

      await service.initialize(forceReload: true);

      expect(service.currentLevel, equals(12));
      expect(service.completedLevelsCount, equals(11));
      expect(service.getStarsForLevel(1), equals(3));
      expect(service.getStarsForLevel(11), equals(2));
      expect(service.coins, equals(2350));
      expect(service.bestStreak, equals(8));
      expect(service.currentStreak, equals(3));
      // Migrated cleanly
      expect(service.selectedThemeId, equals('simple'));
    });

    test('7. Theme selection persists after restarting the app', () async {
      final service = GameService.instance;
      final memory = InMemoryStorageAdapter();
      service.setStorageAdapterForTesting(memory);

      service.selectTheme('cherry_blossom');
      expect(service.selectedThemeId, equals('cherry_blossom'));

      await service.initialize(forceReload: true);
      expect(service.selectedThemeId, equals('cherry_blossom'));

      service.selectTheme('simple');
      expect(service.selectedThemeId, equals('simple'));

      await service.initialize(forceReload: true);
      expect(service.selectedThemeId, equals('simple'));
    });

    test('8. No obsolete Royal Castle asset references exist in model', () {
      for (final theme in GameTheme.allThemes) {
        expect(theme.assetPath.contains('royal_castle'), isFalse);
      }
      expect(
        GameTheme.defaultTheme.assetPath.contains('royal_castle'),
        isFalse,
      );
    });

    test('9. Simple default theme background colors match deep black with subtle dark-green tint', () {
      final theme = GameTheme.defaultTheme;
      expect(theme.backgroundColors.length, equals(2));
      expect(theme.backgroundColors[0], equals(const Color(0xFF020806)));
      expect(theme.backgroundColors[1], equals(const Color(0xFF04140C)));
    });
  });

  group('AquaSort — Glowing Green Background Particles Verification', () {
    testWidgets(
      'GameBackgroundWidget embeds GlowingGreenParticlesWidget wrapped in IgnorePointer and RepaintBoundary',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBackgroundWidget(
                child: Container(
                  key: const ValueKey('test_child'),
                  child: const Text('Game Foreground'),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(GlowingGreenParticlesWidget), findsOneWidget);
        expect(find.byKey(const ValueKey('test_child')), findsOneWidget);

        // Verify IgnorePointer wraps the particle layer so touches never get intercepted
        final ignoreFinder = find.ancestor(
          of: find.byType(GlowingGreenParticlesWidget),
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        );
        expect(ignoreFinder, findsOneWidget);
        final ignorePointer = tester.widget<IgnorePointer>(ignoreFinder);
        expect(ignorePointer.ignoring, isTrue);

        // Verify RepaintBoundary isolates the particle animation from foreground UI
        final repaintFinder = find.ancestor(
          of: find.byType(GlowingGreenParticlesWidget),
          matching: find.byType(RepaintBoundary),
        );
        expect(repaintFinder, findsWidgets);
      },
    );

    testWidgets(
      'Taps pass straight through the particle layer to interactive buttons beneath/above',
      (tester) async {
        int tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBackgroundWidget(
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => tapCount++,
                    child: const Text('Test Tap'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test Tap'));
        await tester.pump();
        expect(tapCount, equals(1));
      },
    );

    testWidgets(
      'GlowingGreenParticlesWidget renders and advances animation over time',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GlowingGreenParticlesWidget(
                particleCount: 42,
                animate: true,
              ),
            ),
          ),
        );

        expect(find.byType(GlowingGreenParticlesWidget), findsOneWidget);

        // Advance frames to ensure no exceptions in painter during animation cycle
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 22));
      },
    );

    testWidgets(
      'GlowingGreenParticlesWidget respects MediaQuery.disableAnimations',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: GlowingGreenParticlesWidget(
                  particleCount: 20,
                  animate: true,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(GlowingGreenParticlesWidget), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
      },
    );
  });
}
