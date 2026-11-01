import 'package:flutter/material.dart';

import '../models/bottle_model.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottle_geometry.dart';

class BottlesScreen extends StatefulWidget {
  const BottlesScreen({super.key});

  @override
  State<BottlesScreen> createState() => _BottlesScreenState();
}

class _BottlesScreenState extends State<BottlesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.radialCanvas),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh.withValues(
                          alpha: 0.70,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDDD0F7),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D28D9)
                                .withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.primaryFixed,
                          size: 20,
                        ),
                        tooltip: 'Back to Home',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDD0F7)),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Color(0xFF6D28D9),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bottles',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.iceWhite,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Choose your style',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B5B85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD0F7)),
                      ),
                      child: Text(
                        '${BottleStyle.allBottles.length} Designs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 20 Bottle Designs Grid
              const Expanded(child: BottlesGridView()),
            ],
          ),
        ),
      ),
    );
  }
}

class BottlesGridView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const BottlesGridView({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  void _onBottleTap(BottleStyle bottle) {
    HapticService.instance.selectionClick();
    SoundService.instance.playBottleSelect();
    GameService.instance.selectBottle(bottle.id);
  }

  @override
  Widget build(BuildContext context) {
    final gameService = GameService.instance;

    return ListenableBuilder(
      listenable: gameService,
      builder: (context, _) {
        final currentBottleId = gameService.selectedBottleId;
        final bottles = BottleStyle.allBottles;

        return GridView.builder(
          padding: padding,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemCount: bottles.length,
          itemBuilder: (context, index) {
            final bottle = bottles[index];
            final isSelected =
                bottle.id == currentBottleId ||
                (bottle.id == 'classic_tube' &&
                    currentBottleId == 'classic_flask');

            return BottleCard(
              bottle: bottle,
              isSelected: isSelected,
              onTap: () => _onBottleTap(bottle),
            );
          },
        );
      },
    );
  }
}

class BottleCard extends StatelessWidget {
  final BottleStyle bottle;
  final bool isSelected;
  final VoidCallback onTap;

  const BottleCard({
    super.key,
    required this.bottle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        highlightColor: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFFAF7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFFE2D9F3),
              width: isSelected ? 2.2 : 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottle preview
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: CustomPaint(
                      size: const Size(44, 90),
                      painter: BottlePreviewPainter(
                        shape: bottle.shape,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  bottle.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF4C1D95)
                        : const Color(0xFF1E1B4B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  bottle.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B5B85),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action badge / button
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFFEDE5FF),
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0xFFDDD0F7)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isSelected ? 'EQUIPPED' : 'EQUIP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6D28D9),
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
}

class BottlePreviewPainter extends CustomPainter {
  final BottleShape shape;
  final bool isSelected;

  static const List<Color> _liquidColors = [
    Color(0xFF38BDF8), // sky blue
    Color(0xFF818CF8), // indigo
    Color(0xFFA855F7), // purple
    Color(0xFFEC4899), // pink
  ];

  const BottlePreviewPainter({required this.shape, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final geometry = BottleGeometry(shape);
    final Path outerPath = geometry.getOuterPath(size);
    final Path cavityPath = geometry.getCavityPath(size);

    // 1. Soft glass background tint
    final Paint glassFill = Paint()
      ..color = Colors.white.withValues(alpha: isSelected ? 0.40 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, glassFill);

    // 2. Liquid layers clipped strictly inside cavityPath
    canvas.save();
    canvas.clipPath(cavityPath);

    final double topY = geometry.getTopCavityY(size);
    final double bottomY = geometry.getBottomY(size);
    final double cavityHeight = (bottomY - topY).clamp(10.0, h);
    final int layerCount = _liquidColors.length;
    final double layerH = cavityHeight / layerCount;

    for (int i = 0; i < layerCount; i++) {
      final double lTop = bottomY - (i + 1) * layerH;
      final double lBottom = bottomY - i * layerH;
      final Rect layerRect = Rect.fromLTRB(0, lTop, w, lBottom);

      final Paint liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_liquidColors[i].withValues(alpha: 0.95), _liquidColors[i]],
        ).createShader(layerRect);

      canvas.drawRect(layerRect, liquidPaint);

      // Top meniscus curve of liquid layer
      final Path meniscus = Path();
      meniscus.moveTo(0, lTop);
      meniscus.quadraticBezierTo(w * 0.5, lTop + 2.0, w, lTop);
      meniscus.lineTo(w, lTop + 1.0);
      meniscus.quadraticBezierTo(w * 0.5, lTop + 3.0, 0, lTop + 1.0);
      meniscus.close();
      final Paint meniscusPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawPath(meniscus, meniscusPaint);
    }
    canvas.restore();

    // 3. Inner glass highlights (specular reflection on left edge)
    canvas.save();
    canvas.clipPath(outerPath);
    final Path specPath = Path();
    specPath.moveTo(w * 0.16, topY + 2.0);
    specPath.lineTo(w * 0.16, bottomY - 6.0);
    final Paint specPaint = Paint()
      ..color = Colors.white.withValues(alpha: isSelected ? 0.70 : 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(specPath, specPaint);
    canvas.restore();

    // 4. Cartoon Glass Outline
    final Paint outlinePaint = Paint()
      ..color = isSelected ? const Color(0xFF6D28D9) : const Color(0xFF1E1B4B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.6 : 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outerPath, outlinePaint);

    // 5. Lip / rim accent at top
    final double lipH = (h * 0.05).clamp(3.0, 6.0);
    final double lipW = w * 0.80;
    final RRect lipRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, lipH / 2),
        width: lipW,
        height: lipH,
      ),
      const Radius.circular(2.5),
    );
    final Paint lipPaint = Paint()
      ..color = isSelected ? const Color(0xFF7C3AED) : const Color(0xFF2E1065)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lipRRect, lipPaint);
  }

  @override
  bool shouldRepaint(covariant BottlePreviewPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.isSelected != isSelected;
  }
}
