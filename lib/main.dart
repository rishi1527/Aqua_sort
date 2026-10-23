import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/game_service.dart';
import 'services/sound_service.dart';
import 'services/haptic_service.dart';

void main() {
  runApp(const WaterSortApp());
}

const List<Color> waterColors = [
  Color(0xFF38BDF8), // Cyan / Sky Blue
  Color(0xFFFB7185), // Rose / Coral Pink
  Color(0xFFA78BFA), // Lavender / Purple
  Color(0xFF34D399), // Emerald / Mint Green
  Color(0xFFFBBF24), // Amber / Sunlight Gold
  Color(0xFFFB923C), // Tangerine / Sunset Orange
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
    with TickerProviderStateMixin {
  static const int capacity = 4;

  int level = 1;
  int moves = 0;
  int? selectedTube;
  int? hintTarget;

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

  // Pouring Animation State
  bool _isPouring = false;
  int? _pourFrom;
  int? _pourTo;
  int? _pourColor;
  int _pourAmount = 0;

  // Invalid move error / Settle states
  int? _invalidTube;
  int? _settlingTube;

  // Calculated tube placements for drawing stream and hit-testing
  final Map<int, Rect> _tubeRects = {};

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

    final start = widget.initialLevel ?? GameService.instance.currentLevel;
    loadLevel(start);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pourController.dispose();
    _invalidController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  List<List<int>> makeLevel(int levelNumber) {
    final int colorCount = (3 + ((levelNumber - 1) ~/ 2)).clamp(3, 6);
    final List<List<int>> result = [];

    // Every color appears exactly four times
    for (int tube = 0; tube < colorCount; tube++) {
      result.add(
        List.generate(
          capacity,
          (row) => (tube + row + levelNumber - 1) % colorCount,
        ),
      );
    }

    // Two empty tubes for sorting
    result.add([]);
    result.add([]);

    return result;
  }

  List<List<int>> copyTubes(List<List<int>> source) {
    return source.map((tube) => List<int>.from(tube)).toList();
  }

  void loadLevel(int levelNumber) {
    final newTubes = makeLevel(levelNumber);

    setState(() {
      level = levelNumber;
      tubes = copyTubes(newTubes);
      startingTubes = copyTubes(newTubes);
      moves = 0;
      selectedTube = null;
      hintTarget = null;
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
    });
  }

  void saveHistory() {
    history.add(GameSnapshot(copyTubes(tubes), moves));
  }

  bool canPour(int from, int to) {
    if (from == to || tubes[from].isEmpty) return false;
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
    if (won || _isPouring) return;

    if (selectedTube == null) {
      if (tubes[index].isNotEmpty) {
        setState(() {
          selectedTube = index;
          hintTarget = null;
        });
        SoundService.instance.playBottleSelect();
        HapticService.instance.bottleSelect();
      } else {
        // Tapped empty tube with nothing selected
        _triggerInvalidMove(index);
      }
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
      selectedTube = from; // Keep selected source bottle identified
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

    SoundService.instance.playWaterSettle();
    HapticService.instance.pourComplete();

    setState(() {
      _isPouring = false;
      _pourFrom = null;
      _pourTo = null;
      _pourColor = null;
      _pourAmount = 0;
      selectedTube = null;
      _settlingTube = to;
      won = completedLevel;
    });

    _settleController.forward(from: 0.0);

    if (won) {
      GameService.instance.completeLevel(level, moves);
      SoundService.instance.playLevelComplete();
      HapticService.instance.levelComplete();
    }
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

    setState(() {
      final previous = history.removeLast();
      tubes = copyTubes(previous.tubes);
      moves = previous.moves;
      selectedTube = null;
      hintTarget = null;
    });
  }

  void restartLevel() {
    if (_isPouring) return;

    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();

    setState(() {
      tubes = copyTubes(startingTubes);
      moves = 0;
      selectedTube = null;
      hintTarget = null;
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
    });
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
    });
  }

  void nextLevel() {
    loadLevel(level + 1);
  }

  void _openSettings() {
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
                color: const Color(0xFF0A1B30),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppTheme.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
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
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings_rounded, color: AppTheme.aquaGlow, size: 22),
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
                      secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.aquaGlow),
                      title: const Text(
                        'Sound Effects',
                        style: TextStyle(color: AppTheme.iceWhite, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Water pouring and glass sounds',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: gameService.soundEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        gameService.setSound(val);
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_rounded, color: AppTheme.aquaGlow),
                      title: const Text(
                        'Haptic Feedback',
                        style: TextStyle(color: AppTheme.iceWhite, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Tactile vibrations during gameplay',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: gameService.hapticsEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        gameService.setHaptics(val);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071A33),
              Color(0xFF091329),
              Color(0xFF050B18),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  buildHeader(),
                  const SizedBox(height: 4),
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
          if (canPop)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.iceWhite, size: 20),
              tooltip: 'Back to Home',
            )
          else
            IconButton(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_rounded, color: AppTheme.iceWhite, size: 21),
              tooltip: 'Settings',
            ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF38D9FF),
                          Color(0xFF087ECA),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.aquaGlow.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AQUA SORT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: AppTheme.iceWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: restartLevel,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.iceWhite, size: 22),
            tooltip: 'Restart level',
          ),
        ],
      ),
    );
  }

  Widget buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: compactStatCard(
              Icons.flag_rounded,
              'LEVEL',
              '$level',
              AppTheme.aquaGlow,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: compactStatCard(
              Icons.swap_vert_rounded,
              'MOVES',
              '$moves',
              const Color(0xFFA78BFA),
            ),
          ),
        ],
      ),
    );
  }

  Widget compactStatCard(
    IconData icon,
    String label,
    String value,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F38).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.glassBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0x99EAF7FF),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.iceWhite,
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

    // For 5 to 8 tubes, enforce 2 rows. Never squeeze 5+ tubes into a single row.
    final List<int> candidateRows = [];
    if (n <= 4) {
      candidateRows.addAll([1, 2]);
    } else if (n <= 8) {
      candidateRows.add(2);
    } else {
      candidateRows.addAll([2, 3]);
    }

    int bestRows = candidateRows.first;
    double bestArea = 0;
    double bestWidth = 48;
    double bestHeight = 160;
    List<int> bestDistribution = _distributeTubes(n, bestRows);

    for (final r in candidateRows) {
      final List<int> dist = _distributeTubes(n, r);
      final int maxCols = dist.reduce(math.max);

      final double spacingX = maxCols >= 5 ? 8.0 : (maxCols == 4 ? 12.0 : 16.0);
      final double spacingY = r == 1 ? 0.0 : (r == 2 ? 18.0 : 12.0);
      const double liftAllowance = 26.0;

      final double usableW = availableWidth - (maxCols - 1) * spacingX - 28.0;
      final double usableH = availableHeight - (r - 1) * spacingY - liftAllowance - 16.0;

      if (usableW <= 0 || usableH <= 0) continue;

      final double maxWPerTube = usableW / maxCols;
      final double maxHPerTube = usableH / r;
      const double targetRatio = 0.28; // width / height

      double w, h;
      if (maxWPerTube / targetRatio <= maxHPerTube) {
        w = maxWPerTube.clamp(28.0, 62.0);
        h = (w / targetRatio).clamp(75.0, maxHPerTube);
      } else {
        h = maxHPerTube.clamp(75.0, 190.0);
        w = (h * targetRatio).clamp(28.0, maxWPerTube);
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
    final double spacingX = maxCols >= 5 ? 8.0 : (maxCols == 4 ? 12.0 : 16.0);
    final double spacingY = bestRows == 1 ? 0.0 : (bestRows == 2 ? 18.0 : 12.0);

    // Calculate grid positions for all tubes
    _tubeRects.clear();
    final double totalGridH = bestDistribution.length * bestHeight + (bestDistribution.length - 1) * spacingY;
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
      animation: Listenable.merge([_waveController, _pourController, _invalidController, _settleController]),
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
          final double deepTilt = tiltDir * 1.17;    // ~67.0 degrees

          // Destination bottle mouth position
          final Offset destMouth = Offset(toRect.center.dx, toRect.top + 4.0);

          // Where the pouring mouth edge should hover relative to destination mouth
          final double desiredLipX = destMouth.dx - tiltDir * (bestWidth * 0.30);
          final double desiredLipY = destMouth.dy - 28.0;

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
          final double hoverTx = desiredLipX - fromRect.center.dx - initialRotLip.dx;
          final double hoverTy = desiredLipY - fromRect.top - initialRotLip.dy;

          // Dynamic flight arc height (lifting upward gracefully)
          final double arcFlightHeight = -math.min(32.0, availableHeight * 0.10);

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
            sourceTiltAngle = initialTilt * Curves.easeInOutQuad.transform(tiltProg);

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

            final double returnArc = (arcFlightHeight * 0.6) * math.sin(p3 * math.pi);
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

          if (_pourColor != null && _pourColor! < waterColors.length) {
            streamColor = waterColors[_pourColor!];
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
          final bool isSelected = selectedTube == i;
          final bool isHintTarget = hintTarget == i;
          final bool isValidDest = selectedTube != null && canPour(selectedTube!, i);
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
              errorIntensity = (1.0 - Curves.easeOutCubic.transform(fade)).clamp(0.0, 1.0);
            }
          }

          final double currentTiltAngle = isSourcePouring ? sourceTiltAngle : 0.0;
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
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
          ],
        );
      },
    );
  }

  List<int> _distributeTubes(int n, int r) {
    if (r <= 1) return [n];
    if (r == 2) {
      final int top = (n / 2.0).ceil();
      final int bottom = n - top;
      return [top, bottom];
    }
    final int r1 = (n / 3.0).ceil();
    final int r2 = ((n - r1) / 2.0).ceil();
    final int r3 = n - r1 - r2;
    return [r1, r2, r3];
  }

  Widget buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: controlButton(
              icon: Icons.undo_rounded,
              label: 'UNDO',
              onTap: undoMove,
              enabled: history.isNotEmpty && !won && !_isPouring,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: controlButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'HINT',
              onTap: useHint,
              enabled: !won && !_isPouring,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: controlButton(
              icon: Icons.add_circle_outline_rounded,
              label: extraTubeUsed ? 'USED' : '+ TUBE',
              onTap: addExtraTube,
              enabled: !extraTubeUsed && !won && !_isPouring,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: controlButton(
              icon: Icons.refresh_rounded,
              label: 'RESTART',
              onTap: restartLevel,
              enabled: !won && !_isPouring,
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF0C1F38).withValues(alpha: 0.85)
                : const Color(0xFF0C1F38).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? AppTheme.glassBorder
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled ? AppTheme.aquaGlow : Colors.white24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: enabled ? AppTheme.iceWhite : Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF070B18).withValues(alpha: 0.88),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF34D399).withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 76,
                  color: Color(0xFFFBBF24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'LEVEL COMPLETE!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Amazing! You solved the puzzle in $moves moves.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: nextLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34D399),
                      foregroundColor: const Color(0xFF052E24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'NEXT LEVEL  →',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: restartLevel,
                  child: const Text('Play this level again'),
                ),
              ],
            ),
          ),
        ),
      ),
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double lipHeight = (h * 0.038).clamp(5.0, 7.5);
    final double lipWidth = w + 4.0;
    final double neckTop = lipHeight;
    final double neckHeight = (h * 0.045).clamp(6.0, 9.0);
    final double neckWidth = w * 0.72;
    final double bodyTop = neckTop + neckHeight;
    final double bodyHeight = h - bodyTop;
    final double baseRadius = w * 0.44;

    final double innerLeft = 1.5;
    final double innerRight = w - 1.5;
    final double bottomY = h - 2.0;
    final double topCavityY = bodyTop + 6.0;
    const int capacity = 4;
    final double slotH = (bottomY - topCavityY) / capacity;

    // 1. Inner cavity clipping path following the curved glass geometry
    final Path cavityPath = Path();
    cavityPath.moveTo((w - neckWidth) / 2 + 1.2, bodyTop);
    cavityPath.lineTo(innerLeft, bodyTop + 6.0);
    cavityPath.lineTo(innerLeft, h - baseRadius);
    cavityPath.arcToPoint(
      Offset(innerRight, h - baseRadius),
      radius: Radius.circular(baseRadius),
      clockwise: false,
    );
    cavityPath.lineTo(innerRight, bodyTop + 6.0);
    cavityPath.lineTo((w + neckWidth) / 2 - 1.2, bodyTop);
    cavityPath.close();

    // 2. Translucent dark glass back fill
    final Paint backPaint = Paint()
      ..color = const Color(0xFF0C1D33).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cavityPath, backPaint);

    // 3. Liquid layers (non-boxy, organic fluid volumes)
    canvas.save();
    canvas.clipPath(cavityPath);

    // Prepare active color segments to render
    final List<Color> activeLiquidColors = [];
    for (int c in colors) {
      if (c < waterColors.length) {
        activeLiquidColors.add(waterColors[c]);
      }
    }

    final int baseCount = activeLiquidColors.length;
    final List<_LiquidSegment> segments = [];

    // Base colors (with sequential drain reduction if this bottle is pouring)
    for (int i = 0; i < baseCount; i++) {
      double units = 1.0;
      if (drainingAmount > 0 && i >= baseCount - drainingAmount) {
        final int drainRankFromTop = (baseCount - 1) - i;
        final double unitsDrainedSoFar = drainingAmount * drainProgress;
        final double drainedFromThis = (unitsDrainedSoFar - drainRankFromTop).clamp(0.0, 1.0);
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
      final double inUnits = (fillingAmount * fillProgress).clamp(0.0, maxIncoming);

      if (inUnits > 0.001 && fillingColor! < waterColors.length) {
        final Color inColor = waterColors[fillingColor!];
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
        const int steps = 24;
        final double yBase = (bottomY - unitLevel * slotH).clamp(topCavityY - 4.0, bottomY);
        final double dx = (innerRight - innerLeft) / steps;
        final double cx = (innerLeft + innerRight) / 2;
        // Gravity compensation: slant water level opposite to bottle tilt
        final double slope = -math.tan(tiltAngle.clamp(-0.85, 0.85));

        for (int s = 0; s <= steps; s++) {
          final double x = innerLeft + s * dx;
          final double u = s / steps; // 0.0 to 1.0

          // Slant due to gravity
          final double tiltDy = (x - cx) * slope;

          // Continuous sinusoidal wave ripple
          double waveDy = math.sin(u * math.pi * 2 + wavePhase + phaseOffset) * amp;
          if (isHighlighted) {
            waveDy += math.sin(u * math.pi * 4 + (wavePhase + phaseOffset) * 1.8) * 0.5;
          }

          // Concave capillary meniscus: gently curves up at glass walls, soft dip in center
          final double meniscusDy = curv * (1.0 - 4.0 * (u - 0.5) * (u - 0.5));

          final double y = (yBase + tiltDy + waveDy + meniscusDy).clamp(neckTop + 2.0, h + 2.0);
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
            topAmp = 4.0 * (1.0 - settlingProgress) + 1.2;
          } else if (drainingAmount > 0 || (fillingColor != null && fillProgress > 0)) {
            topAmp = 3.2;
          } else if (isHighlighted) {
            topAmp = 2.8;
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
          // Bottom-most liquid layer conforms perfectly to the rounded glass bowl
          layerPath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          // Down through the bottom bowl — clipped by cavityPath to match the rounded glass
          layerPath.lineTo(w + 10, h + 10);
          layerPath.lineTo(-10, h + 10);
          layerPath.close();
        } else {
          // Upper liquid layers nest on top of the meniscus curve of the layer below
          layerPath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          layerPath.lineTo(previousTopPoints!.last.dx, previousTopPoints.last.dy);
          for (final pt in previousTopPoints.reversed) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          layerPath.close();
        }

        // Vibrant multi-stop liquid shader with realistic depth
        final Color col = segments[k].color;
        final Rect segRect = Rect.fromLTRB(
          0,
          bottomY - topUnits[k] * slotH - 14.0,
          w,
          bottomY - (k == 0 ? 0.0 : topUnits[k - 1]) * slotH + 14.0,
        );

        final Paint segPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              col.withValues(alpha: 0.88), // light-catching surface
              col.withValues(alpha: 0.98), // rich vibrant liquid body
              Color.lerp(col, const Color(0xFF041020), 0.28)!, // natural depth shading
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(segRect);

        canvas.drawPath(layerPath, segPaint);

        // Fluid boundary between adjacent liquid layers
        if (k > 0 && previousTopPoints != null) {
          final Path interPath = Path();
          interPath.moveTo(previousTopPoints.first.dx, previousTopPoints.first.dy);
          for (final pt in previousTopPoints) {
            interPath.lineTo(pt.dx, pt.dy);
          }

          // Translucent meniscus highlight along the boundary
          final Paint interHighlight = Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawPath(interPath, interHighlight);

          // Subtle contact shadow
          final Paint interShadow = Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7;
          canvas.drawPath(interPath, interShadow);
        }

        // Topmost exposed liquid surface crest and highlight
        if (isTopmost) {
          final Path surfacePath = Path();
          surfacePath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            surfacePath.lineTo(pt.dx, pt.dy);
          }

          // Soft ambient water glow
          final Paint surfGlow = Paint()
            ..color = Colors.white.withValues(alpha: 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfGlow);

          // Illuminated specular meniscus crest
          final Paint surfCrest = Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfCrest);
        }

        // Subtle rising micro-bubbles inside this liquid layer
        final double segBotY = bottomY - (k == 0 ? 0.0 : topUnits[k - 1]) * slotH;
        final double segTopY = bottomY - topUnits[k] * slotH;
        final double segH = segBotY - segTopY;

        if (segH > 10.0) {
          final Paint bubblePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.fill;
          final Paint bubbleGlint = Paint()
            ..color = Colors.white.withValues(alpha: 0.45)
            ..style = PaintingStyle.fill;

          // Bubble 1
          final double b1Prog = ((wavePhase / (2 * math.pi) + k * 0.38) % 1.0);
          final double b1Y = segBotY - b1Prog * segH * 0.88;
          final double b1X = innerLeft + (innerRight - innerLeft) * 0.32 + math.sin(b1Prog * math.pi * 4) * 2.6;
          if (b1Y > segTopY + 3.0) {
            canvas.drawCircle(Offset(b1X, b1Y), 1.2, bubblePaint);
            canvas.drawCircle(Offset(b1X - 0.3, b1Y - 0.3), 0.4, bubbleGlint);
          }

          // Bubble 2
          final double b2Prog = (((wavePhase / (2 * math.pi)) * 0.8 + k * 0.62 + 0.4) % 1.0);
          final double b2Y = segBotY - b2Prog * segH * 0.88;
          final double b2X = innerLeft + (innerRight - innerLeft) * 0.68 + math.cos(b2Prog * math.pi * 3) * 2.2;
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
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.20),
        ],
      ).createShader(Rect.fromLTWH(0, bodyTop, w, bodyHeight));
    canvas.drawRect(Rect.fromLTWH(0, bodyTop, w, bodyHeight), innerShade);

    canvas.restore();

    // 4. Outer Bottle Outline Path
    final Path outline = Path();
    outline.moveTo((w - neckWidth) / 2, neckTop);
    outline.lineTo((w - neckWidth) / 2, bodyTop);
    outline.quadraticBezierTo(0, bodyTop + 2, 0, bodyTop + 7);
    outline.lineTo(0, h - baseRadius);
    outline.arcToPoint(
      Offset(w, h - baseRadius),
      radius: Radius.circular(baseRadius),
      clockwise: false,
    );
    outline.lineTo(w, bodyTop + 7);
    outline.quadraticBezierTo(w, bodyTop + 2, (w + neckWidth) / 2, bodyTop);
    outline.lineTo((w + neckWidth) / 2, neckTop);
    outline.close();

    const Color errorRed = Color(0xFFFF3B4F);

    if (isInvalid && errorIntensity > 0.0) {
      // 1. Bright Red Glow Blur
      final Paint redGlow = Paint()
        ..color = errorRed.withValues(alpha: 0.52 * errorIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8;
      canvas.drawPath(outline, redGlow);

      // 2. Bright Red Outer Border (drawn outside/above liquid)
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

      // Outer stroke
      final Paint strokePaint = Paint()
        ..color = isHighlighted
            ? highlightColor
            : Colors.white.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2.2 : 1.4;
      canvas.drawPath(outline, strokePaint);
    }

    // 5. Top Lip
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

    // 6. Glass Glare Streak down left
    final Path leftGlare = Path();
    leftGlare.moveTo(w * 0.16, bodyTop + 8);
    leftGlare.lineTo(w * 0.16, h - baseRadius * 1.1);

    final Paint glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftGlare, glarePaint);
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

    // Cubic bezier path from source mouth to destination mouth
    final Path streamPath = Path();
    streamPath.moveTo(source.dx, source.dy);

    // Initial ejection tangent from source lip
    final Offset cp1 = Offset(
      source.dx + tiltDir * 8.0,
      source.dy + 4.0,
    );

    // Gravitational plunge straight down into destination mouth
    final Offset cp2 = Offset(
      dest.dx,
      dest.dy - 16.0,
    );

    streamPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, dest.dx, dest.dy);

    const double baseWidth = 3.6;

    // 1. Soft atmospheric water glow
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth + 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(streamPath, glowPaint);

    // 2. Vibrant liquid stream
    final Paint streamPaint = Paint()
      ..color = color.withValues(alpha: 0.92 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(streamPath, streamPaint);

    // 3. Crisp specular white highlight down the center
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(streamPath, highlightPaint);

    // 4. Micro-splash water droplets at destination mouth
    final Paint splashPaint = Paint()
      ..color = color.withValues(alpha: 0.80 * alpha)
      ..style = PaintingStyle.fill;
    final Paint splashGlint = Paint()
      ..color = Colors.white.withValues(alpha: 0.60 * alpha)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final double splashPhase = (wavePhase * 1.6 + i * 1.57) % (math.pi * 2);
      final double sx = dest.dx + math.sin(splashPhase) * 4.5;
      final double sy = dest.dy - math.cos(splashPhase).abs() * 6.0;
      final double r = 0.85 + (i % 2) * 0.45;
      canvas.drawCircle(Offset(sx, sy), r, splashPaint);
      canvas.drawCircle(Offset(sx - 0.25, sy - 0.25), r * 0.4, splashGlint);
    }
  }

  @override
  bool shouldRepaint(covariant PourStreamPainter old) => true;
}
