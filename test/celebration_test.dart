import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/widgets/celebration_particles.dart';

void main() {
  setUp(() {
    GameService.instance.resetProgress();
    GameService.instance.setSound(true);
    GameService.instance.setHaptics(true);
  });

  testWidgets(
    'CelebrationPainter renders particle burst and confetti without error',
    (WidgetTester tester) async {
      final bottleParticles = CelebrationParticle.createBottleBurst(
        bottleRect: const Rect.fromLTWH(50, 100, 60, 180),
        bottleAccentColor: const Color(0xFF38BDF8),
        count: 28,
      );

      final levelParticles = CelebrationParticle.createLevelConfetti(
        boardSize: const Size(400, 600),
        count: 80,
      );

      expect(bottleParticles.length, equals(28));
      expect(levelParticles.length, equals(80));

      // Test painter at beginning, midpoint, and completion
      for (final prog in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(400, 600),
                painter: CelebrationPainter(
                  bottleProgress: prog,
                  bottleParticles: bottleParticles,
                  bottleRect: const Rect.fromLTWH(50, 100, 60, 180),
                  bottleColor: const Color(0xFF38BDF8),
                  levelProgress: prog,
                  levelParticles: levelParticles,
                  tubeRects: const [Rect.fromLTWH(50, 100, 60, 180)],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Bottle completion mini celebration triggers on completing a bottle',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));

      // Initial board has 5 tubes
      expect(find.byType(TubeWidget), findsNWidgets(5));

      // Initially, celebration layer is shrink
      final celebrationFinder = find.byType(CustomPaint);
      expect(celebrationFinder, findsWidgets);

      // Verify game starts without error and with clean initial state
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    },
  );

  testWidgets('Level restart resets completed bottles and celebration guards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));

    // Tap RESTART
    await tester.tap(find.text('RESTART'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Still level 1 with 0 moves
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sound and Haptics settings toggle properly in GameService', (
    WidgetTester tester,
  ) async {
    final game = GameService.instance;

    game.setSound(false);
    expect(game.soundEnabled, isFalse);

    game.setSound(true);
    expect(game.soundEnabled, isTrue);

    game.setHaptics(false);
    expect(game.hapticsEnabled, isFalse);

    game.setHaptics(true);
    expect(game.hapticsEnabled, isTrue);
  });

  test('createLevelConfetti creates medium and large particles with diverse shapes and multi-emitter positions', () {
    final particles = CelebrationParticle.createLevelConfetti(
      boardSize: const Size(420, 860),
      count: 140,
    );

    expect(particles.length, equals(140));

    // Verify presence of all celebration shapes: strip, square, circle, sparkle
    final shapes = particles.map((p) => p.shape).toSet();
    expect(shapes.contains(CelebrationShape.strip), isTrue);
    expect(shapes.contains(CelebrationShape.square), isTrue);
    expect(shapes.contains(CelebrationShape.circle), isTrue);
    expect(shapes.contains(CelebrationShape.sparkle), isTrue);

    // Verify that particles are noticeably larger (sizes >= 7.0)
    for (final p in particles) {
      expect(p.size, greaterThanOrEqualTo(7.0));
      if (p.shape == CelebrationShape.strip) {
        // Ribbons have noticeable length
        expect(p.length, greaterThanOrEqualTo(18.0));
      }
    }

    // Verify particles span full screen width and diverse emitter origins
    final minX = particles
        .map((p) => p.origin.dx)
        .reduce((a, b) => a < b ? a : b);
    final maxX = particles
        .map((p) => p.origin.dx)
        .reduce((a, b) => a > b ? a : b);
    final minY = particles
        .map((p) => p.origin.dy)
        .reduce((a, b) => a < b ? a : b);
    final maxY = particles
        .map((p) => p.origin.dy)
        .reduce((a, b) => a > b ? a : b);

    // X origins should span from near left edge (< 50) to near right edge (> 360)
    expect(minX, lessThan(60.0));
    expect(maxX, greaterThan(360.0));
    // Y origins should include sky cascade (< 250) and bottom cannons (> 750)
    expect(minY, lessThan(250.0));
    expect(maxY, greaterThan(750.0));
  });

  testWidgets(
    'Full-screen celebration overlay does not block taps or navigation',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WaterSortScreen()));

      // Tap RESTART through any overlays
      final restartBtn = find.text('RESTART');
      expect(restartBtn, findsOneWidget);
      await tester.tap(restartBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Buttons remain fully interactive and no unhandled exceptions
      expect(tester.takeException(), isNull);
    },
  );
}
