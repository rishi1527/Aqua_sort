import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _bubbleController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // 1. Fade-in and scale entrance animation (1000ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    // 2. Subtle floating motion (looping 3s)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 3. Soft aqua glow pulse (looping 2s)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.40, end: 0.90).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 4. Ambient floating background bubbles
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entranceController.forward();

    // 5. Navigate to HomeScreen after animation finishes
    _navTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entranceController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.radialCanvas),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle ambient floating bubbles
              AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _BubblePainter(progress: _bubbleController.value),
                ),
              ),

              // Ambient glow sphere
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryContainer.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 90,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Centered Brand Content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _floatAnimation,
                        _glowAnimation,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Decorative Spatial Pill (Discreet Brand Seal from Stitch)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh.withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryContainer.withValues(
                                  alpha: 0.20,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  color: AppTheme.primaryContainer,
                                  size: 13,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'ZEN FLUIDICS LAB',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.2,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Water Drop Icon with exact Stitch Multi-colored liquid layers
                          _buildWaterDropLogo(),
                          const SizedBox(height: 30),

                          // App Name "AquaSort"
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Aqua',
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                TextSpan(
                                  text: 'Sort',
                                  style: TextStyle(
                                    color: AppTheme.primaryContainer,
                                    shadows: [
                                      Shadow(
                                        color: Color(0x806D28D9),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline
                          const Text(
                            'Pour. Sort. Relax.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B5B85),
                              letterSpacing: 3.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Section: Loading Indicator & Subtext
              Positioned(
                bottom: 34,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryContainer.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Preparing your puzzle...',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v2.4 • Fluidics Engine Ready',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.35,
                          ),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterDropLogo() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        final glowOpacity = _glowAnimation.value;
        return Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryContainer.withValues(
                  alpha: 0.28 * glowOpacity,
                ),
                blurRadius: 42,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.32),
                blurRadius: 54,
                spreadRadius: 12,
              ),
            ],
          ),
          child: CustomPaint(
            size: const Size(140, 180),
            painter: _WaterDropPainter(glowStrength: glowOpacity),
          ),
        );
      },
    );
  }
}

// Custom Painter for Water-Drop with exact Stitch SVG layered liquid geometry
class _WaterDropPainter extends CustomPainter {
  final double glowStrength;
  _WaterDropPainter({required this.glowStrength});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stitch SVG Water Drop Path
    // SVG viewBox: 0 0 140 180 -> path: M70 6 C70 6 12 82 12 118 C12 150 38 174 70 174 C102 174 128 150 128 118 C128 82 70 6 70 6 Z
    final sx = w / 140.0;
    final sy = h / 180.0;

    final dropPath = Path();
    dropPath.moveTo(70 * sx, 6 * sy);
    dropPath.cubicTo(70 * sx, 6 * sy, 12 * sx, 82 * sy, 12 * sx, 118 * sy);
    dropPath.cubicTo(12 * sx, 150 * sy, 38 * sx, 174 * sy, 70 * sx, 174 * sy);
    dropPath.cubicTo(
      102 * sx,
      174 * sy,
      128 * sx,
      150 * sy,
      128 * sx,
      118 * sy,
    );
    dropPath.cubicTo(128 * sx, 82 * sy, 70 * sx, 6 * sy, 70 * sx, 6 * sy);
    dropPath.close();

    // Inside glass tint
    final bgPaint = Paint()
      ..color = const Color(0xFF091C35).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dropPath, bgPaint);

    // Clip canvas to the drop shape to paint internal layered liquid
    canvas.save();
    canvas.clipPath(dropPath);

    // Layer 1 (Bottom): Deep Violet Layer (Y: 138 -> 180)
    final p1 = Path();
    p1.moveTo(0, 138 * sy);
    p1.quadraticBezierTo(35 * sx, 134 * sy, 70 * sx, 137 * sy);
    p1.quadraticBezierTo(105 * sx, 140 * sy, 140 * sx, 136 * sy);
    p1.lineTo(140 * sx, 180 * sy);
    p1.lineTo(0, 180 * sy);
    p1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD), Color(0xFF5A189A)],
      ).createShader(Rect.fromLTWH(0, 134 * sy, w, 46 * sy));
    canvas.drawPath(p1, paint1);

    _drawWaveLine(
      canvas,
      sx,
      sy,
      Offset(0, 138 * sy),
      Offset(35 * sx, 134 * sy),
      Offset(70 * sx, 137 * sy),
      Offset(105 * sx, 140 * sy),
      Offset(140 * sx, 136 * sy),
      const Color(0xFFC77DFF).withValues(alpha: 0.5),
    );

    // Layer 2: Vibrant Sunset Orange Layer (Y: 104 -> 138)
    final p2 = Path();
    p2.moveTo(0, 104 * sy);
    p2.quadraticBezierTo(35 * sx, 101 * sy, 70 * sx, 105 * sy);
    p2.quadraticBezierTo(105 * sx, 109 * sy, 140 * sx, 103 * sy);
    p2.lineTo(140 * sx, 138 * sy);
    p2.lineTo(0, 138 * sy);
    p2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6D00), Color(0xFFFF9100), Color(0xFFE85D04)],
      ).createShader(Rect.fromLTWH(0, 101 * sy, w, 37 * sy));
    canvas.drawPath(p2, paint2);

    _drawWaveLine(
      canvas,
      sx,
      sy,
      Offset(0, 104 * sy),
      Offset(35 * sx, 101 * sy),
      Offset(70 * sx, 105 * sy),
      Offset(105 * sx, 109 * sy),
      Offset(140 * sx, 103 * sy),
      const Color(0xFFFFB703).withValues(alpha: 0.6),
    );

    // Layer 3: Emerald Green Layer (Y: 72 -> 104)
    final p3 = Path();
    p3.moveTo(0, 72 * sy);
    p3.quadraticBezierTo(35 * sx, 75 * sy, 70 * sx, 71 * sy);
    p3.quadraticBezierTo(105 * sx, 67 * sy, 140 * sx, 73 * sy);
    p3.lineTo(140 * sx, 104 * sy);
    p3.lineTo(0, 104 * sy);
    p3.close();

    final paint3 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF00E676), Color(0xFF00B348)],
      ).createShader(Rect.fromLTWH(0, 67 * sy, w, 37 * sy));
    canvas.drawPath(p3, paint3);

    _drawWaveLine(
      canvas,
      sx,
      sy,
      Offset(0, 72 * sy),
      Offset(35 * sx, 75 * sy),
      Offset(70 * sx, 71 * sy),
      Offset(105 * sx, 67 * sy),
      Offset(140 * sx, 73 * sy),
      const Color(0xFFB9F6CA).withValues(alpha: 0.6),
    );

    // Layer 4 (Top): Electric Cyan Layer (Y: 38 -> 72)
    final p4 = Path();
    p4.moveTo(0, 38 * sy);
    p4.quadraticBezierTo(35 * sx, 34 * sy, 70 * sx, 37 * sy);
    p4.quadraticBezierTo(105 * sx, 40 * sy, 140 * sx, 36 * sy);
    p4.lineTo(140 * sx, 72 * sy);
    p4.lineTo(0, 72 * sy);
    p4.close();

    final paint4 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00B0FF), Color(0xFF00E5FF), Color(0xFF18FFFF)],
      ).createShader(Rect.fromLTWH(0, 34 * sy, w, 38 * sy));
    canvas.drawPath(p4, paint4);

    _drawWaveLine(
      canvas,
      sx,
      sy,
      Offset(0, 38 * sy),
      Offset(35 * sx, 34 * sy),
      Offset(70 * sx, 37 * sy),
      Offset(105 * sx, 40 * sy),
      Offset(140 * sx, 36 * sy),
      const Color(0xFFEAF7FF).withValues(alpha: 0.8),
    );

    // Ambient Inner Light Meniscus ellipse
    final ellipsePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(70 * sx, 38 * sy),
        width: 56 * sx,
        height: 8 * sy,
      ),
      ellipsePaint,
    );

    // Micro bubbles inside the liquid
    final bubblePaint = Paint()..style = PaintingStyle.fill;

    bubblePaint.color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(48 * sx, 120 * sy), 2.0 * sx, bubblePaint);

    bubblePaint.color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(92 * sx, 88 * sy), 1.5 * sx, bubblePaint);

    bubblePaint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(64 * sx, 56 * sy), 2.5 * sx, bubblePaint);

    bubblePaint.color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(78 * sx, 150 * sy), 1.0 * sx, bubblePaint);

    // Left Arc Specular Highlight Curved Sheen (from Stitch SVG)
    final sheenPath = Path();
    sheenPath.moveTo(30 * sx, 75 * sy);
    sheenPath.cubicTo(24 * sx, 95 * sy, 24 * sx, 125 * sy, 34 * sx, 148 * sy);
    sheenPath.cubicTo(32 * sx, 145 * sy, 20 * sx, 120 * sy, 22 * sx, 92 * sy);
    sheenPath.cubicTo(23 * sx, 78 * sy, 28 * sx, 66 * sy, 30 * sx, 75 * sy);
    sheenPath.close();

    final sheenPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(sheenPath, sheenPaint);

    // Pinpoint Top Specular Glare
    final pinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(68 * sx, 18 * sy), 3.5 * sx, pinPaint);

    canvas.restore();

    // Outer Hydro-Plate Glass Perimeter Contour
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEAF7FF).withValues(alpha: 0.8),
          AppTheme.primaryContainer.withValues(alpha: 0.6),
          const Color(0xFF091C35).withValues(alpha: 0.2),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(dropPath, rimPaint);

    // Soft Rim Inner Glaze
    final innerGlaze = Path();
    innerGlaze.moveTo(68 * sx, 9 * sy);
    innerGlaze.cubicTo(68 * sx, 9 * sy, 16 * sx, 83 * sy, 16 * sx, 118 * sy);
    innerGlaze.cubicTo(16 * sx, 148 * sy, 40 * sx, 170 * sy, 70 * sx, 170 * sy);

    final glazePaint = Paint()
      ..color = AppTheme.primaryContainer.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(innerGlaze, glazePaint);
  }

  void _drawWaveLine(
    Canvas canvas,
    double sx,
    double sy,
    Offset start,
    Offset cp1,
    Offset mid,
    Offset cp2,
    Offset end,
    Color color,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(cp1.dx, cp1.dy, mid.dx, mid.dy);
    path.quadraticBezierTo(cp2.dx, cp2.dy, end.dx, end.dy);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) =>
      oldDelegate.glowStrength != glowStrength;
}

// Background animated bubbles
class _BubblePainter extends CustomPainter {
  final double progress;
  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final bubbles = [
      {'x': 0.15, 'baseY': 0.85, 'radius': 8.0, 'speed': 0.6},
      {'x': 0.82, 'baseY': 0.90, 'radius': 12.0, 'speed': 0.9},
      {'x': 0.32, 'baseY': 0.75, 'radius': 5.0, 'speed': 0.4},
      {'x': 0.70, 'baseY': 0.60, 'radius': 7.0, 'speed': 0.7},
      {'x': 0.20, 'baseY': 0.40, 'radius': 10.0, 'speed': 0.5},
      {'x': 0.88, 'baseY': 0.30, 'radius': 6.0, 'speed': 0.8},
    ];

    for (final b in bubbles) {
      final speed = b['speed'] as double;
      final currentY = ((b['baseY'] as double) - (progress * speed)) % 1.0;
      final offset = Offset(
        (b['x'] as double) * size.width +
            math.sin(progress * 2 * math.pi + speed) * 8,
        currentY * size.height,
      );

      paint.color = AppTheme.primaryContainer.withValues(alpha: 0.12);
      canvas.drawCircle(offset, b['radius'] as double, paint);

      // Bubble highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          offset.dx - (b['radius'] as double) * 0.3,
          offset.dy - (b['radius'] as double) * 0.3,
        ),
        (b['radius'] as double) * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}
