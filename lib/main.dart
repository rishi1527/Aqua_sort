import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/game_service.dart';
import 'services/sound_service.dart';
import 'services/haptic_service.dart';
import 'services/rewarded_ad_service.dart';
import 'widgets/celebration_particles.dart';
import 'widgets/arcade_reward_widget.dart';
import 'widgets/level_complete_dialog.dart';
import 'widgets/timeout_dialog.dart';
import 'services/level_generator.dart';
import 'services/star_rating_service.dart';
import 'widgets/bottle_geometry.dart';
import 'widgets/background_painter.dart';
import 'models/bottle_model.dart';
import 'models/customization_models.dart';
import 'models/theme_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameService.instance.initialize();
  runApp(const WaterSortApp());
}

const List<Color> waterColors = [
  Color(0xFF38BDF8), // 0: Cyan / Sky Blue
  Color(0xFFFB7185), // 1: Rose / Coral Pink
  Color(0xFFA78BFA), // 2: Lavender / Purple
  Color(0xFF34D399), // 3: Emerald / Mint Green
  Color(0xFFFBBF24), // 4: Amber / Sunlight Gold
  Color(0xFFFB923C), // 5: Tangerine / Sunset Orange
  Color(0xFF3B82F6), // 6: Royal Sapphire Blue
  Color(0xFFE11D48), // 7: Crimson Ruby Red
  Color(0xFFA3E635), // 8: Electric Lime / Chartreuse
  Color(0xFFD946EF), // 9: Vivid Fuchsia / Magenta
];

class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aqua Sort',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class GameSnapshot {
  final List<List<int>> tubes;
  final int moves;

  GameSnapshot(this.tubes, this.moves);
}

class WaterSortScreen extends StatefulWidget {
  final int? initialLevel;
  const WaterSortScreen({super.key, this.initialLevel});

  @override
  State<WaterSortScreen> createState() => _WaterSortScreenState();
}

class _WaterSortScreenState extends State<WaterSortScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int capacity = 4;

  int level = 1;
  int moves = 0;
  int? selectedTube;
  int? hintTarget;

  // Level Countdown Timer & Timeout State
  Timer? _countdownTimer;
  int? _initialTimerSeconds;
  int? _remainingSeconds;
  bool _isTimerPaused = false;
  bool _isTimedOut = false;
  int _extraTimeRewardsCount = 0; // Max 2 per level attempt
  bool _inExtraTime = false;
  int? _remainingExtraSeconds;
  int _lastEarnedStars = 3;

  @visibleForTesting
  int? get initialTimerSecondsForTest => _initialTimerSeconds;

  @visibleForTesting
  int? get remainingSecondsForTest => _remainingSeconds;

  @visibleForTesting
  bool get isTimedOutForTest => _isTimedOut;

  @visibleForTesting
  int get extraTimeRewardsCountForTest => _extraTimeRewardsCount;

  @visibleForTesting
  bool get inExtraTimeForTest => _inExtraTime;

  @visibleForTesting
  int? get remainingExtraSecondsForTest => _remainingExtraSeconds;

  @visibleForTesting
  int get lastEarnedStarsForTest => _lastEarnedStars;

  @visibleForTesting
  void setRemainingSecondsForTest(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
    });
  }

  @visibleForTesting
  void setExtraTimeForTest({
    required bool inExtraTime,
    required int remainingSeconds,
    required int remainingExtraSeconds,
    int rewardsCount = 1,
  }) {
    setState(() {
      _inExtraTime = inExtraTime;
      _remainingSeconds = remainingSeconds;
      _remainingExtraSeconds = remainingExtraSeconds;
      _extraTimeRewardsCount = rewardsCount;
      _isTimedOut = false;
    });
  }

  @visibleForTesting
  void triggerTimeoutForTest() {
    setState(() {
      _remainingSeconds = 0;
      if (_inExtraTime) {
        _remainingExtraSeconds = 0;
      }
      _isTimedOut = true;
    });
    _cancelTimer();
  }

  @visibleForTesting
  Future<bool> claimExtraTimeForTest() => _claimExtraTime();

  bool won = false;
  bool extraTubeUsed = false;

  List<List<int>> tubes = [];
  List<List<int>> startingTubes = [];
  final List<GameSnapshot> history = [];

  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _pourController;
  late AnimationController _invalidController;
  late AnimationController _settleController;
  late AnimationController _bottleCelebrationController;
  late AnimationController _levelCelebrationController;

  // Pouring Animation State
  bool _isPouring = false;
  int? _pourFrom;
  int? _pourTo;
  int? _pourColor;
  int _pourAmount = 0;

  // Queued multi-move input during pouring
  int? _queuedSource;
  int? _queuedDest;

  @visibleForTesting
  int? get queuedSourceForTest => _queuedSource;

  @visibleForTesting
  int? get queuedDestForTest => _queuedDest;

  @visibleForTesting
  bool isBottleCompleteForTest(int index) =>
      index >= 0 && index < tubes.length && _isBottleComplete(tubes[index]);

  @visibleForTesting
  bool get isPouringForTest => _isPouring;

  @visibleForTesting
  int? get selectedTubeForTest => selectedTube;

  @visibleForTesting
  void setTubesForTest(List<List<int>> newTubes) {
    setState(() {
      tubes = copyTubes(newTubes);
      startingTubes = copyTubes(newTubes);
      _syncCompletedBottles();
    });
  }

  // Invalid move error / Settle states
  int? _invalidTube;
  int? _settlingTube;

  // Calculated tube placements for drawing stream, hit-testing, and particles
  final Map<int, Rect> _tubeRects = {};
  Size _lastBoardSize = const Size(360, 500);
  Size? _screenSize;

  // Completion celebration state & deduplication guards
  final Set<int> _completedBottles = {};
  bool _levelCelebrated = false;
  Rect? _celebratedBottleRect;
  Color? _celebratedBottleColor;
  List<CelebrationParticle> _bottleParticles = [];
  List<CelebrationParticle> _levelParticles = [];
  String? _rewardWord;
  double _rewardTilt = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Fluid surface wave controller (continuous gentle wave & rising micro-bubbles)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // 2. Pour animation controller (lift, arc flight, tilt, stream, drain/fill, return)
    _pourController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _pourController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _onPourCompleted();
      }
    });

    // 3. Invalid move error controller (subtle shake + bright red border fade, 500ms)
    _invalidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _invalidController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _invalidTube = null;
        });
      }
    });

    // 4. Settling liquid wave in destination bottle
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _settleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _settlingTube = null;
        });
      }
    });

    // 5. Bottle completion mini-celebration (sparkling particle burst & floating reward word, 850ms)
    _bottleCelebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _bottleCelebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _bottleParticles.clear();
          _celebratedBottleRect = null;
          _celebratedBottleColor = null;
          _rewardWord = null;
        });
      }
    });

    // 6. Full level major celebration (grand confetti explosion, 2600ms)
    _levelCelebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _levelCelebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _levelParticles.clear();
        });
      }
    });

    WidgetsBinding.instance.addObserver(this);

    final requestedLevel =
        widget.initialLevel ?? GameService.instance.currentLevel;
    final int start = GameService.instance.isLevelUnlocked(requestedLevel)
        ? requestedLevel.clamp(1, GameService.maxLevel)
        : GameService.instance.currentLevel.clamp(1, GameService.maxLevel);
    level = start;
    GameService.instance.addListener(_onGameServiceChange);
    loadLevel(start);
  }

  void _onGameServiceChange() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _resumeTimer();
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_initialTimerSeconds == null || won || _isTimedOut) return;

    _isTimerPaused = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTimerTick();
    });
  }

  void _pauseTimer() {
    _isTimerPaused = true;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _resumeTimer() {
    if (_initialTimerSeconds == null ||
        won ||
        _isTimedOut ||
        _remainingSeconds == null ||
        _remainingSeconds! <= 0) {
      return;
    }
    _isTimerPaused = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTimerTick();
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _onTimerTick() {
    if (!mounted || _isTimerPaused || won || _isTimedOut) return;
    if (_remainingSeconds == null) return;

    if (_remainingSeconds! > 1) {
      setState(() {
        _remainingSeconds = _remainingSeconds! - 1;
        if (_inExtraTime &&
            _remainingExtraSeconds != null &&
            _remainingExtraSeconds! > 1) {
          _remainingExtraSeconds = _remainingExtraSeconds! - 1;
        } else if (_inExtraTime && _remainingExtraSeconds != null) {
          _remainingExtraSeconds = 0;
        }
      });
    } else {
      setState(() {
        _remainingSeconds = 0;
        if (_inExtraTime) {
          _remainingExtraSeconds = 0;
        }
        _isTimedOut = true;
      });
      _cancelTimer();
      SoundService.instance.playInvalidMove();
      HapticService.instance.invalidMove();
    }
  }

  Future<bool> _claimExtraTime() async {
    if (_extraTimeRewardsCount >= 2) return false;
    final result = await RewardedAdService.instance.showExtraTimeAd();
    if (result == RewardedAdResult.rewardEarned) {
      setState(() {
        _extraTimeRewardsCount++;
        _inExtraTime = true;
        _remainingExtraSeconds = 60;
        _remainingSeconds = 60;
        _isTimedOut = false;
      });
      _startTimer();
      return true;
    }
    return false;
  }

  String _formatTimer(int seconds) {
    final int safeSeconds = seconds < 0 ? 0 : seconds;
    final int m = safeSeconds ~/ 60;
    final int s = safeSeconds % 60;
    final String mm = m.toString().padLeft(2, '0');
    final String ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void didUpdateWidget(WaterSortScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLevel != null &&
        widget.initialLevel != oldWidget.initialLevel &&
        GameService.instance.isLevelUnlocked(widget.initialLevel!)) {
      loadLevel(widget.initialLevel!.clamp(1, GameService.maxLevel));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    GameService.instance.removeListener(_onGameServiceChange);
    _waveController.dispose();
    _pourController.dispose();
    _invalidController.dispose();
    _settleController.dispose();
    _bottleCelebrationController.dispose();
    _levelCelebrationController.dispose();
    super.dispose();
  }

  List<List<int>> makeLevel(int levelNumber) {
    return LevelGenerator.getLevel(levelNumber);
  }

  List<List<int>> copyTubes(List<List<int>> source) {
    return source.map((tube) => List<int>.from(tube)).toList();
  }

  bool _isBottleComplete(List<int> tube) {
    if (tube.length != capacity) return false;
    return tube.every((color) => color == tube.first);
  }

  void _syncCompletedBottles() {
    _completedBottles.clear();
    for (int i = 0; i < tubes.length; i++) {
      if (_isBottleComplete(tubes[i])) {
        _completedBottles.add(i);
      }
    }
  }

  void loadLevel(int levelNumber) {
    _cancelTimer();
    final newTubes = makeLevel(levelNumber);
    final initialTimer = LevelGenerator.getInitialTimerSeconds(levelNumber);

    _bottleCelebrationController.stop();
    _levelCelebrationController.stop();
    _bottleParticles.clear();
    _levelParticles.clear();
    _celebratedBottleRect = null;
    _celebratedBottleColor = null;
    _rewardWord = null;
    _levelCelebrated = false;

    setState(() {
      level = levelNumber;
      tubes = copyTubes(newTubes);
      startingTubes = copyTubes(newTubes);
      moves = 0;
      selectedTube = null;
      hintTarget = null;
      _queuedSource = null;
      _queuedDest = null;
      won = false;
      extraTubeUsed = false;
      _isPouring = false;
      _pourFrom = null;
      _pourTo = null;
      _pourColor = null;
      _pourAmount = 0;
      _invalidTube = null;
      _settlingTube = null;
      history.clear();
      _syncCompletedBottles();

      _isTimedOut = false;
      _extraTimeRewardsCount = 0;
      _inExtraTime = false;
      _remainingExtraSeconds = null;
      _lastEarnedStars = 3;
      _initialTimerSeconds = initialTimer;
      _remainingSeconds = initialTimer;
    });

    if (initialTimer != null) {
      _startTimer();
    }
  }

  void saveHistory() {
    history.add(GameSnapshot(copyTubes(tubes), moves));
  }

  bool canPour(int from, int to) {
    if (from == to || tubes[from].isEmpty) return false;
    if (_isBottleComplete(tubes[from])) return false;
    if (tubes[to].length >= capacity) return false;
    if (tubes[to].isEmpty) return true;
    return tubes[from].last == tubes[to].last;
  }

  void _triggerInvalidMove(int tubeIndex) {
    setState(() {
      _invalidTube = tubeIndex;
    });
    _invalidController.forward(from: 0.0);
    SoundService.instance.playInvalidMove();
    HapticService.instance.invalidMove();
  }

  void onTubeTap(int index) {
    if (won || _isTimedOut) return;

    if (_isPouring) {
      _handlePouringTap(index);
      return;
    }

    _handleNormalTap(index);
  }

  void _handleNormalTap(int index) {
    if (selectedTube == null) {
      if (tubes[index].isEmpty) {
        // Tapped empty tube with nothing selected
        _triggerInvalidMove(index);
        return;
      }
      if (_isBottleComplete(tubes[index])) {
        // Completed bottle cannot be selected as a source
        _triggerInvalidMove(index);
        return;
      }

      setState(() {
        selectedTube = index;
        hintTarget = null;
      });
      SoundService.instance.playBottleSelect();
      HapticService.instance.bottleSelect();
      return;
    }

    final from = selectedTube!;

    if (from == index) {
      // Deselect
      setState(() {
        selectedTube = null;
        hintTarget = null;
      });
      SoundService.instance.playBottleSelect();
      HapticService.instance.bottleSelect();
      return;
    }

    if (canPour(from, index)) {
      startPourAnimation(from, index);
      return;
    }

    // Invalid move attempt: destination tube cannot receive water from the selected tube
    _triggerInvalidMove(index);
  }

  void _handlePouringTap(int index) {
    if (index >= tubes.length) return;

    // 1. If no next source bottle is queued yet:
    if (_queuedSource == null) {
      // Ignore taps on the bottles actively animating in the current pour
      if (index == _pourFrom || index == _pourTo) {
        return;
      }

      // Empty tube cannot be a source
      if (tubes[index].isEmpty) {
        _triggerInvalidMove(index);
        return;
      }

      // Completed bottle cannot be selected as source
      if (_isBottleComplete(tubes[index])) {
        _triggerInvalidMove(index);
        return;
      }

      // Valid source bottle queued!
      setState(() {
        _queuedSource = index;
        _queuedDest = null;
      });
      SoundService.instance.playBottleSelect();
      HapticService.instance.bottleSelect();
      return;
    }

    // 2. A source is already queued:
    if (index == _queuedSource) {
      // Tapping the queued source bottle again deselects it
      setState(() {
        _queuedSource = null;
        _queuedDest = null;
      });
      SoundService.instance.playBottleSelect();
      HapticService.instance.bottleSelect();
      return;
    }

    // 3. Prevent duplicate taps on destination:
    if (_queuedDest == index) {
      // Already queued as destination, ignore duplicate tap
      return;
    }

    // 4. Completed bottle cannot receive water
    if (_isBottleComplete(tubes[index])) {
      _triggerInvalidMove(index);
      return;
    }

    // 5. Destination queued!
    setState(() {
      _queuedDest = index;
    });
    SoundService.instance.playBottleSelect();
    HapticService.instance.bottleSelect();
  }

  void startPourAnimation(int from, int to) {
    if (!canPour(from, to) || _isPouring) return;

    final color = tubes[from].last;
    int amount = 0;
    for (int i = tubes[from].length - 1; i >= 0; i--) {
      if (tubes[from][i] == color && (tubes[to].length + amount) < capacity) {
        amount++;
      } else {
        break;
      }
    }
    if (amount == 0) return;

    setState(() {
      _isPouring = true;
      _pourFrom = from;
      _pourTo = to;
      _pourColor = color;
      _pourAmount = amount;
      selectedTube = null; // Clear active board selection; during pour _queuedSource tracks pre-selection
      hintTarget = null;
    });

    SoundService.instance.playWaterPour();
    HapticService.instance.pourStart();

    _pourController.forward(from: 0.0);
  }

  void _onPourCompleted() {
    if (!_isPouring || _pourFrom == null || _pourTo == null) return;

    saveHistory();

    final from = _pourFrom!;
    final to = _pourTo!;
    final color = _pourColor!;
    int transferred = 0;

    while (tubes[from].isNotEmpty &&
        tubes[from].last == color &&
        tubes[to].length < capacity &&
        transferred < _pourAmount) {
      tubes[to].add(tubes[from].removeLast());
      transferred++;
    }

    if (transferred > 0) {
      moves++;
    }

    final completedLevel = checkWon();

    // Deduplication: identify tubes that transitioned from incomplete to complete
    final newlyCompletedTubes = <int>[];
    for (int i = 0; i < tubes.length; i++) {
      if (_isBottleComplete(tubes[i]) && !_completedBottles.contains(i)) {
        _completedBottles.add(i);
        newlyCompletedTubes.add(i);
      }
    }

    // Extract and clear queued multi-move selections
    final nextSource = _queuedSource;
    final nextDest = _queuedDest;
    _queuedSource = null;
    _queuedDest = null;

    if (completedLevel) {
      setState(() {
        _isPouring = false;
        _pourFrom = null;
        _pourTo = null;
        _pourColor = null;
        _pourAmount = 0;
        selectedTube = null;
        _settlingTube = to;
        won = true;
      });

      _cancelTimer();

      _settleController.forward(from: 0.0);

      if (!_levelCelebrated) {
        _levelCelebrated = true;
        final int earnedStars = StarRatingService.calculateStars(
          level: level,
          moves: moves,
          originalTimerSeconds: _initialTimerSeconds,
          remainingOriginalSeconds: _inExtraTime ? 0 : _remainingSeconds,
          inExtraTime: _inExtraTime,
          remainingExtraTimeSeconds: _remainingExtraSeconds,
          isWon: true,
        );
        _lastEarnedStars = earnedStars;
        GameService.instance.completeLevel(
          level,
          moves,
          earnedStars: earnedStars,
        );
        _triggerLevelCelebration();
        // Also fire mini-burst particles on the final completed bottle without floating reward word
        if (newlyCompletedTubes.isNotEmpty) {
          _triggerBottleCelebration(
            newlyCompletedTubes.last,
            playAudioAndHaptic: false,
            showRewardWord: false,
          );
        }
      }
      return;
    }

    // Preceding move finished, level is not won yet
    setState(() {
      _isPouring = false;
      _pourFrom = null;
      _pourTo = null;
      _pourColor = null;
      _pourAmount = 0;
      selectedTube = null;
      _settlingTube = to;
      won = false;
    });

    _settleController.forward(from: 0.0);

    if (newlyCompletedTubes.isNotEmpty) {
      // Individual bottle completion: mini celebration burst + chime + strong haptic pulse + arcade reward word
      _triggerBottleCelebration(
        newlyCompletedTubes.last,
        playAudioAndHaptic: true,
        showRewardWord: true,
      );
    } else {
      SoundService.instance.playWaterSettle();
      HapticService.instance.pourComplete();
    }

    // Process queued multi-move input after state update
    if (nextSource != null && nextDest != null) {
      // Re-validate queued move against authoritative updated state
      if (nextSource < tubes.length &&
          nextDest < tubes.length &&
          canPour(nextSource, nextDest)) {
        startPourAnimation(nextSource, nextDest);
      } else {
        // Move became invalid because of the preceding move; safely cancel and reset selection
        setState(() {
          selectedTube = null;
        });
        if (nextDest < tubes.length) {
          _triggerInvalidMove(nextDest);
        }
      }
    } else if (nextSource != null) {
      // Only source was queued. Re-validate against updated state
      if (nextSource < tubes.length &&
          tubes[nextSource].isNotEmpty &&
          !_isBottleComplete(tubes[nextSource])) {
        setState(() {
          selectedTube = nextSource;
        });
      } else {
        setState(() {
          selectedTube = null;
        });
      }
    }
  }

  void _triggerBottleCelebration(
    int tubeIndex, {
    bool playAudioAndHaptic = true,
    bool showRewardWord = true,
  }) {
    final rect = _tubeRects[tubeIndex];
    if (rect == null) return;

    final Color accentColor = tubes[tubeIndex].isNotEmpty
        ? GameService.instance.getLiquidColor(tubes[tubeIndex].first)
        : AppTheme.aquaGlow;

    final particles = CelebrationParticle.createBottleBurst(
      bottleRect: rect,
      bottleAccentColor: accentColor,
      count: 28,
    );

    final String? rewardWord = showRewardWord ? getRandomRewardWord() : null;
    final double tiltSeed = showRewardWord
        ? ((math.Random().nextDouble() * 0.12) - 0.06) // ~ -3.4° to +3.4°
        : 0.0;

    setState(() {
      _celebratedBottleRect = rect;
      _celebratedBottleColor = accentColor;
      _bottleParticles = particles;
      _rewardWord = rewardWord;
      _rewardTilt = tiltSeed;
    });

    if (playAudioAndHaptic) {
      SoundService.instance.playBottleComplete();
      HapticService.instance.bottleComplete();
    }

    _bottleCelebrationController.forward(from: 0.0);
  }

  @visibleForTesting
  void triggerBottleCelebrationForTest(int tubeIndex, {required bool won}) {
    if (won) {
      _triggerBottleCelebration(
        tubeIndex,
        playAudioAndHaptic: false,
        showRewardWord: false,
      );
    } else {
      _triggerBottleCelebration(
        tubeIndex,
        playAudioAndHaptic: true,
        showRewardWord: true,
      );
    }
  }

  void _triggerLevelCelebration() {
    final Size celebrationSize = _screenSize ?? _lastBoardSize;
    final particles = CelebrationParticle.createLevelConfetti(
      boardSize: celebrationSize,
      count: 140,
    );

    setState(() {
      _levelParticles = particles;
    });

    SoundService.instance.playLevelComplete();
    HapticService.instance.levelComplete();

    _levelCelebrationController.forward(from: 0.0);
  }

  bool checkWon() {
    return tubes.every((tube) {
      if (tube.isEmpty) return true;
      if (tube.length != capacity) return false;
      return tube.every((color) => color == tube.first);
    });
  }

  void undoMove() {
    if (history.isEmpty || won || _isPouring) return;

    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();

    _bottleCelebrationController.stop();
    _bottleParticles.clear();
    _celebratedBottleRect = null;
    _celebratedBottleColor = null;
    _rewardWord = null;

    setState(() {
      final previous = history.removeLast();
      tubes = copyTubes(previous.tubes);
      moves = previous.moves;
      selectedTube = null;
      hintTarget = null;
      _queuedSource = null;
      _queuedDest = null;
      // If undo reverted a completed bottle back to incomplete, remove from guard set
      _completedBottles.removeWhere(
        (idx) => idx >= tubes.length || !_isBottleComplete(tubes[idx]),
      );
    });
  }

  void restartLevel() {
    if (_isPouring) return;

    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();

    _cancelTimer();

    _bottleCelebrationController.stop();
    _levelCelebrationController.stop();
    _bottleParticles.clear();
    _levelParticles.clear();
    _celebratedBottleRect = null;
    _celebratedBottleColor = null;
    _rewardWord = null;
    _levelCelebrated = false;

    setState(() {
      tubes = copyTubes(startingTubes);
      moves = 0;
      selectedTube = null;
      hintTarget = null;
      _queuedSource = null;
      _queuedDest = null;
      won = false;
      extraTubeUsed = false;
      _isPouring = false;
      _pourFrom = null;
      _pourTo = null;
      _pourColor = null;
      _pourAmount = 0;
      _invalidTube = null;
      _settlingTube = null;
      history.clear();
      _syncCompletedBottles();

      _isTimedOut = false;
      _extraTimeRewardsCount = 0;
      _inExtraTime = false;
      _remainingExtraSeconds = null;
      _lastEarnedStars = 3;
      _remainingSeconds = _initialTimerSeconds;
    });

    if (_initialTimerSeconds != null) {
      _startTimer();
    }
  }

  void useHint() {
    if (won || _isPouring) return;

    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();

    for (int from = 0; from < tubes.length; from++) {
      for (int to = 0; to < tubes.length; to++) {
        if (canPour(from, to)) {
          setState(() {
            selectedTube = from;
            hintTarget = to;
            _queuedSource = null;
            _queuedDest = null;
          });
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No available moves! Try restarting or adding a tube.'),
      ),
    );
  }

  void addExtraTube() {
    if (extraTubeUsed || won || _isPouring) return;

    SoundService.instance.playExtraTube();
    HapticService.instance.extraTube();

    setState(() {
      saveHistory();
      tubes.add([]);
      extraTubeUsed = true;
      selectedTube = null;
      hintTarget = null;
      _queuedSource = null;
      _queuedDest = null;
    });
  }

  void nextLevel() {
    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();

    if (level >= GameService.maxLevel) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        restartLevel();
      }
      return;
    }

    loadLevel(level + 1);
  }

  void _openSettings() {
    _pauseTimer();
    final gameService = GameService.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: AppTheme.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD0F7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          color: AppTheme.aquaGlow,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Game Settings',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.iceWhite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.volume_up_rounded,
                        color: AppTheme.aquaGlow,
                      ),
                      title: const Text(
                        'Sound Effects',
                        style: TextStyle(
                          color: AppTheme.iceWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Water pouring and glass sounds',
                        style: TextStyle(
                          color: Color(0xFF6B5B85),
                          fontSize: 12,
                        ),
                      ),
                      value: gameService.soundEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        gameService.setSound(val);
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.vibration_rounded,
                        color: AppTheme.aquaGlow,
                      ),
                      title: const Text(
                        'Haptic Feedback',
                        style: TextStyle(
                          color: AppTheme.iceWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Tactile vibrations during gameplay',
                        style: TextStyle(
                          color: Color(0xFF6B5B85),
                          fontSize: 12,
                        ),
                      ),
                      value: gameService.hapticsEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        gameService.setHaptics(val);
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.developer_mode_rounded,
                        color: AppTheme.aquaGlow,
                      ),
                      title: const Text(
                        'Unlock All Levels (Testing)',
                        style: TextStyle(
                          color: AppTheme.iceWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Play all 100 levels across all chapters',
                        style: TextStyle(
                          color: Color(0xFF6B5B85),
                          fontSize: 12,
                        ),
                      ),
                      value: gameService.isDebugUnlockAllLevelsEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        gameService.setDebugUnlockAllLevels(val);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) _resumeTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
    final GameTheme currentTheme = GameService.instance.currentTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF020704),
      body: GameBackgroundWidget(
        background: GameService.instance.currentBackground,
        theme: currentTheme,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  buildHeader(),
                  const SizedBox(height: 6),
                  buildStats(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return buildTubes(constraints);
                      },
                    ),
                  ),
                  buildControls(),
                  const SizedBox(height: 10),
                ],
              ),
              if (won) buildWinOverlay(),
              if (_isTimedOut) buildTimeoutOverlay(),
              // Full-screen confetti celebration overlay (renders above gameplay board AND level-completion UI background)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _levelCelebrationController,
                      builder: (context, _) {
                        if (_levelCelebrationController.value == 0.0 ||
                            _levelParticles.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return CustomPaint(
                          painter: CelebrationPainter(
                            levelProgress: _levelCelebrationController.value,
                            levelParticles: _levelParticles,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button / Settings
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFDDD0F7), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: canPop
                  ? () => Navigator.of(context).pop()
                  : _openSettings,
              icon: Icon(
                canPop ? Icons.arrow_back_rounded : Icons.settings_rounded,
                color: AppTheme.primaryFixed,
                size: 19,
              ),
              tooltip: canPop ? 'Back to Home' : 'Settings',
            ),
          ),

          // AquaSort Branding Pill
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDDD0F7),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: AppTheme.primaryContainer,
                      size: 17,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AQUA SORT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppTheme.iceWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Actions: Quick Sound Toggle & Restart Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFFDDD0F7),
                    width: 1.0,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      SoundService.instance.toggleSound();
                    });
                  },
                  icon: Icon(
                    SoundService.instance.soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: AppTheme.primaryFixed,
                    size: 18,
                  ),
                  tooltip: 'Toggle Sound',
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFFDDD0F7),
                    width: 1.0,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: restartLevel,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primaryFixed,
                    size: 19,
                  ),
                  tooltip: 'Restart level',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStats() {
    final tier = LevelGenerator.getTier(level);
    final String tierName = LevelGenerator.getTierName(level).toUpperCase();
    final Color tierColor = switch (tier) {
      DifficultyTier.easy => const Color(0xFF34D399),
      DifficultyTier.medium => const Color(0xFF38BDF8),
      DifficultyTier.hard => const Color(0xFFFBBF24),
      DifficultyTier.veryHard => const Color(0xFFFB923C),
      DifficultyTier.expert => const Color(0xFFFB7185),
    };

    final bool isTimed = _initialTimerSeconds != null;
    final int remaining = _remainingSeconds ?? _initialTimerSeconds ?? 0;
    final bool isLowTime = isTimed && remaining <= 10;
    final String formattedTime = _formatTimer(remaining);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Left: Level Badge with Glowing Cyan Dot
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFDDD0F7), width: 1.0),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceTint,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xE56D28D9),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LEVEL',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$level',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Chapter / Tier Pill
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFDDD0F7), width: 1.0),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tierName,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),

          // Timer Countdown Pill (Levels 4-100 only)
          if (isTimed) ...[
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                key: const ValueKey('gameplay_timer_pill'),
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isLowTime
                      ? const Color(0xFFE11D48).withValues(alpha: 0.35)
                      : AppTheme.surfaceContainerLow.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: isLowTime
                        ? const Color(0xFFFB7185)
                        : const Color(0xFFDDD0F7),
                    width: isLowTime ? 1.5 : 1.0,
                  ),
                  boxShadow: isLowTime
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE11D48)
                                .withValues(alpha: 0.45),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: isLowTime
                            ? const Color(0xFFFB7185)
                            : const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        key: const ValueKey('gameplay_timer_text'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLowTime
                              ? const Color(0xFFFB7185)
                              : AppTheme.primaryFixed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 5),

          // Right: Moves Counter
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFDDD0F7), width: 1.0),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 16,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'MOVES',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$moves',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTubes(BoxConstraints constraints) {
    final int n = tubes.length;
    final double availableWidth = constraints.maxWidth;
    final double availableHeight = constraints.maxHeight;
    _lastBoardSize = Size(availableWidth, availableHeight);

    // Responsive candidate row options based on bottle count
    final List<int> candidateRows = [];
    if (n <= 4) {
      candidateRows.addAll([1, 2]);
    } else if (n <= 8) {
      candidateRows.add(2);
    } else if (n <= 12) {
      candidateRows.addAll([2, 3]);
    } else {
      candidateRows.addAll([3, 4]);
    }

    int bestRows = candidateRows.first;
    double bestArea = 0;
    double bestWidth = 48;
    double bestHeight = 160;
    List<int> bestDistribution = _distributeTubes(n, bestRows);

    for (final r in candidateRows) {
      final List<int> dist = _distributeTubes(n, r);
      final int maxCols = dist.reduce(math.max);

      final double spacingX = maxCols >= 6
          ? 6.0
          : (maxCols >= 5 ? 8.0 : (maxCols == 4 ? 12.0 : 16.0));
      final double spacingY = r == 1 ? 0.0 : (r == 2 ? 18.0 : 12.0);
      const double liftAllowance = 26.0;

      final double usableW = availableWidth - (maxCols - 1) * spacingX - 24.0;
      final double usableH =
          availableHeight - (r - 1) * spacingY - liftAllowance - 16.0;

      if (usableW <= 0 || usableH <= 0) continue;

      final double maxWPerTube = usableW / maxCols;
      final double maxHPerTube = usableH / r;
      final double targetRatio = (maxCols >= 6) ? 0.27 : 0.285;

      double w, h;
      if (maxWPerTube / targetRatio <= maxHPerTube) {
        w = maxWPerTube.clamp(32.0, 60.0);
        h = (w / targetRatio).clamp(95.0, maxHPerTube);
      } else {
        h = maxHPerTube.clamp(95.0, 190.0);
        w = (h * targetRatio).clamp(32.0, maxWPerTube);
      }

      final double area = w * h;
      if (area > bestArea) {
        bestArea = area;
        bestRows = r;
        bestWidth = w;
        bestHeight = h;
        bestDistribution = dist;
      }
    }

    final int maxCols = bestDistribution.reduce(math.max);
    final double spacingX = maxCols >= 6
        ? 6.0
        : (maxCols >= 5 ? 8.0 : (maxCols == 4 ? 12.0 : 16.0));
    final double spacingY = bestRows == 1 ? 0.0 : (bestRows == 2 ? 18.0 : 12.0);

    // Calculate grid positions for all tubes
    _tubeRects.clear();
    final double totalGridH =
        bestDistribution.length * bestHeight +
        (bestDistribution.length - 1) * spacingY;
    final double startY = math.max(10.0, (availableHeight - totalGridH) / 2);

    int tubeIdx = 0;
    for (int r = 0; r < bestDistribution.length; r++) {
      final int rowCount = bestDistribution[r];
      final double totalRowW = rowCount * bestWidth + (rowCount - 1) * spacingX;
      final double rowX = math.max(0.0, (availableWidth - totalRowW) / 2);
      final double rowY = startY + r * (bestHeight + spacingY);

      for (int c = 0; c < rowCount; c++) {
        final int idx = tubeIdx++;
        final double tX = rowX + c * (bestWidth + spacingX);
        _tubeRects[idx] = Rect.fromLTWH(tX, rowY, bestWidth, bestHeight);
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveController,
        _pourController,
        _invalidController,
        _settleController,
      ]),
      builder: (context, child) {
        // Determine pouring animation parameters dynamically on EVERY animation frame
        Offset? streamSource;
        Offset? streamDest;
        Color? streamColor;
        double sourceTiltAngle = 0.0;
        Offset sourceTiltOffset = Offset.zero;
        double drainProgress = 0.0;
        double fillProgress = 0.0;
        double streamAlpha = 0.0;
        double streamTiltDir = 1.0;

        if (_isPouring &&
            _pourFrom != null &&
            _pourTo != null &&
            _tubeRects.containsKey(_pourFrom) &&
            _tubeRects.containsKey(_pourTo)) {
          final Rect fromRect = _tubeRects[_pourFrom!]!;
          final Rect toRect = _tubeRects[_pourTo!]!;
          final double pourProgress = _pourController.value;

          final double dx = toRect.center.dx - fromRect.center.dx;
          final double tiltDir = dx >= 0 ? 1.0 : -1.0;
          streamTiltDir = tiltDir;

          // Natural pouring tilt: ~56 degrees initially, deepening to ~67 degrees as bottle empties
          final double initialTilt = tiltDir * 0.98; // ~56.1 degrees
          final double deepTilt = tiltDir * 1.17; // ~67.0 degrees

          // Destination bottle mouth position
          final Offset destMouth = Offset(toRect.center.dx, toRect.top + 4.0);

          // Where the pouring mouth edge should hover relative to destination mouth
          final double desiredLipX =
              destMouth.dx - tiltDir * (bestWidth * 0.30);
          final double desiredLipY =
              destMouth.dy - (bestHeight * 0.175).clamp(20.0, 28.0);

          // Local mouth coordinates relative to rotation pivot (w / 2, 0)
          final double rxLocal = tiltDir * (bestWidth * 0.36);
          const double ryLocal = 4.0;

          Offset calcRotatedLip(double angle) {
            final double cosA = math.cos(angle);
            final double sinA = math.sin(angle);
            return Offset(
              rxLocal * cosA - ryLocal * sinA,
              rxLocal * sinA + ryLocal * cosA,
            );
          }

          // Compute hover translation offset so bottle mouth lands at (desiredLipX, desiredLipY)
          final Offset initialRotLip = calcRotatedLip(initialTilt);
          final double hoverTx =
              desiredLipX - fromRect.center.dx - initialRotLip.dx;
          final double hoverTy = desiredLipY - fromRect.top - initialRotLip.dy;

          // Dynamic flight arc height (lifting upward gracefully)
          final double arcFlightHeight = -math.min(
            32.0,
            availableHeight * 0.10,
          );

          if (pourProgress < 0.28) {
            // --- PHASE 1 (0.00 -> 0.28, ~266ms): Lift upward, glide in arc to hover, tilt to initial angle ---
            final double p1 = pourProgress / 0.28;
            final double easeMove = Curves.easeOutCubic.transform(p1);

            // Gentle parabolic lift during flight
            final double arcLift = arcFlightHeight * math.sin(p1 * math.pi);
            sourceTiltOffset = Offset(
              hoverTx * easeMove,
              hoverTy * easeMove + arcLift,
            );

            // Smooth progressive tilt during approach
            final double tiltProg = ((p1 - 0.15) / 0.85).clamp(0.0, 1.0);
            sourceTiltAngle =
                initialTilt * Curves.easeInOutQuad.transform(tiltProg);

            drainProgress = 0.0;
            fillProgress = 0.0;
            streamAlpha = 0.0;
          } else if (pourProgress <= 0.78) {
            // --- PHASE 2 (0.28 -> 0.78, ~475ms): Continuous stream, deepen tilt, synchronized drain & fill ---
            final double p2 = (pourProgress - 0.28) / 0.50; // 0.0 -> 1.0
            final double easeP2 = Curves.easeInOutSine.transform(p2);

            sourceTiltAngle = initialTilt + (deepTilt - initialTilt) * easeP2;

            // Keep the pouring mouth pinned right above destination mouth as tilt deepens
            final Offset currentRotLip = calcRotatedLip(sourceTiltAngle);
            sourceTiltOffset = Offset(
              desiredLipX - fromRect.center.dx - currentRotLip.dx,
              desiredLipY - fromRect.top - currentRotLip.dy,
            );

            drainProgress = p2;
            fillProgress = p2;

            // Fast stream emergence at start (30ms), clean fade before end
            if (p2 < 0.08) {
              streamAlpha = (p2 / 0.08).clamp(0.0, 1.0);
            } else if (p2 > 0.92) {
              streamAlpha = ((1.0 - p2) / 0.08).clamp(0.0, 1.0);
            } else {
              streamAlpha = 1.0;
            }
          } else {
            // --- PHASE 3 (0.78 -> 1.00, ~209ms): Stream cutoff, upright rotation, return arc flight ---
            final double p3 = (pourProgress - 0.78) / 0.22; // 0.0 -> 1.0
            final double easeReturn = Curves.easeInOutCubic.transform(p3);

            final double returnArc =
                (arcFlightHeight * 0.6) * math.sin(p3 * math.pi);
            sourceTiltOffset = Offset(
              hoverTx * (1.0 - easeReturn),
              hoverTy * (1.0 - easeReturn) + returnArc,
            );

            sourceTiltAngle = deepTilt * (1.0 - easeReturn);

            drainProgress = 1.0;
            fillProgress = 1.0;
            streamAlpha = 0.0;
          }

          // Exact pixel coordinates of source bottle mouth in container space
          final Offset curLip = calcRotatedLip(sourceTiltAngle);
          streamSource = Offset(
            fromRect.center.dx + sourceTiltOffset.dx + curLip.dx,
            fromRect.top + sourceTiltOffset.dy + curLip.dy,
          );
          streamDest = destMouth;

          if (_pourColor != null) {
            streamColor = GameService.instance.getLiquidColor(_pourColor!);
          }
        }

        final List<Widget> tubeWidgets = [];

        // Order tubes so the moving source bottle is ALWAYS on top of all resting bottles
        final List<int> renderIndices = [];
        for (int i = 0; i < n; i++) {
          if (_isPouring && _pourFrom == i) continue;
          renderIndices.add(i);
        }
        if (_isPouring && _pourFrom != null && _pourFrom! < n) {
          renderIndices.add(_pourFrom!);
        }

        // Build all tubes based on computed rects and custom Z-order
        for (final i in renderIndices) {
          final Rect rect = _tubeRects[i] ?? Rect.zero;
          final bool isSelected = _isPouring
              ? (_queuedSource == i)
              : (selectedTube == i);
          final bool isHintTarget = hintTarget == i;
          final int? activeSource = _isPouring ? _queuedSource : selectedTube;
          final bool isValidDest =
              (_isPouring && _queuedDest == i) ||
              (activeSource != null && canPour(activeSource, i));
          final bool isInvalid = _invalidTube == i;
          final bool isSettling = _settlingTube == i;
          final bool isSourcePouring = _isPouring && _pourFrom == i;
          final bool isDestPouring = _isPouring && _pourTo == i;

          double shakeDx = 0.0;
          double errorIntensity = 0.0;

          if (isInvalid) {
            final double t = _invalidController.value;
            // Shake during first 250ms (decaying sine wave)
            if (t < 0.5) {
              final double p = t / 0.5;
              shakeDx = math.sin(p * math.pi * 6) * 5.5 * (1.0 - p);
            }
            // Red border visible for 400-600ms (solid for 300ms, then smooth ease-out fade for 200ms)
            if (t < 0.6) {
              errorIntensity = 1.0;
            } else {
              final double fade = (t - 0.6) / 0.4;
              errorIntensity = (1.0 - Curves.easeOutCubic.transform(fade))
                  .clamp(0.0, 1.0);
            }
          }

          final double currentTiltAngle = isSourcePouring
              ? sourceTiltAngle
              : 0.0;
          final Offset currentOffset = isSourcePouring
              ? sourceTiltOffset
              : Offset(shakeDx, isSelected ? -12.0 : 0.0);

          final int drainingAmount = isSourcePouring ? _pourAmount : 0;
          final double currentDrainProg = isSourcePouring ? drainProgress : 0.0;
          final int? fillingColor = isDestPouring ? _pourColor : null;
          final int fillingAmount = isDestPouring ? _pourAmount : 0;
          final double currentFillProg = isDestPouring ? fillProgress : 0.0;
          final double settleProg = isSettling ? _settleController.value : 1.0;

          tubeWidgets.add(
            Positioned(
              key: ValueKey('tube_$i'),
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: TubeWidget(
                width: rect.width,
                height: rect.height,
                colors: tubes[i],
                selected: isSelected,
                hintTarget: isHintTarget,
                isValidTarget: isValidDest,
                isHighlighted: isSelected || isHintTarget || isValidDest,
                isInvalid: isInvalid,
                errorIntensity: errorIntensity,
                tiltAngle: currentTiltAngle,
                translationOffset: currentOffset,
                drainingAmount: drainingAmount,
                drainProgress: currentDrainProg,
                fillingColor: fillingColor,
                fillingAmount: fillingAmount,
                fillProgress: currentFillProg,
                settlingProgress: settleProg,
                wavePhase: (_waveController.value * math.pi * 2) + (i * 1.35),
                onTap: () => onTubeTap(i),
              ),
            ),
          );
        }

        final boardStack = Stack(
          clipBehavior: Clip.none,
          children: [
            // Glass card behind bottles with subtle translucency so theme image is clearly visible
            Positioned(
              left: 10,
              right: 10,
              top: 6,
              bottom: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            ...tubeWidgets,
            // Pouring continuous narrow water stream overlay
            if (_isPouring &&
                streamAlpha > 0.001 &&
                streamSource != null &&
                streamDest != null &&
                streamColor != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PourStreamPainter(
                      source: streamSource,
                      dest: streamDest,
                      color: streamColor,
                      alpha: streamAlpha,
                      wavePhase: _waveController.value * math.pi * 2,
                      tiltDir: streamTiltDir,
                    ),
                  ),
                ),
              ),
            // Bottle burst particles & tube aura celebration overlay
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _bottleCelebrationController,
                      _levelCelebrationController,
                    ]),
                    builder: (context, _) {
                      if (_bottleCelebrationController.value == 0.0 &&
                          _levelCelebrationController.value == 0.0 &&
                          _bottleParticles.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        painter: CelebrationPainter(
                          bottleProgress: _bottleCelebrationController.value,
                          bottleParticles: _bottleParticles,
                          bottleRect: _celebratedBottleRect,
                          bottleColor: _celebratedBottleColor,
                          levelProgress: _levelCelebrationController.value,
                          levelParticles: const [],
                          tubeRects: _tubeRects.values.toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Floating arcade-style reward words overlay on bottle completion
            if (_rewardWord != null && _celebratedBottleRect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _bottleCelebrationController,
                      builder: (context, _) {
                        return ArcadeRewardOverlay(
                          word: _rewardWord,
                          progress: _bottleCelebrationController.value,
                          bottleRect: _celebratedBottleRect,
                          boardSize: Size(availableWidth, availableHeight),
                          accentColor: _celebratedBottleColor,
                          tilt: _rewardTilt,
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );

        if (totalGridH + 24.0 > availableHeight) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: availableWidth,
              height: totalGridH + 28.0,
              child: boardStack,
            ),
          );
        }

        return boardStack;
      },
    );
  }

  List<int> _distributeTubes(int n, int r) {
    if (r <= 1) return [n];
    final int base = n ~/ r;
    final int remainder = n % r;
    return List.generate(r, (i) => base + (i < remainder ? 1 : 0));
  }

  Widget buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Action 1: Undo (with move history count badge)
          Expanded(
            child: controlButton(
              icon: Icons.undo_rounded,
              label: 'UNDO',
              onTap: undoMove,
              enabled: history.isNotEmpty && !won && !_isPouring,
              iconColor: AppTheme.primaryFixed,
              badgeText: history.isNotEmpty ? '${history.length}' : null,
              badgeBg: AppTheme.secondaryContainer,
              badgeFg: AppTheme.onSecondary,
            ),
          ),
          const SizedBox(width: 8),

          // Action 2: Hint (with Free badge)
          Expanded(
            child: controlButton(
              icon: Icons.lightbulb_rounded,
              label: 'HINT',
              onTap: useHint,
              enabled: !won && !_isPouring,
              iconColor: AppTheme.tertiaryFixedDim,
              badgeText: 'Free',
              badgeBg: AppTheme.tertiaryContainer,
              badgeFg: AppTheme.onTertiary,
            ),
          ),
          const SizedBox(width: 8),

          // Action 3: + Tube (with +1 badge)
          Expanded(
            child: controlButton(
              icon: Icons.science_rounded,
              label: extraTubeUsed ? 'USED' : '+ TUBE',
              onTap: addExtraTube,
              enabled: !extraTubeUsed && !won && !_isPouring,
              iconColor: AppTheme.primary,
              badgeText: extraTubeUsed ? null : '+1',
              badgeBg: AppTheme.primaryContainer,
              badgeFg: AppTheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),

          // Action 4: Restart
          Expanded(
            child: controlButton(
              icon: Icons.refresh_rounded,
              label: 'RESTART',
              onTap: restartLevel,
              enabled: !won && !_isPouring,
              iconColor: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
    Color? iconColor,
    String? badgeText,
    Color? badgeBg,
    Color? badgeFg,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.surfaceContainer.withValues(alpha: 0.75)
                : AppTheme.surfaceContainer.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFDDD0F7)
                  : const Color(0x40DDD0F7),
              width: 1.0,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: enabled
                        ? (iconColor ?? AppTheme.aquaGlow)
                        : const Color(0x666B5B85),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: enabled
                          ? AppTheme.onSurfaceVariant
                          : const Color(0x666B5B85),
                    ),
                  ),
                ],
              ),
              if (badgeText != null && enabled)
                Positioned(
                  top: -2,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg ?? AppTheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: badgeFg ?? AppTheme.onSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWinOverlay() {
    final int currentBest = GameService.instance.getStarsForLevel(level);
    final int streak = GameService.instance.currentStreak;

    return LevelCompleteDialog(
      level: level,
      moves: moves,
      stars: _lastEarnedStars,
      bestStars: currentBest,
      streak: streak,
      maxLevel: GameService.maxLevel,
      onNextLevel: nextLevel,
      onPlayAgain: restartLevel,
    );
  }

  Widget buildTimeoutOverlay() {
    return TimeoutDialog(
      level: level,
      rewardsUsed: _extraTimeRewardsCount,
      maxRewards: 2,
      onClaimExtraTime: _claimExtraTime,
      onRetry: restartLevel,
      onReturnToMap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

class TubeWidget extends StatelessWidget {
  final List<int> colors;
  final bool selected;
  final bool hintTarget;
  final bool isValidTarget;
  final bool isHighlighted;
  final VoidCallback onTap;
  final bool isInvalid;
  final double errorIntensity;
  final double width;
  final double height;
  final double tiltAngle;
  final Offset translationOffset;
  final int drainingAmount;
  final double drainProgress;
  final int? fillingColor;
  final int fillingAmount;
  final double fillProgress;
  final double settlingProgress;
  final double wavePhase;

  const TubeWidget({
    super.key,
    required this.colors,
    required this.selected,
    required this.hintTarget,
    required this.onTap,
    this.isValidTarget = false,
    this.isHighlighted = false,
    this.isInvalid = false,
    this.errorIntensity = 0.0,
    this.width = 48.0,
    this.height = 160.0,
    this.tiltAngle = 0.0,
    this.translationOffset = Offset.zero,
    this.drainingAmount = 0,
    this.drainProgress = 0.0,
    this.fillingColor,
    this.fillingAmount = 0,
    this.fillProgress = 0.0,
    this.settlingProgress = 1.0,
    this.wavePhase = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color highlightColor = (hintTarget || isValidTarget)
        ? const Color(0xFF00E676)
        : (selected ? AppTheme.aquaGlow : Colors.transparent);

    final gameService = GameService.instance;
    final currentBottle = gameService.currentBottle;
    final currentCap = gameService.currentCap;
    final currentFx = gameService.currentBubbleFx;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.translationValues(
          translationOffset.dx,
          translationOffset.dy,
          0.0,
        )..rotateZ(tiltAngle),
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            size: Size(width, height),
            painter: _TubePainter(
              colors: colors,
              selected: selected,
              hintTarget: hintTarget,
              isValidTarget: isValidTarget,
              isHighlighted: isHighlighted,
              isInvalid: isInvalid,
              errorIntensity: errorIntensity,
              highlightColor: highlightColor,
              drainingAmount: drainingAmount,
              drainProgress: drainProgress,
              fillingColor: fillingColor,
              fillingAmount: fillingAmount,
              fillProgress: fillProgress,
              settlingProgress: settlingProgress,
              wavePhase: wavePhase,
              tiltAngle: tiltAngle,
              bottleShape: currentBottle.shape,
              capType: currentCap.type,
              capGemColor: currentCap.gemColor,
              supportsCap: currentBottle.supportsCap,
              bubbleFxType: currentFx.type,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidSegment {
  final Color color;
  final double heightUnits;
  _LiquidSegment(this.color, this.heightUnits);
}

class _TubePainter extends CustomPainter {
  final List<int> colors;
  final bool selected;
  final bool hintTarget;
  final bool isValidTarget;
  final bool isHighlighted;
  final bool isInvalid;
  final double errorIntensity;
  final Color highlightColor;
  final int drainingAmount;
  final double drainProgress;
  final int? fillingColor;
  final int fillingAmount;
  final double fillProgress;
  final double settlingProgress;
  final double wavePhase;
  final double tiltAngle;
  final BottleShape bottleShape;
  final CapType capType;
  final Color capGemColor;
  final bool supportsCap;
  final BubbleFxType bubbleFxType;

  _TubePainter({
    required this.colors,
    required this.selected,
    required this.hintTarget,
    required this.isValidTarget,
    required this.isHighlighted,
    this.isInvalid = false,
    this.errorIntensity = 0.0,
    required this.highlightColor,
    required this.drainingAmount,
    required this.drainProgress,
    required this.fillingColor,
    required this.fillingAmount,
    required this.fillProgress,
    required this.settlingProgress,
    required this.wavePhase,
    this.tiltAngle = 0.0,
    this.bottleShape = BottleShape.classic,
    this.capType = CapType.none,
    this.capGemColor = const Color(0xFF9333EA),
    this.supportsCap = true,
    this.bubbleFxType = BubbleFxType.sodaFizz,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final geometry = BottleGeometry(bottleShape);
    final Path cavityPath = geometry.getCavityPath(size);
    final Path outline = geometry.getOuterPath(size);
    final double topCavityY = geometry.getTopCavityY(size);
    final double bottomY = geometry.getBottomY(size);
    const int capacity = 4;
    final double slotH = (bottomY - topCavityY) / capacity;
    final double baseRadius = w * 0.44;

    final Rect cavityBounds = cavityPath.getBounds();
    final double innerLeft = cavityBounds.left.clamp(0.0, w * 0.4);
    final double innerRight = cavityBounds.right.clamp(w * 0.6, w);
    final double neckTop = (h * 0.038).clamp(5.0, 7.5);
    final double bodyTop = topCavityY - 6.0;
    final double bodyHeight = bottomY - bodyTop;

    // 1. Ambient drop shadow & grounding rim (ensures silhouette pops against bright/busy backgrounds)
    final Paint dropShadowPaint = Paint()
      ..color = const Color(0x66020617)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6;
    canvas.drawPath(outline, dropShadowPaint);

    final Paint cavityBackingShadow = Paint()
      ..color = const Color(0x28000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cavityPath, cavityBackingShadow);

    // 2. Translucent cartoon glass backing (provides rich physical volume while keeping background visible)
    final Paint glassBackingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.24),
          const Color(0xFF0F172A).withValues(alpha: 0.38),
        ],
      ).createShader(Rect.fromLTWH(0, topCavityY, w, bottomY - topCavityY))
      ..style = PaintingStyle.fill;
    canvas.drawPath(cavityPath, glassBackingPaint);

    // 3. Liquid layers (smooth, non-rectangular fluid volumes)
    canvas.save();
    canvas.clipPath(cavityPath);

    // Prepare active color segments to render
    final List<Color> activeLiquidColors = [];
    for (int c in colors) {
      activeLiquidColors.add(GameService.instance.getLiquidColor(c));
    }

    final int baseCount = activeLiquidColors.length;
    final List<_LiquidSegment> segments = [];

    // Base colors (with sequential drain reduction if this bottle is pouring)
    for (int i = 0; i < baseCount; i++) {
      double units = 1.0;
      if (drainingAmount > 0 && i >= baseCount - drainingAmount) {
        final int drainRankFromTop = (baseCount - 1) - i;
        final double unitsDrainedSoFar = drainingAmount * drainProgress;
        final double drainedFromThis = (unitsDrainedSoFar - drainRankFromTop)
            .clamp(0.0, 1.0);
        units = (1.0 - drainedFromThis).clamp(0.0, 1.0);
      }
      if (units > 0.001) {
        segments.add(_LiquidSegment(activeLiquidColors[i], units));
      }
    }

    // Incoming color (if this bottle is receiving a pour)
    if (fillingColor != null && fillingAmount > 0 && fillProgress > 0.001) {
      double existingUnits = 0.0;
      for (final s in segments) {
        existingUnits += s.heightUnits;
      }
      final double maxIncoming = (capacity - existingUnits).clamp(0.0, 4.0);
      final double inUnits = (fillingAmount * fillProgress).clamp(
        0.0,
        maxIncoming,
      );

      if (inUnits > 0.001) {
        final Color inColor = GameService.instance.getLiquidColor(
          fillingColor!,
        );
        if (segments.isNotEmpty && segments.last.color == inColor) {
          segments[segments.length - 1] = _LiquidSegment(
            inColor,
            segments.last.heightUnits + inUnits,
          );
        } else {
          segments.add(_LiquidSegment(inColor, inUnits));
        }
      }
    }

    if (segments.isNotEmpty) {
      // Calculate cumulative unit heights
      final List<double> topUnits = [];
      double runningUnits = 0.0;
      for (final seg in segments) {
        runningUnits += seg.heightUnits;
        topUnits.add(runningUnits.clamp(0.0, capacity.toDouble()));
      }

      // Helper to compute surface curve points across the width
      List<Offset> computeSurfacePoints({
        required double unitLevel,
        required double amp,
        required double curv,
        required double phaseOffset,
      }) {
        final List<Offset> points = [];
        const int steps = 32;
        final double yBase = (bottomY - unitLevel * slotH).clamp(
          topCavityY - 4.0,
          bottomY,
        );
        final double dx = (innerRight - innerLeft) / steps;
        final double cx = (innerLeft + innerRight) / 2;
        // Gravity compensation: slant water level opposite to bottle tilt
        final double slope = -math.tan(tiltAngle.clamp(-1.25, 1.25));

        // Damped settling slosh rocking naturally across the bottle
        double settleSlosh = 0.0;
        if (settlingProgress < 0.99) {
          settleSlosh =
              math.sin(settlingProgress * math.pi * 4.5) *
              math.exp(-settlingProgress * 3.4) *
              4.8;
        }

        for (int s = 0; s <= steps; s++) {
          final double x = innerLeft + s * dx;
          final double u = s / steps; // 0.0 to 1.0

          // Slant due to gravity
          final double tiltDy = (x - cx) * slope;

          // Continuous sinusoidal wave ripple with harmonic
          double waveDy =
              math.sin(u * math.pi * 2 + wavePhase + phaseOffset) * amp;
          waveDy +=
              math.sin(u * math.pi * 4 - (wavePhase + phaseOffset) * 0.7) *
              (amp * 0.28);
          if (isHighlighted) {
            waveDy +=
                math.sin(u * math.pi * 3 + (wavePhase + phaseOffset) * 1.6) *
                0.5;
          }

          // Concave capillary meniscus: gently curves up at glass walls, soft dip in center
          final double meniscusDy = curv * (1.0 - 4.0 * (u - 0.5) * (u - 0.5));

          // Slosh rocking
          final double sloshDy = (u - 0.5) * settleSlosh;

          final double y = (yBase + tiltDy + waveDy + meniscusDy + sloshDy)
              .clamp(neckTop + 1.0, h + 4.0);
          points.add(Offset(x, y));
        }
        return points;
      }

      List<Offset>? previousTopPoints;

      for (int k = 0; k < segments.length; k++) {
        final bool isTopmost = k == segments.length - 1;

        // Wave amplitude and curvature dynamics
        double topAmp = 0.5; // gentle internal layer movement
        double topCurv = 1.0;

        if (isTopmost) {
          if (settlingProgress < 0.99) {
            topAmp = 3.8 * (1.0 - settlingProgress) + 1.2;
          } else if (drainingAmount > 0 ||
              (fillingColor != null && fillProgress > 0)) {
            topAmp = 3.0;
          } else if (isHighlighted) {
            topAmp = 2.6;
          } else {
            topAmp = 1.2; // idle soothing breathing wave
          }
          topCurv = 1.5;
        }

        final topPoints = computeSurfacePoints(
          unitLevel: topUnits[k],
          amp: topAmp,
          curv: topCurv,
          phaseOffset: k * 0.45,
        );

        final Path layerPath = Path();

        if (k == 0) {
          // Bottom-most liquid layer fills cleanly to the inner bottom of the bottle.
          // It is clipped precisely by cavityPath to the bottle's inner rounded bottom.
          layerPath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          layerPath.lineTo(w + 10.0, h + 10.0);
          layerPath.lineTo(-10.0, h + 10.0);
          layerPath.close();
        } else {
          // Upper liquid layers nest seamlessly on top of the meniscus curve of the layer below
          layerPath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          layerPath.lineTo(
            previousTopPoints!.last.dx,
            previousTopPoints.last.dy,
          );
          for (final pt in previousTopPoints.reversed) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          layerPath.close();
        }

        // 1. Vibrant multi-stop liquid shader with realistic depth
        final Color col = segments[k].color;
        final double segTopY = bottomY - topUnits[k] * slotH;
        final double segBotY = k == 0 ? h : bottomY - topUnits[k - 1] * slotH;
        final Rect segRect = Rect.fromLTRB(
          0,
          segTopY - 12.0,
          w,
          segBotY + 12.0,
        );

        final Paint segPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              col.withValues(alpha: 0.90), // luminous light-catching surface
              col.withValues(alpha: 0.98), // rich vibrant liquid body
              Color.lerp(
                col,
                const Color(0xFF030D1A),
                0.28,
              )!, // natural depth shading
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(segRect);

        canvas.drawPath(layerPath, segPaint);

        // 2. Horizontal cylindrical volume lighting (gives realistic 3D round fullness)
        final Paint cylinderShade = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.04),
              Colors.black.withValues(alpha: 0.22),
            ],
            stops: const [0.0, 0.28, 0.65, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, w, h));

        canvas.drawPath(layerPath, cylinderShade);

        // Fluid boundary between adjacent liquid layers
        if (k > 0 && previousTopPoints != null) {
          final Path interPath = Path();
          interPath.moveTo(
            previousTopPoints.first.dx,
            previousTopPoints.first.dy,
          );
          for (final pt in previousTopPoints) {
            interPath.lineTo(pt.dx, pt.dy);
          }

          // Translucent meniscus highlight along the boundary
          final Paint interHighlight = Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawPath(interPath, interHighlight);

          // Subtle contact shadow below the boundary
          final Paint interShadow = Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7;
          canvas.drawPath(interPath, interShadow);
        }

        // Topmost exposed liquid surface crest, ambient glow, and specular meniscus
        if (isTopmost) {
          final Path surfacePath = Path();
          surfacePath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            surfacePath.lineTo(pt.dx, pt.dy);
          }

          // Soft ambient water glow
          final Paint surfGlow = Paint()
            ..color = col.withValues(alpha: 0.30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfGlow);

          // Illuminated specular meniscus crest
          final Paint surfCrest = Paint()
            ..color = Colors.white.withValues(alpha: 0.68)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfCrest);

          // Fine bright glint along center of meniscus
          final Paint surfGlint = Paint()
            ..color = Colors.white.withValues(alpha: 0.90)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfGlint);
        }

        // Subtle rising micro-bubbles inside this liquid layer
        final double segH = segBotY - segTopY;

        if (segH > 10.0) {
          final Paint bubblePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.fill;
          final Paint bubbleGlint = Paint()
            ..color = Colors.white.withValues(alpha: 0.50)
            ..style = PaintingStyle.fill;

          // Bubble 1
          final double b1Prog = ((wavePhase / (2 * math.pi) + k * 0.38) % 1.0);
          final double b1Y = segBotY - b1Prog * segH * 0.88;
          final double b1X =
              innerLeft +
              (innerRight - innerLeft) * 0.32 +
              math.sin(b1Prog * math.pi * 4) * 2.6;
          if (b1Y > segTopY + 3.0) {
            canvas.drawCircle(Offset(b1X, b1Y), 1.2, bubblePaint);
            canvas.drawCircle(Offset(b1X - 0.3, b1Y - 0.3), 0.4, bubbleGlint);
          }

          // Bubble 2
          final double b2Prog =
              (((wavePhase / (2 * math.pi)) * 0.8 + k * 0.62 + 0.4) % 1.0);
          final double b2Y = segBotY - b2Prog * segH * 0.88;
          final double b2X =
              innerLeft +
              (innerRight - innerLeft) * 0.68 +
              math.cos(b2Prog * math.pi * 3) * 2.2;
          if (b2Y > segTopY + 3.0) {
            canvas.drawCircle(Offset(b2X, b2Y), 1.1, bubblePaint);
            canvas.drawCircle(Offset(b2X - 0.2, b2Y - 0.2), 0.3, bubbleGlint);
          }
        }

        previousTopPoints = topPoints;
      }
    }

    // Specular glass interior depth gradient
    final Paint innerShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.16),
        ],
      ).createShader(Rect.fromLTWH(0, bodyTop, w, bodyHeight));
    canvas.drawRect(Rect.fromLTWH(0, bodyTop, w, bodyHeight), innerShade);

    // Bubble FX inside liquid
    if (bubbleFxType != BubbleFxType.none && segments.isNotEmpty) {
      BubbleFxPainter.paintFx(
        canvas: canvas,
        liquidRect: Rect.fromLTRB(innerLeft, topCavityY, innerRight, bottomY),
        fxType: bubbleFxType,
        animationValue: wavePhase / (2 * math.pi),
      );
    }

    canvas.restore();

    // 4. Subtle outer bottom curve glass reflection
    final Path bottomGlint = Path();
    bottomGlint.moveTo(w * 0.22, h - 3.0);
    bottomGlint.quadraticBezierTo(w * 0.5, h - 1.2, w * 0.78, h - 3.0);
    final Paint bottomGlintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(bottomGlint, bottomGlintPaint);

    // 5. Outer Bottle Outline Path (using geometry outline)
    const Color errorRed = Color(0xFFFF3B4F);

    if (isInvalid && errorIntensity > 0.0) {
      // Bright Red Glow Blur
      final Paint redGlow = Paint()
        ..color = errorRed.withValues(alpha: 0.52 * errorIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8;
      canvas.drawPath(outline, redGlow);

      // Bright Red Outer Border
      final Paint redBorder = Paint()
        ..color = errorRed.withValues(alpha: errorIntensity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6;
      canvas.drawPath(outline, redBorder);

      // Smooth cross-fade to normal glass border as it fades out
      if (errorIntensity < 0.95) {
        final double baseAlpha = (1.0 - errorIntensity) * 0.36;
        final Paint normalStroke = Paint()
          ..color = Colors.white.withValues(alpha: baseAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawPath(outline, normalStroke);
      }
    } else {
      // Glow shadow if highlighted (bottle selected or valid target)
      if (isHighlighted) {
        final Paint glowPaint = Paint()
          ..color = highlightColor.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2;
        canvas.drawPath(outline, glowPaint);
      }

      // Outer stroke with clean glass shimmer
      final Paint strokePaint = Paint()
        ..color = isHighlighted
            ? highlightColor
            : Colors.white.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2.2 : 1.4;
      canvas.drawPath(outline, strokePaint);
    }

    // 6. Top Lip (Mouth ring)
    final double lipHeight = (h * 0.038).clamp(5.0, 7.5);
    final double lipWidth =
        w *
        (bottleShape == BottleShape.classic ||
                bottleShape == BottleShape.classicTube
            ? 1.08
            : 0.76);
    final RRect lipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, lipHeight / 2),
        width: lipWidth,
        height: lipHeight,
      ),
      const Radius.circular(3.0),
    );

    final Paint lipFill = Paint()
      ..color = const Color(0xFF132B47).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lipRect, lipFill);

    // Top rim highlight on the lip
    final Path lipTopHighlight = Path();
    lipTopHighlight.moveTo(w * 0.15, lipHeight * 0.25);
    lipTopHighlight.lineTo(w * 0.85, lipHeight * 0.25);
    final Paint lipTopPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(lipTopHighlight, lipTopPaint);

    if (isInvalid && errorIntensity > 0.0) {
      final Paint redLipGlow = Paint()
        ..color = errorRed.withValues(alpha: 0.45 * errorIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawRRect(lipRect, redLipGlow);

      final Paint redLipStroke = Paint()
        ..color = errorRed.withValues(alpha: errorIntensity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(lipRect, redLipStroke);
    } else {
      final Paint lipStroke = Paint()
        ..color = isHighlighted
            ? highlightColor
            : Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawRRect(lipRect, lipStroke);
    }

    // 7. Glass Glare Streak down left (Primary reflection)
    final Path leftGlare = Path();
    leftGlare.moveTo(w * 0.15, bodyTop + 8);
    leftGlare.lineTo(w * 0.15, h - baseRadius * 1.15);

    final Paint glarePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.32),
              Colors.white.withValues(alpha: 0.10),
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              bodyTop + 8,
              w,
              h - baseRadius * 1.15 - (bodyTop + 8),
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftGlare, glarePaint);

    // Secondary subtle left highlight
    final Path secondaryGlare = Path();
    secondaryGlare.moveTo(w * 0.24, bodyTop + 12);
    secondaryGlare.lineTo(w * 0.24, bodyTop + 34);

    final Paint secGlarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(secondaryGlare, secGlarePaint);

    // Right rim Fresnel reflection
    final Path rightRimGlint = Path();
    rightRimGlint.moveTo(w * 0.86, bodyTop + 10);
    rightRimGlint.lineTo(w * 0.86, h - baseRadius * 1.1);

    final Paint rightRimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(rightRimGlint, rightRimPaint);

    // 8. Stitch Floor Glow Indicator under bottle
    final Paint floorGlowPaint = Paint()
      ..color = selected
          ? AppTheme.surfaceTint.withValues(alpha: 0.65)
          : (isHighlighted
                ? highlightColor.withValues(alpha: 0.40)
                : AppTheme.primary.withValues(alpha: 0.16))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, selected ? 4.5 : 2.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h + 3.0),
        width: selected ? w * 0.65 : w * 0.50,
        height: selected ? 4.0 : 3.0,
      ),
      floorGlowPaint,
    );

    // 9. Bottle Cap (rendered when bottle is upright)
    if (supportsCap &&
        capType != CapType.none &&
        drainingAmount == 0 &&
        tiltAngle.abs() < 0.1) {
      BottleCapPainter.paintCap(
        canvas: canvas,
        anchor: geometry.getCapAnchor(size),
        capType: capType,
        gemColor: capGemColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TubePainter old) => true;
}

class PourStreamPainter extends CustomPainter {
  final Offset source;
  final Offset dest;
  final Color color;
  final double alpha;
  final double wavePhase;
  final double tiltDir;

  PourStreamPainter({
    required this.source,
    required this.dest,
    required this.color,
    required this.alpha,
    required this.wavePhase,
    required this.tiltDir,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.001) return;

    // Cubic bezier control points from source mouth to destination mouth
    final Offset cp1 = Offset(source.dx + tiltDir * 10.0, source.dy + 5.0);
    final Offset cp2 = Offset(dest.dx, dest.dy - 18.0);

    // Construct a smooth, naturally tapering 2D liquid ribbon
    const int steps = 24;
    const double wStart = 5.4; // wider at pouring mouth
    const double wEnd =
        3.2; // naturally accelerated & tapered at destination mouth

    final List<Offset> leftRibbon = [];
    final List<Offset> rightRibbon = [];
    final List<Offset> centerLine = [];

    Offset evalCubic(double t) {
      final double u = 1.0 - t;
      final double tt = t * t;
      final double uu = u * u;
      final double uuu = uu * u;
      final double ttt = tt * t;

      final double x =
          uuu * source.dx +
          3 * uu * t * cp1.dx +
          3 * u * tt * cp2.dx +
          ttt * dest.dx;
      final double y =
          uuu * source.dy +
          3 * uu * t * cp1.dy +
          3 * u * tt * cp2.dy +
          ttt * dest.dy;
      return Offset(x, y);
    }

    Offset evalCubicDerivative(double t) {
      final double u = 1.0 - t;
      final double dx =
          3 * u * u * (cp1.dx - source.dx) +
          6 * u * t * (cp2.dx - cp1.dx) +
          3 * t * t * (dest.dx - cp2.dx);
      final double dy =
          3 * u * u * (cp1.dy - source.dy) +
          6 * u * t * (cp2.dy - cp1.dy) +
          3 * t * t * (dest.dy - cp2.dy);
      return Offset(dx, dy);
    }

    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      final Offset pt = evalCubic(t);
      centerLine.add(pt);

      final Offset deriv = evalCubicDerivative(t);
      final double len = math.sqrt(deriv.dx * deriv.dx + deriv.dy * deriv.dy);
      final Offset normal = len > 0.0001
          ? Offset(-deriv.dy / len, deriv.dx / len)
          : const Offset(1, 0);

      // Width tapers with gentle fluid wave shimmer
      final double baseHalfW = (wStart + (wEnd - wStart) * t) / 2.0;
      final double shimmer =
          math.sin(t * math.pi * 6.0 - wavePhase * 2.5) * 0.28;
      final double halfW = (baseHalfW + shimmer).clamp(1.2, 3.5);

      leftRibbon.add(
        Offset(pt.dx + normal.dx * halfW, pt.dy + normal.dy * halfW),
      );
      rightRibbon.add(
        Offset(pt.dx - normal.dx * halfW, pt.dy - normal.dy * halfW),
      );
    }

    final Path ribbonPath = Path();
    ribbonPath.moveTo(leftRibbon.first.dx, leftRibbon.first.dy);
    for (final pt in leftRibbon) {
      ribbonPath.lineTo(pt.dx, pt.dy);
    }
    for (final pt in rightRibbon.reversed) {
      ribbonPath.lineTo(pt.dx, pt.dy);
    }
    ribbonPath.close();

    // 1. Soft atmospheric water glow
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.38 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, glowPaint);

    // 2. Vibrant liquid ribbon body
    final Paint streamPaint = Paint()
      ..color = color.withValues(alpha: 0.94 * alpha)
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, streamPaint);

    // 3. Crisp specular white highlight along the stream centerline
    final Path centerPath = Path();
    centerPath.moveTo(centerLine.first.dx, centerLine.first.dy);
    for (final pt in centerLine) {
      centerPath.lineTo(pt.dx, pt.dy);
    }

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.76 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(centerPath, highlightPaint);

    // 4. Traveling luminous glints down the stream
    final Paint glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * alpha)
      ..style = PaintingStyle.fill;

    for (int g = 0; g < 2; g++) {
      final double gProg = ((wavePhase / (math.pi * 2) * 1.5 + g * 0.5) % 1.0);
      final Offset gPt = evalCubic(gProg);
      canvas.drawCircle(gPt, 1.3, glintPaint);
    }

    // 5. Impact ripple rings and micro-droplets at destination mouth
    final Paint ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double rippleW = 7.0 + math.sin(wavePhase * 2.0) * 2.0;
    canvas.drawOval(
      Rect.fromCenter(center: dest, width: rippleW, height: 2.8),
      ripplePaint,
    );

    final Paint splashPaint = Paint()
      ..color = color.withValues(alpha: 0.82 * alpha)
      ..style = PaintingStyle.fill;
    final Paint splashGlint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65 * alpha)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final double splashPhase = (wavePhase * 1.8 + i * 1.57) % (math.pi * 2);
      final double sx = dest.dx + math.sin(splashPhase) * 5.0;
      final double sy = dest.dy - math.cos(splashPhase).abs() * 6.5;
      final double r = 0.9 + (i % 2) * 0.45;
      canvas.drawCircle(Offset(sx, sy), r, splashPaint);
      canvas.drawCircle(Offset(sx - 0.25, sy - 0.25), r * 0.4, splashGlint);
    }
  }

  @override
  bool shouldRepaint(covariant PourStreamPainter old) => true;
}
