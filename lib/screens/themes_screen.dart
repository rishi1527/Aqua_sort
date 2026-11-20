import 'package:flutter/material.dart';

import '../models/theme_model.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/sound_service.dart';

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF261042)
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.4),
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
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.palette_rounded,
                              color: Color(0xFFC084FC),
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
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                Text(
                                  'Customize your world',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFBCA7E8),
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
                        color: const Color(0xFF261042).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
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
                              color: Color(0xFFFDE68A),
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

  Future<void> _handleThemeTap(
    BuildContext context,
    GameTheme theme,
    bool isSelected,
    bool isOwned,
    int price,
  ) async {
    final gameService = GameService.instance;
    if (isOwned) {
      if (isSelected) return;
      gameService.selectTheme(theme.id);
      SoundService.instance.playBottlePop();
      HapticService.instance.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipped "${theme.name}" theme!'),
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

      final success = await gameService.purchaseTheme(theme.id);
      if (!context.mounted) return;
      if (success) {
        SoundService.instance.playBottlePop();
        HapticService.instance.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlocked "${theme.name}" theme! Tap to equip.'),
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

  Future<void> _handleWatchAd(BuildContext context, GameTheme theme) async {
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

    final success = await GameService.instance.unlockThemeWithAd(theme.id);
    if (!context.mounted) return;
    if (success) {
      SoundService.instance.playBottlePop();
      HapticService.instance.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unlocked "${theme.name}" theme! Tap to equip.'),
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
            childAspectRatio: 0.68,
          ),
          itemCount: GameTheme.allThemes.length,
          itemBuilder: (context, index) {
            final theme = GameTheme.allThemes[index];
            final bool isSelected = gameService.selectedThemeId == theme.id;
            final bool isOwned = gameService.isThemeOwned(theme.id);
            final int price = gameService.getThemePrice(theme.id);
            return ThemeCard(
              theme: theme,
              isSelected: isSelected,
              isOwned: isOwned,
              price: price,
              onTap: () =>
                  _handleThemeTap(context, theme, isSelected, isOwned, price),
              onWatchAd: () => _handleWatchAd(context, theme),
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
  final bool isOwned;
  final int price;
  final VoidCallback onTap;
  final VoidCallback? onWatchAd;

  const ThemeCard({
    super.key,
    required this.theme,
    required this.isSelected,
    this.isOwned = true,
    this.price = 200,
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
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview Frame
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0317).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFA855F7).withValues(alpha: 0.6)
                            : const Color(0xFF6D28D9).withValues(alpha: 0.3),
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
                                    color: const Color(0xFF1A0A2C),
                                    child: const Center(
                                      child: Icon(
                                        Icons.palette_outlined,
                                        color: Color(0xFF8B5CF6),
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
                          // Locked Icon Badge (Top Left)
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
                          // Selected Checkmark Badge (Top Right)
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF8B5CF6),
                                    ],
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
                    color: Color(0xFFF3E8FF),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Action Status Badge
                _buildActionBadge(
                  isSelected: isSelected,
                  isOwned: isOwned,
                  price: price,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge({
    required bool isSelected,
    required bool isOwned,
    required int price,
  }) {
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
