import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../theme/app_theme.dart';
import 'bottles_screen.dart';
import 'themes_screen.dart';

enum ShopTab { bottles, themes, hints }

enum CustomizationTab { tubes, caps, bubbleFx, themes, palettes }

class CustomizationScreen extends StatelessWidget {
  final CustomizationTab initialTab;

  const CustomizationScreen({
    super.key,
    this.initialTab = CustomizationTab.tubes,
  });

  @override
  Widget build(BuildContext context) {
    final gameService = GameService.instance;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.radialCanvas),
        child: SafeArea(
          child: Column(
            children: [
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
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.primaryFixed,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customization',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.iceWhite,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Personalize your gameplay',
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          ListenableBuilder(
                            listenable: gameService,
                            builder: (context, _) => Text(
                              _formatCoins(gameService.coins),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCoins(int count) {
    if (count < 1000) return count.toString();
    final s = count.toString();
    final len = s.length;
    final prefix = s.substring(0, len - 3);
    final suffix = s.substring(len - 3);
    return '$prefix,$suffix';
  }
}

class ShopView extends StatefulWidget {
  final ShopTab initialTab;
  final bool showBackButton;

  const ShopView({
    super.key,
    this.initialTab = ShopTab.bottles,
    this.showBackButton = false,
  });

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  late ShopTab _activeTab;
  final GameService _gameService = GameService.instance;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
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
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.showBackButton) ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh.withValues(
                          alpha: 0.70,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD0F7)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF6D28D9),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDD0F7)),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF6D28D9),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.iceWhite,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Bottles & Themes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B5B85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Coins Pill
              ListenableBuilder(
                listenable: _gameService,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDD0F7)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D28D9)
                              .withValues(alpha: 0.08),
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
                  );
                },
              ),
            ],
          ),
        ),

        // Segmented Tab Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDD0F7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    tab: ShopTab.bottles,
                    title: 'Bottles (20)',
                    icon: Icons.science_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentButton(
                    tab: ShopTab.themes,
                    title: 'Themes (20)',
                    icon: Icons.palette_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentButton(
                    tab: ShopTab.hints,
                    title: 'Hints',
                    icon: Icons.lightbulb_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_activeTab) {
              ShopTab.bottles => const BottlesGridView(
                key: ValueKey('shop_bottles_grid'),
              ),
              ShopTab.themes => const ThemesGridView(
                key: ValueKey('shop_themes_grid'),
              ),
              ShopTab.hints => const HintsShopCard(
                key: ValueKey('shop_hints_card'),
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required ShopTab tab,
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = _activeTab == tab;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_activeTab != tab) {
            setState(() => _activeTab = tab);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? const Color(0xFF6D28D9)
                      : const Color(0xFF6B5B85),
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF6D28D9)
                        : const Color(0xFF6B5B85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HintsShopCard extends StatelessWidget {
  const HintsShopCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gameService = GameService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDD0F7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: const Center(
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFD97706),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Puzzle Hints',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF32145A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDD0F7)),
              ),
              child: const Text(
                '🪙 25 Coins per Hint',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stuck on a challenging level? Tap the HINT button in any puzzle to highlight the next valid water pour.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: Color(0xFF6B5B85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fair Play Guarantee: Coins are only deducted when a valid hint move is available and executed. You will never be charged if no move exists.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        color: Color(0xFF32145A),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: gameService,
              builder: (context, _) => Text(
                'Your balance: 🪙 ${gameService.coins} coins',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B5B85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
