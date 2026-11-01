import 'package:flutter/services.dart';

import 'game_service.dart';

class HapticService {
  static final HapticService instance = HapticService._internal();
  factory HapticService() => instance;
  HapticService._internal();

  bool get _enabled => GameService.instance.hapticsEnabled;

  Future<void> bottleSelect() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> selectionClick() async {
    await bottleSelect();
  }

  Future<void> pourStart() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> pourComplete() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> invalidMove() async {
    if (!_enabled) return;
    try {
      // First firm impact
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_enabled) return;
      // Second firm impact after brief pause
      await HapticFeedback.heavyImpact();
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  DateTime? _lastBottleCompleteTime;

  Future<void> bottleComplete() async {
    if (!_enabled) return;
    // Deduplication guard: ignore calls within 600ms to guarantee single trigger per completion event
    final now = DateTime.now();
    if (_lastBottleCompleteTime != null &&
        now.difference(_lastBottleCompleteTime!).inMilliseconds < 600) {
      return;
    }
    _lastBottleCompleteTime = now;

    // Fire strong multi-pulse asynchronously so it doesn't block UI frame renders
    _playBottleCompleteHaptics();
  }

  Future<void> _playBottleCompleteHaptics() async {
    try {
      // Strong, snappy 2-pulse haptic pattern (punchy arcade tactile feedback)
      // Pulse 1: Strong heavy impact
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 70));
      if (!_enabled) return;

      // Pulse 2: Second firm impact for a crisp double-pulse
      await HapticFeedback.heavyImpact();
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  DateTime? _lastLevelCompleteTime;

  Future<void> levelComplete() async {
    if (!_enabled) return;
    // Deduplication guard: ignore calls within 1500ms to guarantee single trigger
    final now = DateTime.now();
    if (_lastLevelCompleteTime != null &&
        now.difference(_lastLevelCompleteTime!).inMilliseconds < 1500) {
      return;
    }
    _lastLevelCompleteTime = now;

    // Fire asynchronously so it doesn't block UI or state transitions
    _playLevelCompleteHaptics();
  }

  Future<void> _celebratoryPulse({bool strong = true}) async {
    if (!_enabled) return;
    try {
      if (strong) {
        // Combines heavy impact and vibrate where supported for a distinct,
        // strong celebratory tactile punch that is much more noticeable than
        // a single bottle completion.
        await HapticFeedback.heavyImpact();
        await HapticFeedback.vibrate();
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  Future<void> _playLevelCompleteHaptics() async {
    try {
      // 5-pulse celebratory fanfare rhythm (total ~410ms)
      // Pulse 1: Strong opening burst
      await _celebratoryPulse(strong: true);
      await Future.delayed(const Duration(milliseconds: 105));
      if (!_enabled) return;

      // Pulse 2: Quick energetic follow-up
      await _celebratoryPulse(strong: true);
      await Future.delayed(const Duration(milliseconds: 115));
      if (!_enabled) return;

      // Pulse 3: Mid syncopated beat
      await _celebratoryPulse(strong: false);
      await Future.delayed(const Duration(milliseconds: 85));
      if (!_enabled) return;

      // Pulse 4: Climax strong pulse
      await _celebratoryPulse(strong: true);
      await Future.delayed(const Duration(milliseconds: 105));
      if (!_enabled) return;

      // Pulse 5: Grand finale exclamation
      await _celebratoryPulse(strong: true);
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  Future<void> buttonTap() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> extraTube() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
