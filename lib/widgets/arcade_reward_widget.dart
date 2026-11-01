import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Exciting arcade-style reward messages displayed upon completing a bottle
const List<String> kArcadeRewardWords = [
  'NICE!',
  'GREAT!',
  'PERFECT!',
  'AWESOME!',
  'EXCELLENT!',
  'AMAZING!',
  'SUPER!',
  'FANTASTIC!',
];

/// Pick a random reward message from the curated list
String getRandomRewardWord([math.Random? random]) {
  final rng = random ?? math.Random();
  return kArcadeRewardWords[rng.nextInt(kArcadeRewardWords.length)];
}

/// Color theme for arcade reward badges matching AquaSort's vibrant palette
class ArcadeRewardTheme {
  final Color primaryText;
  final Color secondaryAccent;
  final Color glow;
  final Color outline;

  const ArcadeRewardTheme({
    required this.primaryText,
    required this.secondaryAccent,
    required this.glow,
    required this.outline,
  });

  /// Generate a harmonious theme based on completed bottle liquid accent
  factory ArcadeRewardTheme.fromAccent(Color accent) {
    return ArcadeRewardTheme(
      primaryText: Colors.white,
      secondaryAccent: accent,
      glow: accent,
      outline: const Color(0xFF071A33),
    );
  }

  static const ArcadeRewardTheme cyanAqua = ArcadeRewardTheme(
    primaryText: Color(0xFFEAF7FF),
    secondaryAccent: Color(0xFF00E5FF),
    glow: Color(0xFF38D9FF),
    outline: Color(0xFF031A2E),
  );

  static const ArcadeRewardTheme goldAmber = ArcadeRewardTheme(
    primaryText: Color(0xFFFFFBEB),
    secondaryAccent: Color(0xFFFFD166),
    glow: Color(0xFFFFBE0B),
    outline: Color(0xFF2E1C03),
  );

  static const ArcadeRewardTheme purpleViolet = ArcadeRewardTheme(
    primaryText: Color(0xFFFAF5FF),
    secondaryAccent: Color(0xFFD946EF),
    glow: Color(0xFF9D4EDD),
    outline: Color(0xFF240433),
  );

  static const ArcadeRewardTheme mintEmerald = ArcadeRewardTheme(
    primaryText: Color(0xFFECFDF5),
    secondaryAccent: Color(0xFF00E676),
    glow: Color(0xFF00F5D4),
    outline: Color(0xFF032617),
  );

  /// Select preset theme based on liquid hue or index
  static ArcadeRewardTheme selectTheme(Color? accent) {
    if (accent == null) return cyanAqua;

    final double hue = HSVColor.fromColor(accent).hue;
    if (hue >= 35 && hue < 75) {
      return goldAmber;
    } else if (hue >= 250 && hue < 330) {
      return purpleViolet;
    } else if (hue >= 90 && hue < 165) {
      return mintEmerald;
    } else {
      return cyanAqua;
    }
  }
}

/// Standalone floating arcade reward widget with pop, bounce, float, and glow effects.
class ArcadeRewardWidget extends StatelessWidget {
  final String word;
  final double progress; // 0.0 to 1.0
  final Color? accentColor;
  final double tilt;

  const ArcadeRewardWidget({
    super.key,
    required this.word,
    required this.progress,
    this.accentColor,
    this.tilt = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0 || progress >= 1.0) {
      return const SizedBox.shrink();
    }

    final theme = ArcadeRewardTheme.selectTheme(accentColor);

    // 1. Scale animation: quick pop-up (0.0-0.22), subtle bounce settle (0.22-0.42), gentle float (0.42-1.0)
    double scale;
    if (progress <= 0.22) {
      final t = progress / 0.22;
      scale = 0.25 + (Curves.easeOutBack.transform(t) * 0.95); // peaks at ~1.20
    } else if (progress <= 0.42) {
      final t = (progress - 0.22) / 0.20;
      scale = 1.20 - (t * 0.20); // settles to 1.00
    } else {
      final t = (progress - 0.42) / 0.58;
      scale = 1.00 + (t * 0.08); // floats to 1.08
    }

    // 2. Opacity: quick fade in (0.0-0.12), solid hold (0.12-0.65), smooth fade out (0.65-1.0)
    double opacity;
    if (progress < 0.12) {
      opacity = (progress / 0.12).clamp(0.0, 1.0);
    } else if (progress < 0.65) {
      opacity = 1.0;
    } else {
      final t = (progress - 0.65) / 0.35;
      opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    }

    // 3. Dynamic tilt settling toward upright
    final double currentTilt = tilt * (1.0 - (progress * 0.75));

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: currentTilt,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xF2071A33), // deep glass navy background
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.glow.withValues(alpha: 0.8),
                width: 1.6,
              ),
              boxShadow: [
                // Outer bright neon aura matching theme
                BoxShadow(
                  color: theme.glow.withValues(alpha: 0.55),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
                // Inner depth drop shadow for strong contrast
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: theme.secondaryAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  word,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Roboto',
                    letterSpacing: 1.4,
                    color: theme.primaryText,
                    shadows: [
                      Shadow(
                        color: theme.glow.withValues(alpha: 0.9),
                        blurRadius: 14,
                      ),
                      Shadow(
                        color: theme.outline,
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: theme.secondaryAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay container that positions and floats the [ArcadeRewardWidget] near the completed bottle,
/// cleanly clamped within screen and board boundaries.
class ArcadeRewardOverlay extends StatelessWidget {
  final String? word;
  final double progress; // 0.0 to 1.0
  final Rect? bottleRect;
  final Size boardSize;
  final Color? accentColor;
  final double tilt;

  const ArcadeRewardOverlay({
    super.key,
    required this.word,
    required this.progress,
    required this.bottleRect,
    required this.boardSize,
    this.accentColor,
    this.tilt = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (word == null ||
        bottleRect == null ||
        progress <= 0.0 ||
        progress >= 1.0) {
      return const SizedBox.shrink();
    }

    // Upward floating distance over time (~50 logical pixels)
    final double floatDy = -Curves.easeOutCubic.transform(progress) * 50.0;

    // Approximate width and height of the reward pill for boundary clamping
    const double badgeHalfWidth = 96.0;
    const double badgeHeight = 44.0;
    const double margin = 6.0;

    // Clamping coordinates to ensure the badge stays within board edges
    final double clampedCenterX = bottleRect!.center.dx.clamp(
      badgeHalfWidth + margin,
      math.max(
        badgeHalfWidth + margin,
        boardSize.width - badgeHalfWidth - margin,
      ),
    );

    final double baseTop = bottleRect!.top - 20.0;
    final double clampedTop = (baseTop + floatDy).clamp(
      6.0,
      math.max(6.0, boardSize.height - badgeHeight - 6.0),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: clampedCenterX - badgeHalfWidth,
          top: clampedTop,
          width: badgeHalfWidth * 2,
          height: badgeHeight,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ArcadeRewardWidget(
                word: word!,
                progress: progress,
                accentColor: accentColor,
                tilt: tilt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
