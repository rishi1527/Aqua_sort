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
        MaterialPageRoute(
          builder: (_) => WaterSortScreen(initialLevel: level),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complete Level ${level - 1} first to unlock Level $level!'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
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
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.aquaGlow.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: AppTheme.aquaGlow,
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
                              color: Color(0x99EAF7FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current Level Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.deepNavy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    _buildChapterSection('Chapter 1: Tranquil Waters', 1, 10),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 2: Coral Lagoon', 11, 20),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 3: Bioluminescent Abyss', 21, 30),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 4: Crystal Fjord', 31, 40),
                    const SizedBox(height: 20),
                    _buildChapterSection('Chapter 5: Celestial Tide', 41, 50),
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
        color: const Color(0xFF0C1F38).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.iceWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
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
              final isCompleted = _gameService.completedLevels.contains(levelNum);
              final stars = _gameService.getStarsForLevel(levelNum);

              return _buildLevelNode(levelNum, isUnlocked, isCurrent, isCompleted, stars);
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
      bg = const Color(0xFF0D3E3A);
      border = Border.all(color: const Color(0xFF00E676), width: 1.5);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$level',
            style: const TextStyle(
              color: Colors.white,
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
                    : Colors.white24,
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
      bg = const Color(0xFF142C4B);
      border = Border.all(color: AppTheme.glassBorder);
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
      bg = Colors.white.withValues(alpha: 0.04);
      border = Border.all(color: Colors.white.withValues(alpha: 0.06));
      content = const Center(
        child: Icon(Icons.lock_rounded, color: Colors.white24, size: 16),
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
