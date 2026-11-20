import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/screens/bottles_screen.dart';
import 'package:water_sort_game/screens/themes_screen.dart';
import 'package:water_sort_game/services/game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Capture visual preview screenshots of ThemesScreen and BottlesScreen',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = GameService.instance;
      service.resetProgress();

      // 1. Capture ThemesScreen
      final themeKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(key: themeKey, child: const ThemesScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.runAsync(() async {
        final RenderRepaintBoundary themeBoundary =
            themeKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final ui.Image themeImage = await themeBoundary.toImage(
          pixelRatio: 1.0,
        );
        final themeByteData = await themeImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (themeByteData != null) {
          final file = File(
            r'C:\Users\rishi\.gemini\antigravity\brain\961decc1-fb58-4138-8110-6612e9678144\preview_themes_screen.png',
          );
          await file.writeAsBytes(themeByteData.buffer.asUint8List());
        }
      });

      // 2. Capture BottlesScreen
      final bottleKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(key: bottleKey, child: const BottlesScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.runAsync(() async {
        final RenderRepaintBoundary bottleBoundary =
            bottleKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final ui.Image bottleImage = await bottleBoundary.toImage(
          pixelRatio: 1.0,
        );
        final bottleByteData = await bottleImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (bottleByteData != null) {
          final file = File(
            r'C:\Users\rishi\.gemini\antigravity\brain\961decc1-fb58-4138-8110-6612e9678144\preview_bottles_screen.png',
          );
          await file.writeAsBytes(bottleByteData.buffer.asUint8List());
        }
      });
    },
  );
}
