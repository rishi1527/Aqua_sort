import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/main.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/level_generator.dart';
import 'package:water_sort_game/services/rewarded_ad_service.dart';
import 'package:water_sort_game/services/storage_stub.dart';
import 'package:water_sort_game/widgets/timeout_dialog.dart';

class MockRewardedAdProvider implements RewardedAdProvider {
  bool available;
  RewardedAdResult nextResult;
  int showCallCount = 0;

  MockRewardedAdProvider({
    this.available = true,
    this.nextResult = RewardedAdResult.rewardEarned,
  });

  @override
  bool get isAdAvailable => available;

  @override
  Future<RewardedAdResult> showRewardedAd() async {
    showCallCount++;
    return nextResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GameService.instance.setStorageAdapterForTesting(InMemoryStorageAdapter());
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(true);
    RewardedAdService.instance.resetProvider();
  });

  tearDown(() {
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
    RewardedAdService.instance.resetProvider();
  });

  group('AquaSort — Timer Rules & Configuration', () {
    test('Levels 1–3: timer is disabled (null)', () {
      expect(LevelGenerator.getInitialTimerSeconds(1), isNull);
      expect(LevelGenerator.getInitialTimerSeconds(2), isNull);
      expect(LevelGenerator.getInitialTimerSeconds(3), isNull);

      final config1 = LevelGenerator.getLevelConfig(1);
      final config3 = LevelGenerator.getLevelConfig(3);
      expect(config1.initialTimerSeconds, isNull);
      expect(config3.initialTimerSeconds, isNull);
    });

    test('Levels 4–19: 30 seconds initial timer', () {
      expect(LevelGenerator.getInitialTimerSeconds(4), equals(30));
      expect(LevelGenerator.getInitialTimerSeconds(10), equals(30));
      expect(LevelGenerator.getInitialTimerSeconds(19), equals(30));

      final config4 = LevelGenerator.getLevelConfig(4);
      final config19 = LevelGenerator.getLevelConfig(19);
      expect(config4.initialTimerSeconds, equals(30));
      expect(config19.initialTimerSeconds, equals(30));
    });

    test('Levels 20–59: 45 seconds initial timer', () {
      expect(LevelGenerator.getInitialTimerSeconds(20), equals(45));
      expect(LevelGenerator.getInitialTimerSeconds(35), equals(45));
      expect(LevelGenerator.getInitialTimerSeconds(59), equals(45));

      final config20 = LevelGenerator.getLevelConfig(20);
      final config59 = LevelGenerator.getLevelConfig(59);
      expect(config20.initialTimerSeconds, equals(45));
      expect(config59.initialTimerSeconds, equals(45));
    });

    test('Levels 60–100: 60 seconds initial timer', () {
      expect(LevelGenerator.getInitialTimerSeconds(60), equals(60));
      expect(LevelGenerator.getInitialTimerSeconds(80), equals(60));
      expect(LevelGenerator.getInitialTimerSeconds(100), equals(60));

      final config60 = LevelGenerator.getLevelConfig(60);
      final config100 = LevelGenerator.getLevelConfig(100);
      expect(config60.initialTimerSeconds, equals(60));
      expect(config100.initialTimerSeconds, equals(60));
    });
  });

  group('AquaSort — Rewarded Ad Service Placeholder & Boundary', () {
    test(
      'Default production provider is privacy-safe: no ads, no tracking',
      () async {
        final service = RewardedAdService.instance;
        expect(service.isAdAvailable, isFalse);
        final result = await service.showExtraTimeAd();
        expect(result, equals(RewardedAdResult.unavailable));
      },
    );

    test('Custom test provider can earn reward, skip, or fail', () async {
      final mock = MockRewardedAdProvider(
        nextResult: RewardedAdResult.rewardEarned,
      );
      RewardedAdService.instance.setProviderForTesting(mock);

      expect(RewardedAdService.instance.isAdAvailable, isTrue);
      final result = await RewardedAdService.instance.showExtraTimeAd();
      expect(result, equals(RewardedAdResult.rewardEarned));
      expect(mock.showCallCount, equals(1));
    });
  });

  group('AquaSort — Gameplay Timer Display & Visibility Tests', () {
    testWidgets('Level 1: No timer pill or timer countdown is rendered', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        const MaterialApp(home: WaterSortScreen(initialLevel: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('gameplay_timer_pill')), findsNothing);
      expect(find.byKey(const ValueKey('gameplay_timer_text')), findsNothing);
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Level 4: Visible 00:30 countdown rendered on screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('gameplay_timer_pill')), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('Level 20: Visible 00:45 countdown rendered on screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        const MaterialApp(home: WaterSortScreen(initialLevel: 20)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('gameplay_timer_pill')), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
    });

    testWidgets('Level 60: Visible 01:00 countdown rendered on screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        const MaterialApp(home: WaterSortScreen(initialLevel: 60)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('gameplay_timer_pill')), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
    });
  });

  group(
    'AquaSort — Timer Countdown, Lifecycle, Timeout & Extra-Time Reward',
    () {
      testWidgets('Timer counts down each second: 00:30 -> 00:29 -> 00:28', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
        );
        await tester.pump();

        expect(find.text('00:30'), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:29'), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:28'), findsOneWidget);
      });

      testWidgets(
        'Timeout at 00:00 displays TimeoutDialog and blocks tube taps',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
          );
          await tester.pump();

          // Advance by 30 seconds to trigger timeout
          await tester.pump(const Duration(seconds: 30));
          await tester.pump(const Duration(milliseconds: 500));

          // Timeout dialog is visible
          expect(find.byType(TimeoutDialog), findsOneWidget);
          expect(find.text("TIME'S UP!"), findsOneWidget);
          expect(find.text('Ran out of time on Level 4'), findsOneWidget);

          // Tube tap does not change selectedTube while timed out
          final state = tester.state(find.byType(WaterSortScreen));
          expect(state, isNotNull);
        },
      );

      testWidgets(
        'Claiming extra time grants +60 seconds and resumes countdown',
        (tester) async {
          final mock = MockRewardedAdProvider(
            nextResult: RewardedAdResult.rewardEarned,
          );
          RewardedAdService.instance.setProviderForTesting(mock);

          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
          );
          await tester.pump();

          // Advance to timeout
          await tester.pump(const Duration(seconds: 30));
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(TimeoutDialog), findsOneWidget);

          // Tap +60s Extra Time button
          final extraTimeBtn = find.text('+60s Extra Time (0/2)');
          expect(extraTimeBtn, findsOneWidget);
          await tester.tap(extraTimeBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Dialog dismissed, timer renewed with 60 seconds (01:00)
          expect(find.byType(TimeoutDialog), findsNothing);
          expect(find.text('01:00'), findsOneWidget);

          // Advances normally
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('00:59'), findsOneWidget);
        },
      );

      testWidgets('Maximum 2 extra time rewards allowed per level attempt', (
        tester,
      ) async {
        final mock = MockRewardedAdProvider(
          nextResult: RewardedAdResult.rewardEarned,
        );
        RewardedAdService.instance.setProviderForTesting(mock);

        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
        );
        await tester.pump();

        // 1. First timeout
        await tester.pump(const Duration(seconds: 30));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('+60s Extra Time (0/2)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // 2. Second timeout (+60s elapsed)
        await tester.pump(const Duration(seconds: 60));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('+60s Extra Time (1/2)'), findsOneWidget);
        await tester.tap(find.text('+60s Extra Time (1/2)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // 3. Third timeout (+60s elapsed)
        await tester.pump(const Duration(seconds: 60));
        await tester.pump(const Duration(milliseconds: 500));

        // Third attempt is disabled with limit message
        expect(find.text('Extra-time limit reached (2/2)'), findsOneWidget);
        expect(mock.showCallCount, equals(2));
      });

      testWidgets(
        'Restarting level resets reward count back to 0 and restores initial timer',
        (tester) async {
          final mock = MockRewardedAdProvider(
            nextResult: RewardedAdResult.rewardEarned,
          );
          RewardedAdService.instance.setProviderForTesting(mock);

          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
          );
          await tester.pump();

          // Timeout and claim reward
          await tester.pump(const Duration(seconds: 30));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text('+60s Extra Time (0/2)'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Tap restart button in header
          await tester.tap(find.byTooltip('Restart level'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Timer restored to 00:30
          expect(find.text('00:30'), findsOneWidget);

          // Advance to timeout again: reward count is reset to 0/2
          await tester.pump(const Duration(seconds: 30));
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('+60s Extra Time (0/2)'), findsOneWidget);
        },
      );

      testWidgets(
        'App backgrounding pauses countdown; resuming continues timer',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            const MaterialApp(home: WaterSortScreen(initialLevel: 4)),
          );
          await tester.pump();
          expect(find.text('00:30'), findsOneWidget);

          await tester.pump(const Duration(seconds: 2));
          expect(find.text('00:28'), findsOneWidget);

          // Simulate app sent to background
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump(const Duration(seconds: 5));

          // Timer was paused while in background
          expect(find.text('00:28'), findsOneWidget);

          // Resume app
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('00:27'), findsOneWidget);
        },
      );
    },
  );
}
