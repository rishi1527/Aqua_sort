import 'dart:math' as math;

import '../models/leaderboard_entry.dart';

/// ---------------------------------------------------------------------------
/// DEVELOPMENT-ONLY MOCK DATA PROVIDER FOR UI VERIFICATION
///
/// STRICT RESTRICTION COMPLIANCE:
/// This provider supplies structured mock players exclusively for Phase 2 UI
/// prototyping and widget testing. It is isolated from production logic and
/// does not connect to Firebase or write to persistent storage.
/// ---------------------------------------------------------------------------
class MockLeaderboardProvider implements ILeaderboardProvider {
  static final MockLeaderboardProvider instance =
      MockLeaderboardProvider._internal();

  factory MockLeaderboardProvider() => instance;

  MockLeaderboardProvider._internal();

  LeaderboardStatus _status = LeaderboardStatus.loaded;
  String _playerNickname = 'AquaMaster#7421';
  String _playerAvatarId = 'avatar_droplet';
  DateTime? _nicknameLastChangedAt;

  @override
  LeaderboardStatus get status => _status;
  String get playerNickname => _playerNickname;
  String get playerAvatarId => _playerAvatarId;
  DateTime? get nicknameLastChangedAt => _nicknameLastChangedAt;

  @override
  void setStatusForTesting(LeaderboardStatus newStatus) {
    _status = newStatus;
  }

  @override
  Future<bool> updateNickname(String newNickname, {String? avatarId}) async {
    final trimmed = newNickname.trim();
    if (trimmed.length < 3 || trimmed.length > 15) {
      return false;
    }
    final validCharacters = RegExp(r'^[a-zA-Z0-9 _]+$');
    if (!validCharacters.hasMatch(trimmed)) {
      return false;
    }
    if (_nicknameLastChangedAt != null) {
      final difference = DateTime.now().difference(_nicknameLastChangedAt!);
      if (difference.inDays < 7) {
        return false;
      }
    }
    _playerNickname = trimmed;
    if (avatarId != null) {
      _playerAvatarId = avatarId;
    }
    _nicknameLastChangedAt = DateTime.now();
    return true;
  }

  void setNicknameLastChangedAtForTesting(DateTime? dt) {
    _nicknameLastChangedAt = dt;
  }

  /// Deterministic top 100 players ranked by lifetimeCoinsEarned descending.
  @override
  List<LeaderboardEntry> getTop100Players() {
    if (_status != LeaderboardStatus.loaded) {
      return const [];
    }

    const List<String> aquaticNames = [
      'CrystalHydra',
      'MarinaSorcerer',
      'AquaAura',
      'TidalSage',
      'HydroPhoenix',
      'ZenCascade',
      'CoralAlchemist',
      'DeepCurrent',
      'OceanWhisper',
      'PrismWaterfall',
      'GlacierMage',
      'VibrantDew',
      'AbyssalRider',
      'SapphireDrift',
      'RiverEmpress',
      'VortexShifter',
      'PureMist',
      'LunarSpring',
      'CelestialTide',
      'AquaPhantom',
      'EmeraldGeyser',
      'BiolumMaster',
      'LagoonDruid',
      'SunkenOracle',
      'WaveSculptor',
      'LiquidAdept',
      'LotusDiver',
      'NeptuneAcolyte',
      'TorrentKnight',
      'FrostSpire',
    ];

    const List<String> avatarIds = [
      'avatar_crown_droplet',
      'avatar_sapphire_gem',
      'avatar_coral_pearl',
      'avatar_droplet',
      'avatar_potion_vial',
      'avatar_water_lotus',
      'avatar_sea_turtle',
      'avatar_ocean_trident',
    ];

    final List<LeaderboardEntry> list = [];

    // Pre-calibrated score descent for 100 players:
    // Rank 1: 4,850 coins
    // Rank 2: 4,620 coins
    // Rank 3: 4,390 coins
    // ... decreasing monotonically down to Rank 100: ~450 coins
    int currentCoins = 4850;

    for (int i = 1; i <= 100; i++) {
      final nameIndex = (i - 1) % aquaticNames.length;
      final cycle = (i - 1) ~/ aquaticNames.length;
      final suffix = cycle > 0 ? '_${cycle + 1}' : '';
      final name = '${aquaticNames[nameIndex]}$suffix';

      final avatar = i == 1
          ? 'avatar_crown_droplet'
          : i == 2
              ? 'avatar_sapphire_gem'
              : i == 3
                  ? 'avatar_coral_pearl'
                  : avatarIds[(i - 1) % avatarIds.length];

      list.add(
        LeaderboardEntry(
          rank: i,
          uid: 'mock_uid_${i.toString().padLeft(3, '0')}',
          nickname: name,
          avatarId: avatar,
          lifetimeCoinsEarned: currentCoins,
          updatedAt: DateTime(2026, 11, 15, 10, 0).subtract(
            Duration(hours: i * 2),
          ),
        ),
      );

      // Decrement strictly monotonically
      final step = i <= 5
          ? 230
          : i <= 20
              ? 110
              : i <= 50
                  ? 55
                  : 22;
      currentCoins = math.max(450, currentCoins - step);
    }

    return list;
  }

  /// Calculates the player's rank summary based on their verified local lifetimeCoins.
  @override
  PlayerRankSummary getPlayerRankSummary(int playerLifetimeCoins) {
    final top100 = getTop100Players();

    // Check if player falls inside Top 100
    int? exactRank;
    bool isTop100 = false;

    if (_status == LeaderboardStatus.loaded && top100.isNotEmpty) {
      for (int i = 0; i < top100.length; i++) {
        if (playerLifetimeCoins >= top100[i].lifetimeCoinsEarned) {
          exactRank = i + 1;
          isTop100 = true;
          break;
        }
      }

      // If lower than rank 100 score:
      if (exactRank == null) {
        // Deterministic extrapolation outside Top 100 for UI simulation
        final lowestCoins = top100.last.lifetimeCoinsEarned;
        final deficit = math.max(0, lowestCoins - playerLifetimeCoins);
        exactRank = 101 + (deficit ~/ 30);
        isTop100 = false;
      }
    } else if (_status == LeaderboardStatus.offline) {
      // Offline mode: rank is undetermined
      exactRank = null;
      isTop100 = false;
    }

    return PlayerRankSummary(
      rank: exactRank,
      nickname: _playerNickname,
      avatarId: _playerAvatarId,
      lifetimeCoinsEarned: playerLifetimeCoins,
      isTop100: isTop100,
      nicknameLastChangedAt: _nicknameLastChangedAt,
    );
  }
}
