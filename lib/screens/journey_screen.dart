import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/game_service.dart';
import '../main.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
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

  void _playLevel(int level) {
    if (_gameService.isLevelUnlocked(level)) {
      _gameService.recordGameStarted();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WaterSortScreen(initialLevel: level)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete Level ${level - 1} first to unlock Level $level!',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
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
                        border: Border.all(color: const Color(0xFFDDD0F7)),
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Color(0xFF6D28D9),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Journey',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.iceWhite,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Explore your progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B5B85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current Level Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.deepNavy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB703),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${_gameService.currentLevel}',
                            style: const TextStyle(
                              color: AppTheme.iceWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Level Chapters & Grid
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  children: [
                    _buildChapterSection('Chapter 1: Tranquil Waters', 1, 10),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 2: Coral Lagoon', 11, 20),
                    const SizedBox(height: 20),
                    _buildChapterSection(
                      'Chapter 3: Bioluminescent Abyss',
                      21,
                      30,
                    ),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 4: Crystal Fjord', 31, 40),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 5: Celestial Tide', 41, 50),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 6: Mystic Caverns', 51, 60),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 7: Aurora Springs', 61, 70),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 8: Prismatic Reef', 71, 80),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 9: Starlight Falls', 81, 90),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 10: Infinity Ocean', 91, 100),
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

  Widget _buildChapterSection(String title, int startLevel, int endLevel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.iceWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lv $startLevel - $endLevel',
                style: TextStyle(
                  color: AppTheme.aquaGlow.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: endLevel - startLevel + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final levelNum = startLevel + index;
              final isUnlocked = _gameService.isLevelUnlocked(levelNum);
              final isCurrent = _gameService.currentLevel == levelNum;
              final isCompleted = _gameService.completedLevels.contains(
                levelNum,
              );
              final stars = _gameService.getStarsForLevel(levelNum);

              return _buildLevelNode(
                levelNum,
                isUnlocked,
                isCurrent,
                isCompleted,
                stars,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNode(
    int level,
    bool isUnlocked,
    bool isCurrent,
    bool isCompleted,
    int stars,
  ) {
    Color bg;
    Border border;
    Widget content;

    if (isCompleted) {
      bg = const Color(0xFFEDE5FF);
      border = Border.all(color: const Color(0xFF6D28D9), width: 1.5);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$level',
            style: const TextStyle(
              color: Color(0xFF32145A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Icon(
                Icons.star_rounded,
                size: 9,
                color: i < (stars == 0 ? 3 : stars)
                    ? const Color(0xFFFFB703)
                    : const Color(0xFFDDD0F7),
              ),
            ),
          ),
        ],
      );
    } else if (isCurrent) {
      bg = AppTheme.primaryBlue;
      border = Border.all(color: AppTheme.aquaGlow, width: 2.0);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          Text(
            '$level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else if (isUnlocked) {
      bg = const Color(0xFFF7F3FF);
      border = Border.all(color: const Color(0xFFDDD0F7));
      content = Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: AppTheme.iceWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    } else {
      bg = const Color(0xFFF7F3FF);
      border = Border.all(color: const Color(0xFFDDD0F7));
      content = const Center(
        child: Icon(Icons.lock_rounded, color: Color(0xFF6B5B85), size: 16),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playLevel(level),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.aquaGlow.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: content,
        ),
      ),
    );
  }
}
