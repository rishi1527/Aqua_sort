import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/theme_model.dart';
import '../services/game_service.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
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

  void _onThemeTap(GameTheme theme, bool isUnlocked, bool isSelected) {
    if (isSelected) return;

    if (isUnlocked) {
      _gameService.selectTheme(theme.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to "${theme.name}" theme'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } else {
      if (theme.isAdReward) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F243E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.glassBorder),
            ),
            title: Row(
              children: [
                Icon(Icons.video_library_rounded, color: theme.accentColor),
                const SizedBox(width: 10),
                const Text(
                  'Rewarded Video',
                  style: TextStyle(color: AppTheme.iceWhite, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'No rewarded ad provider is configured in this build. Continue playing to unlock themes through level progression!',
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
            content: Text('Reach Level ${theme.requiredLevel} to unlock "${theme.name}"!'),
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
                        color: const Color(0xFF9D4EDD).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF9D4EDD).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.palette_rounded,
                        color: Color(0xFFC77DFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Themes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.iceWhite,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Customize your world',
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

              // Themes Grid
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: GameTheme.allThemes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final theme = GameTheme.allThemes[index];
                    final isUnlocked = _gameService.unlockedThemeIds.contains(theme.id);
                    final isSelected = _gameService.selectedThemeId == theme.id;

                    return _buildThemeCard(theme, isUnlocked, isSelected);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(GameTheme theme, bool isUnlocked, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onThemeTap(theme, isUnlocked, isSelected),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1F38).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? theme.accentColor
                  : isUnlocked
                      ? AppTheme.glassBorder
                      : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Visual Theme Preview Box
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.backgroundColors,
                  ),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 10,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title, Subtitle and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            color: AppTheme.iceWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (theme.isFree) ...[
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
                      theme.description,
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
                            theme.isAdReward
                                ? Icons.video_library_rounded
                                : Icons.lock_outline_rounded,
                            size: 13,
                            color: const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            theme.isAdReward
                                ? 'Watch Ad to Unlock'
                                : 'Unlocks at Level ${theme.requiredLevel}',
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

              // Selection Action Indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.accentColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: theme.accentColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: theme.accentColor,
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
                    'USE',
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
