import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_game/models/leaderboard_entry.dart';
import 'package:water_sort_game/screens/home_screen.dart';
import 'package:water_sort_game/screens/leaderboard_screen.dart';
import 'package:water_sort_game/services/game_service.dart';
import 'package:water_sort_game/services/mock_leaderboard_provider.dart';
import 'package:water_sort_game/services/storage_stub.dart';
import 'package:water_sort_game/widgets/nickname_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStorageAdapter memoryStorage;

  setUp(() {
    LeaderboardScreen.enableAnimations = false;
    memoryStorage = InMemoryStorageAdapter();
    GameService.instance.setStorageAdapterForTesting(memoryStorage);
    GameService.instance.disableMidnightTimerForTesting();
    GameService.instance.resetProgress();
    GameService.instance.setDebugUnlockAllLevels(false);
    MockLeaderboardProvider.instance.setStatusForTesting(
      LeaderboardStatus.loaded,
    );
    MockLeaderboardProvider.instance.updateNickname('AquaMaster#7421');
    MockLeaderboardProvider.instance.setNicknameLastChangedAtForTesting(null);
  });

  tearDown(() {
    LeaderboardScreen.enableAnimations = true;
    GameService.instance.cancelMidnightTimerForTesting();
    GameService.instance.resetProgress();
    MockLeaderboardProvider.instance.setStatusForTesting(
      LeaderboardStatus.loaded,
    );
    MockLeaderboardProvider.instance.setNicknameLastChangedAtForTesting(null);
  });

  group('AquaSort — Leaderboard UI & Interaction Tests', () {
    testWidgets(
      '1. LeaderboardScreen renders header, tabs, podium, Top 100 list, and Your Rank panel',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: LeaderboardScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Header elements
        expect(find.text('LEADERBOARD'), findsOneWidget);
        expect(find.text('ZEN FLUIDICS'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

        // Tabs
        expect(find.text('Global'), findsOneWidget);
        expect(find.text('Rewards'), findsOneWidget);

        // Top 100 ranking banner
        expect(find.text('TOP 100 PLAYERS'), findsOneWidget);

        // Top 3 Podium elements
        expect(find.text('#1'), findsOneWidget);
        expect(find.text('#2'), findsOneWidget);
        expect(find.text('#3'), findsOneWidget);
        expect(find.byIcon(Icons.military_tech_rounded), findsOneWidget);

        // Sticky Bottom "Your Rank" Panel
        expect(find.text('YOUR RANK'), findsOneWidget);
        expect(find.text('AquaMaster#7421'), findsOneWidget);
        expect(find.text('LIFETIME'), findsOneWidget);
        expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Tapping Rules Info button opens LEADERBOARD RULES dialog',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: LeaderboardScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Tap info button
        await tester.tap(find.byIcon(Icons.info_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('LEADERBOARD RULES'), findsOneWidget);
        expect(find.text('Ranked by Lifetime Coins'), findsOneWidget);
        expect(find.text('Level Rewards (50 Coins)'), findsOneWidget);
        expect(find.text('Daily Rewards (30 Coins)'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('GOT IT'));
        await tester.pumpAndSettle();

        expect(find.text('LEADERBOARD RULES'), findsNothing);
      },
    );

    testWidgets(
      '3. Switching tabs switches between Global and Rewards Coming Soon view',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: LeaderboardScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Initially on Global tab
        expect(find.text('TOP 100 PLAYERS'), findsOneWidget);
        expect(find.text('SEASON 1 REWARDS'), findsNothing);

        // Switch to Rewards tab
        await tester.tap(find.text('Rewards'));
        await tester.pumpAndSettle();

        expect(find.text('SEASON 1 REWARDS'), findsOneWidget);
        expect(find.text('TOP 100 PLAYERS'), findsNothing);

        // Switch back to Global tab
        await tester.tap(find.text('Global'));
        await tester.pumpAndSettle();

        expect(find.text('TOP 100 PLAYERS'), findsOneWidget);
        expect(find.text('SEASON 1 REWARDS'), findsNothing);
      },
    );

    testWidgets(
      '4. Loading state renders progress spinner',
      (WidgetTester tester) async {
        final mock = MockLeaderboardProvider.instance;
        mock.setStatusForTesting(LeaderboardStatus.loading);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaderboardScreen(mockProvider: mock),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Retrieving global rankings...'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Empty state renders when no rankings exist',
      (WidgetTester tester) async {
        final mock = MockLeaderboardProvider.instance;
        mock.setStatusForTesting(LeaderboardStatus.empty);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaderboardScreen(mockProvider: mock),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('No Rankings Yet'), findsOneWidget);
        expect(
          find.text(
            'Complete puzzles to earn lifetime coins\nand claim the top spot!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Error state renders with working Retry button',
      (WidgetTester tester) async {
        final mock = MockLeaderboardProvider.instance;
        mock.setStatusForTesting(LeaderboardStatus.error);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaderboardScreen(mockProvider: mock),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Leaderboard Unavailable'), findsOneWidget);
        expect(find.text('RETRY'), findsOneWidget);

        // Tap RETRY restores loaded state
        await tester.tap(find.text('RETRY'));
        await tester.pumpAndSettle();

        expect(find.text('TOP 100 PLAYERS'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Offline state renders with Reconnect button and shows OFFLINE rank',
      (WidgetTester tester) async {
        final mock = MockLeaderboardProvider.instance;
        mock.setStatusForTesting(LeaderboardStatus.offline);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaderboardScreen(mockProvider: mock),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Offline Mode'), findsOneWidget);
        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.text('RECONNECT'), findsOneWidget);

        // Tap RECONNECT restores loaded state
        await tester.tap(find.text('RECONNECT'));
        await tester.pumpAndSettle();

        expect(find.text('TOP 100 PLAYERS'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Nickname dialog validates minimum length, allowed characters, and updates nickname',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        String? savedNickname;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NicknameDialog(
                currentNickname: 'OldName',
                canChange: true,
                onNicknameSaved: (name) => savedNickname = name,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CHANGE NICKNAME'), findsOneWidget);

        // Too short validation (< 3 chars)
        await tester.enterText(find.byType(TextFormField), 'AB');
        await tester.pump();
        expect(
          find.text('Nickname must be at least 3 characters'),
          findsOneWidget,
        );

        // Invalid characters validation
        await tester.enterText(find.byType(TextFormField), 'Aqua@Drop!');
        await tester.pump();
        expect(
          find.text('Only letters, numbers, spaces, and _ allowed'),
          findsOneWidget,
        );

        // Valid nickname
        await tester.enterText(find.byType(TextFormField), 'TidalKnight');
        await tester.pump();
        expect(find.byType(Text), findsWidgets);

        // Tap Save
        await tester.tap(find.text('SAVE NICKNAME'));
        await tester.pumpAndSettle();

        expect(savedNickname, equals('TidalKnight'));
      },
    );

    testWidgets(
      '9. Nickname dialog enforces 7-day cooldown when active',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NicknameDialog(
                currentNickname: 'CooldownUser',
                canChange: false,
                daysRemaining: 4,
                onNicknameSaved: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Nickname cooldown active. You can change your name again in 4 days.',
          ),
          findsOneWidget,
        );
        expect(find.text('LOCKED'), findsOneWidget);

        // Form field is disabled
        final textField = tester.widget<TextFormField>(
          find.byType(TextFormField),
        );
        expect(textField.enabled, isFalse);
      },
    );

    testWidgets(
      '10. Top HUD: Clean top header preserves Profile, Coins, Daily Reward & Settings without duplicate Leaderboard icon',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Top HUD preserves Profile avatar, Settings, and Daily Reward
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
        expect(find.byKey(const ValueKey('daily_reward_button')), findsOneWidget);

        // No duplicate leaderboard trophy button in top HUD
        expect(
          find.byKey(const ValueKey('leaderboard_button')),
          findsNothing,
        );

        // Leaderboard is accessed via bottom navigation
        expect(find.text('Leaderboard'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Navigation: Bottom navigation Leaderboard tab opens LeaderboardScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));

        // Find Leaderboard tab in bottom navigation
        final leaderboardTab = find.text('Leaderboard');
        expect(leaderboardTab, findsOneWidget);

        // Tap Leaderboard tab
        await tester.tap(leaderboardTab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Displays LeaderboardScreen
        expect(find.byType(LeaderboardScreen), findsOneWidget);
        expect(find.text('LEADERBOARD'), findsOneWidget);
        expect(find.text('YOUR RANK'), findsOneWidget);
      },
    );

    testWidgets(
      '12. Responsive layout on small screen (360x640) with zero overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: LeaderboardScreen(showBackButton: false),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('LEADERBOARD'), findsOneWidget);
        expect(find.text('YOUR RANK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
