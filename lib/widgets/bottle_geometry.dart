import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bottle_model.dart';
import '../models/customization_models.dart';

class BottleGeometry {
  final BottleShape shape;

  const BottleGeometry(this.shape);

  /// Returns the outer glass silhouette path for the bottle
  Path getOuterPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path path = Path();

    switch (shape) {
      case BottleShape.classicTube:
      case BottleShape.classic:
        final double lipH = (h * 0.038).clamp(5.0, 7.5);
        final double neckW = w * 0.72;
        final double bodyTop = lipH + (h * 0.045).clamp(6.0, 9.0);
        final double baseRadius = w * 0.44;

        path.moveTo((w - neckW) / 2, lipH);
        path.lineTo((w - neckW) / 2, bodyTop);
        path.quadraticBezierTo(0, bodyTop + 2.0, 0, bodyTop + 6.0);
        path.lineTo(0, h - baseRadius);
        path.arcToPoint(
          Offset(w, h - baseRadius),
          radius: Radius.circular(baseRadius),
          clockwise: false,
        );
        path.lineTo(w, bodyTop + 6.0);
        path.quadraticBezierTo(w, bodyTop + 2.0, (w + neckW) / 2, bodyTop);
        path.lineTo((w + neckW) / 2, lipH);
        path.close();
        break;

      case BottleShape.conicalFlask:
      case BottleShape.flask:
        path.moveTo(w * 0.30, h * 0.04);
        path.lineTo(w * 0.30, h * 0.20);
        path.lineTo(0, h * 0.90);
        path.quadraticBezierTo(0, h, w * 0.20, h);
        path.lineTo(w * 0.80, h);
        path.quadraticBezierTo(w, h, w, h * 0.90);
        path.lineTo(w * 0.70, h * 0.20);
        path.lineTo(w * 0.70, h * 0.04);
        path.close();
        break;

      case BottleShape.curvyBottle:
      case BottleShape.sodaBottle:
        path.moveTo(w * 0.26, h * 0.04);
        path.lineTo(w * 0.26, h * 0.14);
        path.quadraticBezierTo(w * 0.02, h * 0.26, w * 0.08, h * 0.44);
        path.quadraticBezierTo(w * 0.20, h * 0.58, w * 0.05, h * 0.78);
        path.lineTo(w * 0.05, h * 0.90);
        path.quadraticBezierTo(w * 0.05, h, w * 0.22, h);
        path.lineTo(w * 0.78, h);
        path.quadraticBezierTo(w * 0.95, h, w * 0.95, h * 0.90);
        path.lineTo(w * 0.95, h * 0.78);
        path.quadraticBezierTo(w * 0.80, h * 0.58, w * 0.92, h * 0.44);
        path.quadraticBezierTo(w * 0.98, h * 0.26, w * 0.74, h * 0.14);
        path.lineTo(w * 0.74, h * 0.04);
        path.close();
        break;

      case BottleShape.squareBottle:
        path.moveTo(w * 0.30, h * 0.04);
        path.lineTo(w * 0.30, h * 0.12);
        path.lineTo(w * 0.08, h * 0.16);
        path.quadraticBezierTo(0, h * 0.18, 0, h * 0.24);
        path.lineTo(0, h * 0.92);
        path.quadraticBezierTo(0, h, w * 0.08, h);
        path.lineTo(w * 0.92, h);
        path.quadraticBezierTo(w, h, w, h * 0.92);
        path.lineTo(w, h * 0.24);
        path.quadraticBezierTo(w, h * 0.18, w * 0.92, h * 0.16);
        path.lineTo(w * 0.70, h * 0.12);
        path.lineTo(w * 0.70, h * 0.04);
        path.close();
        break;

      case BottleShape.roundBottle:
      case BottleShape.bulbFlask:
        path.moveTo(w * 0.34, h * 0.04);
        path.lineTo(w * 0.34, h * 0.30);
        path.quadraticBezierTo(0, h * 0.36, 0, h * 0.68);
        path.arcToPoint(
          Offset(w, h * 0.68),
          radius: Radius.circular(w * 0.5),
          clockwise: false,
        );
        path.quadraticBezierTo(w, h * 0.36, w * 0.66, h * 0.30);
        path.lineTo(w * 0.66, h * 0.04);
        path.close();
        break;

      case BottleShape.triangleBottle:
        path.moveTo(w * 0.35, h * 0.04);
        path.lineTo(w * 0.35, h * 0.14);
        path.lineTo(w * 0.04, h * 0.88);
        path.quadraticBezierTo(0, h, w * 0.12, h);
        path.lineTo(w * 0.88, h);
        path.quadraticBezierTo(w, h, w * 0.96, h * 0.88);
        path.lineTo(w * 0.65, h * 0.14);
        path.lineTo(w * 0.65, h * 0.04);
        path.close();
        break;

      case BottleShape.waveBottle:
        path.moveTo(w * 0.28, h * 0.04);
        path.lineTo(w * 0.28, h * 0.12);
        path.cubicTo(w * 0.02, h * 0.25, w * 0.22, h * 0.42, w * 0.04, h * 0.62);
        path.cubicTo(w * 0.18, h * 0.78, 0, h * 0.90, w * 0.22, h);
        path.lineTo(w * 0.78, h);
        path.cubicTo(w, h * 0.90, w * 0.82, h * 0.78, w * 0.96, h * 0.62);
        path.cubicTo(w * 0.78, h * 0.42, w * 0.98, h * 0.25, w * 0.72, h * 0.12);
        path.lineTo(w * 0.72, h * 0.04);
        path.close();
        break;

      case BottleShape.hexagonBottle:
      case BottleShape.crystal:
        path.moveTo(w * 0.28, h * 0.04);
        path.lineTo(w * 0.28, h * 0.10);
        path.lineTo(0, h * 0.25);
        path.lineTo(w * 0.04, h * 0.80);
        path.lineTo(w * 0.50, h);
        path.lineTo(w * 0.96, h * 0.80);
        path.lineTo(w, h * 0.25);
        path.lineTo(w * 0.72, h * 0.10);
        path.lineTo(w * 0.72, h * 0.04);
        path.close();
        break;

      case BottleShape.heartBottle:
        path.moveTo(w * 0.40, h * 0.04);
        path.lineTo(w * 0.40, h * 0.12);
        path.quadraticBezierTo(w * 0.18, h * 0.10, w * 0.06, h * 0.26);
        path.cubicTo(0, h * 0.45, w * 0.20, h * 0.75, w * 0.50, h);
        path.cubicTo(w * 0.80, h * 0.75, w, h * 0.45, w * 0.94, h * 0.26);
        path.quadraticBezierTo(w * 0.82, h * 0.10, w * 0.60, h * 0.12);
        path.lineTo(w * 0.60, h * 0.04);
        path.close();
        break;

      case BottleShape.starBottle:
        path.moveTo(w * 0.35, h * 0.04);
        path.lineTo(w * 0.35, h * 0.12);
        path.lineTo(w * 0.08, h * 0.28);
        path.lineTo(w * 0.24, h * 0.50);
        path.lineTo(0, h * 0.78);
        path.lineTo(w * 0.36, h * 0.84);
        path.lineTo(w * 0.50, h);
        path.lineTo(w * 0.64, h * 0.84);
        path.lineTo(w, h * 0.78);
        path.lineTo(w * 0.76, h * 0.50);
        path.lineTo(w * 0.92, h * 0.28);
        path.lineTo(w * 0.65, h * 0.12);
        path.lineTo(w * 0.65, h * 0.04);
        path.close();
        break;

      case BottleShape.spiralBottle:
        path.moveTo(w * 0.28, h * 0.04);
        path.lineTo(w * 0.28, h * 0.12);
        path.lineTo(w * 0.08, h * 0.24);
        path.lineTo(w * 0.20, h * 0.38);
        path.lineTo(w * 0.04, h * 0.52);
        path.lineTo(w * 0.18, h * 0.68);
        path.lineTo(0, h * 0.84);
        path.quadraticBezierTo(0, h, w * 0.25, h);
        path.lineTo(w * 0.75, h);
        path.quadraticBezierTo(w, h, w, h * 0.84);
        path.lineTo(w * 0.82, h * 0.68);
        path.lineTo(w * 0.96, h * 0.52);
        path.lineTo(w * 0.80, h * 0.38);
        path.lineTo(w * 0.92, h * 0.24);
        path.lineTo(w * 0.72, h * 0.12);
        path.lineTo(w * 0.72, h * 0.04);
        path.close();
        break;

      case BottleShape.gourdBottle:
      case BottleShape.babyBottle:
        path.moveTo(w * 0.32, h * 0.04);
        path.lineTo(w * 0.32, h * 0.12);
        path.quadraticBezierTo(w * 0.10, h * 0.18, w * 0.14, h * 0.38);
        path.quadraticBezierTo(w * 0.22, h * 0.48, w * 0.04, h * 0.66);
        path.arcToPoint(
          Offset(w * 0.96, h * 0.66),
          radius: Radius.circular(w * 0.48),
          clockwise: false,
        );
        path.quadraticBezierTo(w * 0.78, h * 0.48, w * 0.86, h * 0.38);
        path.quadraticBezierTo(w * 0.90, h * 0.18, w * 0.68, h * 0.12);
        path.lineTo(w * 0.68, h * 0.04);
        path.close();
        break;

      case BottleShape.diamondBottle:
      case BottleShape.diamond:
      case BottleShape.diamondDecanter:
        path.moveTo(w * 0.30, h * 0.04);
        path.lineTo(w * 0.30, h * 0.14);
        path.lineTo(0, h * 0.32);
        path.lineTo(w * 0.24, h);
        path.lineTo(w * 0.76, h);
        path.lineTo(w, h * 0.32);
        path.lineTo(w * 0.70, h * 0.14);
        path.lineTo(w * 0.70, h * 0.04);
        path.close();
        break;

      case BottleShape.ribbedBottle:
        path.moveTo(w * 0.30, h * 0.04);
        path.lineTo(w * 0.30, h * 0.12);
        for (int i = 0; i < 4; i++) {
          final double t0 = 0.12 + i * 0.21;
          final double t1 = t0 + 0.21;
          path.lineTo(0, h * (t0 + 0.05));
          path.lineTo(0, h * (t1 - 0.03));
          path.lineTo(w * 0.08, h * t1);
        }
        path.lineTo(w * 0.92, h);
        for (int i = 3; i >= 0; i--) {
          final double t0 = 0.12 + i * 0.21;
          final double t1 = t0 + 0.21;
          path.lineTo(w * 0.92, h * t1);
          path.lineTo(w, h * (t1 - 0.03));
          path.lineTo(w, h * (t0 + 0.05));
        }
        path.lineTo(w * 0.70, h * 0.12);
        path.lineTo(w * 0.70, h * 0.04);
        path.close();
        break;

      case BottleShape.waveEdgeBottle:
        path.moveTo(w * 0.28, h * 0.04);
        path.lineTo(w * 0.28, h * 0.12);
        path.quadraticBezierTo(0, h * 0.24, w * 0.12, h * 0.36);
        path.quadraticBezierTo(0, h * 0.50, w * 0.12, h * 0.64);
        path.quadraticBezierTo(0, h * 0.78, w * 0.20, h * 0.94);
        path.lineTo(w * 0.80, h * 0.94);
        path.quadraticBezierTo(w, h * 0.78, w * 0.88, h * 0.64);
        path.quadraticBezierTo(w, h * 0.50, w * 0.88, h * 0.36);
        path.quadraticBezierTo(w, h * 0.24, w * 0.72, h * 0.12);
        path.lineTo(w * 0.72, h * 0.04);
        path.close();
        break;

      case BottleShape.potionBottle:
      case BottleShape.potion:
        path.moveTo(w * 0.28, h * 0.04);
        path.lineTo(w * 0.28, h * 0.20);
        path.quadraticBezierTo(0, h * 0.35, 0, h * 0.72);
        path.arcToPoint(
          Offset(w, h * 0.72),
          radius: Radius.circular(w * 0.5),
          clockwise: false,
        );
        path.quadraticBezierTo(w, h * 0.35, w * 0.72, h * 0.20);
        path.lineTo(w * 0.72, h * 0.04);
        path.close();
        break;

      case BottleShape.elegantBottle:
      case BottleShape.champagneFlute:
      case BottleShape.flowerVase:
        path.moveTo(w * 0.25, h * 0.04);
        path.lineTo(w * 0.25, h * 0.32);
        path.quadraticBezierTo(w * 0.06, h * 0.55, w * 0.12, h * 0.88);
        path.quadraticBezierTo(w * 0.16, h, w * 0.30, h);
        path.lineTo(w * 0.70, h);
        path.quadraticBezierTo(w * 0.84, h, w * 0.88, h * 0.88);
        path.quadraticBezierTo(w * 0.94, h * 0.55, w * 0.75, h * 0.32);
        path.lineTo(w * 0.75, h * 0.04);
        path.close();
        break;

      case BottleShape.dropBottle:
        path.moveTo(w * 0.35, h * 0.04);
        path.lineTo(w * 0.35, h * 0.16);
        path.cubicTo(w * 0.25, h * 0.40, 0, h * 0.65, 0, h * 0.82);
        path.arcToPoint(
          Offset(w, h * 0.82),
          radius: Radius.circular(w * 0.5),
          clockwise: false,
        );
        path.cubicTo(w, h * 0.65, w * 0.75, h * 0.40, w * 0.65, h * 0.16);
        path.lineTo(w * 0.65, h * 0.04);
        path.close();
        break;

      case BottleShape.catBottle:
        path.moveTo(w * 0.32, h * 0.04);
        path.lineTo(w * 0.32, h * 0.10);
        // Left cat ear
        path.lineTo(w * 0.12, h * 0.06);
        path.lineTo(w * 0.08, h * 0.20);
        path.quadraticBezierTo(0, h * 0.35, 0, h * 0.75);
        path.arcToPoint(
          Offset(w, h * 0.75),
          radius: Radius.circular(w * 0.5),
          clockwise: false,
        );
        path.quadraticBezierTo(w, h * 0.35, w * 0.92, h * 0.20);
        // Right cat ear
        path.lineTo(w * 0.88, h * 0.06);
        path.lineTo(w * 0.68, h * 0.10);
        path.lineTo(w * 0.68, h * 0.04);
        path.close();
        break;

      case BottleShape.moonBottle:
        path.moveTo(w * 0.40, h * 0.04);
        path.lineTo(w * 0.40, h * 0.12);
        // Outer crescent arc
        path.cubicTo(w * 0.05, h * 0.25, 0, h * 0.65, w * 0.40, h);
        path.lineTo(w * 0.75, h);
        path.cubicTo(w * 0.95, h * 0.80, w, h * 0.40, w * 0.65, h * 0.12);
        path.lineTo(w * 0.65, h * 0.04);
        path.close();
        break;

      case BottleShape.beaker:
        path.moveTo(w * 0.25, h * 0.04);
        path.lineTo(w * 0.25, h * 0.12);
        path.lineTo(0, h * 0.92);
        path.quadraticBezierTo(0, h, w * 0.18, h);
        path.lineTo(w * 0.82, h);
        path.quadraticBezierTo(w, h, w, h * 0.92);
        path.lineTo(w * 0.75, h * 0.12);
        path.lineTo(w * 0.75, h * 0.04);
        path.close();
        break;

      case BottleShape.cocktailGlass:
        path.moveTo(w * 0.08, h * 0.04);
        path.lineTo(w * 0.44, h * 0.60);
        path.lineTo(w * 0.44, h * 0.90);
        path.lineTo(w * 0.20, h);
        path.lineTo(w * 0.80, h);
        path.lineTo(w * 0.56, h * 0.90);
        path.lineTo(w * 0.56, h * 0.60);
        path.lineTo(w * 0.92, h * 0.04);
        path.close();
        break;
    }

    return path;
  }

  /// Returns the inner cavity clipping path where liquids are rendered safely
  Path getCavityPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path cavity = Path();

    // Inset border wall thickness for glass realism
    const double inset = 1.8;
    final double innerW = w - inset * 2;
    final double innerH = h - inset * 2;

    final Matrix4 m = Matrix4.diagonal3Values(innerW / w, innerH / h, 1.0)
      ..setTranslationRaw(inset, inset, 0.0);

    final Path raw = getOuterPath(size);
    cavity.addPath(raw.transform(m.storage), Offset.zero);
    return cavity;
  }

  /// Rect anchor where the bottle cap sits on top of the neck
  Rect getCapAnchor(Size size) {
    final double w = size.width;
    final double h = size.height;

    switch (shape) {
      case BottleShape.classicTube:
      case BottleShape.classic:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.035),
          width: w * 0.70,
          height: 12.0,
        );
      case BottleShape.hexagonBottle:
      case BottleShape.crystal:
      case BottleShape.beaker:
      case BottleShape.conicalFlask:
      case BottleShape.flask:
      case BottleShape.squareBottle:
      case BottleShape.triangleBottle:
      case BottleShape.waveBottle:
      case BottleShape.ribbedBottle:
      case BottleShape.waveEdgeBottle:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.04),
          width: w * 0.60,
          height: 12.0,
        );
      case BottleShape.roundBottle:
      case BottleShape.potionBottle:
      case BottleShape.potion:
      case BottleShape.bulbFlask:
      case BottleShape.heartBottle:
      case BottleShape.starBottle:
      case BottleShape.spiralBottle:
      case BottleShape.catBottle:
      case BottleShape.moonBottle:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.04),
          width: w * 0.55,
          height: 10.0,
        );
      case BottleShape.gourdBottle:
      case BottleShape.babyBottle:
      case BottleShape.curvyBottle:
      case BottleShape.sodaBottle:
      case BottleShape.diamondBottle:
      case BottleShape.diamond:
      case BottleShape.diamondDecanter:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.04),
          width: w * 0.58,
          height: 12.0,
        );
      case BottleShape.elegantBottle:
      case BottleShape.champagneFlute:
      case BottleShape.flowerVase:
      case BottleShape.dropBottle:
      case BottleShape.cocktailGlass:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.04),
          width: w * 0.50,
          height: 10.0,
        );
    }
  }

  /// Top limit of the liquid cavity (just below the neck)
  double getTopCavityY(Size size) {
    switch (shape) {
      case BottleShape.classicTube:
      case BottleShape.classic:
        return size.height * 0.12;
      case BottleShape.hexagonBottle:
      case BottleShape.crystal:
      case BottleShape.diamondBottle:
      case BottleShape.diamond:
      case BottleShape.gourdBottle:
      case BottleShape.babyBottle:
      case BottleShape.squareBottle:
      case BottleShape.triangleBottle:
      case BottleShape.waveBottle:
      case BottleShape.heartBottle:
      case BottleShape.starBottle:
      case BottleShape.spiralBottle:
      case BottleShape.ribbedBottle:
      case BottleShape.waveEdgeBottle:
      case BottleShape.catBottle:
      case BottleShape.moonBottle:
        return size.height * 0.14;
      case BottleShape.conicalFlask:
      case BottleShape.flask:
      case BottleShape.roundBottle:
      case BottleShape.bulbFlask:
      case BottleShape.potionBottle:
      case BottleShape.potion:
        return size.height * 0.20;
      case BottleShape.curvyBottle:
      case BottleShape.sodaBottle:
      case BottleShape.beaker:
      case BottleShape.elegantBottle:
      case BottleShape.champagneFlute:
      case BottleShape.flowerVase:
      case BottleShape.dropBottle:
      case BottleShape.diamondDecanter:
      case BottleShape.cocktailGlass:
        return size.height * 0.16;
    }
  }

  /// Bottom limit of the liquid cavity
  double getBottomY(Size size) {
    return size.height - 2.5;
  }
}

/// ---------------------------------------------------------------------------
/// BOTTLE CAP PAINTER
/// ---------------------------------------------------------------------------

class BottleCapPainter {
  static void paintCap({
    required Canvas canvas,
    required Rect anchor,
    required CapType capType,
    required Color gemColor,
  }) {
    if (capType == CapType.none) return;

    final double cx = anchor.center.dx;
    final double cy = anchor.center.dy;
    final double w = anchor.width;
    final double h = anchor.height;

    switch (capType) {
      case CapType.none:
        break;

      case CapType.classicCork:
        final corkPath = Path()
          ..moveTo(cx - w * 0.42, cy + h * 0.45)
          ..lineTo(cx - w * 0.50, cy - h * 0.55)
          ..quadraticBezierTo(cx, cy - h * 0.70, cx + w * 0.50, cy - h * 0.55)
          ..lineTo(cx + w * 0.42, cy + h * 0.45)
          ..close();

        final corkPaint = Paint()..color = const Color(0xFFC29B38);
        canvas.drawPath(corkPath, corkPaint);

        final stroke = Paint()
          ..color = const Color(0xFF78350F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawPath(corkPath, stroke);
        break;

      case CapType.royalAmethyst:
      case CapType.prismDiamond:
      case CapType.rubyHeart:
      case CapType.imperialEmerald:
      case CapType.flamingAmber:
      case CapType.celestialStar:
        final baseRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - h * 0.2),
            width: w * 0.85,
            height: h * 0.6,
          ),
          const Radius.circular(3),
        );
        final basePaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFF64748B)],
          ).createShader(baseRRect.outerRect);
        canvas.drawRRect(baseRRect, basePaint);

        final gemPaint = Paint()..color = gemColor;
        canvas.drawCircle(Offset(cx, cy - h * 0.5), h * 0.35, gemPaint);
        break;
    }
  }
}

/// ---------------------------------------------------------------------------
/// BUBBLE FX PAINTER
/// ---------------------------------------------------------------------------

class BubbleFxPainter {
  static void paintFx({
    required Canvas canvas,
    required Rect liquidRect,
    required BubbleFxType fxType,
    required double animationValue,
  }) {
    if (fxType == BubbleFxType.none) return;

    final rand = math.Random(fxType.index * 100);
    const int count = 6;
    for (int i = 0; i < count; i++) {
      final double seedX = rand.nextDouble();
      final double seedY = rand.nextDouble();
      final double progress = (seedY + animationValue) % 1.0;

      final double px = liquidRect.left + seedX * liquidRect.width;
      final double py = liquidRect.bottom - progress * liquidRect.height;
      final double r = 1.5 + (rand.nextDouble() * 2.0);

      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35 + rand.nextDouble() * 0.30)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), r, bubblePaint);
    }
  }
}
