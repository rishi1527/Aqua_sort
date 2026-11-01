import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/theme_model.dart';
import '../models/bottle_model.dart';
import '../models/customization_models.dart';
import 'level_generator.dart';
import 'storage_stub.dart' if (dart.library.io) 'storage_io.dart';

class GameService extends ChangeNotifier {
  static final GameService instance = GameService._internal();

  factory GameService() => instance;

  Future<void>? _initFuture;

  Future<void> initialize({bool forceReload = false}) {
    if (forceReload || _initFuture == null) {
      _initFuture = _loadFromStorage();
    }
    return _initFuture!;
  }

  GameService._internal() {
    initialize();
  }

  StorageAdapter _storage = getStorageAdapter();

  @visibleForTesting
  void setStorageAdapterForTesting(StorageAdapter adapter) {
    _storage = adapter;
  }

  int _currentLevel = 1;
  final Set<int> _completedLevels = {};
  final Map<int, int> _starsPerLevel = {};
  int _totalMoves = 0;
  int _gamesPlayed = 0;
  int _bestStreak = 0;
  int _currentStreak = 0;
  int _coins = 1250;

  // 1. Themes
  String _selectedThemeId = 'simple';
  final Set<String> _unlockedThemeIds = {
    'purple_white',
    'ocean_deep',
    for (final t in GameTheme.allThemes) t.id,
  };

  // 2. Bottles / Tubes
  String _selectedBottleId = 'classic_tube';
  final Set<String> _unlockedBottleIds = {
    for (final b in BottleStyle.allBottles) b.id,
    'classic_flask',
  };

  // 3. Bottle Caps
  String _selectedCapId = 'cap_none';
  final Set<String> _unlockedCapIds = {'cap_none', 'cap_cork'};

  // 4. Bubble FX
  String _selectedBubbleFxId = 'fx_soda_fizz';
  final Set<String> _unlockedBubbleFxIds = {'fx_soda_fizz', 'fx_none'};

  // 5. Backgrounds
  String _selectedBackgroundId = 'bg_purple_white';
  final Set<String> _unlockedBackgroundIds = {'bg_purple_white'};

  // 6. Color Palettes
  String _selectedPaletteId = 'palette_vibrant_pop';
  final Set<String> _unlockedPaletteIds = {'palette_vibrant_pop'};

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  // Getters
  int get currentLevel => _currentLevel;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  int get completedLevelsCount => _completedLevels.length;
  int get totalMoves => _totalMoves;
  int get gamesPlayed => _gamesPlayed;
  int get bestStreak => _bestStreak;
  int get currentStreak => _currentStreak;
  int get coins => _coins;

  // Themes
  String get selectedThemeId => _selectedThemeId;
  GameTheme get currentTheme => GameTheme.getById(_selectedThemeId);
  Set<String> get unlockedThemeIds => Set.unmodifiable(_unlockedThemeIds);

  // Bottles
  String get selectedBottleId => _selectedBottleId;
  BottleStyle get currentBottle => BottleStyle.getById(_selectedBottleId);
  Set<String> get unlockedBottleIds => Set.unmodifiable(_unlockedBottleIds);

  // Caps
  String get selectedCapId => _selectedCapId;
  BottleCapStyle get currentCap => BottleCapStyle.getById(_selectedCapId);
  Set<String> get unlockedCapIds => Set.unmodifiable(_unlockedCapIds);

  // Bubble FX
  String get selectedBubbleFxId => _selectedBubbleFxId;
  BubbleFxStyle get currentBubbleFx =>
      BubbleFxStyle.getById(_selectedBubbleFxId);
  Set<String> get unlockedBubbleFxIds => Set.unmodifiable(_unlockedBubbleFxIds);

  // Backgrounds
  String get selectedBackgroundId => _selectedBackgroundId;
  BackgroundStyle get currentBackground =>
      BackgroundStyle.getById(_selectedBackgroundId);
  Set<String> get unlockedBackgroundIds =>
      Set.unmodifiable(_unlockedBackgroundIds);

  // Color Palettes
  String get selectedPaletteId => _selectedPaletteId;
  ColorPaletteStyle get currentPalette =>
      ColorPaletteStyle.getById(_selectedPaletteId);
  Set<String> get unlockedPaletteIds => Set.unmodifiable(_unlockedPaletteIds);

  Color getLiquidColor(int index) {
    return currentPalette.getColor(index);
  }

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _saveToStorage();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      _saveToStorage();
      notifyListeners();
    }
  }

  void toggleHaptics() {
    _hapticsEnabled = !_hapticsEnabled;
    _saveToStorage();
    notifyListeners();
  }

  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled != value) {
      _hapticsEnabled = value;
      _saveToStorage();
      notifyListeners();
    }
  }

  // Progress metrics
  static const int maxLevel = 100;

  int get progressInTier {
    if (_completedLevels.length >= maxLevel) return 10;
    return _completedLevels.length % 10;
  }

  double get tierProgressRatio {
    if (_completedLevels.length >= maxLevel) return 1.0;
    return (_completedLevels.length % 10) / 10.0;
  }

  String get progressFraction => '$progressInTier/10';

  static bool debugUnlockAllLevels = false;

  bool get isDebugUnlockAllLevelsEnabled => debugUnlockAllLevels;

  void setDebugUnlockAllLevels(bool enabled) {
    if (debugUnlockAllLevels != enabled) {
      debugUnlockAllLevels = enabled;
      notifyListeners();
    }
  }

  bool isLevelUnlocked(int level) {
    if (level < 1 || level > maxLevel) return false;
    if (debugUnlockAllLevels) return true;
    if (level == 1) return true;
    return _completedLevels.contains(level - 1) || level <= _currentLevel;
  }

  int getStarsForLevel(int level) {
    return _starsPerLevel[level] ?? 0;
  }

  int get totalStars => _starsPerLevel.values.fold(0, (sum, s) => sum + s);

  int get maxPossibleStars => maxLevel * 3;

  void saveBestStars(int level, int stars) {
    if (level < 1 || level > maxLevel) return;
    final int existing = _starsPerLevel[level] ?? 0;
    final int validStars = stars.clamp(0, 3);
    if (validStars > existing) {
      _starsPerLevel[level] = validStars;
      _saveToStorage();
      notifyListeners();
    }
  }

  // State modifiers
  void setSound(bool enabled) {
    _soundEnabled = enabled;
    _saveToStorage();
    notifyListeners();
  }

  void setHaptics(bool enabled) {
    _hapticsEnabled = enabled;
    _saveToStorage();
    notifyListeners();
  }

  void recordGameStarted() {
    _gamesPlayed++;
    _saveToStorage();
    notifyListeners();
  }

  void completeLevel(int levelNumber, int movesUsed, {int? earnedStars}) {
    _completedLevels.add(levelNumber);
    _totalMoves += movesUsed;

    int stars;
    if (earnedStars != null) {
      stars = earnedStars.clamp(0, 3);
    } else {
      final config = LevelGenerator.getLevelConfig(levelNumber);
      if (movesUsed <= config.threeStarThreshold) {
        stars = 3;
      } else if (movesUsed <= config.twoStarThreshold) {
        stars = 2;
      } else {
        stars = 1;
      }
    }

    final int existingStars = _starsPerLevel[levelNumber] ?? 0;
    if (stars > existingStars) {
      _starsPerLevel[levelNumber] = stars;
    }

    _currentStreak++;
    if (_currentStreak > _bestStreak) {
      _bestStreak = _currentStreak;
    }

    if (levelNumber >= _currentLevel) {
      if (levelNumber < maxLevel) {
        _currentLevel = levelNumber + 1;
      } else {
        _currentLevel = maxLevel;
      }
    }

    // Award level completion coins
    _coins += 50;

    _checkAutoUnlocks();
    _saveToStorage();
    notifyListeners();
  }

  // Economy methods
  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins >= amount) {
      _coins -= amount;
      _saveToStorage();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addCoins(int amount) {
    if (amount > 0) {
      _coins += amount;
      _saveToStorage();
      notifyListeners();
    }
  }

  // 1. Theme selection & unlock
  void selectTheme(String themeId) {
    final effectiveThemeId = (themeId == 'royal_castle') ? 'simple' : themeId;
    if (_unlockedThemeIds.contains(effectiveThemeId) ||
        GameTheme.allThemes.any((t) => t.id == effectiveThemeId) ||
        effectiveThemeId == 'purple_white') {
      _unlockedThemeIds.add(effectiveThemeId);
      _selectedThemeId = effectiveThemeId;
      _saveToStorage();
      notifyListeners();
    }
  }

  bool unlockThemeWithCoins(String themeId) {
    _unlockedThemeIds.add(themeId);
    selectTheme(themeId);
    return true;
  }

  // 2. Bottle selection & unlock
  void selectBottle(String bottleId) {
    _unlockedBottleIds.add(bottleId);
    _selectedBottleId = bottleId;
    _saveToStorage();
    notifyListeners();
  }

  bool unlockBottleWithCoins(String bottleId) {
    if (_unlockedBottleIds.contains(bottleId)) return true;
    final bottle = BottleStyle.getById(bottleId);
    if (spendCoins(bottle.coinCost)) {
      _unlockedBottleIds.add(bottleId);
      _selectedBottleId = bottleId;
      _saveToStorage();
      notifyListeners();
      return true;
    }
    return false;
  }

  // 3. Cap selection & unlock
  void selectCap(String capId) {
    if (_unlockedCapIds.contains(capId)) {
      _selectedCapId = capId;
      _saveToStorage();
      notifyListeners();
    }
  }

  bool unlockCapWithCoins(String capId) {
    if (_unlockedCapIds.contains(capId)) return true;
    final cap = BottleCapStyle.getById(capId);
    if (spendCoins(cap.coinCost)) {
      _unlockedCapIds.add(capId);
      _selectedCapId = capId;
      _saveToStorage();
      notifyListeners();
      return true;
    }
    return false;
  }

  // 4. Bubble FX selection & unlock
  void selectBubbleFx(String fxId) {
    if (_unlockedBubbleFxIds.contains(fxId)) {
      _selectedBubbleFxId = fxId;
      _saveToStorage();
      notifyListeners();
    }
  }

  bool unlockBubbleFxWithCoins(String fxId) {
    if (_unlockedBubbleFxIds.contains(fxId)) return true;
    final fx = BubbleFxStyle.getById(fxId);
    if (spendCoins(fx.coinCost)) {
      _unlockedBubbleFxIds.add(fxId);
      _selectedBubbleFxId = fxId;
      _saveToStorage();
      notifyListeners();
      return true;
    }
    return false;
  }

  // 5. Background selection & unlock
  void selectBackground(String bgId) {
    if (_unlockedBackgroundIds.contains(bgId)) {
      _selectedBackgroundId = bgId;
      _saveToStorage();
      notifyListeners();
    }
  }

  bool unlockBackgroundWithCoins(String bgId) {
    if (_unlockedBackgroundIds.contains(bgId)) return true;
    final bg = BackgroundStyle.getById(bgId);
    if (spendCoins(bg.coinCost)) {
      _unlockedBackgroundIds.add(bgId);
      _selectedBackgroundId = bgId;
      _saveToStorage();
      notifyListeners();
      return true;
    }
    return false;
  }

  // 6. Color Palette selection & unlock
  void selectPalette(String paletteId) {
    if (_unlockedPaletteIds.contains(paletteId)) {
      _selectedPaletteId = paletteId;
      _saveToStorage();
      notifyListeners();
    }
  }

  bool unlockPaletteWithCoins(String paletteId) {
    if (_unlockedPaletteIds.contains(paletteId)) return true;
    final p = ColorPaletteStyle.getById(paletteId);
    if (spendCoins(p.coinCost)) {
      _unlockedPaletteIds.add(paletteId);
      _selectedPaletteId = paletteId;
      _saveToStorage();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Ad reward fallback or testing
  bool confirmAdRewardItem({String? themeId, String? bottleId}) {
    bool changed = false;
    if (themeId != null && !_unlockedThemeIds.contains(themeId)) {
      _unlockedThemeIds.add(themeId);
      _selectedThemeId = themeId;
      changed = true;
    }
    if (bottleId != null && !_unlockedBottleIds.contains(bottleId)) {
      _unlockedBottleIds.add(bottleId);
      _selectedBottleId = bottleId;
      changed = true;
    }
    if (changed) {
      _saveToStorage();
      notifyListeners();
    }
    return changed;
  }

  void resetProgress() {
    _currentLevel = 1;
    _completedLevels.clear();
    _starsPerLevel.clear();
    _totalMoves = 0;
    _gamesPlayed = 0;
    _bestStreak = 0;
    _currentStreak = 0;
    _coins = 1250;

    _selectedThemeId = 'simple';
    _unlockedThemeIds.clear();
    _unlockedThemeIds.addAll([
      'purple_white',
      'ocean_deep',
      for (final t in GameTheme.allThemes) t.id,
    ]);

    _selectedBottleId = 'classic_tube';
    _unlockedBottleIds.clear();
    _unlockedBottleIds.addAll(BottleStyle.allBottles.map((b) => b.id));
    _unlockedBottleIds.add('classic_flask');

    _selectedCapId = 'cap_none';
    _unlockedCapIds.clear();
    _unlockedCapIds.addAll(['cap_none', 'cap_cork']);

    _selectedBubbleFxId = 'fx_soda_fizz';
    _unlockedBubbleFxIds.clear();
    _unlockedBubbleFxIds.addAll(['fx_soda_fizz', 'fx_none']);

    _selectedBackgroundId = 'bg_purple_white';
    _unlockedBackgroundIds.clear();
    _unlockedBackgroundIds.add('bg_purple_white');

    _selectedPaletteId = 'palette_vibrant_pop';
    _unlockedPaletteIds.clear();
    _unlockedPaletteIds.add('palette_vibrant_pop');

    _saveToStorage();
    notifyListeners();
  }

  void _checkAutoUnlocks() {
    for (final theme in GameTheme.allThemes) {
      _unlockedThemeIds.add(theme.id);
    }
    for (final bottle in BottleStyle.allBottles) {
      if ((bottle.isFree || !bottle.isAdReward) &&
          _currentLevel >= bottle.requiredLevel) {
        _unlockedBottleIds.add(bottle.id);
      }
    }
    for (final cap in BottleCapStyle.allCaps) {
      if ((cap.isFree || cap.coinCost == 0) &&
          _currentLevel >= cap.requiredLevel) {
        _unlockedCapIds.add(cap.id);
      }
    }
    for (final fx in BubbleFxStyle.allEffects) {
      if ((fx.isFree || fx.coinCost == 0) &&
          _currentLevel >= fx.requiredLevel) {
        _unlockedBubbleFxIds.add(fx.id);
      }
    }
    for (final bg in BackgroundStyle.allBackgrounds) {
      if ((bg.isFree || bg.coinCost == 0) &&
          _currentLevel >= bg.requiredLevel) {
        _unlockedBackgroundIds.add(bg.id);
      }
    }
    for (final p in ColorPaletteStyle.allPalettes) {
      if ((p.isFree || p.coinCost == 0) && _currentLevel >= p.requiredLevel) {
        _unlockedPaletteIds.add(p.id);
      }
    }
  }

  Future<void> _saveToStorage() async {
    final Map<String, dynamic> data = {
      'currentLevel': _currentLevel,
      'completedLevels': _completedLevels.toList(),
      'starsPerLevel': _starsPerLevel.map((k, v) => MapEntry(k.toString(), v)),
      'totalMoves': _totalMoves,
      'gamesPlayed': _gamesPlayed,
      'bestStreak': _bestStreak,
      'currentStreak': _currentStreak,
      'coins': _coins,
      'selectedThemeId': _selectedThemeId,
      'unlockedThemeIds': _unlockedThemeIds.toList(),
      'selectedBottleId': _selectedBottleId,
      'unlockedBottleIds': _unlockedBottleIds.toList(),
      'selectedCapId': _selectedCapId,
      'unlockedCapIds': _unlockedCapIds.toList(),
      'selectedBubbleFxId': _selectedBubbleFxId,
      'unlockedBubbleFxIds': _unlockedBubbleFxIds.toList(),
      'selectedBackgroundId': _selectedBackgroundId,
      'unlockedBackgroundIds': _unlockedBackgroundIds.toList(),
      'selectedPaletteId': _selectedPaletteId,
      'unlockedPaletteIds': _unlockedPaletteIds.toList(),
      'soundEnabled': _soundEnabled,
      'hapticsEnabled': _hapticsEnabled,
    };
    await _storage.save(jsonEncode(data));
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.load();
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _currentLevel = ((data['currentLevel'] as num?)?.toInt() ?? 1).clamp(
          1,
          maxLevel,
        );
        if (data['completedLevels'] is List) {
          _completedLevels.clear();
          for (final item in (data['completedLevels'] as List)) {
            _completedLevels.add((item as num).toInt());
          }
        }
        if (data['starsPerLevel'] is Map) {
          _starsPerLevel.clear();
          (data['starsPerLevel'] as Map).forEach((k, v) {
            final key = int.tryParse(k.toString());
            if (key != null) {
              _starsPerLevel[key] = (v as num).toInt();
            }
          });
        }
        _totalMoves = (data['totalMoves'] as num?)?.toInt() ?? 0;
        _gamesPlayed = (data['gamesPlayed'] as num?)?.toInt() ?? 0;
        _bestStreak = (data['bestStreak'] as num?)?.toInt() ?? 0;
        _currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
        _coins = (data['coins'] as num?)?.toInt() ?? 1250;

        bool needsSave = false;
        final loadedThemeId = data['selectedThemeId'] as String? ?? 'simple';
        if (loadedThemeId == 'royal_castle') {
          _selectedThemeId = 'simple';
          needsSave = true;
        } else {
          _selectedThemeId = loadedThemeId;
        }
        if (!GameTheme.allThemes.any((t) => t.id == _selectedThemeId) &&
            _selectedThemeId != 'purple_white' &&
            _selectedThemeId != 'ocean_deep') {
          _selectedThemeId = 'simple';
          needsSave = true;
        }
        if (data['unlockedThemeIds'] is List) {
          for (final t in (data['unlockedThemeIds'] as List)) {
            final tid = t.toString();
            if (tid == 'royal_castle') {
              needsSave = true;
            } else {
              _unlockedThemeIds.add(tid);
            }
          }
        }
        _unlockedThemeIds.remove('royal_castle');
        _unlockedThemeIds.addAll(['purple_white', 'ocean_deep']);
        _unlockedThemeIds.addAll(GameTheme.allThemes.map((t) => t.id));

        final loadedBottleId =
            data['selectedBottleId'] as String? ?? 'classic_tube';
        _selectedBottleId = (loadedBottleId == 'classic_flask')
            ? 'classic_tube'
            : loadedBottleId;
        if (data['unlockedBottleIds'] is List) {
          for (final b in (data['unlockedBottleIds'] as List)) {
            _unlockedBottleIds.add(b.toString());
          }
        }
        _unlockedBottleIds.addAll(BottleStyle.allBottles.map((b) => b.id));
        _unlockedBottleIds.add('classic_flask');

        _selectedCapId = data['selectedCapId'] as String? ?? 'cap_none';
        if (data['unlockedCapIds'] is List) {
          for (final c in (data['unlockedCapIds'] as List)) {
            _unlockedCapIds.add(c.toString());
          }
        }
        _unlockedCapIds.addAll(['cap_none', 'cap_cork']);

        _selectedBubbleFxId =
            data['selectedBubbleFxId'] as String? ?? 'fx_soda_fizz';
        if (data['unlockedBubbleFxIds'] is List) {
          for (final f in (data['unlockedBubbleFxIds'] as List)) {
            _unlockedBubbleFxIds.add(f.toString());
          }
        }
        _unlockedBubbleFxIds.addAll(['fx_soda_fizz', 'fx_none']);

        _selectedBackgroundId =
            data['selectedBackgroundId'] as String? ?? 'bg_purple_white';
        if (data['unlockedBackgroundIds'] is List) {
          for (final bg in (data['unlockedBackgroundIds'] as List)) {
            _unlockedBackgroundIds.add(bg.toString());
          }
        }
        _unlockedBackgroundIds.add('bg_purple_white');

        _selectedPaletteId =
            data['selectedPaletteId'] as String? ?? 'palette_vibrant_pop';
        if (data['unlockedPaletteIds'] is List) {
          for (final p in (data['unlockedPaletteIds'] as List)) {
            _unlockedPaletteIds.add(p.toString());
          }
        }
        _unlockedPaletteIds.add('palette_vibrant_pop');

        _soundEnabled = data['soundEnabled'] as bool? ?? true;
        _hapticsEnabled = data['hapticsEnabled'] as bool? ?? true;

        _checkAutoUnlocks();
        if (needsSave) {
          await _saveToStorage();
        }
        notifyListeners();
      }
    } catch (_) {
      // Default to initial state on error
    }
  }
}
