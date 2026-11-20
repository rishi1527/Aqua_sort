import 'package:flutter/material.dart';

import '../models/bottle_model.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/sound_service.dart';
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
      backgroundColor: const Color(0xFF0F041C),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
            colors: [Color(0xFF260D42), Color(0xFF150527), Color(0xFF0A0213)],
          ),
        ),
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
                        color: const Color(0xFF261042).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
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
                          color: Color(0xFFE9D5FF),
                          size: 20,
                        ),
                        tooltip: 'Back to Home',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D124E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Color(0xFFC084FC),
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
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Choose your style',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBCA7E8),
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
                        color: const Color(0xFF261042).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${BottleStyle.allBottles.length} Designs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC084FC),
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

  Future<void> _onBottleTap(
    BuildContext context,
    BottleStyle bottle,
    bool isSelected,
    bool isOwned,
    int price,
  ) async {
    final gameService = GameService.instance;
    if (isOwned) {
      if (isSelected) return;
      HapticService.instance.selectionClick();
      SoundService.instance.playBottleSelect();
      gameService.selectBottle(bottle.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipped "${bottle.name}" bottle!'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF6D28D9),
        ),
      );
    } else {
      if (gameService.coins < price) {
        HapticService.instance.invalidMove();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough coins! (Costs $price coins)'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }

      final success = await gameService.purchaseBottleSkin(bottle.id);
      if (!context.mounted) return;
      if (success) {
        SoundService.instance.playBottlePop();
        HapticService.instance.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlocked "${bottle.name}" bottle! Tap to equip.'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase could not be completed.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _onWatchAd(BuildContext context, BottleStyle bottle) async {
    final adService = RewardedAdService.instance;
    if (!adService.isAdAvailable) {
      HapticService.instance.invalidMove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ads are currently unavailable.'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF6B7280),
        ),
      );
      return;
    }

    final success = await GameService.instance.unlockBottleSkinWithAd(
      bottle.id,
    );
    if (!context.mounted) return;
    if (success) {
      SoundService.instance.playBottlePop();
      HapticService.instance.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unlocked "${bottle.name}" bottle! Tap to equip.'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad reward could not be completed.'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
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
            childAspectRatio: 0.65,
          ),
          itemCount: bottles.length,
          itemBuilder: (context, index) {
            final bottle = bottles[index];
            final isSelected =
                bottle.id == currentBottleId ||
                (bottle.id == 'classic_tube' &&
                    currentBottleId == 'classic_flask');
            final bool isOwned = gameService.isBottleOwned(bottle.id);
            final int price = gameService.getBottlePrice(bottle.id);

            return BottleCard(
              bottle: bottle,
              isSelected: isSelected,
              isOwned: isOwned,
              price: price,
              onTap: () =>
                  _onBottleTap(context, bottle, isSelected, isOwned, price),
              onWatchAd: () => _onWatchAd(context, bottle),
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
  final bool isOwned;
  final int price;
  final VoidCallback onTap;
  final VoidCallback? onWatchAd;

  const BottleCard({
    super.key,
    required this.bottle,
    required this.isSelected,
    this.isOwned = true,
    this.price = 150,
    required this.onTap,
    this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOwned ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        highlightColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E124D), Color(0xFF1B0833)],
                  )
                : isOwned
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1F0D36), Color(0xFF140724)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0A2C), Color(0xFF10051C)],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFA855F7)
                  : isOwned
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                  : const Color(0xFF4C1D95).withValues(alpha: 0.45),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottle preview
              Expanded(
                child: Stack(
                  children: [
                    if (isSelected)
                      Center(
                        child: Container(
                          width: 52,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.3),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Center(
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
                    if (!isOwned)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F041C)
                                .withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFA78BFA)
                                  .withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFFE9D5FF),
                            size: 13,
                          ),
                        ),
                      ),
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  bottle.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF3E8FF),
                    letterSpacing: 0.3,
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
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    color: Color(0xFFBCA7E8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action badge / buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: _buildActionButtons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (!isOwned) {
      final bool isAdAvailable = RewardedAdService.instance.isAdAvailable;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Buy with Coins button
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B240B), Color(0xFF261605)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙 ', style: TextStyle(fontSize: 10)),
                    Text(
                      'BUY WITH COINS ($price)',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDE68A),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 2. Watch Ad to Unlock button
          GestureDetector(
            onTap: isAdAvailable ? onWatchAd : null,
            child: Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isAdAvailable
                    ? const LinearGradient(
                        colors: [Color(0xFF2E124D), Color(0xFF1D0A34)],
                      )
                    : null,
                color: isAdAvailable
                    ? null
                    : const Color(0xFF1B1128).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAdAvailable
                      ? const Color(0xFFA855F7).withValues(alpha: 0.7)
                      : const Color(0xFF4C3866).withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: isAdAvailable
                    ? [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAdAvailable
                          ? Icons.play_circle_fill_rounded
                          : Icons.videocam_off_outlined,
                      size: 11,
                      color: isAdAvailable
                          ? const Color(0xFFC084FC)
                          : const Color(0xFF7E6E99),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAdAvailable ? 'WATCH AD TO UNLOCK' : 'Ads unavailable',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isAdAvailable
                            ? const Color(0xFFF3E8FF)
                            : const Color(0xFF9E8DBA),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (isSelected) {
      return Container(
        height: 26,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC084FC).withValues(alpha: 0.7),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'EQUIPPED',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF261042),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'EQUIP',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE9D5FF),
          letterSpacing: 0.6,
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
