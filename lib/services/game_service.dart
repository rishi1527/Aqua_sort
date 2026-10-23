import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/theme_model.dart';
import '../models/bottle_model.dart';
import 'storage_stub.dart'
    if (dart.library.io) 'storage_io.dart';

class GameService extends ChangeNotifier {
  static final GameService instance = GameService._internal();

  factory GameService() => instance;

  GameService._internal() {
    _loadFromStorage();
  }

  final StorageAdapter _storage = getStorageAdapter();

  int _currentLevel = 1;
  final Set<int> _completedLevels = {};
  final Map<int, int> _starsPerLevel = {};
  int _totalMoves = 0;
  int _gamesPlayed = 0;
  int _bestStreak = 0;
  int _currentStreak = 0;

  String _selectedThemeId = 'ocean_deep';
  final Set<String> _unlockedThemeIds = {'ocean_deep'};

  String _selectedBottleId = 'classic_flask';
  final Set<String> _unlockedBottleIds = {'classic_flask'};

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

  String get selectedThemeId => _selectedThemeId;
  GameTheme get currentTheme => GameTheme.getById(_selectedThemeId);
  Set<String> get unlockedThemeIds => Set.unmodifiable(_unlockedThemeIds);

  String get selectedBottleId => _selectedBottleId;
  BottleStyle get currentBottle => BottleStyle.getById(_selectedBottleId);
  Set<String> get unlockedBottleIds => Set.unmodifiable(_unlockedBottleIds);

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  // Progress metrics
  int get progressInTier => _completedLevels.length % 10;
  double get tierProgressRatio => (_completedLevels.length % 10) / 10.0;
  String get progressFraction => '$progressInTier/10';

  bool isLevelUnlocked(int level) {
    if (level <= 1) return true;
    return _completedLevels.contains(level - 1) || level <= _currentLevel;
  }

  int getStarsForLevel(int level) {
    return _starsPerLevel[level] ?? 0;
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

  void completeLevel(int levelNumber, int movesUsed) {
    _completedLevels.add(levelNumber);
    _totalMoves += movesUsed;

    // Star rating based on efficiency:
    // <= 14 moves: 3 stars, <= 22 moves: 2 stars, else 1 star
    int stars = 3;
    if (movesUsed > 22) {
      stars = 1;
    } else if (movesUsed > 14) {
      stars = 2;
    }
    _starsPerLevel[levelNumber] = stars;

    _currentStreak++;
    if (_currentStreak > _bestStreak) {
      _bestStreak = _currentStreak;
    }

    if (levelNumber >= _currentLevel) {
      _currentLevel = levelNumber + 1;
    }

    _checkAutoUnlocks();
    _saveToStorage();
    notifyListeners();
  }

  void selectTheme(String themeId) {
    if (_unlockedThemeIds.contains(themeId)) {
      _selectedThemeId = themeId;
      _saveToStorage();
      notifyListeners();
    }
  }

  void selectBottle(String bottleId) {
    if (_unlockedBottleIds.contains(bottleId)) {
      _selectedBottleId = bottleId;
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Only call this if an external rewarded ad SDK confirms reward
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
    _selectedThemeId = 'ocean_deep';
    _unlockedThemeIds.clear();
    _unlockedThemeIds.add('ocean_deep');
    _selectedBottleId = 'classic_flask';
    _unlockedBottleIds.clear();
    _unlockedBottleIds.add('classic_flask');
    _saveToStorage();
    notifyListeners();
  }

  void _checkAutoUnlocks() {
    for (final theme in GameTheme.allThemes) {
      if (!theme.isAdReward && _currentLevel >= theme.requiredLevel) {
        _unlockedThemeIds.add(theme.id);
      }
    }
    for (final bottle in BottleStyle.allBottles) {
      if (!bottle.isAdReward && _currentLevel >= bottle.requiredLevel) {
        _unlockedBottleIds.add(bottle.id);
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
      'selectedThemeId': _selectedThemeId,
      'unlockedThemeIds': _unlockedThemeIds.toList(),
      'selectedBottleId': _selectedBottleId,
      'unlockedBottleIds': _unlockedBottleIds.toList(),
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
        _currentLevel = (data['currentLevel'] as num?)?.toInt() ?? 1;
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

        _selectedThemeId = data['selectedThemeId'] as String? ?? 'ocean_deep';
        if (data['unlockedThemeIds'] is List) {
          for (final t in (data['unlockedThemeIds'] as List)) {
            _unlockedThemeIds.add(t.toString());
          }
        }

        _selectedBottleId = data['selectedBottleId'] as String? ?? 'classic_flask';
        if (data['unlockedBottleIds'] is List) {
          for (final b in (data['unlockedBottleIds'] as List)) {
            _unlockedBottleIds.add(b.toString());
          }
        }

        _soundEnabled = data['soundEnabled'] as bool? ?? true;
        _hapticsEnabled = data['hapticsEnabled'] as bool? ?? true;

        _checkAutoUnlocks();
        notifyListeners();
      }
    } catch (_) {
      // Default to initial state on error
    }
  }
}
