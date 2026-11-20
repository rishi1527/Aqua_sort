import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/leaderboard_service.dart';
import '../services/sound_service.dart';
import '../widgets/nickname_dialog.dart';

/// Premium Global Leaderboard Screen for AquaSort.
///
/// Implements deep nocturnal purple glassmorphism, gold/silver/bronze podium,
/// Top 100 list, pinned "Your Rank" bottom panel, and resilient state handling.
class LeaderboardScreen extends StatefulWidget {
  final ILeaderboardProvider? mockProvider;
  final bool showBackButton;
  static bool enableAnimations = true;

  const LeaderboardScreen({
    super.key,
    this.mockProvider,
    this.showBackButton = true,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final ILeaderboardProvider _provider;
  final GameService _gameService = GameService.instance;

  LeaderboardTab _selectedTab = LeaderboardTab.global;
  bool _isUpdatingNickname = false;
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _provider = widget.mockProvider ?? LeaderboardService.instance;
    _scrollController = ScrollController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (LeaderboardScreen.enableAnimations) {
      _pulseController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _gameService.addListener(_onStateChange);
    if (widget.mockProvider == null) {
      LeaderboardService.instance.addListener(_onStateChange);
    }
  }

  @override
  void dispose() {
    _gameService.removeListener(_onStateChange);
    if (widget.mockProvider == null) {
      LeaderboardService.instance.removeListener(_onStateChange);
    }
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _openRulesInfoDialog() {
    SoundService.instance.playButtonTap();
    HapticService.instance.selectionClick();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E0854), Color(0xFF140224)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFC084FC).withValues(alpha: 0.50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.40),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF78350F),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'LEADERBOARD RULES',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildRuleItem(
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFFDE047),
                  title: 'Ranked by Lifetime Coins',
                  description:
                      'Rankings are based strictly on total coins ever earned. Spending coins in the Shop never decreases your rank.',
                ),
                const SizedBox(height: 12),
                _buildRuleItem(
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF38BDF8),
                  title: 'Level Rewards (50 Coins)',
                  description:
                      'First-time level completion awards 50 coins once. Replaying completed levels awards 0 additional coins.',
                ),
                const SizedBox(height: 12),
                _buildRuleItem(
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFFEC4899),
                  title: 'Daily Rewards (30 Coins)',
                  description:
                      'Claim your daily bonus once per day (Asia/Kolkata boundary) to steadily climb the global leaderboard.',
                ),
                const SizedBox(height: 12),
                _buildRuleItem(
                  icon: Icons.military_tech_rounded,
                  color: const Color(0xFFA78BFA),
                  title: 'Top 100 Showcase',
                  description:
                      'The top 100 sorters are displayed globally. Your real rank is always visible in your bottom panel.',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'GOT IT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
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
  }

  Widget _buildRuleItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openNicknameDialog() {
    if (_isUpdatingNickname) return;
    SoundService.instance.playButtonTap();
    HapticService.instance.selectionClick();

    final summary = _provider.getPlayerRankSummary(
      _gameService.lifetimeEarnedCoins,
    );

    NicknameDialog.show(
      context,
      currentNickname: summary.nickname,
      canChange: summary.canChangeNickname,
      daysRemaining: summary.daysUntilNicknameChange,
      onNicknameSaved: (newNickname) async {
        if (_isUpdatingNickname) return;
        _isUpdatingNickname = true;
        try {
          final success = await _provider.updateNickname(newNickname);
          if (!mounted) return;
          if (success) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Display nickname updated to "$newNickname"'),
                backgroundColor: const Color(0xFF9333EA),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to update nickname. Please check restrictions.'),
                backgroundColor: Color(0xFFE11D48),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating nickname: $e'),
              backgroundColor: const Color(0xFFE11D48),
              duration: const Duration(seconds: 2),
            ),
          );
        } finally {
          if (mounted) {
            _isUpdatingNickname = false;
          }
        }
      },
    );
  }

  String _formatNumber(int count) {
    if (count >= 1000) {
      final int thousands = count ~/ 1000;
      final int remainder = count % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final status = _provider.status;
    final topPlayers = _provider.getTop100Players();
    final playerSummary = _provider.getPlayerRankSummary(
      _gameService.lifetimeEarnedCoins,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F011B),
      body: Stack(
        children: [
          // 1. Full-screen Deep Nocturnal Purple Radial Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.4,
                  colors: [
                    Color(0xFF2E0854),
                    Color(0xFF1D0535),
                    Color(0xFF0F011B),
                  ],
                ),
              ),
            ),
          ),

          // 2. Ambient Bioluminescent Particle Light Bubbles
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) => CustomPaint(
                  painter: _AmbientAuraPainter(pulse: _pulseAnimation.value),
                ),
              ),
            ),
          ),

          // 3. Screen Structure with full SafeArea handling
          SafeArea(
            child: Column(
              children: [
                // Top Header (Back Button, Brand, Title, Info)
                _buildHeader(),

                // Tab Switcher (Global / Rewards)
                _buildTabs(),

                // Main Content Body
                Expanded(
                  child: _selectedTab == LeaderboardTab.rewards
                      ? _buildRewardsComingSoonView()
                      : _buildMainLeaderboardBody(status, topPlayers),
                ),

                // Sticky Bottom "Your Rank" Panel
                _buildYourRankPanel(playerSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header with back navigation, title, and rules info
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button or Balanced Brand Trophy Badge
          if (widget.showBackButton)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  SoundService.instance.playButtonTap();
                  HapticService.instance.buttonTap();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0A3C).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.50),
                      width: 1.4,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E0A3C).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.40),
                  width: 1.4,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFDE047),
                  size: 22,
                ),
              ),
            ),

          // Centered Title & Brand Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0A3C).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF38BDF8),
                      size: 11,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ZEN FLUIDICS',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFFC084FC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'LEADERBOARD',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0x809333EA),
                      blurRadius: 16,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Info Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openRulesInfoDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0A3C).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.50),
                    width: 1.4,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFE9D5FF),
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

  // Tab switcher
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF140224).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          _buildTabPill(
            tab: LeaderboardTab.global,
            label: 'Global',
            icon: Icons.public_rounded,
          ),
          _buildTabPill(
            tab: LeaderboardTab.rewards,
            label: 'Rewards',
            icon: Icons.card_giftcard_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required LeaderboardTab tab,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != tab) {
            SoundService.instance.playButtonTap();
            HapticService.instance.selectionClick();
            setState(() => _selectedTab = tab);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFF6B21A8)],
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.6,
                  color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Main list content handler based on status
  Widget _buildMainLeaderboardBody(
    LeaderboardStatus status,
    List<LeaderboardEntry> players,
  ) {
    switch (status) {
      case LeaderboardStatus.loading:
        return _buildLoadingState();
      case LeaderboardStatus.error:
        return _buildErrorState();
      case LeaderboardStatus.empty:
        return _buildEmptyState();
      case LeaderboardStatus.offline:
        return _buildOfflineState();
      case LeaderboardStatus.loaded:
        return _buildLoadedList(players);
    }
  }

  // Loaded List with Ranking Banner, Top 3 Podium, and Ranks 4-100
  Widget _buildLoadedList(List<LeaderboardEntry> players) {
    if (players.isEmpty) return _buildEmptyState();

    final topThree = players.take(3).toList();
    final remaining = players.skip(3).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Ranking Information Pill
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0A3C).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC084FC).withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFDE047),
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'TOP 100 PLAYERS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFFE9D5FF),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top-Three Podium (Rank 2 [Left], Rank 1 [Center/Tallest], Rank 3 [Right])
        if (topThree.length >= 3) _buildTopThreePodium(topThree),

        const SizedBox(height: 14),

        // Ranks 4 to 100 List
        for (final entry in remaining)
          _buildPlayerRowCard(entry),
      ],
    );
  }

  // Top-Three Podium Highlight
  Widget _buildTopThreePodium(List<LeaderboardEntry> topThree) {
    final rank1 = topThree[0];
    final rank2 = topThree[1];
    final rank3 = topThree[2];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF140224).withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2: Silver
          Expanded(child: _buildPodiumColumn(rank2, rank: 2, height: 140)),

          // Rank 1: Gold (Center & Tallest)
          Expanded(child: _buildPodiumColumn(rank1, rank: 1, height: 165)),

          // Rank 3: Bronze
          Expanded(child: _buildPodiumColumn(rank3, rank: 3, height: 125)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    LeaderboardEntry entry, {
    required int rank,
    required double height,
  }) {
    final Color badgeColor = rank == 1
        ? const Color(0xFFFDE047) // Gold
        : rank == 2
            ? const Color(0xFFE2E8F0) // Silver
            : const Color(0xFFFB923C); // Bronze

    final Color glowColor = rank == 1
        ? const Color(0xFFEAB308)
        : rank == 2
            ? const Color(0xFF94A3B8)
            : const Color(0xFFEA580C);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown Icon for Rank 1
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFFDE047),
              size: 26,
            ),
          ),

        // Avatar with Glowing Rank Ring
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: rank == 1 ? 58 : 50,
              height: rank == 1 ? 58 : 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [badgeColor, glowColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E0A3C),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: badgeColor,
                      size: rank == 1 ? 32 : 26,
                    ),
                  ),
                ),
              ),
            ),

            // Rank Number Badge Pill
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [badgeColor, glowColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 4),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E0A3C),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Nickname
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Lifetime Coins Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0A3C).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text(
                _formatNumber(entry.lifetimeCoinsEarned),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Row card for Ranks 4 to 100
  Widget _buildPlayerRowCard(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0A3C).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 34,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: entry.rank <= 10
                    ? const Color(0xFFC084FC)
                    : const Color(0xFF8B5CF6),
              ),
            ),
          ),

          // Avatar Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF140224),
              border: Border.all(
                color: const Color(0xFFC084FC).withValues(alpha: 0.35),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: Color(0xFFE9D5FF),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Nickname
          Expanded(
            child: Text(
              entry.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          // Lifetime Coins with Coin Icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                _formatNumber(entry.lifetimeCoinsEarned),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFDE047),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sticky Bottom "Your Rank" Panel
  Widget _buildYourRankPanel(PlayerRankSummary summary) {
    final bool isOffline = _provider.status == LeaderboardStatus.offline;
    final String rankDisplay = isOffline
        ? 'OFFLINE'
        : summary.rank != null
            ? '#${summary.rank}'
            : 'UNRANKED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0A3C),
        border: const Border(
          top: BorderSide(
            color: Color(0xFF38BDF8),
            width: 1.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge Column
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR RANK',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rankDisplay,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Avatar Squircle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF9333EA)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Nickname + Edit Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        summary.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    GestureDetector(
                      onTap: _openNicknameDialog,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF38BDF8),
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  summary.isTop100 ? 'Top 100 Sorter' : 'Climbing Rankings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: Color(0xFFC084FC),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Lifetime Coins Total
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'LIFETIME',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFFDE047),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    _formatNumber(summary.lifetimeCoinsEarned),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFDE047),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Rewards Tab: Coming Soon State
  Widget _buildRewardsComingSoonView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0A3C).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFC084FC).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'SEASON 1 REWARDS',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rank-based seasonal rewards and exclusive bottle caps are arriving soon!\nKeep sorting to secure a spot in the Top 100.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  color: Color(0xFFE9D5FF),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Retrieving global rankings...',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: Color(0xFFE9D5FF),
            ),
          ),
        ],
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Color(0xFFC084FC),
            size: 56,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Rankings Yet',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete puzzles to earn lifetime coins\nand claim the top spot!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: Color(0xFFE9D5FF),
            ),
          ),
        ],
      ),
    );
  }

  // Error State with Retry
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFFB7185),
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'Leaderboard Unavailable',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Could not reach global servers.\nPlease check your connection and retry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                SoundService.instance.playButtonTap();
                HapticService.instance.buttonTap();
                setState(() {
                  _provider.setStatusForTesting(LeaderboardStatus.loaded);
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Offline State with Retry
  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF38BDF8),
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'Offline Mode',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You are playing offline. Puzzles and coins\ncontinue to track locally.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                SoundService.instance.playButtonTap();
                HapticService.instance.buttonTap();
                setState(() {
                  _provider.setStatusForTesting(LeaderboardStatus.loaded);
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RECONNECT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF140224),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subtle ambient bioluminescent background circles
class _AmbientAuraPainter extends CustomPainter {
  final double pulse;
  _AmbientAuraPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9333EA).withValues(alpha: 0.12 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 90, paint);

    paint.color = const Color(0xFF38BDF8).withValues(alpha: 0.08 * pulse);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 110, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientAuraPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
