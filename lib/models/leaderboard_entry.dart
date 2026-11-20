import 'package:flutter/foundation.dart';

/// Represents the active tab on the Leaderboard screen.
enum LeaderboardTab {
  global,
  rewards,
}

/// Represents the operational UI status of the Leaderboard.
enum LeaderboardStatus {
  loading,
  loaded,
  empty,
  error,
  offline,
}

/// Represents a single public player ranking row.
@immutable
class LeaderboardEntry {
  final int rank;
  final String uid;
  final String nickname;
  final String avatarId;
  final int lifetimeCoinsEarned;
  final DateTime? updatedAt;

  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.nickname,
    required this.avatarId,
    required this.lifetimeCoinsEarned,
    this.updatedAt,
  });

  bool get isTopThree => rank >= 1 && rank <= 3;
  bool get isFirst => rank == 1;
  bool get isSecond => rank == 2;
  bool get isThird => rank == 3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          uid == other.uid &&
          nickname == other.nickname &&
          lifetimeCoinsEarned == other.lifetimeCoinsEarned;

  @override
  int get hashCode =>
      rank.hashCode ^
      uid.hashCode ^
      nickname.hashCode ^
      lifetimeCoinsEarned.hashCode;
}

/// Represents the current local player's ranking profile.
@immutable
class PlayerRankSummary {
  final int? rank;
  final String nickname;
  final String avatarId;
  final int lifetimeCoinsEarned;
  final bool isTop100;
  final DateTime? nicknameLastChangedAt;

  const PlayerRankSummary({
    this.rank,
    required this.nickname,
    required this.avatarId,
    required this.lifetimeCoinsEarned,
    this.isTop100 = false,
    this.nicknameLastChangedAt,
  });

  bool get canChangeNickname {
    if (nicknameLastChangedAt == null) return true;
    final diff = DateTime.now().difference(nicknameLastChangedAt!);
    return diff.inDays >= 7;
  }

  int get daysUntilNicknameChange {
    if (nicknameLastChangedAt == null) return 0;
    final diff = DateTime.now().difference(nicknameLastChangedAt!);
    final remaining = 7 - diff.inDays;
    return remaining > 0 ? remaining : 0;
  }
}

/// Common contract for both real Firebase LeaderboardService and development MockLeaderboardProvider.
abstract interface class ILeaderboardProvider {
  LeaderboardStatus get status;
  List<LeaderboardEntry> getTop100Players();
  PlayerRankSummary getPlayerRankSummary(int localLifetimeCoins);
  Future<bool> updateNickname(String newNickname, {String? avatarId});
  void setStatusForTesting(LeaderboardStatus newStatus);
}

