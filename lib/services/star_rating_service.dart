import 'level_generator.dart';

/// Pure calculation service for AquaSort star ratings.
///
/// Implements deterministic, production-quality star ratings for all 100 levels:
///
/// 1. Untimed Levels (1–3):
///    - Move efficiency evaluated against [LevelConfig.threeStarThreshold] and [LevelConfig.twoStarThreshold].
///    - Moves <= threeStarThreshold -> 3 stars.
///    - Moves <= twoStarThreshold -> 2 stars.
///    - Moves > twoStarThreshold -> 1 star.
///
/// 2. Normal Timed Completion (Levels 4–100 within original timer):
///    - 3 stars: >= 50% of original timer remains (T_rem >= T_orig * 0.5).
///    - 2 stars: >= 25% but < 50% remains (0.25 <= T_rem / T_orig < 0.5).
///    - 1 star:  > 0% but < 25% remains (0 < T_rem / T_orig < 0.25).
///    - 0 stars: Not won or timed out (T_rem <= 0).
///
/// 3. Extra-Time Completion (rewarded ad +60s periods, max 2):
///    - If solved with 30–60s remaining in the active 60s period -> 2 stars.
///    - If solved with 1–29s remaining in the active 60s period -> 1 star.
///    - If 0s remaining or timed out -> 0 stars.
///    - Never 3 stars if original timer expired.
class StarRatingService {
  const StarRatingService._();

  /// Calculates stars for untimed levels (Levels 1–3) based on moves used.
  static int calculateUntimedStars({required int level, required int moves}) {
    final config = LevelGenerator.getLevelConfig(level);
    if (moves <= config.threeStarThreshold) {
      return 3;
    } else if (moves <= config.twoStarThreshold) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Calculates stars for normal timed completions within the original countdown.
  static int calculateNormalTimedStars({
    required int originalTimerSeconds,
    required int remainingOriginalSeconds,
  }) {
    if (remainingOriginalSeconds <= 0 || originalTimerSeconds <= 0) {
      return 0;
    }

    final double ratio = remainingOriginalSeconds / originalTimerSeconds;
    if (ratio >= 0.5) {
      return 3;
    } else if (ratio >= 0.25) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Calculates stars for extra-time completions (after original timer expired).
  ///
  /// Solved with 30–60s remaining in the 60s period -> 2 stars.
  /// Solved with 1–29s remaining in the 60s period -> 1 star.
  /// Solved with 0s remaining -> 0 stars.
  /// Never returns 3 stars.
  static int calculateExtraTimeStars({required int remainingExtraTimeSeconds}) {
    if (remainingExtraTimeSeconds >= 30 && remainingExtraTimeSeconds <= 60) {
      return 2;
    } else if (remainingExtraTimeSeconds > 0 &&
        remainingExtraTimeSeconds < 30) {
      return 1;
    } else {
      return 0;
    }
  }

  /// Unified star calculation for any level attempt.
  static int calculateStars({
    required int level,
    required int moves,
    required int? originalTimerSeconds,
    required int? remainingOriginalSeconds,
    required bool inExtraTime,
    required int? remainingExtraTimeSeconds,
    bool isWon = true,
  }) {
    if (!isWon) return 0;

    // Untimed levels (Levels 1–3)
    if (originalTimerSeconds == null) {
      return calculateUntimedStars(level: level, moves: moves);
    }

    // Extra-time period (original timer expired, player claimed +60s bonus)
    if (inExtraTime) {
      return calculateExtraTimeStars(
        remainingExtraTimeSeconds: remainingExtraTimeSeconds ?? 0,
      );
    }

    // Normal timed completion within original timer
    return calculateNormalTimedStars(
      originalTimerSeconds: originalTimerSeconds,
      remainingOriginalSeconds: remainingOriginalSeconds ?? 0,
    );
  }
}
