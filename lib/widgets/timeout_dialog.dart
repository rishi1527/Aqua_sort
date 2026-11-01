import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';

/// Dark glass timeout dialog shown when level countdown reaches 00:00.
class TimeoutDialog extends StatefulWidget {
  final int level;
  final int rewardsUsed;
  final int maxRewards;
  final Future<bool> Function() onClaimExtraTime;
  final VoidCallback onRetry;
  final VoidCallback onReturnToMap;

  const TimeoutDialog({
    super.key,
    required this.level,
    required this.rewardsUsed,
    this.maxRewards = 2,
    required this.onClaimExtraTime,
    required this.onRetry,
    required this.onReturnToMap,
  });

  @override
  State<TimeoutDialog> createState() => _TimeoutDialogState();
}

class _TimeoutDialogState extends State<TimeoutDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isClaiming = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleClaimExtraTime() async {
    if (_isClaiming || widget.rewardsUsed >= widget.maxRewards) return;

    setState(() {
      _isClaiming = true;
      _statusMessage = null;
    });

    SoundService.instance.playButtonTap();
    final bool success = await widget.onClaimExtraTime();

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isClaiming = false;
        _statusMessage = 'Extra time unavailable right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canClaimReward = widget.rewardsUsed < widget.maxRewards;

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Softly blurred & dimmed backdrop
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                child: Container(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ),
          ),

          // 2. Animated Dialog Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF28114B), Color(0xFF16082C)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.6),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48)
                                .withValues(alpha: 0.25),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glowing Hourglass Icon Badge
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFB7185), Color(0xFFBE123C)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.hourglass_bottom_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          const Text(
                            "TIME'S UP!",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            'Ran out of time on Level ${widget.level}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFDDD0F7),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Extra Time Button (Rewarded Ad)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: canClaimReward && !_isClaiming
                                  ? _handleClaimExtraTime
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: canClaimReward
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF059669),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.shade700,
                                            Colors.grey.shade800,
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: canClaimReward
                                        ? const Color(0xFF34D399)
                                        : Colors.grey.shade600,
                                    width: 1.5,
                                  ),
                                  boxShadow: canClaimReward
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: _isClaiming
                                    ? const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            canClaimReward
                                                ? Icons.more_time_rounded
                                                : Icons.lock_clock_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              canClaimReward
                                                  ? '+60s Extra Time (${widget.rewardsUsed}/${widget.maxRewards})'
                                                  : 'Extra-time limit reached (${widget.maxRewards}/${widget.maxRewards})',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: canClaimReward
                                                    ? Colors.white
                                                    : Colors.white70,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          // Status message if claim fails
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Color(0xFFFB7185),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Retry Level Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onRetry,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF5B21B6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFA78BFA),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Retry Level',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Return to Map Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onReturnToMap,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      color: Color(0xFFDDD0F7),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Return to Map',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDDD0F7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
