import 'package:flutter/foundation.dart';

/// Possible results from a rewarded ad presentation attempt.
enum RewardedAdResult {
  /// User watched the ad completely and earned the reward.
  rewardEarned,

  /// User dismissed or skipped the ad before completion.
  skipped,

  /// Ad failed to load or display.
  failed,

  /// No ad available (privacy-safe default in production).
  unavailable,
}

/// Abstract provider interface for rewarded advertisements.
///
/// Ensures strict privacy separation and zero tracking by default.
abstract class RewardedAdProvider {
  /// Whether an ad is currently ready and available to show.
  bool get isAdAvailable;

  /// Shows the rewarded ad and returns the outcome.
  Future<RewardedAdResult> showRewardedAd();
}

/// Default privacy-safe placeholder provider.
///
/// In production, no real ad SDK is initialized and no data is collected.
class PlaceholderRewardedAdProvider implements RewardedAdProvider {
  const PlaceholderRewardedAdProvider();

  @override
  bool get isAdAvailable => false;

  @override
  Future<RewardedAdResult> showRewardedAd() async {
    // Explicitly unavailable in production until approved.
    return RewardedAdResult.unavailable;
  }
}

/// Central singleton service managing rewarded ad interactions.
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  RewardedAdProvider _provider = const PlaceholderRewardedAdProvider();

  /// Whether rewarded ads are currently available.
  bool get isAdAvailable => _provider.isAdAvailable;

  /// Displays a rewarded ad for 60 seconds of extra time.
  Future<RewardedAdResult> showExtraTimeAd() async {
    return await _provider.showRewardedAd();
  }

  /// Sets a custom provider for testing purposes.
  @visibleForTesting
  void setProviderForTesting(RewardedAdProvider provider) {
    _provider = provider;
  }

  /// Resets the provider back to the privacy-preserving default.
  @visibleForTesting
  void resetProvider() {
    _provider = const PlaceholderRewardedAdProvider();
  }
}

