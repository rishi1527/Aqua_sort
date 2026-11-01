import 'package:flutter/material.dart';

import '../models/theme_model.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

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

  String _formatCoins(int count) {
    if (count < 1000) return count.toString();
    final s = count.toString();
    final len = s.length;
    final prefix = s.substring(0, len - 3);
    final suffix = s.substring(len - 3);
    return '$prefix,$suffix';
  }

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                              border: Border.all(
                                color: const Color(0xFFDDD0F7),
                              ),
                            ),
                            child: const Icon(
                              Icons.palette_rounded,
                              color: Color(0xFF6D28D9),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B5B85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Coins Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh.withValues(
                          alpha: 0.70,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDD0F7)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D28D9)
                                .withValues(alpha: 0.06),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            _formatCoins(_gameService.coins),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF32145A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              const Expanded(child: ThemesGridView()),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemesGridView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const ThemesGridView({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 20),
  });

  void _handleThemeTap(BuildContext context, GameTheme theme, bool isSelected) {
    if (isSelected) return;

    GameService.instance.selectTheme(theme.id);
    SoundService.instance.playBottlePop();
    HapticService.instance.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Equipped "${theme.name}" theme!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF6D28D9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameService = GameService.instance;

    return ListenableBuilder(
      listenable: gameService,
      builder: (context, _) {
        if (GameTheme.allThemes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE5FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDDD0F7)),
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: Color(0xFF6D28D9),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Themes Available',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32145A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New themes will appear here when added.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B5B85)),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: padding,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: GameTheme.allThemes.length,
          itemBuilder: (context, index) {
            final theme = GameTheme.allThemes[index];
            final bool isSelected = gameService.selectedThemeId == theme.id;
            return ThemeCard(
              theme: theme,
              isSelected: isSelected,
              onTap: () => _handleThemeTap(context, theme, isSelected),
            );
          },
        );
      },
    );
  }
}

class ThemeCard extends StatelessWidget {
  final GameTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeCard({
    super.key,
    required this.theme,
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6D28D9)
                  : const Color(0xFFDDD0F7),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview Frame
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFDDD0F7).withValues(alpha: 0.6),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (theme.assetPath.isNotEmpty)
                            Image.asset(
                              theme.assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFEDE5FF),
                                    child: const Center(
                                      child: Icon(
                                        Icons.palette_outlined,
                                        color: Color(0xFF6D28D9),
                                      ),
                                    ),
                                  ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: theme.backgroundColors,
                                ),
                              ),
                            ),
                          // Selected Checkmark Badge (Top Right)
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
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
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  theme.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32145A),
                  ),
                ),
                const SizedBox(height: 6),
                // Action Status Badge
                _buildActionBadge(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge({required bool isSelected}) {
    if (isSelected) {
      return Container(
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE5FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDD0F7)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'EQUIPPED',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6D28D9),
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF6D28D9),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'EQUIP',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
