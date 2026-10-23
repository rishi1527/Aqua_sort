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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    // 2. Subtle floating motion (looping 3s)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Soft aqua glow pulse (looping 2s)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
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
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepNavy,
              Color(0xFF05152B),
              AppTheme.deepNavyEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
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

              // Centered Brand Content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_floatAnimation, _glowAnimation]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Water Drop Icon with Multi-colored liquid layers
                          _buildWaterDropLogo(),
                          const SizedBox(height: 32),

                          // App Name "AquaSort"
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Aqua',
                                  style: TextStyle(color: AppTheme.iceWhite),
                                ),
                                TextSpan(
                                  text: 'Sort',
                                  style: TextStyle(
                                    color: AppTheme.aquaGlow,
                                    shadows: [
                                      Shadow(
                                        color: Color(0x6638D9FF),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tagline
                          const Text(
                            'Pour. Sort. Relax.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xB3EAF7FF),
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
                bottom: 36,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.aquaGlow.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preparing your puzzle...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.iceWhite.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
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
                color: AppTheme.aquaGlow.withValues(alpha: 0.25 * glowOpacity),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 60,
                spreadRadius: 15,
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

// Custom Painter for Water-Drop with layered puzzle liquid
class _WaterDropPainter extends CustomPainter {
  final double glowStrength;
  _WaterDropPainter({required this.glowStrength});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Water Drop Path
    final dropPath = Path();
    dropPath.moveTo(w * 0.5, h * 0.04);
    dropPath.cubicTo(w * 0.85, h * 0.45, w * 0.98, h * 0.68, w * 0.98, h * 0.78);
    dropPath.cubicTo(w * 0.98, h * 0.92, w * 0.77, h * 0.98, w * 0.5, h * 0.98);
    dropPath.cubicTo(w * 0.23, h * 0.98, w * 0.02, h * 0.92, w * 0.02, h * 0.78);
    dropPath.cubicTo(w * 0.02, h * 0.68, w * 0.15, h * 0.45, w * 0.5, h * 0.04);
    dropPath.close();

    // Clip canvas to the drop shape to paint internal layered liquid
    canvas.save();
    canvas.clipPath(dropPath);

    // Layer 1 (Bottom): Deep Purple Liquid
    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
      ).createShader(Rect.fromLTWH(0, h * 0.76, w, h * 0.24));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.76, w, h * 0.24), paint1);

    // Wave separator 1
    _drawLiquidDivider(canvas, w, h * 0.76, const Color(0xFFC77DFF));

    // Layer 2: Vibrant Orange Liquid
    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
      ).createShader(Rect.fromLTWH(0, h * 0.54, w, h * 0.22));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.54, w, h * 0.22), paint2);

    // Wave separator 2
    _drawLiquidDivider(canvas, w, h * 0.54, const Color(0xFFFFB703));

    // Layer 3: Emerald Green Liquid
    final paint3 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF00E676)],
      ).createShader(Rect.fromLTWH(0, h * 0.34, w, h * 0.20));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.34, w, h * 0.20), paint3);

    // Wave separator 3
    _drawLiquidDivider(canvas, w, h * 0.34, const Color(0xFF69F0AE));

    // Layer 4 (Top): Bright Aqua Blue Liquid
    final paint4 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0091EA), Color(0xFF00E5FF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.34));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.34), paint4);

    // Inner Glass Glare / Specular highlight
    final glossPath = Path();
    glossPath.moveTo(w * 0.22, h * 0.40);
    glossPath.quadraticBezierTo(w * 0.12, h * 0.70, w * 0.28, h * 0.88);
    glossPath.quadraticBezierTo(w * 0.20, h * 0.70, w * 0.28, h * 0.42);
    glossPath.close();

    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glossPath, glossPaint);

    canvas.restore();

    // Outer Glass Rim with Aqua Glow
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.aquaGlow.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.6),
          AppTheme.primaryBlue.withValues(alpha: 0.4),
          AppTheme.aquaGlow.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawPath(dropPath, rimPaint);
  }

  void _drawLiquidDivider(Canvas canvas, double w, double y, Color color) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
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
        (b['x'] as double) * size.width + math.sin(progress * 2 * math.pi + speed) * 8,
        currentY * size.height,
      );

      paint.color = AppTheme.aquaGlow.withValues(alpha: 0.12);
      canvas.drawCircle(offset, b['radius'] as double, paint);

      // Bubble highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(offset.dx - (b['radius'] as double) * 0.3, offset.dy - (b['radius'] as double) * 0.3),
        (b['radius'] as double) * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}
