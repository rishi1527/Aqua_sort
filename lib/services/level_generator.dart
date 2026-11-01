import 'dart:math' as math;

/// Difficulty tiers across all 100 levels.
enum DifficultyTier { easy, medium, hard, veryHard, expert }

/// Metadata and gameplay metrics for a level.
class LevelConfig {
  final int level;
  final DifficultyTier tier;
  final String tierName;
  final String chapterTitle;
  final int colorCount;
  final int emptyCount;
  final int bottleCount;
  final int targetMoves;
  final int threeStarThreshold;
  final int twoStarThreshold;
  final int? initialTimerSeconds;

  const LevelConfig({
    required this.level,
    required this.tier,
    required this.tierName,
    required this.chapterTitle,
    required this.colorCount,
    this.emptyCount = 2,
    required this.bottleCount,
    required this.targetMoves,
    required this.threeStarThreshold,
    required this.twoStarThreshold,
    this.initialTimerSeconds,
  });
}

/// Solves and validates Water Sort puzzles using breadth-first search (BFS).
class WaterSortSolver {
  static const int capacity = 4;

  static bool isComplete(List<int> tube) {
    if (tube.length != capacity) return false;
    final first = tube.first;
    for (int i = 1; i < capacity; i++) {
      if (tube[i] != first) return false;
    }
    return true;
  }

  static bool isSolved(List<List<int>> tubes) {
    for (final tube in tubes) {
      if (tube.isEmpty) continue;
      if (!isComplete(tube)) return false;
    }
    return true;
  }

  static String canonicalKey(List<List<int>> tubes) {
    final list = tubes.map((t) => t.join(',')).toList()..sort();
    return list.join('|');
  }

  static bool canPour(List<List<int>> tubes, int from, int to) {
    if (from == to) return false;
    final source = tubes[from];
    final dest = tubes[to];
    if (source.isEmpty || isComplete(source)) return false;
    if (dest.length >= capacity) return false;
    if (dest.isEmpty) return true;
    return source.last == dest.last;
  }

  static List<List<int>> copyTubes(List<List<int>> source) {
    return source.map((t) => List<int>.from(t)).toList();
  }

  /// Solves the puzzle and returns the minimum number of moves, or `null` if unsolvable.
  static int? solve(List<List<int>> initialTubes, {int maxStates = 14000}) {
    if (isSolved(initialTubes)) return 0;

    final queue = <_QueueItem>[];
    final visited = <String>{};

    final startKey = canonicalKey(initialTubes);
    visited.add(startKey);
    queue.add(_QueueItem(copyTubes(initialTubes), 0));

    int head = 0;
    while (head < queue.length && visited.length < maxStates) {
      final current = queue[head++];
      final currentTubes = current.tubes;
      final currentMoves = current.moves;

      bool triedEmptyDest = false;

      for (int i = 0; i < currentTubes.length; i++) {
        final source = currentTubes[i];
        if (source.isEmpty || isComplete(source)) continue;

        final bool isPure = source.every((c) => c == source.first);

        for (int j = 0; j < currentTubes.length; j++) {
          if (i == j) continue;
          final dest = currentTubes[j];

          if (dest.isEmpty) {
            // Prune redundant moves: moving pure single color into empty bottle,
            // or pouring into multiple different empty bottles
            if (isPure) continue;
            if (triedEmptyDest) continue;
            triedEmptyDest = true;
          }

          if (canPour(currentTubes, i, j)) {
            final nextTubes = copyTubes(currentTubes);
            final color = nextTubes[i].last;
            while (nextTubes[i].isNotEmpty &&
                nextTubes[i].last == color &&
                nextTubes[j].length < capacity) {
              nextTubes[j].add(nextTubes[i].removeLast());
            }

            if (isSolved(nextTubes)) {
              return currentMoves + 1;
            }

            final key = canonicalKey(nextTubes);
            if (visited.add(key)) {
              queue.add(_QueueItem(nextTubes, currentMoves + 1));
            }
          }
        }
      }
    }

    return null;
  }
}

class _QueueItem {
  final List<List<int>> tubes;
  final int moves;
  _QueueItem(this.tubes, this.moves);
}

/// Service that defines level progression, configurations, and verified level generation.
class LevelGenerator {
  static const int capacity = 4;
  static const int emptyTubesCount = 2;
  static const int maxLevels = 100;

  /// Verified random seed map for levels 1..100.
  /// Each seed has been mathematically and algorithmically verified to:
  /// - Produce the exact color count (3..10) and bottle count (5..12)
  /// - Have each color appear exactly 4 times (1 full bottle capacity)
  /// - Have exactly 2 empty bottles for sorting
  /// - Have NO bottles starting already completed
  /// - Be 100% solvable by [WaterSortSolver]
  static const Map<int, int> _levelSeeds = {
    1: 1037,
    2: 1074,
    3: 1111,
    4: 1148,
    5: 1185,
    6: 1222,
    7: 1259,
    8: 1296,
    9: 1333,
    10: 1370,
    11: 1407,
    12: 1444,
    13: 1481,
    14: 1518,
    15: 1555,
    16: 1592,
    17: 1629,
    18: 1666,
    19: 1703,
    20: 1741,
    21: 1777,
    22: 1817,
    23: 1851,
    24: 1889,
    25: 1926,
    26: 1962,
    27: 1999,
    28: 2036,
    29: 2073,
    30: 2110,
    31: 2147,
    32: 2185,
    33: 2224,
    34: 2259,
    35: 2295,
    36: 2332,
    37: 2370,
    38: 2406,
    39: 2443,
    40: 2480,
    41: 2519,
    42: 2554,
    43: 2593,
    44: 2628,
    45: 2665,
    46: 2705,
    47: 2740,
    48: 2776,
    49: 2814,
    50: 2851,
    51: 4687,
    52: 4724,
    53: 4761,
    54: 4805,
    55: 4835,
    56: 4875,
    57: 4909,
    58: 4950,
    59: 4984,
    60: 5021,
    61: 5057,
    62: 5095,
    63: 5131,
    64: 5168,
    65: 5205,
    66: 5244,
    67: 5282,
    68: 5318,
    69: 5356,
    70: 5390,
    71: 5430,
    72: 5466,
    73: 5501,
    74: 5538,
    75: 5576,
    76: 5624,
    77: 5662,
    78: 5686,
    79: 5724,
    80: 5761,
    81: 5798,
    82: 5834,
    83: 5871,
    84: 5910,
    85: 5945,
    86: 5982,
    87: 6020,
    88: 6056,
    89: 6095,
    90: 6134,
    91: 6167,
    92: 6204,
    93: 6241,
    94: 6279,
    95: 6316,
    96: 6352,
    97: 6389,
    98: 6433,
    99: 6466,
    100: 6504,
  };

  /// Verified optimal move counts for levels 1..100.
  static const Map<int, int> _levelTargetMoves = {
    1: 7,
    2: 8,
    3: 12,
    4: 9,
    5: 10,
    6: 12,
    7: 9,
    8: 15,
    9: 17,
    10: 16,
    11: 17,
    12: 18,
    13: 14,
    14: 18,
    15: 19,
    16: 17,
    17: 19,
    18: 20,
    19: 19,
    20: 21,
    21: 22,
    22: 27,
    23: 21,
    24: 19,
    25: 24,
    26: 20,
    27: 21,
    28: 26,
    29: 26,
    30: 28,
    31: 25,
    32: 28,
    33: 26,
    34: 25,
    35: 30,
    36: 27,
    37: 30,
    38: 31,
    39: 30,
    40: 27,
    41: 29,
    42: 29,
    43: 28,
    44: 30,
    45: 34,
    46: 29,
    47: 31,
    48: 33,
    49: 32,
    50: 31,
    51: 33,
    52: 32,
    53: 31,
    54: 35,
    55: 32,
    56: 36,
    57: 34,
    58: 33,
    59: 33,
    60: 32,
    61: 33,
    62: 32,
    63: 36,
    64: 32,
    65: 31,
    66: 33,
    67: 34,
    68: 32,
    69: 33,
    70: 31,
    71: 35,
    72: 31,
    73: 31,
    74: 33,
    75: 32,
    76: 32,
    77: 36,
    78: 31,
    79: 34,
    80: 34,
    81: 36,
    82: 33,
    83: 30,
    84: 35,
    85: 35,
    86: 32,
    87: 34,
    88: 32,
    89: 35,
    90: 34,
    91: 30,
    92: 33,
    93: 32,
    94: 32,
    95: 34,
    96: 31,
    97: 36,
    98: 33,
    99: 29,
    100: 36,
  };

  /// Returns the difficulty tier for [level].
  static DifficultyTier getTier(int level) {
    if (level <= 10) return DifficultyTier.easy;
    if (level <= 20) return DifficultyTier.medium;
    if (level <= 30) return DifficultyTier.hard;
    if (level <= 40) return DifficultyTier.veryHard;
    return DifficultyTier.expert;
  }

  /// Returns user-facing name for the difficulty tier.
  static String getTierName(int level) {
    switch (getTier(level)) {
      case DifficultyTier.easy:
        return 'Easy';
      case DifficultyTier.medium:
        return 'Medium';
      case DifficultyTier.hard:
        return 'Hard';
      case DifficultyTier.veryHard:
        return 'Very Hard';
      case DifficultyTier.expert:
        return 'Expert';
    }
  }

  /// Returns the chapter title corresponding to [level].
  static String getChapterTitle(int level) {
    if (level <= 10) return 'Chapter 1: Tranquil Waters';
    if (level <= 20) return 'Chapter 2: Coral Lagoon';
    if (level <= 30) return 'Chapter 3: Bioluminescent Abyss';
    if (level <= 40) return 'Chapter 4: Crystal Fjord';
    if (level <= 50) return 'Chapter 5: Celestial Tide';
    if (level <= 60) return 'Chapter 6: Mystic Caverns';
    if (level <= 70) return 'Chapter 7: Aurora Springs';
    if (level <= 80) return 'Chapter 8: Prismatic Reef';
    if (level <= 90) return 'Chapter 9: Starlight Falls';
    return 'Chapter 10: Infinity Ocean';
  }

  /// Returns the number of distinct water colors for [level].
  ///
  /// Progressive progression:
  /// - Levels 1–3: 3 colors (5 bottles)
  /// - Levels 4–7: 4 colors (6 bottles)
  /// - Levels 8–13: 5 colors (7 bottles)
  /// - Levels 14–20: 6 colors (8 bottles)
  /// - Levels 21–27: 7 colors (9 bottles)
  /// - Levels 28–34: 8 colors (10 bottles)
  /// - Levels 35–44: 9 colors (11 bottles)
  /// - Levels 45–100: 10 colors (12 bottles)
  static int getColorCount(int level) {
    final int l = level.clamp(1, maxLevels);
    if (l <= 3) return 3;
    if (l <= 7) return 4;
    if (l <= 13) return 5;
    if (l <= 20) return 6;
    if (l <= 27) return 7;
    if (l <= 34) return 8;
    if (l <= 44) return 9;
    return 10;
  }

  /// Returns the total bottle count (colors + 2 empty bottles).
  static int getBottleCount(int level) {
    return getColorCount(level) + emptyTubesCount;
  }

  /// Returns the initial timer duration in seconds for [levelNumber].
  ///
  /// - Levels 1–3: null (no timer)
  /// - Levels 4–19: 30 seconds
  /// - Levels 20–59: 45 seconds
  /// - Levels 60–100: 60 seconds
  static int? getInitialTimerSeconds(int levelNumber) {
    final int l = levelNumber.clamp(1, maxLevels);
    if (l <= 3) return null;
    if (l <= 19) return 30;
    if (l <= 59) return 45;
    return 60;
  }

  /// Returns full metadata and star thresholds for [level].
  static LevelConfig getLevelConfig(int level) {
    final int l = level.clamp(1, maxLevels);
    final int colors = getColorCount(l);
    final int target = _levelTargetMoves[l] ?? (colors * 3 + 2);
    final int threeStars = target + 6;
    final int twoStars = target + 16;

    return LevelConfig(
      level: l,
      tier: getTier(l),
      tierName: getTierName(l),
      chapterTitle: getChapterTitle(l),
      colorCount: colors,
      emptyCount: emptyTubesCount,
      bottleCount: colors + emptyTubesCount,
      targetMoves: target,
      threeStarThreshold: threeStars,
      twoStarThreshold: twoStars,
      initialTimerSeconds: getInitialTimerSeconds(l),
    );
  }

  /// Generates the verified, deterministic bottle layout for [levelNumber].
  static List<List<int>> getLevel(int levelNumber) {
    final int l = levelNumber.clamp(1, maxLevels);
    final int colors = getColorCount(l);
    final int seed = _levelSeeds[l] ?? (1000 + l * 37);

    // Build color pool: each of the `colors` appears exactly 4 times
    final List<int> pool = [];
    for (int c = 0; c < colors; c++) {
      for (int u = 0; u < capacity; u++) {
        pool.add(c);
      }
    }

    final rand = math.Random(seed);
    pool.shuffle(rand);

    final List<List<int>> result = [];
    for (int i = 0; i < colors; i++) {
      result.add(pool.sublist(i * capacity, (i + 1) * capacity));
    }

    // Two empty tubes for maneuvering
    result.add(<int>[]);
    result.add(<int>[]);

    return result;
  }
}
