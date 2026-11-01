import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/level_generator.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'customization_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GameService _gameService = GameService.instance;
  late final PageController _pageController;

  int _currentTabIndex = 1; // 0: Shop, 1: Map (Home), 2: Achievements
  late int _selectedLevel;
  int _lastKnownCurrentLevel = 1;
  bool _isNavigating = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _ambientController;
  late final Animation<double> _ambientAnimation;

  late final ScrollController _scrollController;

  int get _highestUnlockedLevel {
    if (_gameService.isDebugUnlockAllLevelsEnabled) {
      return GameService.maxLevel;
    }
    return _gameService.currentLevel.clamp(1, GameService.maxLevel).toInt();
  }

  static const int _totalMapLevels = GameService.maxLevel;
  static const double _mapTopPadding = 140.0;
  static const double _mapBottomPadding = 180.0;

  // 4-step cyclical horizontal multipliers producing alternating S-curve matching reference:
  // Level 7: +0.65 (Right), Level 8: -0.20 (Center-Left), Level 9: -0.68 (Left), Level 10: +0.12 (Center-Right)
  static const List<double> _horizontalMultipliers = [0.65, -0.20, -0.68, 0.12];

  // Calibrated vertical step increments ensuring sqrt(dx^2 + dy^2) == 138.00px for every consecutive pair
  static const List<double> _calibratedDySteps = [
    117.58,
    131.83,
    120.08,
    130.44,
  ];

  static final double _mapTotalHeight = () {
    double totalY = 0.0;
    for (int lvl = 1; lvl < _totalMapLevels; lvl++) {
      final int stepIdx = ((lvl - 7) % 4 + 4) % 4;
      totalY += _calibratedDySteps[stepIdx];
    }
    return totalY + _mapTopPadding + _mapBottomPadding;
  }();

  static final List<double> _levelYTable = () {
    final list = List<double>.filled(_totalMapLevels + 1, 0.0);
    double y = _mapTotalHeight - _mapBottomPadding;
    list[1] = y;
    for (int lvl = 1; lvl < _totalMapLevels; lvl++) {
      final int stepIdx = ((lvl - 7) % 4 + 4) % 4;
      y -= _calibratedDySteps[stepIdx];
      list[lvl + 1] = y;
    }
    return list;
  }();

  static double _getLevelY(int level) {
    final int clamped = level.clamp(1, _totalMapLevels);
    return _levelYTable[clamped];
  }

  static double _getLevelX(int level, double centerX, double amplitude) {
    final int idx = ((level - 7) % 4 + 4) % 4;
    return centerX + _horizontalMultipliers[idx] * amplitude;
  }

  void _scrollToLevel(int level, {bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double targetY = _getLevelY(level);
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double targetOffset = (targetY - viewportHeight * 0.45).clamp(
      0.0,
      maxScroll,
    );
    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedLevel = _gameService.currentLevel
        .clamp(1, GameService.maxLevel)
        .toInt();
    _lastKnownCurrentLevel = _gameService.currentLevel;
    _pageController = PageController(initialPage: _currentTabIndex);
    _scrollController = ScrollController();
    _gameService.addListener(_onStateChange);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    _ambientAnimation = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOutSine,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToLevel(_selectedLevel, animate: false);
      }
    });
  }

  @override
  void dispose() {
    _gameService.removeListener(_onStateChange);
    _pageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {
        if (_gameService.currentLevel != _lastKnownCurrentLevel) {
          _lastKnownCurrentLevel = _gameService.currentLevel;
          _selectedLevel = _gameService.currentLevel
              .clamp(1, GameService.maxLevel)
              .toInt();
        } else if (!_gameService.isLevelUnlocked(_selectedLevel)) {
          _selectedLevel = _highestUnlockedLevel;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToLevel(_selectedLevel, animate: true);
        }
      });
    }
  }

  String _formatCoins(int count) {
    if (count >= 1000) {
      final int thousands = count ~/ 1000;
      final int remainder = count % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return count.toString();
  }

  void _onLevelTapped(int level) {
    if (_gameService.isLevelUnlocked(level)) {
      SoundService.instance.playBottleSelect();
      HapticService.instance.selectionClick();
      setState(() {
        _selectedLevel = level;
      });
    } else {
      HapticService.instance.invalidMove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete Level ${level - 1} first to unlock Level $level!',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF6D28D9),
        ),
      );
    }
  }

  void _onTabTapped(int index) {
    if (_currentTabIndex == index) {
      return;
    }

    SoundService.instance.playButtonTap();
    HapticService.instance.selectionClick();
    setState(() => _currentTabIndex = index);

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPlayPressed() {
    if (_isNavigating) return;
    _isNavigating = true;

    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();

    final int levelToPlay = _selectedLevel;
    _gameService.recordGameStarted();

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => WaterSortScreen(initialLevel: levelToPlay),
          ),
        )
        .then((_) {
          _isNavigating = false;
          if (mounted) {
            setState(() {
              if (_gameService.currentLevel != _lastKnownCurrentLevel) {
                _lastKnownCurrentLevel = _gameService.currentLevel;
                _selectedLevel = _gameService.currentLevel
                    .clamp(1, GameService.maxLevel)
                    .toInt();
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _scrollToLevel(_selectedLevel, animate: true);
              }
            });
          }
        });
  }

  void _openSettings() {
    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();
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
                color: AppTheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: AppTheme.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.12),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD0F7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          color: AppTheme.primaryContainer,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Game Settings',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.volume_up_rounded,
                        color: AppTheme.primaryContainer,
                      ),
                      title: const Text(
                        'Sound Effects',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Water pouring and glass clinking',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _gameService.soundEnabled,
                      activeThumbColor: AppTheme.primaryContainer,
                      onChanged: (val) {
                        _gameService.setSound(val);
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.vibration_rounded,
                        color: AppTheme.primaryContainer,
                      ),
                      title: const Text(
                        'Haptic Feedback',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Vibrations on move and level win',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _gameService.hapticsEnabled,
                      activeThumbColor: AppTheme.primaryContainer,
                      onChanged: (val) {
                        _gameService.setHaptics(val);
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.developer_mode_rounded,
                        color: AppTheme.primaryContainer,
                      ),
                      title: const Text(
                        'Unlock All Levels (Testing)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Play all 100 levels across all chapters',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _gameService.isDebugUnlockAllLevelsEnabled,
                      activeThumbColor: AppTheme.primaryContainer,
                      onChanged: (val) {
                        _gameService.setDebugUnlockAllLevels(val);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(
                        Icons.restart_alt_rounded,
                        color: Color(0xFFFB7185),
                      ),
                      title: const Text(
                        'Reset Progress',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFFFB7185),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Restart all levels and achievements',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (confirmCtx) => AlertDialog(
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: AppTheme.glassBorder,
                              ),
                            ),
                            title: const Text(
                              'Reset All Progress?',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppTheme.onSurface,
                              ),
                            ),
                            content: const Text(
                              'This will reset your current level back to Level 1. This action cannot be undone.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE11D48),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(confirmCtx);
                                  _gameService.resetProgress();
                                  setModalState(() {});
                                  setState(() {
                                    _selectedLevel = 1;
                                  });
                                  _scrollToLevel(1, animate: true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'All game progress has been reset.',
                                      ),
                                      backgroundColor: AppTheme.primaryPurple,
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
                          foregroundColor: AppTheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
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

  void _openProfile() {
    SoundService.instance.playButtonTap();
    HapticService.instance.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final totalStars = _gameService.completedLevels.fold<int>(0, (
          sum,
          lvl,
        ) {
          final s = _gameService.getStarsForLevel(lvl);
          return sum + (s == 0 ? 3 : s);
        });

        String rank = 'Novice Sorter';
        if (_gameService.currentLevel >= 20) {
          rank = 'Grand Hydromancer';
        } else if (_gameService.currentLevel >= 12) {
          rank = 'Fluid Maestro';
        } else if (_gameService.currentLevel >= 7) {
          rank = 'Aqua Sorcerer';
        } else if (_gameService.currentLevel >= 3) {
          rank = 'Liquid Alchemist';
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0A3C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD0F7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.45),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aqua Explorer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rank,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProfileMetric(
                      'Level',
                      '${_gameService.currentLevel}',
                    ),
                    _buildProfileMetric('Stars', '$totalStars'),
                    _buildProfileMetric(
                      'Streak',
                      '${_gameService.bestStreak}x',
                    ),
                    _buildProfileMetric('Coins', '${_gameService.coins}'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFC084FC)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140224),
      body: Stack(
        children: [
          // 1. Full-screen Deep Nocturnal Purple Radial Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.35,
                  colors: [
                    Color(0xFF2E0854),
                    Color(0xFF1D0535),
                    Color(0xFF0F011B),
                  ],
                ),
              ),
            ),
          ),

          // 2. Animated Tropical Foliage Layer with gentle, restrained ambient sway
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambientAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _TropicalFoliagePainter(
                      progress: _ambientAnimation.value,
                      tabIndex: _currentTabIndex,
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Screen Structure with full SafeArea handling
          SafeArea(
            child: Column(
              children: [
                // Horizontal PageView with smooth slide navigation
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      if (_currentTabIndex != index) {
                        setState(() => _currentTabIndex = index);
                      }
                    },
                    children: [
                      // 0: Shop Tab (Bottles & Themes)
                      const ShopView(showBackButton: false),

                      // 1: Map Tab (Journey Map with transparent floating HUD + dedicated Play button)
                      _buildJourneyMapTab(),

                      // 2: Achievements Tab (Stats & Records)
                      const StatsContentView(),
                    ],
                  ),
                ),

                // Bottom Navigation Bar with animated sliding pill indicator
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Transparent, Borderless Glass Top HUD
  Widget _buildTopHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Translucent Profile Avatar Squircle with Hot Pink Glow
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0A3C).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.85),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: const Color(0xFFE9D5FF).withValues(alpha: 0.90),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Center: Translucent Coin Balance Pill (journey path visible through glass)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onTabTapped(0),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0A3C).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.80),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.water_drop_rounded,
                          color: Color(0xFF78350F),
                          size: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ListenableBuilder(
                      listenable: _gameService,
                      builder: (context, _) {
                        return Text(
                          _formatCoins(_gameService.coins),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right: Translucent Settings Button with Hot Pink Glow
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openSettings,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0A3C).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.85),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.settings_rounded,
                    color: const Color(0xFFE9D5FF).withValues(alpha: 0.90),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyMapTab() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 1. Dedicated Scrollable Journey Map
        Positioned.fill(child: _buildScrollableMapView()),

        // 2. Translucent, borderless Top HUD pinned at top
        Positioned(top: 0, left: 0, right: 0, child: _buildTopHud()),

        // Subtle Chapter Bar (only visible when advanced beyond initial levels, never overflows)
        _buildChapterBar(),

        // 3. Dedicated 3D Play Button Area - positioned safely 18px above bottom nav
        Positioned(
          bottom: 18,
          left: 0,
          right: 0,
          child: Center(child: _buildFloatingPlayButton()),
        ),
      ],
    );
  }

  Widget _buildChapterBar() {
    // Only display when player has progressed beyond Chapter 1
    if (_highestUnlockedLevel <= 10) {
      return const SizedBox.shrink();
    }
    final int currentChapter = ((_selectedLevel - 1) ~/ 10) + 1;
    final title = LevelGenerator.getChapterTitle((currentChapter - 1) * 10 + 1);
    final int startLvl = (currentChapter - 1) * 10 + 1;
    final int endLvl = currentChapter * 10;

    return Positioned(
      top: 52,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0A3C).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC084FC).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Chapter $currentChapter: $title ($startLvl-$endLvl)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE9D5FF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableMapView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double centerX = width / 2.0;
        final double amplitude = (width * 0.25).clamp(75.0, 95.0);

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: width,
            height: _mapTotalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Continuous thick winding 3D purple path through all 100 levels
                Positioned.fill(
                  child: CustomPaint(
                    size: Size(width, _mapTotalHeight),
                    painter: _WindingPathPainter(
                      totalLevels: _totalMapLevels,
                      getX: (lvl) => _getLevelX(lvl, centerX, amplitude),
                      getY: _getLevelY,
                      selectedLevel: _selectedLevel,
                    ),
                  ),
                ),

                // 2. Visible Level Nodes (all 100 large, glossy 3D buttons)
                for (int level = 1; level <= _totalMapLevels; level++)
                  () {
                    final double x = _getLevelX(level, centerX, amplitude);
                    final double y = _getLevelY(level);
                    final bool isSelected = level == _selectedLevel;
                    final double halfSize = isSelected ? 47.0 : 41.0;

                    return Positioned(
                      left: x - halfSize,
                      top: y - halfSize,
                      child: _LevelNodeWidget(
                        key: ValueKey('level_node_$level'),
                        level: level,
                        stars: _gameService.getStarsForLevel(level),
                        isSelected: isSelected,
                        isCompleted: _gameService.completedLevels.contains(
                          level,
                        ),
                        isUnlocked: _gameService.isLevelUnlocked(level),
                        pulseAnimation: _pulseAnimation,
                        onTap: () => _onLevelTapped(level),
                      ),
                    );
                  }(),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. 3D Green Play Button with Layered Canary Yellow & Autumn Red Leaf Flanks
  Widget _buildFloatingPlayButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Accessory Potion Flask Badge showing selected level
        _buildPotionFlask(),

        const SizedBox(width: 8),

        // Main Green 3D Play Button with Controlled Leaf Flanks
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Top-Left decorative canary-yellow leaf cluster (clearly visible, radiant, non-obscuring)
            const Positioned(
              left: -14,
              top: -10,
              child: IgnorePointer(child: _YellowLeafCluster()),
            ),

            // Bottom-Right decorative autumn leaf cluster (tangerine orange + ruby red)
            const Positioned(
              right: -14,
              bottom: -10,
              child: IgnorePointer(child: _AutumnLeafCluster()),
            ),

            // 3D Play Button Pill
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onPlayPressed,
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  width: 220,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF86EFAC),
                        Color(0xFF22C55E),
                        Color(0xFF16A34A),
                        Color(0xFF15803D),
                      ],
                    ),
                    boxShadow: const [
                      // Dark 3D bottom bevel skirt
                      BoxShadow(
                        color: Color(0xFF0F4A24),
                        offset: Offset(0, 6),
                        blurRadius: 0,
                      ),
                      // Soft restrained green ambient glow
                      BoxShadow(
                        color: Color(0x5522C55E),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Top inner specular gloss arc
                      Positioned(
                        top: 2,
                        left: 18,
                        right: 18,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.50),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // "Play" Text with ample clearance from leaves
                      const Text(
                        'Play',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color(0xFF0F4A24),
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPotionFlask() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF17042C),
        border: Border.all(color: const Color(0xFF38BDF8), width: 2.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
            blurRadius: 14,
          ),
          const BoxShadow(color: Color(0xFF090014), offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Luminous liquid gradient
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    radius: 0.85,
                    colors: [
                      Color(0xFF67E8F9),
                      Color(0xFF0284C7),
                      Color(0xFF0C4A6E),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Glass specular reflection arc
          Positioned(
            top: 4,
            left: 8,
            right: 8,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Flask Cork Stopper on top
          Positioned(
            top: 2,
            child: Container(
              width: 14,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFB45309),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFF78350F), width: 0.8),
              ),
            ),
          ),

          // Current Level Badge Number
          Center(
            child: Text(
              '$_selectedLevel',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bottom Navigation Bar with Consistent Raised Purple Selection across Shop, Map & Achievements
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF140224),
        border: Border(top: BorderSide(color: Color(0xFF2E0A4E), width: 1.5)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Shop Tab
            _buildAnimatedNavItem(
              index: 0,
              icon: Icons.storefront_rounded,
              label: 'Shop',
            ),

            // 2. Map Tab (Center)
            _buildAnimatedNavItem(
              index: 1,
              icon: Icons.location_on_rounded,
              label: 'Map',
            ),

            // 3. Achievements Tab
            _buildAnimatedNavItem(
              index: 2,
              icon: Icons.military_tech_rounded,
              label: 'Achievements',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 8,
              vertical: isSelected ? 4 : 2,
            ),
            height: isSelected ? 56 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9333EA), Color(0xFF6B21A8)],
                    )
                  : null,
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.50),
                      width: 1.2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.55),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFFDE047),
                          Color(0xFFEC4899),
                          Color(0xFF38BDF8),
                        ],
                      ).createShader(bounds);
                    },
                    child: Icon(icon, color: Colors.white, size: 22),
                  )
                else
                  Icon(icon, size: 20, color: const Color(0xFF7E649E)),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF7E649E),
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

class _LevelNodeWidget extends StatelessWidget {
  final int level;
  final int stars;
  final bool isSelected;
  final bool isCompleted;
  final bool isUnlocked;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _LevelNodeWidget({
    super.key,
    required this.level,
    this.stars = 0,
    required this.isSelected,
    required this.isCompleted,
    required this.isUnlocked,
    required this.pulseAnimation,
    required this.onTap,
  });

  Widget _buildStarsRow(int count, {double size = 12}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final bool earned = i < count;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: earned
                ? const Color(0xFFFFD166)
                : Colors.white.withValues(alpha: 0.32),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Transform.scale(scale: pulseAnimation.value, child: child);
        },
        child: _buildNodeButton(),
      );
    }
    return _buildNodeButton();
  }

  Widget _buildNodeButton() {
    // 1. Current / Selected Level: Chunky 94px 3D Magenta Button with Controlled Golden Rim
    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // Thick glowing golden halo outer rim matching reference
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF785),
                Color(0xFFFBBF24),
                Color(0xFFF59E0B),
                Color(0xFFD97706),
              ],
            ),
            boxShadow: [
              // Soft and controlled golden ambient glow (reduced 55-65% for refined elegance)
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                blurRadius: 10,
                spreadRadius: 0,
              ),
              // Golden 3D bottom bevel skirt
              const BoxShadow(
                color: Color(0xFF78350F),
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
              // Subtle ground shadow for realistic 3D depth
              const BoxShadow(
                color: Color(0x55000000),
                offset: Offset(0, 6),
                blurRadius: 8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                // Vibrant glossy magenta/pink surface
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF3388),
                    Color(0xFFE6007A),
                    Color(0xFFC00060),
                    Color(0xFF990048),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF600028),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top specular gloss highlight arc
                  Positioned(
                    top: 2,
                    left: 8,
                    right: 8,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.50),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bold level number
                  Positioned(
                    top: (isCompleted && stars > 0) ? 10 : null,
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: (isCompleted && stars > 0) ? 33 : 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0xFF500020),
                            offset: Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Saved Best Stars on completed selected node
                  if (isCompleted && stars > 0)
                    Positioned(
                      bottom: 7,
                      child: _buildStarsRow(stars, size: 13),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. Completed Level: Chunky 82px 3D Royal Purple Cushion with Crisp White Checkmark
    if (isCompleted) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
              width: 1.0,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF280C48), Color(0xFF1B0533)],
            ),
            boxShadow: const [
              // 3D bottom bevel skirt
              BoxShadow(
                color: Color(0xFF120224),
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
              // Ground shadow
              BoxShadow(
                color: Color(0x55000000),
                offset: Offset(0, 6),
                blurRadius: 8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF6D28D9),
                    Color(0xFF5B21B6),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF381072),
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top highlight arc
                  Positioned(
                    top: 2,
                    left: 10,
                    right: 10,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Crisp checkmark matching reference
                  Positioned(
                    top: stars > 0 ? 10 : null,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: stars > 0 ? 32 : 40,
                    ),
                  ),

                  // Saved Best Stars Row
                  if (stars > 0)
                    Positioned(
                      bottom: 7,
                      child: _buildStarsRow(stars, size: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Locked Level: Chunky 82px 3D Royal Purple Cushion with bold lavender number
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.20),
            width: 1.0,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF220A3E), Color(0xFF150426)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0F011B),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x55000000),
              offset: Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3B137B),
                  Color(0xFF2A0A5B),
                  Color(0xFF1E0642),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF140226),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 2,
                  left: 10,
                  right: 10,
                  height: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC084FC).withValues(alpha: 0.65),
                    shadows: const [
                      Shadow(
                        color: Color(0xFF0E0117),
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
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

class _WindingPathPainter extends CustomPainter {
  final int totalLevels;
  final double Function(int level) getX;
  final double Function(int level) getY;
  final int selectedLevel;

  _WindingPathPainter({
    required this.totalLevels,
    required this.getX,
    required this.getY,
    required this.selectedLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalLevels < 2) return;

    final Path fullPath = Path();

    // Start lead-in below level 1 (behind Play button at bottom)
    final double startX = getX(1);
    final double startY = getY(1);
    fullPath.moveTo(startX, startY + 60);
    fullPath.cubicTo(startX, startY + 40, startX, startY + 20, startX, startY);

    for (int lvl = 1; lvl < totalLevels; lvl++) {
      final double x1 = getX(lvl);
      final double y1 = getY(lvl);
      final double x2 = getX(lvl + 1);
      final double y2 = getY(lvl + 1);

      final double dy = y1 - y2;
      fullPath.cubicTo(x1, y1 - dy * 0.50, x2, y2 + dy * 0.50, x2, y2);
    }

    // Top lead-out above level 100
    final double lastX = getX(totalLevels);
    final double lastY = getY(totalLevels);
    fullPath.cubicTo(
      lastX,
      lastY - 20,
      lastX - 15,
      lastY - 40,
      lastX - 25,
      lastY - 60,
    );

    // 1. Deep 3D Path Ground Shadow
    final Paint shadowPaint = Paint()
      ..color = const Color(0xCC090014)
      ..strokeWidth = 48.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate(0, 8);
    canvas.drawPath(fullPath, shadowPaint);
    canvas.restore();

    // 2. Extruded 3D Bottom Bevel Skirt
    final Paint bevelPaint = Paint()
      ..color = const Color(0xFF240645)
      ..strokeWidth = 42.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate(0, 5);
    canvas.drawPath(fullPath, bevelPaint);
    canvas.restore();

    // 3. Thick 3D Winding Purple Ribbon
    final Paint mainPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8B5CF6), Color(0xFF6B21A8), Color(0xFF4C1D95)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 36.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, mainPaint);

    // 4. Glowing Magenta Energy Segment under/around the selected level (matching reference)
    if (selectedLevel >= 1 && selectedLevel <= totalLevels) {
      final int startLvl = (selectedLevel - 1).clamp(1, totalLevels);
      final int endLvl = (selectedLevel + 1).clamp(1, totalLevels);

      if (startLvl < endLvl) {
        final Path activeSegment = Path();
        activeSegment.moveTo(getX(startLvl), getY(startLvl));
        for (int lvl = startLvl; lvl < endLvl; lvl++) {
          final double x1 = getX(lvl);
          final double y1 = getY(lvl);
          final double x2 = getX(lvl + 1);
          final double y2 = getY(lvl + 1);
          final double dy = y1 - y2;
          activeSegment.cubicTo(x1, y1 - dy * 0.50, x2, y2 + dy * 0.50, x2, y2);
        }

        final Paint activeGlowPaint = Paint()
          ..shader =
              const LinearGradient(
                colors: [
                  Color(0xFFFF3388),
                  Color(0xFFE6007A),
                  Color(0xFFC026D3),
                ],
              ).createShader(
                Rect.fromLTWH(
                  0,
                  getY(endLvl),
                  size.width,
                  (getY(startLvl) - getY(endLvl)).abs() + 1,
                ),
              )
          ..strokeWidth = 36.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(activeSegment, activeGlowPaint);
      }
    }

    // 5. Subtle Tubular Specular Highlight along Path Spine
    final Paint highlightPaint = Paint()
      ..color = const Color(0xFFF3E8FF).withValues(alpha: 0.35)
      ..strokeWidth = 3.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _WindingPathPainter oldDelegate) {
    return oldDelegate.totalLevels != totalLevels ||
        oldDelegate.selectedLevel != selectedLevel;
  }
}

// Enchanted Tropical Foliage Painter with Subtle, Restrained Ambient Swaying
class _TropicalFoliagePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 from ambient animation
  final int tabIndex; // 0: Shop, 1: Map, 2: Achievements

  _TropicalFoliagePainter({required this.progress, required this.tabIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Smooth horizontal parallax offset when switching tabs (-14 to +14 px)
    final double tabParallax = (tabIndex - 1) * -14.0;

    // Distant Foliage (Layer 1 - deep background, subtle sway)
    final double distantSwayY = math.sin(progress * math.pi) * 3.5;
    final double distantRot = math.cos(progress * math.pi) * 0.02;

    _drawMonstera(
      canvas: canvas,
      center: Offset(w * 0.0 + tabParallax * 0.5, h * 0.12 + distantSwayY),
      scale: 1.10,
      rotation: 0.32 + distantRot,
      baseColor: const Color(0xFF0F172A),
      highlightColor: const Color(0xFF1E3A8A),
    );

    _drawMonstera(
      canvas: canvas,
      center: Offset(w * 1.0 + tabParallax * 0.5, h * 0.15 - distantSwayY),
      scale: 1.05,
      rotation: -0.28 - distantRot,
      baseColor: const Color(0xFF1E1B4B),
      highlightColor: const Color(0xFF2563EB),
    );

    // Foreground Foliage (Layer 2 - lush tropical, gentle organic sway)
    final double midSwayY = -math.cos(progress * math.pi) * 4.5;
    final double midSwayX = math.sin(progress * math.pi) * 2.5;
    final double midRot = -math.sin(progress * math.pi) * 0.028;

    // Left Monstera Leaf
    _drawMonstera(
      canvas: canvas,
      center: Offset(w * 0.02 + tabParallax + midSwayX, h * 0.44 + midSwayY),
      scale: 1.35,
      rotation: -0.22 + midRot,
      baseColor: const Color(0xFF0F172A),
      highlightColor: const Color(0xFF0284C7),
    );

    // Bottom-Left Tropical Leaf
    _drawMonstera(
      canvas: canvas,
      center: Offset(w * 0.03 + tabParallax - midSwayX, h * 0.80 - midSwayY),
      scale: 1.18,
      rotation: 0.38 - midRot,
      baseColor: const Color(0xFF3B0764),
      highlightColor: const Color(0xFFA855F7),
    );

    // Right Big Cerulean Monstera (Hero leaf with vibrant cyan highlights)
    _drawMonstera(
      canvas: canvas,
      center: Offset(w * 0.98 + tabParallax - midSwayX, h * 0.38 + midSwayY),
      scale: 1.42,
      rotation: -0.38 + midRot,
      baseColor: const Color(0xFF0284C7),
      highlightColor: const Color(0xFF38BDF8),
    );

    // Bottom-Right Royal Purple Leaf
    _drawMonstera(
      canvas: canvas,
      center: Offset(w * 1.02 + tabParallax + midSwayX, h * 0.72 - midSwayY),
      scale: 1.25,
      rotation: 0.28 - midRot,
      baseColor: const Color(0xFF2E1065),
      highlightColor: const Color(0xFFC084FC),
    );
  }

  void _drawMonstera({
    required Canvas canvas,
    required Offset center,
    required double scale,
    required double rotation,
    required Color baseColor,
    required Color highlightColor,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    // Stylized Monstera leaf with deep fenestrations/finger lobes
    final leafPath = Path();
    leafPath.moveTo(0, 115);
    // Right side lobes
    leafPath.cubicTo(45, 100, 72, 75, 78, 55);
    leafPath.cubicTo(65, 48, 30, 48, 22, 42); // deep notch 1
    leafPath.cubicTo(40, 36, 88, 32, 94, 8);
    leafPath.cubicTo(82, 0, 35, 8, 26, -2); // deep notch 2
    leafPath.cubicTo(45, -12, 85, -28, 76, -56);
    leafPath.cubicTo(62, -58, 28, -44, 20, -56); // deep notch 3
    leafPath.cubicTo(32, -72, 48, -90, 0, -112); // Apex

    // Left side lobes (mirrored natural curve)
    leafPath.cubicTo(-48, -90, -32, -72, -20, -56); // notch 3
    leafPath.cubicTo(-28, -44, -62, -58, -76, -56);
    leafPath.cubicTo(-85, -28, -45, -12, -26, -2); // notch 2
    leafPath.cubicTo(-35, 8, -82, 0, -94, 8);
    leafPath.cubicTo(-88, 32, -40, 36, -22, 42); // notch 1
    leafPath.cubicTo(-30, 48, -65, 48, -78, 55);
    leafPath.cubicTo(-72, 75, -45, 100, 0, 115);
    leafPath.close();

    // 1. Soft Leaf Ambient Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.save();
    canvas.translate(0, 6);
    canvas.drawPath(leafPath, shadowPaint);
    canvas.restore();

    // 2. Volumetric 3D Leaf Body Gradient
    final fillPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              highlightColor.withValues(alpha: 0.65),
              baseColor.withValues(alpha: 0.92),
              const Color(0xFF060D1E),
            ],
          ).createShader(
            Rect.fromCenter(center: Offset.zero, width: 200, height: 260),
          );
    canvas.drawPath(leafPath, fillPaint);

    // 3. Curved Lobe Upper Rim Highlights
    final rimPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leafPath, rimPaint);

    // 4. Center Midrib Stem
    final stemPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.50)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 115), const Offset(0, -105), stemPaint);

    // 5. Lateral Leaf Veins to each lobe
    final veinPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final offsets = [
      [const Offset(0, 52), const Offset(65, 58), const Offset(-65, 58)],
      [const Offset(0, 15), const Offset(80, 12), const Offset(-80, 12)],
      [const Offset(0, -25), const Offset(68, -48), const Offset(-68, -48)],
      [const Offset(0, -65), const Offset(36, -88), const Offset(-36, -88)],
    ];

    for (final triplet in offsets) {
      final start = triplet[0];
      final rightEnd = triplet[1];
      final leftEnd = triplet[2];

      final rightVein = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + rightEnd.dx) / 2,
          start.dy - 6,
          rightEnd.dx,
          rightEnd.dy,
        );
      canvas.drawPath(rightVein, veinPaint);

      final leftVein = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + leftEnd.dx) / 2,
          start.dy - 6,
          leftEnd.dx,
          leftEnd.dy,
        );
      canvas.drawPath(leftVein, veinPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TropicalFoliagePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.tabIndex != tabIndex;
  }
}

// Canary Yellow Leaf Cluster: Positioned on the Top-Left of the Play button
class _YellowLeafCluster extends StatelessWidget {
  const _YellowLeafCluster();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 44),
      painter: _YellowLeafClusterPainter(),
    );
  }
}

class _YellowLeafClusterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Leaf 1: Bright Canary Yellow (Topmost, fully visible and fanning outward)
    final leaf1 = Path()
      ..moveTo(10, 32)
      ..quadraticBezierTo(0, 12, 14, 2)
      ..quadraticBezierTo(28, 8, 10, 32);
    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF785), Color(0xFFFDE047), Color(0xFFFACC15)],
      ).createShader(const Rect.fromLTWH(0, 0, 36, 36));
    canvas.drawPath(leaf1, paint1);

    final outline1 = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leaf1, outline1);

    final vein1 = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(10, 32), const Offset(14, 4), vein1);

    // Leaf 2: Radiant Golden Yellow (Middle leaf)
    final leaf2 = Path()
      ..moveTo(16, 38)
      ..quadraticBezierTo(14, 18, 36, 10)
      ..quadraticBezierTo(38, 24, 16, 38);
    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFDE047), Color(0xFFEAB308)],
      ).createShader(const Rect.fromLTWH(0, 0, 42, 42));
    canvas.drawPath(leaf2, paint2);

    final outline2 = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leaf2, outline2);

    final vein2 = Paint()
      ..color = const Color(0xFF92400E).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(16, 38), const Offset(34, 12), vein2);

    // Leaf 3: Warm Golden Amber (Base leaf)
    final leaf3 = Path()
      ..moveTo(22, 42)
      ..quadraticBezierTo(28, 26, 42, 26)
      ..quadraticBezierTo(38, 40, 22, 42);
    final paint3 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFD97706)],
      ).createShader(const Rect.fromLTWH(0, 0, 44, 44));
    canvas.drawPath(leaf3, paint3);

    final outline3 = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leaf3, outline3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Autumn Leaf Cluster: Positioned on the Bottom-Right of the Play button
class _AutumnLeafCluster extends StatelessWidget {
  const _AutumnLeafCluster();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 44),
      painter: _AutumnLeafClusterPainter(),
    );
  }
}

class _AutumnLeafClusterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Mirror horizontally for the right side
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);

    // Leaf 1: Tangerine Orange (Top leaf of right cluster)
    final leaf1 = Path()
      ..moveTo(10, 32)
      ..quadraticBezierTo(2, 12, 16, 4)
      ..quadraticBezierTo(28, 10, 10, 32);
    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFED7AA), Color(0xFFFB923C), Color(0xFFEA580C)],
      ).createShader(const Rect.fromLTWH(0, 0, 36, 36));
    canvas.drawPath(leaf1, paint1);

    final outline1 = Paint()
      ..color = const Color(0xFF7C2D12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leaf1, outline1);

    final vein1 = Paint()
      ..color = const Color(0xFF9A3412).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(10, 32), const Offset(16, 6), vein1);

    // Leaf 2: Fiery Autumn Orange (Middle leaf)
    final leaf2 = Path()
      ..moveTo(16, 38)
      ..quadraticBezierTo(16, 20, 36, 14)
      ..quadraticBezierTo(38, 28, 16, 38);
    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDBA74), Color(0xFFF97316), Color(0xFFC2410C)],
      ).createShader(const Rect.fromLTWH(0, 0, 42, 42));
    canvas.drawPath(leaf2, paint2);

    final outline2 = Paint()
      ..color = const Color(0xFF7C2D12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leaf2, outline2);

    final vein2 = Paint()
      ..color = const Color(0xFF9A3412).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(16, 38), const Offset(34, 16), vein2);

    // Leaf 3: Deep Ruby Autumn Red (Bottom leaf)
    final leaf3 = Path()
      ..moveTo(22, 42)
      ..quadraticBezierTo(30, 26, 44, 28)
      ..quadraticBezierTo(40, 42, 22, 42);
    final paint3 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFECACA), Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(const Rect.fromLTWH(0, 0, 46, 46));
    canvas.drawPath(leaf3, paint3);

    final outline3 = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leaf3, outline3);

    final vein3 = Paint()
      ..color = const Color(0xFF991B1B).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(22, 42), const Offset(42, 30), vein3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
