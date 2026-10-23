import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/theme_model.dart';
import '../models/bottle_model.dart';
import '../services/game_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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

  String _getPlayerRank(int level) {
    if (level < 3) return 'Novice Sorter';
    if (level < 7) return 'Liquid Alchemist';
    if (level < 12) return 'Aqua Sorcerer';
    if (level < 20) return 'Fluid Maestro';
    return 'Grand Hydromancer';
  }

  int _calculateTotalStars() {
    int total = 0;
    for (final level in _gameService.completedLevels) {
      final stars = _gameService.getStarsForLevel(level);
      total += (stars == 0 ? 3 : stars);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _gameService.currentTheme;
    final totalStars = _calculateTotalStars();
    final rank = _getPlayerRank(_gameService.currentLevel);

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
                        color: const Color(0xFFFFB703).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFFFFB703),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.iceWhite,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Your game record',
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

              // Scrollable Stats Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Rank & Progression Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F325E),
                            Color(0xFF0A2242),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.aquaGlow.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.aquaGlow.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB703).withValues(alpha: 0.3),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rank,
                                  style: const TextStyle(
                                    color: AppTheme.iceWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Level ${_gameService.currentLevel} Explorer',
                                  style: const TextStyle(
                                    color: AppTheme.aquaGlow,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalStars Stars Earned',
                                      style: TextStyle(
                                        color: AppTheme.iceWhite.withValues(alpha: 0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Grid of 4 Core Stats
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.35,
                      children: [
                        _buildStatBox(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Completed',
                          value: '${_gameService.completedLevelsCount}',
                          color: const Color(0xFF00E676),
                        ),
                        _buildStatBox(
                          icon: Icons.swap_vert_rounded,
                          label: 'Total Moves',
                          value: '${_gameService.totalMoves}',
                          color: AppTheme.aquaGlow,
                        ),
                        _buildStatBox(
                          icon: Icons.whatshot_rounded,
                          label: 'Best Streak',
                          value: '${_gameService.bestStreak}',
                          color: const Color(0xFFFF7A00),
                        ),
                        _buildStatBox(
                          icon: Icons.games_rounded,
                          label: 'Games Played',
                          value: '${_gameService.gamesPlayed}',
                          color: const Color(0xFFA78BFA),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Collections Summary
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1F38).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collection Unlocked',
                            style: TextStyle(
                              color: AppTheme.iceWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildCollectionProgress(
                            label: 'Visual Themes',
                            current: _gameService.unlockedThemeIds.length,
                            total: GameTheme.allThemes.length,
                            color: const Color(0xFF9D4EDD),
                          ),
                          const SizedBox(height: 12),
                          _buildCollectionProgress(
                            label: 'Bottle Styles',
                            current: _gameService.unlockedBottleIds.length,
                            total: BottleStyle.allBottles.length,
                            color: AppTheme.aquaGlow,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F38).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0x99EAF7FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.iceWhite,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionProgress({
    required String label,
    required int current,
    required int total,
    required Color color,
  }) {
    final double ratio = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.iceWhite.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$current / $total',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
