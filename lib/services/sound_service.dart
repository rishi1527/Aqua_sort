import 'package:audioplayers/audioplayers.dart';

import 'game_service.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  factory SoundService() => instance;

  SoundService._internal() {
    _init();
  }

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _pourPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _bottleCompletePlayer = AudioPlayer();

  bool _initialized = false;

  void _init() {
    if (_initialized) return;
    _initialized = true;
    try {
      _uiPlayer.setReleaseMode(ReleaseMode.stop);
      _pourPlayer.setReleaseMode(ReleaseMode.stop);
      _effectPlayer.setReleaseMode(ReleaseMode.stop);
      _bottleCompletePlayer.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
  }

  bool get _enabled => GameService.instance.soundEnabled;
  bool get soundEnabled => GameService.instance.soundEnabled;
  void toggleSound() => GameService.instance.toggleSound();

  Future<void> playBottleSelect() async {
    if (!_enabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(
        AssetSource('audio/bottle_select.wav'),
        volume: 0.75,
      );
    } catch (_) {}
  }

  Future<void> playWaterPour() async {
    if (!_enabled) return;
    try {
      await _pourPlayer.stop();
      await _pourPlayer.play(AssetSource('audio/water_pour.wav'), volume: 0.95);
    } catch (_) {}
  }

  Future<void> playWaterSettle() async {
    if (!_enabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(
        AssetSource('audio/water_settle.wav'),
        volume: 0.85,
      );
    } catch (_) {}
  }

  Future<void> playInvalidMove() async {
    if (!_enabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('audio/invalid_move.wav'), volume: 0.65);
    } catch (_) {}
  }

  Future<void> playBottleComplete() async {
    if (!_enabled) return;
    try {
      await _bottleCompletePlayer.stop();
      await _bottleCompletePlayer.play(
        AssetSource('audio/bottle_complete.wav'),
        volume: 0.90,
      );
    } catch (_) {}
  }

  Future<void> playLevelComplete() async {
    if (!_enabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(
        AssetSource('audio/level_complete.wav'),
        volume: 0.95,
      );
    } catch (_) {}
  }

  Future<void> playButtonTap() async {
    if (!_enabled) return;
    try {
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('audio/button_tap.wav'), volume: 0.55);
    } catch (_) {}
  }

  Future<void> playBottlePop() async {
    await playBottleComplete();
  }

  Future<void> playTubeTap() async {
    await playButtonTap();
  }

  Future<void> playExtraTube() async {
    if (!_enabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(
        AssetSource('audio/extra_tube.wav'),
        volume: 0.8,
      );
    } catch (_) {}
  }

  void dispose() {
    try {
      _uiPlayer.dispose();
      _pourPlayer.dispose();
      _effectPlayer.dispose();
      _bottleCompletePlayer.dispose();
    } catch (_) {}
  }
}
