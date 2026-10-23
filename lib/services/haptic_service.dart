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

  Future<void> levelComplete() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.lightImpact();
    } catch (_) {}
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
