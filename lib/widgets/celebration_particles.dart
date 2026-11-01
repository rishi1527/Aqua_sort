import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CelebrationShape { circle, square, strip, sparkle }

class CelebrationParticle {
  final Offset origin;
  final double vx;
  final double vy;
  final double gravity;
  final double drag;
  final double initialAngle;
  final double angularVelocity;
  final double size;
  final double length;
  final Color color;
  final CelebrationShape shape;
  final double flipSpeed;
  final double flipPhase;
  final double delay; // normalized delay (0.0 .. 0.25)

  CelebrationParticle({
    required this.origin,
    required this.vx,
    required this.vy,
    required this.gravity,
    this.drag = 0.4,
    required this.initialAngle,
    required this.angularVelocity,
    required this.size,
    double? length,
    required this.color,
    required this.shape,
    this.flipSpeed = 0.0,
    this.flipPhase = 0.0,
    this.delay = 0.0,
  }) : length = length ?? size * 2.5;

  /// Generate mini-celebration particle burst originating from a completed bottle.
  static List<CelebrationParticle> createBottleBurst({
    required Rect bottleRect,
    required Color bottleAccentColor,
    int count = 28,
  }) {
    final math.Random rng = math.Random();
    final List<CelebrationParticle> particles = [];

    // Origin: slightly inside bottle mouth/neck so burst blooms outward from tube opening
    final Offset origin = Offset(
      bottleRect.center.dx,
      bottleRect.top + bottleRect.height * 0.12,
    );

    final List<Color> palette = [
      const Color(0xFF00F0FF), // Aqua/cyan
      const Color(0xFF38B6FF), // Sky blue
      const Color(0xFFA78BFA), // Lavender purple
      const Color(0xFFFF52A2), // Vivid pink
      const Color(0xFFFFD166), // Bright gold
      bottleAccentColor, // Completed bottle color
      bottleAccentColor.withValues(alpha: 0.9),
      Colors.white,
    ];

    for (int i = 0; i < count; i++) {
      // 80% burst upward & fan out, 20% burst slightly sideways/down for splash
      final double angle;
      if (rng.nextDouble() < 0.82) {
        // Upward arc: -145 degrees to -35 degrees
        angle = -math.pi * (0.20 + rng.nextDouble() * 0.60);
      } else {
        // Lateral splash
        angle = rng.nextBool()
            ? -math.pi * (0.05 + rng.nextDouble() * 0.18)
            : -math.pi * (0.77 + rng.nextDouble() * 0.18);
      }

      final double speed = 160.0 + rng.nextDouble() * 260.0;
      final double vx = math.cos(angle) * speed;
      final double vy = math.sin(angle) * speed;

      final double shapeChoice = rng.nextDouble();
      final CelebrationShape shape;
      final double size;
      final double length;

      if (shapeChoice < 0.32) {
        shape = CelebrationShape.sparkle;
        size = 5.0 + rng.nextDouble() * 4.0;
        length = size;
      } else if (shapeChoice < 0.60) {
        shape = CelebrationShape.circle;
        size = 3.0 + rng.nextDouble() * 3.0;
        length = size;
      } else if (shapeChoice < 0.82) {
        shape = CelebrationShape.strip;
        size = 2.5 + rng.nextDouble() * 1.5;
        length = 6.0 + rng.nextDouble() * 5.0;
      } else {
        shape = CelebrationShape.square;
        size = 3.5 + rng.nextDouble() * 2.5;
        length = size;
      }

      final Color color = palette[rng.nextInt(palette.length)];

      particles.add(
        CelebrationParticle(
          origin: origin,
          vx: vx,
          vy: vy,
          gravity: 460.0 + rng.nextDouble() * 140.0,
          drag: 0.35 + rng.nextDouble() * 0.20,
          initialAngle: rng.nextDouble() * math.pi * 2,
          angularVelocity: (rng.nextDouble() - 0.5) * 14.0,
          size: size,
          length: length,
          color: color,
          shape: shape,
          flipSpeed: 6.0 + rng.nextDouble() * 10.0,
          flipPhase: rng.nextDouble() * math.pi * 2,
          delay: rng.nextDouble() * 0.08,
        ),
      );
    }

    return particles;
  }

  /// Generate major confetti celebration bursting across the full screen.
  static List<CelebrationParticle> createLevelConfetti({
    required Size boardSize,
    int count = 140,
  }) {
    final math.Random rng = math.Random();
    final List<CelebrationParticle> particles = [];

    final double w = boardSize.width;
    final double h = boardSize.height;

    // Rich, harmonious AquaSort celebration color palette
    final List<Color> palette = const [
      Color(0xFF00F0FF), // Neon cyan / aqua glow
      Color(0xFF0077FE), // Vibrant azure blue
      Color(0xFF9D4EDD), // Royal purple
      Color(0xFFFF007F), // Electric neon pink
      Color(0xFFFFD000), // Sparkling gold
      Color(0xFF00F5D4), // Mint cyan
      Color(0xFFFF6B6B), // Vivid coral
      Color(0xFFFFB703), // Golden amber
      Color(0xFF7000FF), // Electric violet
      Color(0xFFFFFFFF), // Shimmering white
    ];

    for (int i = 0; i < count; i++) {
      // Deterministically distribute particles across 5 diverse emission zones
      // to achieve complete full-screen coverage.
      final int emitterType = i % 5;
      final Offset origin;
      final double vx;
      final double vy;
      final double gravity;
      final double drag;
      final double delay;

      switch (emitterType) {
        case 0:
          // 1. Bottom-Left Cannon: shoots upward & across to right/center
          origin = Offset(
            w * 0.08 + (rng.nextDouble() - 0.5) * 32.0,
            h * 0.98 + (rng.nextDouble() - 0.5) * 20.0,
          );
          // Angle -78 to -32 degrees
          final double angleBL = -math.pi * (0.18 + rng.nextDouble() * 0.26);
          final double speedBL = (h * 0.72 + rng.nextDouble() * h * 0.42).clamp(
            520.0,
            1020.0,
          );
          vx = math.cos(angleBL) * speedBL;
          vy = math.sin(angleBL) * speedBL;
          gravity = 350.0 + rng.nextDouble() * 110.0;
          drag = 0.24 + rng.nextDouble() * 0.12;
          delay = rng.nextDouble() * 0.16;
          break;

        case 1:
          // 2. Bottom-Right Cannon: shoots upward & across to left/center
          origin = Offset(
            w * 0.92 + (rng.nextDouble() - 0.5) * 32.0,
            h * 0.98 + (rng.nextDouble() - 0.5) * 20.0,
          );
          // Angle -148 to -102 degrees
          final double angleBR = -math.pi * (0.56 + rng.nextDouble() * 0.26);
          final double speedBR = (h * 0.72 + rng.nextDouble() * h * 0.42).clamp(
            520.0,
            1020.0,
          );
          vx = math.cos(angleBR) * speedBR;
          vy = math.sin(angleBR) * speedBR;
          gravity = 350.0 + rng.nextDouble() * 110.0;
          drag = 0.24 + rng.nextDouble() * 0.12;
          delay = rng.nextDouble() * 0.16;
          break;

        case 2:
          // 3. Bottom-Center High Fountain: shoots high into central sky
          origin = Offset(
            w * 0.50 + (rng.nextDouble() - 0.5) * 48.0,
            h * 0.94 + (rng.nextDouble() - 0.5) * 24.0,
          );
          // Angle -108 to -72 degrees
          final double angleC = -math.pi * (0.40 + rng.nextDouble() * 0.20);
          final double speedC = (h * 0.78 + rng.nextDouble() * h * 0.40).clamp(
            560.0,
            1100.0,
          );
          vx = math.cos(angleC) * speedC;
          vy = math.sin(angleC) * speedC;
          gravity = 370.0 + rng.nextDouble() * 90.0;
          drag = 0.25 + rng.nextDouble() * 0.12;
          delay = rng.nextDouble() * 0.14;
          break;

        case 3:
          // 4. Mid-Screen Lateral Boosters: lateral inward sweeps
          final bool isLeftFlank = rng.nextBool();
          if (isLeftFlank) {
            origin = Offset(
              w * 0.02 + rng.nextDouble() * 16.0,
              h * (0.35 + rng.nextDouble() * 0.30),
            );
            // Angled inward/upward: -40 to +5 degrees
            final double angleFlank =
                -math.pi * (0.0 - rng.nextDouble() * 0.22);
            final double speedFlank = 360.0 + rng.nextDouble() * 260.0;
            vx = math.cos(angleFlank) * speedFlank;
            vy = math.sin(angleFlank) * speedFlank;
          } else {
            origin = Offset(
              w * 0.98 - rng.nextDouble() * 16.0,
              h * (0.35 + rng.nextDouble() * 0.30),
            );
            // Angled inward/upward: -185 to -140 degrees
            final double angleFlank =
                -math.pi * (0.78 + rng.nextDouble() * 0.25);
            final double speedFlank = 360.0 + rng.nextDouble() * 260.0;
            vx = math.cos(angleFlank) * speedFlank;
            vy = math.sin(angleFlank) * speedFlank;
          }
          gravity = 300.0 + rng.nextDouble() * 100.0;
          drag = 0.28 + rng.nextDouble() * 0.14;
          delay = 0.04 + rng.nextDouble() * 0.16;
          break;

        default:
          // 5. Sky Cascade: confetti drifting down from upper screen
          origin = Offset(
            w * (0.05 + rng.nextDouble() * 0.90),
            h * (-0.06 + rng.nextDouble() * 0.28),
          );
          vx = (rng.nextDouble() - 0.5) * 160.0;
          vy = 40.0 + rng.nextDouble() * 120.0;
          gravity = 150.0 + rng.nextDouble() * 120.0;
          drag = 0.32 + rng.nextDouble() * 0.16;
          delay = rng.nextDouble() * 0.18;
          break;
      }

      // Mixture of medium and large colorful confetti pieces:
      // Strips (rectangles), squares, circles, and occasional sparkles
      final double shapeChoice = rng.nextDouble();
      final CelebrationShape shape;
      final double size;
      final double length;

      if (shapeChoice < 0.38) {
        // Ribbon strips / rectangles (noticeably larger, 7-12 width x 18-32 length)
        shape = CelebrationShape.strip;
        size = 7.0 + rng.nextDouble() * 5.0;
        length = 18.0 + rng.nextDouble() * 14.0;
      } else if (shapeChoice < 0.68) {
        // Confetti squares (medium ~10-12, large ~13-17)
        shape = CelebrationShape.square;
        size = 10.0 + rng.nextDouble() * 7.0;
        length = size;
      } else if (shapeChoice < 0.86) {
        // Circles / dots (medium ~9-11, large ~12-16)
        shape = CelebrationShape.circle;
        size = 9.0 + rng.nextDouble() * 7.0;
        length = size;
      } else {
        // Occasional diamond star sparkles (12-20)
        shape = CelebrationShape.sparkle;
        size = 12.0 + rng.nextDouble() * 8.0;
        length = size;
      }

      final Color color = palette[rng.nextInt(palette.length)];

      particles.add(
        CelebrationParticle(
          origin: origin,
          vx: vx,
          vy: vy,
          gravity: gravity,
          drag: drag,
          initialAngle: rng.nextDouble() * math.pi * 2,
          angularVelocity: (rng.nextDouble() - 0.5) * 14.0,
          size: size,
          length: length,
          color: color,
          shape: shape,
          flipSpeed: 5.0 + rng.nextDouble() * 11.0,
          flipPhase: rng.nextDouble() * math.pi * 2,
          delay: delay,
        ),
      );
    }

    return particles;
  }
}

/// CustomPainter rendering both bottle-burst particles and grand confetti.
class CelebrationPainter extends CustomPainter {
  final double bottleProgress; // 0.0 .. 1.0 (duration ~750ms)
  final List<CelebrationParticle> bottleParticles;
  final Rect? bottleRect;
  final Color? bottleColor;

  final double levelProgress; // 0.0 .. 1.0 (duration ~2.6s)
  final List<CelebrationParticle> levelParticles;
  final List<Rect> tubeRects;

  CelebrationPainter({
    this.bottleProgress = 0.0,
    this.bottleParticles = const [],
    this.bottleRect,
    this.bottleColor,
    this.levelProgress = 0.0,
    this.levelParticles = const [],
    this.tubeRects = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw bottle celebration glow and particles
    if (bottleProgress > 0.0 && bottleProgress < 1.0) {
      _paintBottleCelebration(canvas, size);
    }

    // 2. Draw full level celebration highlights and confetti
    if (levelProgress > 0.0 && levelProgress < 1.0) {
      _paintLevelCelebration(canvas, size);
    }
  }

  void _paintBottleCelebration(Canvas canvas, Size size) {
    final double p = bottleProgress;

    // A. Soft luminous radial aura expanding from bottle neck
    if (bottleRect != null && bottleColor != null && p < 0.70) {
      final double glowProg = p / 0.70;
      final double glowAlpha =
          (1.0 - Curves.easeOutQuad.transform(glowProg)) * 0.55;
      if (glowAlpha > 0.01) {
        final Offset glowCenter = Offset(
          bottleRect!.center.dx,
          bottleRect!.top + bottleRect!.height * 0.14,
        );
        final double radius =
            bottleRect!.width *
            (0.5 + 1.2 * Curves.easeOutCubic.transform(glowProg));

        final Paint glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              bottleColor!.withValues(alpha: glowAlpha),
              const Color(0xFF00F0FF).withValues(alpha: glowAlpha * 0.6),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: glowCenter, radius: radius));

        canvas.drawCircle(glowCenter, radius, glowPaint);
      }
    }

    // B. Render particles
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;

    for (final particle in bottleParticles) {
      if (p < particle.delay) continue;
      final double localP = ((p - particle.delay) / (1.0 - particle.delay))
          .clamp(0.0, 1.0);
      final double lt = localP * 0.75;

      // Position physics with air drag and gravity
      final double dragFactor = (1.0 - (particle.drag * 0.5 * localP)).clamp(
        0.4,
        1.0,
      );
      final double x = particle.origin.dx + particle.vx * lt * dragFactor;
      final double y =
          particle.origin.dy +
          particle.vy * lt * dragFactor +
          0.5 * particle.gravity * lt * lt;

      // Alpha fade (holds until 60%, then fades to 0)
      final double alpha;
      if (localP < 0.60) {
        alpha = 1.0;
      } else {
        alpha = (1.0 - ((localP - 0.60) / 0.40)).clamp(0.0, 1.0);
      }

      // Scale pop-in and gentle shrink
      final double scale;
      if (localP < 0.12) {
        scale = localP / 0.12;
      } else if (localP > 0.75) {
        scale = 1.0 - 0.7 * ((localP - 0.75) / 0.25);
      } else {
        scale = 1.0;
      }

      if (alpha <= 0.005 || scale <= 0.01) continue;

      final double rotation =
          particle.initialAngle + particle.angularVelocity * lt;
      final double flipCos = math.cos(
        particle.flipPhase + particle.flipSpeed * lt,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      particlePaint.color = particle.color.withValues(alpha: alpha);

      _drawShape(
        canvas: canvas,
        shape: particle.shape,
        size: particle.size * scale,
        length: particle.length * scale,
        flipCos: flipCos,
        paint: particlePaint,
      );

      canvas.restore();
    }
  }

  void _paintLevelCelebration(Canvas canvas, Size size) {
    final double p = levelProgress;

    // A. Celebratory aura pulse around all completed tubes
    if (tubeRects.isNotEmpty && p < 0.90) {
      // Gentle breathing glow (alpha peaks at 0.35, then fades)
      final double glowProg = (p / 0.90).clamp(0.0, 1.0);
      final double pulse = math.sin(glowProg * math.pi);
      final double auraAlpha = (pulse * 0.38).clamp(0.0, 0.45);

      if (auraAlpha > 0.01) {
        final Paint auraPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        for (final rect in tubeRects) {
          final RRect tubeAura = RRect.fromRectAndCorners(
            rect.inflate(4.0),
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(rect.width * 0.52),
            bottomRight: Radius.circular(rect.width * 0.52),
          );

          auraPaint.color = const Color(0xFF00F0FF)
              .withValues(alpha: auraAlpha);
          canvas.drawRRect(tubeAura, auraPaint);

          // Subtle inner golden rim
          auraPaint.strokeWidth = 1.5;
          auraPaint.color = const Color(0xFFFFD166)
              .withValues(alpha: auraAlpha * 0.75);
          canvas.drawRRect(tubeAura.inflate(-1.5), auraPaint);
          auraPaint.strokeWidth = 3.0;
        }
      }
    }

    // B. Render grand confetti particles
    final Paint confettiPaint = Paint()..style = PaintingStyle.fill;

    for (final particle in levelParticles) {
      if (p < particle.delay) continue;
      final double localP = ((p - particle.delay) / (1.0 - particle.delay))
          .clamp(0.0, 1.0);
      final double lt = localP * 2.6;

      // Natural drag and gravity
      final double dragFactor = (1.0 - (particle.drag * 0.45 * localP)).clamp(
        0.35,
        1.0,
      );
      final double x = particle.origin.dx + particle.vx * lt * dragFactor;
      final double y =
          particle.origin.dy +
          particle.vy * lt * dragFactor +
          0.5 * particle.gravity * lt * lt;

      // Confetti stays bright during ascent & peak (first 65%), then fades smoothly
      final double alpha;
      if (localP < 0.65) {
        alpha = 1.0;
      } else {
        alpha = Curves.easeOutQuad.transform(
          (1.0 - ((localP - 0.65) / 0.35)).clamp(0.0, 1.0),
        );
      }

      if (alpha <= 0.005) continue;

      final double rotation =
          particle.initialAngle + particle.angularVelocity * lt;
      // 3D paper flutter simulation
      final double flipCos = math.cos(
        particle.flipPhase + particle.flipSpeed * lt,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      Color shapeColor = particle.color.withValues(alpha: alpha);
      // Subtle back-side illumination difference when paper is facing away
      if (flipCos < 0 &&
          (particle.shape == CelebrationShape.strip ||
              particle.shape == CelebrationShape.square)) {
        shapeColor = Color.lerp(shapeColor, Colors.black, 0.16) ?? shapeColor;
      }
      confettiPaint.color = shapeColor;

      _drawShape(
        canvas: canvas,
        shape: particle.shape,
        size: particle.size,
        length: particle.length,
        flipCos: flipCos,
        paint: confettiPaint,
      );

      canvas.restore();
    }
  }

  void _drawShape({
    required Canvas canvas,
    required CelebrationShape shape,
    required double size,
    required double length,
    required double flipCos,
    required Paint paint,
  }) {
    switch (shape) {
      case CelebrationShape.circle:
        canvas.drawCircle(Offset.zero, size * 0.5, paint);
        break;

      case CelebrationShape.square:
        final double minW = math.min(1.5, size);
        final double w = (size * flipCos.abs()).clamp(minW, size);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: w, height: size),
          paint,
        );
        break;

      case CelebrationShape.strip:
        // 3D tumbling confetti ribbon
        final double minW = math.min(1.5, size);
        final double w = (size * flipCos.abs()).clamp(minW, size);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: length),
            const Radius.circular(2.0),
          ),
          paint,
        );
        break;

      case CelebrationShape.sparkle:
        // 4-pointed diamond star sparkle
        final double r = size;
        final double inner = r * 0.24;
        final Path sparklePath = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(0, -inner, inner, 0)
          ..quadraticBezierTo(0, inner, 0, r)
          ..quadraticBezierTo(0, inner, -inner, 0)
          ..quadraticBezierTo(0, -inner, 0, -r)
          ..close();
        canvas.drawPath(sparklePath, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(CelebrationPainter oldDelegate) {
    return bottleProgress != oldDelegate.bottleProgress ||
        levelProgress != oldDelegate.levelProgress ||
        bottleParticles != oldDelegate.bottleParticles ||
        levelParticles != oldDelegate.levelParticles;
  }
}
