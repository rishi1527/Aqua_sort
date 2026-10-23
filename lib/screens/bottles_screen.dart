import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bottle_model.dart';
import '../services/game_service.dart';

class BottlesScreen extends StatefulWidget {
  const BottlesScreen({super.key});

  @override
  State<BottlesScreen> createState() => _BottlesScreenState();
}

class _BottlesScreenState extends State<BottlesScreen> {
  final GameService _gameService = GameService.instance;

  @override
  void initState() {
    super.initState();
    _gameService.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _gameService.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _onBottleTap(BottleStyle bottle, bool isUnlocked, bool isSelected) {
    if (isSelected) return;

    if (isUnlocked) {
      _gameService.selectBottle(bottle.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipped "${bottle.name}" bottle style'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } else {
      if (bottle.isAdReward) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F243E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.glassBorder),
            ),
            title: const Row(
              children: [
                Icon(Icons.video_library_rounded, color: AppTheme.aquaGlow),
                SizedBox(width: 10),
                Text(
                  'Rewarded Video',
                  style: TextStyle(color: AppTheme.iceWhite, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'No rewarded ad provider is configured in this build. Continue playing to unlock bottles through level milestones!',
              style: TextStyle(color: AppTheme.iceWhite.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppTheme.aquaGlow)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reach Level ${bottle.requiredLevel} to unlock "${bottle.name}"!'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _gameService.currentTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: activeTheme.backgroundColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.iceWhite,
                        size: 20,
                      ),
                      tooltip: 'Back to Home',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Color(0xFF00E676),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
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
                            color: Color(0x99EAF7FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottles List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: BottleStyle.allBottles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final bottle = BottleStyle.allBottles[index];
                    final isUnlocked = _gameService.unlockedBottleIds.contains(bottle.id);
                    final isSelected = _gameService.selectedBottleId == bottle.id;

                    return _buildBottleCard(bottle, isUnlocked, isSelected);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottleCard(BottleStyle bottle, bool isUnlocked, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onBottleTap(bottle, isUnlocked, isSelected),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1F38).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppTheme.aquaGlow
                  : isUnlocked
                      ? AppTheme.glassBorder
                      : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.aquaGlow.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Custom Painted Mini Bottle Preview
              Container(
                width: 60,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF071426),
                  border: Border.all(
                    color: isSelected ? AppTheme.aquaGlow : AppTheme.glassBorder,
                  ),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(26, 52),
                    painter: _MiniBottlePainter(shape: bottle.shape, isSelected: isSelected),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bottle.name,
                          style: const TextStyle(
                            color: AppTheme.iceWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (bottle.isFree) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.aquaGlow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: AppTheme.aquaGlow,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bottle.description,
                      style: const TextStyle(
                        color: Color(0x99EAF7FF),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (!isUnlocked)
                      Row(
                        children: [
                          Icon(
                            bottle.isAdReward
                                ? Icons.video_library_rounded
                                : Icons.lock_outline_rounded,
                            size: 13,
                            color: const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            bottle.isAdReward
                                ? 'Watch Ad to Unlock'
                                : 'Unlocks at Level ${bottle.requiredLevel}',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action button/badge
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.aquaGlow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.aquaGlow),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: AppTheme.aquaGlow, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'EQUIPPED',
                        style: TextStyle(
                          color: AppTheme.aquaGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Text(
                    'EQUIP',
                    style: TextStyle(
                      color: AppTheme.iceWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBottlePainter extends CustomPainter {
  final BottleShape shape;
  final bool isSelected;

  _MiniBottlePainter({required this.shape, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path path = Path();
    if (shape == BottleShape.crystal) {
      // Hexagonal / faceted angles
      path.moveTo(w * 0.2, 0);
      path.lineTo(w * 0.8, 0);
      path.lineTo(w, h * 0.25);
      path.lineTo(w * 0.9, h * 0.85);
      path.lineTo(w * 0.5, h);
      path.lineTo(w * 0.1, h * 0.85);
      path.lineTo(0, h * 0.25);
      path.close();
    } else if (shape == BottleShape.potion) {
      // Bulbous potion flask
      path.moveTo(w * 0.35, 0);
      path.lineTo(w * 0.65, 0);
      path.lineTo(w * 0.65, h * 0.35);
      path.quadraticBezierTo(w, h * 0.45, w, h * 0.75);
      path.arcToPoint(Offset(0, h * 0.75), radius: Radius.circular(w * 0.5), clockwise: true);
      path.quadraticBezierTo(0, h * 0.45, w * 0.35, h * 0.35);
      path.close();
    } else if (shape == BottleShape.beaker) {
      // Flared laboratory beaker
      path.moveTo(w * 0.25, 0);
      path.lineTo(w * 0.75, 0);
      path.lineTo(w * 0.85, h * 0.85);
      path.arcToPoint(Offset(w * 0.15, h * 0.85), radius: Radius.circular(w * 0.4), clockwise: true);
      path.close();
    } else if (shape == BottleShape.diamond) {
      // Diamond cut
      path.moveTo(w * 0.5, 0);
      path.lineTo(w, h * 0.35);
      path.lineTo(w * 0.75, h);
      path.lineTo(w * 0.25, h);
      path.lineTo(0, h * 0.35);
      path.close();
    } else {
      // Classic flask
      path.moveTo(w * 0.25, 0);
      path.lineTo(w * 0.75, 0);
      path.lineTo(w * 0.75, h * 0.2);
      path.lineTo(w, h * 0.25);
      path.lineTo(w, h * 0.75);
      path.arcToPoint(Offset(0, h * 0.75), radius: Radius.circular(w * 0.5), clockwise: true);
      path.lineTo(0, h * 0.25);
      path.lineTo(w * 0.25, h * 0.2);
      path.close();
    }

    // Clip to path and draw colored water
    canvas.save();
    canvas.clipPath(path);

    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFF9D4EDD),
      const Color(0xFFFF9100),
      const Color(0xFF00E676),
    ];

    final double layerH = h / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      canvas.drawRect(Rect.fromLTWH(0, h - (i + 1) * layerH, w, layerH), paint);
    }

    // Highlight sheen
    final sheenPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.3, h), sheenPaint);

    canvas.restore();

    // Outline
    final outlinePaint = Paint()
      ..color = isSelected ? AppTheme.aquaGlow : Colors.white60
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniBottlePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.isSelected != isSelected;
}
