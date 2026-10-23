import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/game_service.dart';
import '../widgets/animated_bottles_widget.dart';
import '../main.dart';
import 'themes_screen.dart';
import 'journey_screen.dart';
import 'bottles_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _onPlayPressed() {
    _gameService.recordGameStarted();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaterSortScreen(initialLevel: _gameService.currentLevel),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1B30),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppTheme.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle pill
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings_rounded, color: AppTheme.aquaGlow, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Game Settings',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.iceWhite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.aquaGlow),
                      title: const Text(
                        'Sound Effects',
                        style: TextStyle(color: AppTheme.iceWhite, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Water pouring and glass clinking',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: _gameService.soundEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        _gameService.setSound(val);
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_rounded, color: AppTheme.aquaGlow),
                      title: const Text(
                        'Haptic Feedback',
                        style: TextStyle(color: AppTheme.iceWhite, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Vibrations on move and level win',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: _gameService.hapticsEnabled,
                      activeThumbColor: AppTheme.aquaGlow,
                      onChanged: (val) {
                        _gameService.setHaptics(val);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded, color: Color(0xFFFB7185)),
                      title: const Text(
                        'Reset Progress',
                        style: TextStyle(color: Color(0xFFFB7185), fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Restart all levels and achievements',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (confirmCtx) => AlertDialog(
                            backgroundColor: const Color(0xFF0F243E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            title: const Text(
                              'Reset All Progress?',
                              style: TextStyle(color: AppTheme.iceWhite),
                            ),
                            content: const Text(
                              'This will reset your current level back to Level 1. This action cannot be undone.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx),
                                child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE11D48),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _gameService.resetProgress();
                                  Navigator.pop(confirmCtx);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Progress has been reset to Level 1'),
                                      backgroundColor: Color(0xFF1E293B),
                                    ),
                                  );
                                },
                                child: const Text('RESET'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: AppTheme.iceWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine responsive sizing based on available height
              final bool isCompact = constraints.maxHeight < 680;
              final double bottleHeight = isCompact ? 142.0 : 168.0;
              final double horizontalPadding = 22.0;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),

                          // A. Header (AquaSort logo/title, water-droplet brand accent, Settings gear)
                          _buildHeader(),

                          SizedBox(height: isCompact ? 8 : 16),

                          // B. Three Animated Bottles (custom painted, liquid layers, idle animations)
                          AnimatedBottlesWidget(height: bottleHeight),

                          SizedBox(height: isCompact ? 14 : 20),

                          // C. Main PLAY Button (large cyan-to-blue gradient button with play icon)
                          _buildPlayButton(),

                          SizedBox(height: isCompact ? 12 : 18),

                          // D. Level Progress (Level X, slim horizontal indicator, 0/10 format)
                          _buildLevelProgress(),

                          SizedBox(height: isCompact ? 14 : 20),

                          // Section 3: Four Menu Cards in 2x2 grid (Themes, Journey, Bottles, Stats)
                          _buildMenuCardsGrid(),

                          SizedBox(height: isCompact ? 16 : 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // A. Header: Title, Droplet Accent, and Settings Gear Icon
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Water-droplet brand accent + Title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF38D9FF),
                    Color(0xFF087ECA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.aquaGlow.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
                children: [
                  TextSpan(
                    text: 'Aqua',
                    style: TextStyle(color: AppTheme.iceWhite),
                  ),
                  TextSpan(
                    text: 'Sort',
                    style: TextStyle(
                      color: AppTheme.aquaGlow,
                      shadows: [
                        Shadow(
                          color: Color(0x6638D9FF),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Settings Gear Icon in the top-right corner
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openSettings,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0C1F38).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: AppTheme.iceWhite,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // C. Main PLAY Button: Large, rounded cyan-to-blue gradient button
  Widget _buildPlayButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF38D9FF),
            Color(0xFF087ECA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.aquaGlow.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onPlayPressed,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withValues(alpha: 0.25),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text(
                  'PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // D. Level Progress: Level 1 (or current), slim indicator, 0/10 format
  Widget _buildLevelProgress() {
    final int level = _gameService.currentLevel;
    final double progressRatio = _gameService.tierProgressRatio;
    final String fraction = _gameService.progressFraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: const TextStyle(
                color: AppTheme.iceWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              fraction,
              style: const TextStyle(
                color: AppTheme.aquaGlow,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // Slim horizontal progress indicator
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F38),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppTheme.glassBorder.withValues(alpha: 0.5),
              width: 0.6,
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressRatio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF38D9FF),
                    Color(0xFF087ECA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.aquaGlow.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Section 3: Four Menu Cards in 2-column x 2-row grid
  Widget _buildMenuCardsGrid() {
    return Column(
      children: [
        // Row 1: Themes & Journey
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Themes',
                subtitle: 'Customize your world',
                icon: Icons.palette_rounded,
                iconGradient: const [Color(0xFFC77DFF), Color(0xFF7B2CBF)],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMenuCard(
                title: 'Journey',
                subtitle: 'Explore your progress',
                icon: Icons.alt_route_rounded,
                iconGradient: const [Color(0xFF38D9FF), Color(0xFF087ECA)],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JourneyScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Bottles & Stats
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Bottles',
                subtitle: 'Choose your style',
                icon: Icons.science_rounded,
                iconGradient: const [Color(0xFF00E676), Color(0xFF00897B)],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BottlesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMenuCard(
                title: 'Stats',
                subtitle: 'Your game record',
                icon: Icons.insights_rounded,
                iconGradient: const [Color(0xFFFFB703), Color(0xFFFB8500)],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1F38).withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.glassBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Icon + Right Chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: iconGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: iconGradient.first.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0x66EAF7FF),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.iceWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              // Subtitle
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0x99EAF7FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
