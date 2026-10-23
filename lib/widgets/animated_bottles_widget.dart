import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBottlesWidget extends StatefulWidget {
  final double height;

  const AnimatedBottlesWidget({
    super.key,
    this.height = 175,
  });

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

        // Subtle floating and tilting oscillations
        final double floatLeft = math.sin(t) * 4.0;
        final double tiltLeft = -0.12 + math.sin(t + 0.5) * 0.02;

        final double floatCenter = math.sin(t + 1.2) * 5.5;
        final double tiltCenter = math.sin(t + 2.0) * 0.025;

        final double floatRight = math.sin(t + 2.4) * 4.0;
        final double tiltRight = 0.12 + math.sin(t + 2.8) * 0.02;

        return SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient soft glow behind bottles
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.aquaGlow.withValues(alpha: 0.16 + math.sin(t) * 0.04),
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
                  painter: _BottleBubblePainter(progress: _idleController.value),
                ),
              ),

              // Row of the 3 bottles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Bottle: Tilted slightly left, 4 layers: Blue, Purple, Pink, Cyan
                  Transform.translate(
                    offset: Offset(0, floatLeft),
                    child: Transform.rotate(
                      angle: tiltLeft,
                      child: const _SingleBottleWidget(
                        width: 46,
                        height: 132,
                        liquidColors: [
                          Color(0xFF087ECA), // Blue
                          Color(0xFF9D4EDD), // Purple
                          Color(0xFFEC4899), // Pink
                          Color(0xFF00E5FF), // Cyan
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Middle Bottle: Slightly taller, stands proud, 4 layers: Green, Yellow, Purple, Aqua
                  Transform.translate(
                    offset: Offset(0, -6 + floatCenter),
                    child: Transform.rotate(
                      angle: tiltCenter,
                      child: const _SingleBottleWidget(
                        width: 52,
                        height: 155,
                        isCenter: true,
                        liquidColors: [
                          Color(0xFF10B981), // Green
                          Color(0xFFFBBF24), // Yellow
                          Color(0xFF9333EA), // Purple
                          Color(0xFF38D9FF), // Cyan/Aqua
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Bottle: Tilted slightly right, 4 layers: Pink, Green, Yellow, Blue
                  Transform.translate(
                    offset: Offset(0, floatRight),
                    child: Transform.rotate(
                      angle: tiltRight,
                      child: const _SingleBottleWidget(
                        width: 46,
                        height: 132,
                        liquidColors: [
                          Color(0xFFF43F5E), // Pink
                          Color(0xFF059669), // Green
                          Color(0xFFF59E0B), // Yellow
                          Color(0xFF0284C7), // Blue
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

  const _SingleBottleWidget({
    required this.width,
    required this.height,
    required this.liquidColors,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BottlePainter(
        liquidColors: liquidColors,
        isCenter: isCenter,
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final List<Color> liquidColors;
  final bool isCenter;

  _BottlePainter({
    required this.liquidColors,
    this.isCenter = false,
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
    final double bodyHeight = h - bodyTop;
    final double baseRadius = w * 0.44;

    // 1. Draw Glass Cavity Path (for clipping the liquid)
    final Path cavityPath = Path();
    cavityPath.moveTo((w - neckWidth) / 2 + 1.5, bodyTop);
    cavityPath.lineTo(1.5, bodyTop + 8.0);
    cavityPath.lineTo(1.5, h - baseRadius);
    cavityPath.arcToPoint(
      Offset(w - 1.5, h - baseRadius),
      radius: Radius.circular(baseRadius),
      clockwise: false,
    );
    cavityPath.lineTo(w - 1.5, bodyTop + 8.0);
    cavityPath.lineTo((w + neckWidth) / 2 - 1.5, bodyTop);
    cavityPath.close();

    // 2. Draw Translucent Glass Backing
    final Paint glassBackingPaint = Paint()
      ..color = const Color(0xFF142B4C).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cavityPath, glassBackingPaint);

    // 3. Draw Liquid Layers (clipped inside bottle)
    canvas.save();
    canvas.clipPath(cavityPath);

    final int layerCount = liquidColors.length;
    final double liquidTotalHeight = bodyHeight - 4.0;
    final double layerHeight = liquidTotalHeight / layerCount;
    final double liquidStartTop = bodyTop + 8.0;

    for (int i = 0; i < layerCount; i++) {
      // index 0 is bottom, index layerCount - 1 is top
      final Color color = liquidColors[i];
      final double top = h - (i + 1) * layerHeight;
      final Rect layerRect = Rect.fromLTWH(0, top, w, layerHeight + 0.8);

      final Paint layerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color,
            color.withValues(alpha: 0.82),
          ],
        ).createShader(layerRect);

      canvas.drawRect(layerRect, layerPaint);

      // Layer surface meniscus / separator line
      if (i < layerCount - 1) {
        final Paint dividerPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        final Path wavePath = Path();
        wavePath.moveTo(0, top);
        wavePath.quadraticBezierTo(w * 0.5, top - 1.2, w, top);
        canvas.drawPath(wavePath, dividerPaint);
      } else {
        // Top meniscus of highest liquid layer
        final Paint meniscusPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final Path wavePath = Path();
        wavePath.moveTo(0, top);
        wavePath.quadraticBezierTo(w * 0.5, top - 2.0, w, top);
        canvas.drawPath(wavePath, meniscusPaint);
      }
    }

    // Inner liquid specular glow
    final Rect innerGlowRect = Rect.fromLTWH(2, liquidStartTop, w - 4, liquidTotalHeight);
    final Paint innerGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.15),
        ],
      ).createShader(innerGlowRect);
    canvas.drawRect(innerGlowRect, innerGlowPaint);

    canvas.restore();

    // 4. Outer Glass Body Path (with neck and lip)
    final Path bottleOutline = Path();
    // Neck left
    bottleOutline.moveTo((w - neckWidth) / 2, neckTop);
    bottleOutline.lineTo((w - neckWidth) / 2, bodyTop);
    // Shoulder left
    bottleOutline.quadraticBezierTo(0, bodyTop + 2, 0, bodyTop + 9);
    // Body left
    bottleOutline.lineTo(0, h - baseRadius);
    // Rounded Bottom
    bottleOutline.arcToPoint(
      Offset(w, h - baseRadius),
      radius: Radius.circular(baseRadius),
      clockwise: false,
    );
    // Body right
    bottleOutline.lineTo(w, bodyTop + 9);
    // Shoulder right
    bottleOutline.quadraticBezierTo(w, bodyTop + 2, (w + neckWidth) / 2, bodyTop);
    // Neck right
    bottleOutline.lineTo((w + neckWidth) / 2, neckTop);
    bottleOutline.close();

    // 5. Draw Glass Outer Stroke with Aqua Shimmer
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

    // 6. Draw Top Glass Lip (Rounded pill)
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

    // 7. Glass Specular Highlights (Left-side reflection streak)
    final Path leftGlint = Path();
    leftGlint.moveTo(w * 0.16, bodyTop + 12);
    leftGlint.lineTo(w * 0.16, h - baseRadius * 1.1);

    final Paint glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftGlint, glintPaint);

    // Shorter soft specular highlight
    final Path secondaryGlint = Path();
    secondaryGlint.moveTo(w * 0.24, bodyTop + 14);
    secondaryGlint.lineTo(w * 0.24, bodyTop + 36);

    final Paint secGlintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(secondaryGlint, secGlintPaint);

    // Bottom curve specular glint
    final Path bottomCurveGlint = Path();
    bottomCurveGlint.arcToPoint(
      Offset(w * 0.75, h - 3.5),
      radius: Radius.circular(baseRadius * 0.8),
      clockwise: false,
    );
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) =>
      oldDelegate.isCenter != isCenter || oldDelegate.liquidColors != liquidColors;
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
      final double currentX = (b['x'] as double) * w + math.sin(progress * 2 * math.pi + speed) * drift;

      bubblePaint.color = AppTheme.aquaGlow.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(currentX, currentY), radius, bubblePaint);

      bubblePaint.color = Colors.white.withValues(alpha: 0.5);
      canvas.drawCircle(Offset(currentX - radius * 0.3, currentY - radius * 0.3), radius * 0.35, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BottleBubblePainter oldDelegate) => true;
}
