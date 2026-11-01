import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/customization_models.dart';
import '../models/theme_model.dart';
import '../services/game_service.dart';

class GameBackgroundWidget extends StatelessWidget {
  final BackgroundStyle? background;
  final GameTheme? theme;
  final Widget? child;

  const GameBackgroundWidget({
    super.key,
    this.background,
    this.theme,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme =
        theme ?? GameTheme.getById(GameService.instance.selectedThemeId);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (background != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _ScenicBackgroundPainter(background: background!),
            ),
          )
        else if (activeTheme.backgroundColors.isNotEmpty)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: activeTheme.backgroundColors,
                ),
              ),
            ),
          ),
        if (activeTheme.assetPath.isNotEmpty)
          Positioned.fill(
            child: Image.asset(
              activeTheme.assetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        // Premium softly glowing green particles floating in background behind UI
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: GlowingGreenParticlesWidget()),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

/// A lightweight, high-performance particle layer that renders softly glowing
/// green particles drifting gently over the deep black background.
///
/// Designed to strictly match the reference image atmosphere:
/// - Varied particle sizes (small specks, medium motes, hero glowing particles).
/// - Soft green glowing halos using MaskFilter blur and luminous mint/lime cores.
/// - Gentle vertical drift with sinusoidal horizontal sway and breathing opacity.
/// - Wrapped with RepaintBoundary and IgnorePointer to ensure 60 FPS performance
///   and zero touch interception.
class GlowingGreenParticlesWidget extends StatefulWidget {
  final int particleCount;
  final bool animate;

  const GlowingGreenParticlesWidget({
    super.key,
    this.particleCount = 42,
    this.animate = true,
  });

  @override
  State<GlowingGreenParticlesWidget> createState() =>
      _GlowingGreenParticlesWidgetState();
}

class _GlowingGreenParticlesWidgetState
    extends State<GlowingGreenParticlesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<_GlowingParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles(widget.particleCount);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlowingGreenParticlesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.particleCount != oldWidget.particleCount) {
      _particles.clear();
      _particles.addAll(_generateParticles(widget.particleCount));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static List<_GlowingParticle> _generateParticles(int count) {
    // Deterministic pseudo-random generator with fixed seed so particle layout
    // is consistent, beautifully balanced, and doesn't recreate every frame.
    final rng = math.Random(54321);
    final list = <_GlowingParticle>[];

    for (int i = 0; i < count; i++) {
      // Stratify into categories:
      // ~50% small (1.2 to 2.0px)
      // ~35% medium (2.2 to 3.4px)
      // ~15% hero (3.8 to 4.8px) with radiant halo
      final double tier = rng.nextDouble();
      final double baseRadius;
      final double glowRadius;
      final double baseOpacity;
      final Color coreColor;
      final Color haloColor;

      if (tier < 0.50) {
        // Small background stardust
        baseRadius = 1.2 + rng.nextDouble() * 0.8;
        glowRadius = 3.0 + rng.nextDouble() * 2.5;
        baseOpacity = 0.25 + rng.nextDouble() * 0.35;
        coreColor = const Color(0xFF86EFAC); // soft mint green
        haloColor = const Color(0xFF15803D);
      } else if (tier < 0.85) {
        // Medium luminous motes
        baseRadius = 2.2 + rng.nextDouble() * 1.2;
        glowRadius = 6.0 + rng.nextDouble() * 3.5;
        baseOpacity = 0.55 + rng.nextDouble() * 0.30;
        coreColor = const Color(0xFF4ADE80); // radiant emerald-lime
        haloColor = const Color(0xFF22C55E);
      } else {
        // Hero glowing particles
        baseRadius = 3.6 + rng.nextDouble() * 1.2;
        glowRadius = 10.0 + rng.nextDouble() * 5.0;
        baseOpacity = 0.85 + rng.nextDouble() * 0.15;
        coreColor = const Color(0xFFDCFCE7); // bright white-mint
        haloColor = const Color(0xFF4ADE80);
      }

      list.add(
        _GlowingParticle(
          initialX: rng.nextDouble(),
          initialY: rng.nextDouble(),
          radius: baseRadius,
          glowRadius: glowRadius,
          baseOpacity: baseOpacity,
          speedY: 0.35 + rng.nextDouble() * 0.65, // slow upward drift
          swayAmplitude: 3.5 + rng.nextDouble() * 5.0, // horizontal sine sway
          swayFrequency: 1.0 + rng.nextDouble() * 2.0,
          swayPhase: rng.nextDouble() * 2 * math.pi,
          pulseFrequency: 1.5 + rng.nextDouble() * 2.5,
          pulsePhase: rng.nextDouble() * 2 * math.pi,
          coreColor: coreColor,
          haloColor: haloColor,
          isHero: tier >= 0.85,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _controller.isAnimating) {
      _controller.stop();
    }

    return CustomPaint(
      painter: _GlowingParticlesPainter(
        animation: _controller,
        particles: _particles,
      ),
      size: Size.infinite,
    );
  }
}

class _GlowingParticle {
  final double initialX;
  final double initialY;
  final double radius;
  final double glowRadius;
  final double baseOpacity;
  final double speedY;
  final double swayAmplitude;
  final double swayFrequency;
  final double swayPhase;
  final double pulseFrequency;
  final double pulsePhase;
  final Color coreColor;
  final Color haloColor;
  final bool isHero;

  const _GlowingParticle({
    required this.initialX,
    required this.initialY,
    required this.radius,
    required this.glowRadius,
    required this.baseOpacity,
    required this.speedY,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.swayPhase,
    required this.pulseFrequency,
    required this.pulsePhase,
    required this.coreColor,
    required this.haloColor,
    required this.isHero,
  });
}

class _GlowingParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_GlowingParticle> particles;

  // Cached paint objects to avoid any allocation during paint cycles
  final Paint _haloPaint = Paint()..style = PaintingStyle.fill;
  final Paint _corePaint = Paint()..style = PaintingStyle.fill;
  final Paint _highlightPaint = Paint()..style = PaintingStyle.fill;

  _GlowingParticlesPainter({required this.animation, required this.particles})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;

    final double t = animation.value;

    for (final p in particles) {
      // 1. Vertical position: smooth toroidal wrap (drifting upward)
      final double rawY = (p.initialY - (t * p.speedY)) % 1.0;
      final double normalizedY = rawY < 0 ? rawY + 1.0 : rawY;
      final double cy = normalizedY * h;

      // 2. Horizontal position: gentle sinusoidal sway
      final double sway =
          math.sin((2 * math.pi * p.swayFrequency * t) + p.swayPhase) *
          p.swayAmplitude;
      final double cx = (p.initialX * w) + sway;

      // 3. Opacity pulse / twinkle
      final double pulse =
          0.72 +
          0.28 * math.sin((2 * math.pi * p.pulseFrequency * t) + p.pulsePhase);
      final double opacity = (p.baseOpacity * pulse).clamp(0.0, 1.0);

      if (opacity <= 0.01) continue;

      // 4. Draw outer soft glow halo
      _haloPaint
        ..color = p.haloColor.withValues(alpha: opacity * 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.glowRadius);
      canvas.drawCircle(Offset(cx, cy), p.glowRadius * 0.85, _haloPaint);

      // 5. Draw luminous core
      _corePaint
        ..color = p.coreColor.withValues(alpha: opacity)
        ..maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), p.radius, _corePaint);

      // 6. Draw bright pinpoint center for hero particles
      if (p.isHero) {
        _highlightPaint
          ..color = const Color(0xFFF0FDF4).withValues(alpha: opacity * 0.95)
          ..maskFilter = null;
        canvas.drawCircle(Offset(cx, cy), p.radius * 0.42, _highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingParticlesPainter oldDelegate) => true;
}

class _ScenicBackgroundPainter extends CustomPainter {
  final BackgroundStyle background;

  _ScenicBackgroundPainter({required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Base Gradient
    final Rect fullRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: background.gradientColors,
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    // 2. Procedural Scenic Layer based on Scene Type
    switch (background.sceneType) {
      case BackgroundSceneType.purpleCanvas:
        // Ambient soft green glowing circles
        final glow1 = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
        canvas.drawCircle(Offset(w * 0.5, h * 0.15), 140, glow1);

        final glow2 = Paint()
          ..color = const Color(0xFF059669).withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
        canvas.drawCircle(Offset(w * 0.2, h * 0.70), 120, glow2);
        break;

      case BackgroundSceneType.alpineValley:
        // Distant mountains
        final mountainPaint = Paint()
          ..color = const Color(0xFF93C5FD).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        final mountainPath = Path();
        mountainPath.moveTo(0, h * 0.45);
        mountainPath.lineTo(w * 0.25, h * 0.32);
        mountainPath.lineTo(w * 0.50, h * 0.42);
        mountainPath.lineTo(w * 0.75, h * 0.28);
        mountainPath.lineTo(w, h * 0.46);
        mountainPath.lineTo(w, h);
        mountainPath.lineTo(0, h);
        mountainPath.close();
        canvas.drawPath(mountainPath, mountainPaint);

        // Rolling green hills
        final hillPaint = Paint()
          ..color = const Color(0xFF86EFAC).withValues(alpha: 0.30)
          ..style = PaintingStyle.fill;
        final hillPath = Path();
        hillPath.moveTo(0, h * 0.58);
        hillPath.quadraticBezierTo(w * 0.35, h * 0.50, w * 0.70, h * 0.62);
        hillPath.quadraticBezierTo(w * 0.85, h * 0.66, w, h * 0.60);
        hillPath.lineTo(w, h);
        hillPath.lineTo(0, h);
        hillPath.close();
        canvas.drawPath(hillPath, hillPaint);
        break;

      case BackgroundSceneType.dreamTwilight:
        // Twilight star dust and crescent moon
        final moonPaint = Paint()
          ..color = const Color(0xFFFDE68A).withValues(alpha: 0.45)
          ..style = PaintingStyle.fill;
        final moonPath = Path();
        moonPath.addOval(
          Rect.fromCircle(center: Offset(w * 0.82, h * 0.14), radius: 18),
        );
        final moonCut = Path();
        moonCut.addOval(
          Rect.fromCircle(center: Offset(w * 0.86, h * 0.12), radius: 18),
        );
        final crescent = Path.combine(
          PathOperation.difference,
          moonPath,
          moonCut,
        );
        canvas.drawPath(crescent, moonPaint);

        // Twinkling star field
        final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
        for (int i = 0; i < 24; i++) {
          final double sx = ((i * 37) % 100) / 100.0 * w;
          final double sy = ((i * 53) % 65) / 100.0 * h;
          canvas.drawCircle(
            Offset(sx, sy),
            (i % 3 == 0) ? 1.5 : 1.0,
            starPaint,
          );
        }
        break;

      case BackgroundSceneType.enchantedForest:
        // Forest silhouettes
        final treePaint = Paint()
          ..color = const Color(0xFF022C22).withValues(alpha: 0.30)
          ..style = PaintingStyle.fill;
        for (int i = 0; i < 10; i++) {
          final double tx = (i / 9.0) * w;
          final double th = h * 0.18 + (i % 3) * 20.0;
          final Path tree = Path();
          tree.moveTo(tx, h * 0.70 - th);
          tree.lineTo(tx + 22, h * 0.70);
          tree.lineTo(tx - 22, h * 0.70);
          tree.close();
          canvas.drawPath(tree, treePaint);
        }

        // Firefly motes
        final fireflyPaint = Paint()
          ..color = const Color(0xFFBBF7D0).withValues(alpha: 0.50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        for (int i = 0; i < 12; i++) {
          final double fx = ((i * 43) % 90 + 5) / 100.0 * w;
          final double fy = ((i * 67) % 70 + 20) / 100.0 * h;
          canvas.drawCircle(Offset(fx, fy), 2.2, fireflyPaint);
        }
        break;

      case BackgroundSceneType.sunsetCastle:
        // Sun setting on horizon
        final sunPaint = Paint()
          ..color = const Color(0xFFFDE047).withValues(alpha: 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
        canvas.drawCircle(Offset(w * 0.5, h * 0.65), 50, sunPaint);

        // Distant castle silhouette
        final castlePaint = Paint()
          ..color = const Color(0xFF431407).withValues(alpha: 0.30)
          ..style = PaintingStyle.fill;
        final castlePath = Path();
        castlePath.moveTo(0, h * 0.72);
        castlePath.lineTo(w * 0.35, h * 0.72);
        castlePath.lineTo(w * 0.35, h * 0.64);
        castlePath.lineTo(w * 0.40, h * 0.60);
        castlePath.lineTo(w * 0.45, h * 0.64);
        castlePath.lineTo(w * 0.55, h * 0.64);
        castlePath.lineTo(w * 0.60, h * 0.58);
        castlePath.lineTo(w * 0.65, h * 0.64);
        castlePath.lineTo(w, h * 0.72);
        castlePath.lineTo(w, h);
        castlePath.lineTo(0, h);
        castlePath.close();
        canvas.drawPath(castlePath, castlePaint);
        break;

      case BackgroundSceneType.celestialValley:
        // Swirling galaxy nebula
        final neb1 = Paint()
          ..color = const Color(0xFF818CF8).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.3, h * 0.25),
            width: w * 0.8,
            height: 160,
          ),
          neb1,
        );

        final neb2 = Paint()
          ..color = const Color(0xFFC084FC).withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.7, h * 0.55),
            width: w * 0.7,
            height: 140,
          ),
          neb2,
        );

        final star = Paint()..color = Colors.white.withValues(alpha: 0.6);
        for (int i = 0; i < 30; i++) {
          final double sx = ((i * 31) % 95 + 2) / 100.0 * w;
          final double sy = ((i * 73) % 85 + 5) / 100.0 * h;
          canvas.drawCircle(Offset(sx, sy), 0.9, star);
        }
        break;

      case BackgroundSceneType.oceanValley:
        // Caustic sunlight rays
        final causticPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        for (int i = 0; i < 4; i++) {
          final Path ray = Path();
          final double rx = (i * 0.28) * w;
          ray.moveTo(rx, 0);
          ray.lineTo(rx + 40, 0);
          ray.lineTo(rx + 90, h);
          ray.lineTo(rx + 20, h);
          ray.close();
          canvas.drawPath(ray, causticPaint);
        }
        break;

      case BackgroundSceneType.doodleDark:
        // Subtle geometric line grid
        final linePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 1.0;
        for (double x = 20; x < w; x += 40) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
        }
        for (double y = 20; y < h; y += 40) {
          canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
        }
        break;
    }

    // 3. Optional Readability Overlay for gameplay contrast
    if (background.overlayColor != Colors.transparent) {
      canvas.drawRect(fullRect, Paint()..color = background.overlayColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenicBackgroundPainter old) =>
      old.background.id != background.id;
}
