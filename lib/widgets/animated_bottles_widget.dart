import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnimatedBottlesWidget extends StatefulWidget {
  final double height;

  const AnimatedBottlesWidget({super.key, this.height = 175});

  @override
  State<AnimatedBottlesWidget> createState() => _AnimatedBottlesWidgetState();
}

class _AnimatedBottlesWidgetState extends State<AnimatedBottlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, _) {
        final double t = _idleController.value * 2 * math.pi;

        // Subtle floating and tilting oscillations matching Stitch design
        // Left Bottle (-8deg / -0.14rad)
        final double floatLeft = math.sin(t) * 3.5;
        final double tiltLeft = -0.14 + math.sin(t + 0.5) * 0.015;

        // Center Bottle (Hero, Upright, Elevated)
        final double floatCenter = math.sin(t + 1.2) * 4.5;
        final double tiltCenter = math.sin(t + 2.0) * 0.015;

        // Right Bottle (+9deg / +0.157rad)
        final double floatRight = math.sin(t + 2.4) * 3.5;
        final double tiltRight = 0.157 + math.sin(t + 2.8) * 0.015;

        return SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient soft glow behind bottles
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 240,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryContainer.withValues(
                            alpha: 0.16 + math.sin(t) * 0.04,
                          ),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                          blurRadius: 60,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ambient ascending micro-bubbles
              Positioned.fill(
                child: CustomPaint(
                  painter: _BottleBubblePainter(
                    progress: _idleController.value,
                  ),
                ),
              ),

              // Row of the 3 bottles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Bottle: Tilted -8deg, 4 layers: Bottom Pink #FF4DA6, Purple #7655D9, Blue #087ECA, Top Cyan #38D9FF
                  Transform.translate(
                    offset: Offset(0, -6 + floatLeft),
                    child: Transform.rotate(
                      angle: tiltLeft,
                      child: _SingleBottleWidget(
                        width: 48,
                        height: 138,
                        tiltAngle: tiltLeft,
                        wavePhase: t,
                        liquidColors: const [
                          Color(0xFFFF4DA6), // Layer 1 (Bottom): Pink #FF4DA6
                          Color(0xFF7655D9), // Layer 2: Purple #7655D9
                          Color(0xFF087ECA), // Layer 3: Blue #087ECA
                          Color(0xFF38D9FF), // Layer 4 (Top): Cyan #38D9FF
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Middle Bottle (Hero): Elevated, 4 layers: Bottom Cyan #38D9FF, Mint #06D6A0, Orange #FF6B4A, Top Gold #FFD166
                  Transform.translate(
                    offset: Offset(0, -12 + floatCenter),
                    child: Transform.rotate(
                      angle: tiltCenter,
                      child: _SingleBottleWidget(
                        width: 54,
                        height: 160,
                        isCenter: true,
                        tiltAngle: tiltCenter,
                        wavePhase: t + 1.2,
                        liquidColors: const [
                          Color(0xFF38D9FF), // Layer 1 (Bottom): Cyan #38D9FF
                          Color(0xFF06D6A0), // Layer 2: Mint #06D6A0
                          Color(0xFFFF6B4A), // Layer 3: Coral #FF6B4A
                          Color(0xFFFFD166), // Layer 4 (Top): Gold #FFD166
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Bottle: Tilted +9deg, 4 layers: Bottom Purple #7655D9, Mint #06D6A0, Pink #FF4DA6, Top Blue #087ECA
                  Transform.translate(
                    offset: Offset(0, -6 + floatRight),
                    child: Transform.rotate(
                      angle: tiltRight,
                      child: _SingleBottleWidget(
                        width: 48,
                        height: 138,
                        tiltAngle: tiltRight,
                        wavePhase: t + 2.4,
                        liquidColors: const [
                          Color(0xFF7655D9), // Layer 1 (Bottom): Purple #7655D9
                          Color(0xFF06D6A0), // Layer 2: Mint #06D6A0
                          Color(0xFFFF4DA6), // Layer 3: Pink #FF4DA6
                          Color(0xFF087ECA), // Layer 4 (Top): Blue #087ECA
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SingleBottleWidget extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> liquidColors;
  final bool isCenter;
  final double tiltAngle;
  final double wavePhase;

  const _SingleBottleWidget({
    required this.width,
    required this.height,
    required this.liquidColors,
    this.isCenter = false,
    this.tiltAngle = 0.0,
    this.wavePhase = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BottlePainter(
        liquidColors: liquidColors,
        isCenter: isCenter,
        tiltAngle: tiltAngle,
        wavePhase: wavePhase,
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final List<Color> liquidColors;
  final bool isCenter;
  final double tiltAngle;
  final double wavePhase;

  _BottlePainter({
    required this.liquidColors,
    this.isCenter = false,
    this.tiltAngle = 0.0,
    this.wavePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double lipHeight = 7.0;
    final double lipWidth = w + 6.0;
    final double neckTop = lipHeight;
    final double neckHeight = 9.0;
    final double neckWidth = w * 0.68;
    final double bodyTop = neckTop + neckHeight;
    final double baseRadius = w * 0.44;

    // Realistic glass wall thickness
    final double innerLeft = 1.6;
    final double innerRight = w - 1.6;
    final double bottomY = h - 2.0;
    final double innerBaseRadius = baseRadius - 1.6;
    final double innerNeckWidth = neckWidth - 2.4;
    final double topCavityY = bodyTop + 6.0;

    // 1. Draw Glass Cavity Path (for clipping liquid smoothly inside)
    final Path cavityPath = Path();
    cavityPath.moveTo((w - innerNeckWidth) / 2, neckTop);
    cavityPath.lineTo((w - innerNeckWidth) / 2, bodyTop + 1.0);
    cavityPath.quadraticBezierTo(
      innerLeft,
      bodyTop + 3.0,
      innerLeft,
      topCavityY,
    );
    cavityPath.lineTo(innerLeft, h - baseRadius);
    cavityPath.arcToPoint(
      Offset(innerRight, h - baseRadius),
      radius: Radius.circular(innerBaseRadius),
      clockwise: false,
    );
    cavityPath.lineTo(innerRight, topCavityY);
    cavityPath.quadraticBezierTo(
      innerRight,
      bodyTop + 3.0,
      (w + innerNeckWidth) / 2,
      bodyTop + 1.0,
    );
    cavityPath.lineTo((w + innerNeckWidth) / 2, neckTop);
    cavityPath.close();

    // 2. Translucent Glass Backing
    final Paint glassBackingPaint = Paint()
      ..color = const Color(0xFF0F1E36).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cavityPath, glassBackingPaint);

    // 3. Liquid Layers (drawn as organic fluid volumes with smooth meniscus curves)
    canvas.save();
    canvas.clipPath(cavityPath);

    final int layerCount = liquidColors.length;
    if (layerCount > 0) {
      final double liquidTotalHeight = bottomY - topCavityY;
      final double layerHeight = liquidTotalHeight / layerCount;
      const int steps = 28;
      final double dx = (innerRight - innerLeft) / steps;
      final double cx = (innerLeft + innerRight) / 2;
      final double slope = -math.tan(tiltAngle.clamp(-0.85, 0.85));

      List<Offset> computeSurfacePoints(int layerIndex) {
        final List<Offset> points = [];
        final double yBase = bottomY - (layerIndex + 1) * layerHeight;
        final bool isTopmost = layerIndex == layerCount - 1;
        final double amp = isTopmost ? 1.2 : 0.5;
        final double curv = isTopmost ? 1.5 : 0.9;

        for (int s = 0; s <= steps; s++) {
          final double x = innerLeft + s * dx;
          final double u = s / steps;
          final double tiltDy = (x - cx) * slope;
          final double waveDy =
              math.sin(u * math.pi * 2 + wavePhase + layerIndex * 0.45) * amp;
          final double meniscusDy = curv * (1.0 - 4.0 * (u - 0.5) * (u - 0.5));
          final double y = (yBase + tiltDy + waveDy + meniscusDy).clamp(
            bodyTop + 4.0,
            h + 4.0,
          );
          points.add(Offset(x, y));
        }
        return points;
      }

      List<Offset>? previousTopPoints;

      for (int i = 0; i < layerCount; i++) {
        final Color color = liquidColors[i];
        final bool isTopmost = i == layerCount - 1;
        final topPoints = computeSurfacePoints(i);

        final Path layerPath = Path();
        if (i == 0) {
          // Bottom-most layer fills completely down to the inner bottom of the bottle
          layerPath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            layerPath.lineTo(pt.dx, pt.dy);
          }
          layerPath.lineTo(w + 10.0, h + 10.0);
          layerPath.lineTo(-10.0, h + 10.0);
          layerPath.close();
        } else {
          // Upper layers nest seamlessly on top of layer below
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

        // 1. Multi-stop vertical liquid shader
        final double segTopY = bottomY - (i + 1) * layerHeight;
        final double segBotY = i == 0 ? h : bottomY - i * layerHeight;
        final Rect layerRect = Rect.fromLTRB(
          0,
          segTopY - 10.0,
          w,
          segBotY + 10.0,
        );

        final Paint layerPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.90),
              color.withValues(alpha: 0.98),
              Color.lerp(color, const Color(0xFF030D1A), 0.28)!,
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(layerRect);

        canvas.drawPath(layerPath, layerPaint);

        // 2. Horizontal cylindrical 3D lighting
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

        // Fluid boundary between adjacent layers
        if (i > 0 && previousTopPoints != null) {
          final Path interPath = Path();
          interPath.moveTo(
            previousTopPoints.first.dx,
            previousTopPoints.first.dy,
          );
          for (final pt in previousTopPoints) {
            interPath.lineTo(pt.dx, pt.dy);
          }

          final Paint dividerPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawPath(interPath, dividerPaint);

          final Paint shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7;
          canvas.drawPath(interPath, shadowPaint);
        }

        // Topmost liquid meniscus surface crest
        if (isTopmost) {
          final Path surfacePath = Path();
          surfacePath.moveTo(topPoints.first.dx, topPoints.first.dy);
          for (final pt in topPoints) {
            surfacePath.lineTo(pt.dx, pt.dy);
          }

          final Paint surfGlow = Paint()
            ..color = color.withValues(alpha: 0.30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfGlow);

          final Paint surfCrest = Paint()
            ..color = Colors.white.withValues(alpha: 0.68)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfCrest);

          final Paint surfGlint = Paint()
            ..color = Colors.white.withValues(alpha: 0.90)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(surfacePath, surfGlint);
        }

        previousTopPoints = topPoints;
      }
    }

    // Inner liquid specular glow
    final Rect innerGlowRect = Rect.fromLTWH(
      innerLeft,
      topCavityY,
      innerRight - innerLeft,
      bottomY - topCavityY,
    );
    final Paint innerGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.15),
        ],
      ).createShader(innerGlowRect);
    canvas.drawRect(innerGlowRect, innerGlowPaint);

    canvas.restore();

    // 4. Subtle outer bottom curve glass reflection
    final Path bottomGlint = Path();
    bottomGlint.moveTo(w * 0.22, h - 3.0);
    bottomGlint.quadraticBezierTo(w * 0.5, h - 1.2, w * 0.78, h - 3.0);
    final Paint bottomGlintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(bottomGlint, bottomGlintPaint);

    // 5. Outer Glass Body Path (with neck and lip)
    final Path bottleOutline = Path();
    bottleOutline.moveTo((w - neckWidth) / 2, neckTop);
    bottleOutline.lineTo((w - neckWidth) / 2, bodyTop);
    bottleOutline.quadraticBezierTo(0, bodyTop + 2, 0, bodyTop + 9);
    bottleOutline.lineTo(0, h - baseRadius);
    bottleOutline.arcToPoint(
      Offset(w, h - baseRadius),
      radius: Radius.circular(baseRadius),
      clockwise: false,
    );
    bottleOutline.lineTo(w, bodyTop + 9);
    bottleOutline.quadraticBezierTo(
      w,
      bodyTop + 2,
      (w + neckWidth) / 2,
      bodyTop,
    );
    bottleOutline.lineTo((w + neckWidth) / 2, neckTop);
    bottleOutline.close();

    // 6. Draw Glass Outer Stroke with Aqua Shimmer
    final Paint outlinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.aquaGlow.withValues(alpha: isCenter ? 0.95 : 0.8),
          Colors.white.withValues(alpha: 0.7),
          AppTheme.primaryBlue.withValues(alpha: 0.5),
          AppTheme.aquaGlow.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCenter ? 2.2 : 1.8;

    canvas.drawPath(bottleOutline, outlinePaint);

    // 7. Draw Top Glass Lip (Rounded pill)
    final RRect lipRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, lipHeight / 2),
        width: lipWidth,
        height: lipHeight,
      ),
      const Radius.circular(3.5),
    );

    final Paint lipFill = Paint()
      ..color = const Color(0xFF1B3D66).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lipRRect, lipFill);

    final Paint lipStroke = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.8),
          AppTheme.aquaGlow.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, lipHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(lipRRect, lipStroke);

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

    // 8. Glass Specular Highlights (Left-side reflection streak)
    final Path leftGlint = Path();
    leftGlint.moveTo(w * 0.15, bodyTop + 10);
    leftGlint.lineTo(w * 0.15, h - baseRadius * 1.15);

    final Paint glintPaint = Paint()
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
              bodyTop + 10,
              w,
              h - baseRadius * 1.15 - (bodyTop + 10),
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftGlint, glintPaint);

    // Shorter soft specular highlight
    final Path secondaryGlint = Path();
    secondaryGlint.moveTo(w * 0.24, bodyTop + 14);
    secondaryGlint.lineTo(w * 0.24, bodyTop + 36);

    final Paint secGlintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(secondaryGlint, secGlintPaint);

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
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) => true;
}

class _BottleBubblePainter extends CustomPainter {
  final double progress;

  _BottleBubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bubbles = [
      {'x': 0.28, 'yBase': 0.85, 'radius': 2.4, 'speed': 0.7, 'drift': 4.0},
      {'x': 0.50, 'yBase': 0.90, 'radius': 3.2, 'speed': 0.9, 'drift': 6.0},
      {'x': 0.72, 'yBase': 0.80, 'radius': 2.0, 'speed': 0.6, 'drift': -4.0},
      {'x': 0.38, 'yBase': 0.65, 'radius': 1.8, 'speed': 0.8, 'drift': -3.0},
      {'x': 0.62, 'yBase': 0.70, 'radius': 2.2, 'speed': 0.75, 'drift': 5.0},
    ];

    final Paint bubblePaint = Paint()..style = PaintingStyle.fill;

    for (final b in bubbles) {
      final double speed = b['speed'] as double;
      final double yBase = b['yBase'] as double;
      final double drift = b['drift'] as double;
      final double radius = b['radius'] as double;

      final double currentY = ((yBase - progress * speed) % 1.0) * h;
      final double currentX =
          (b['x'] as double) * w +
          math.sin(progress * 2 * math.pi + speed) * drift;

      bubblePaint.color = AppTheme.aquaGlow.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(currentX, currentY), radius, bubblePaint);

      bubblePaint.color = Colors.white.withValues(alpha: 0.5);
      canvas.drawCircle(
        Offset(currentX - radius * 0.3, currentY - radius * 0.3),
        radius * 0.35,
        bubblePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BottleBubblePainter oldDelegate) => true;
}
