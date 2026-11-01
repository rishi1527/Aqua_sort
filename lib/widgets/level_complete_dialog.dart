import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Premium level-completion celebration dialog for AquaSort.
class LevelCompleteDialog extends StatefulWidget {
  final int level;
  final int moves;
  final int stars; // 1, 2, or 3
  final int? bestStars;
  final int streak;
  final int maxLevel;
  final VoidCallback onNextLevel;
  final VoidCallback onPlayAgain;

  const LevelCompleteDialog({
    super.key,
    required this.level,
    required this.moves,
    required this.stars,
    this.bestStars,
    required this.streak,
    this.maxLevel = 100,
    required this.onNextLevel,
    required this.onPlayAgain,
  });

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleNextLevel() {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    widget.onNextLevel();
  }

  void _handlePlayAgain() {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    widget.onPlayAgain();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMaxLevel = widget.level >= widget.maxLevel;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Softly blurred & dimmed background overlay
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                child: Container(color: const Color(0x6632145A)),
              ),
            ),
          ),

          // 2. Main celebration dialog
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: reduceMotion
                    ? _buildDialogCard(context, isMaxLevel)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildDialogCard(context, isMaxLevel),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogCard(BuildContext context, bool isMaxLevel) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F3FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outline, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Staggered Star Rating Banner
          _buildStarsRow(),
          const SizedBox(height: 14),

          // Prominent Success Heading
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF32145A), Color(0xFF6D28D9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: const Text(
              'LEVEL COMPLETE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Short positive subtitle
          const Text(
            'Brilliant sorting! Ready for the next challenge?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B5B85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Best Stars Record Indicator (if available)
          _buildBestStarsIndicator(),
          const SizedBox(height: 8),

          // Level Rewards & Progress Stat Cards
          _buildStatsRow(),
          const SizedBox(height: 22),

          // Primary Button: "NEXT LEVEL" (or "JOURNEY COMPLETE")
          _buildPrimaryButton(isMaxLevel),
          const SizedBox(height: 10),

          // Secondary Button: "PLAY AGAIN"
          _buildSecondaryButton(),
        ],
      ),
    );
  }

  Widget _buildBestStarsIndicator() {
    final int? best = widget.bestStars;
    if (best == null || best <= 0) return const SizedBox.shrink();

    final bool isLower = widget.stars < best;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isLower
            ? const Color(0xFF6D28D9).withValues(alpha: 0.08)
            : const Color(0xFFFFBE0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLower
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
              : const Color(0xFFFFB703).withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLower ? Icons.shield_rounded : Icons.workspace_premium_rounded,
              size: 15,
              color: isLower
                  ? const Color(0xFF6D28D9)
                  : const Color(0xFFD97706),
            ),
            const SizedBox(width: 5),
            Text(
              isLower
                  ? 'Best: $best ★  (Current: ${widget.stars} ★)'
                  : 'Best: $best ★',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isLower
                    ? const Color(0xFF5B21B6)
                    : const Color(0xFF92400E),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarsRow() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final double t = _animController.value;
        // Staggered star pop progress
        final double s1 = ((t - 0.15) / 0.35).clamp(0.0, 1.0);
        final double s2 = ((t - 0.28) / 0.35).clamp(0.0, 1.0);
        final double s3 = ((t - 0.40) / 0.35).clamp(0.0, 1.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStarItem(
              index: 1,
              earned: widget.stars >= 1,
              scaleProgress: s1,
              size: 36,
              tiltAngle: -0.16,
            ),
            const SizedBox(width: 8),
            _buildStarItem(
              index: 2,
              earned: widget.stars >= 2,
              scaleProgress: s2,
              size: 48,
              tiltAngle: 0.0,
            ),
            const SizedBox(width: 8),
            _buildStarItem(
              index: 3,
              earned: widget.stars >= 3,
              scaleProgress: s3,
              size: 36,
              tiltAngle: 0.16,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStarItem({
    required int index,
    required bool earned,
    required double scaleProgress,
    required double size,
    required double tiltAngle,
  }) {
    final double scale = earned
        ? 0.3 + Curves.easeOutBack.transform(scaleProgress) * 0.7
        : 1.0;

    return Transform.rotate(
      angle: tiltAngle,
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: earned
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          child: Icon(
            earned ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: earned ? const Color(0xFFFFBE0B) : const Color(0xFFDDD0F7),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final String efficiencyLabel = widget.moves <= 14
        ? 'Optimal'
        : (widget.moves <= 22 ? 'Great' : 'Cleared');

    return Row(
      children: [
        // 1. Level Stat Card
        Expanded(
          child: _buildStatCard(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF6D28D9),
            label: 'LEVEL',
            value: '${widget.level}',
            subLabel: 'Completed',
          ),
        ),
        const SizedBox(width: 8),

        // 2. Moves Stat Card
        Expanded(
          child: _buildStatCard(
            icon: Icons.swap_horiz_rounded,
            iconColor: const Color(0xFFA78BFA),
            label: 'MOVES',
            value: '${widget.moves}',
            subLabel: efficiencyLabel,
          ),
        ),
        const SizedBox(width: 8),

        // 3. Streak Stat Card
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFFB703),
            label: 'STREAK',
            value: '${widget.streak > 0 ? widget.streak : 1}x',
            subLabel: 'Win Streak',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD0F7), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF6B5B85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF32145A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: iconColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isMaxLevel) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B21B6).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isTransitioning ? null : _handleNextLevel,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isMaxLevel ? 'JOURNEY COMPLETE' : 'NEXT LEVEL',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isMaxLevel
                      ? Icons.emoji_events_rounded
                      : Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: _isTransitioning ? null : _handlePlayAgain,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.outline, width: 1.2),
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: AppTheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.replay_rounded, size: 17, color: Color(0xFF6B5B85)),
            SizedBox(width: 6),
            Text(
              'PLAY AGAIN',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF6B5B85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
