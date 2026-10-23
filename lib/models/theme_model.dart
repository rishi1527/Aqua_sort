import 'package:flutter/material.dart';

class GameTheme {
  final String id;
  final String name;
  final String description;
  final List<Color> backgroundColors;
  final Color primaryColor;
  final Color accentColor;
  final bool isFree;
  final int requiredLevel;
  final bool isAdReward;

  const GameTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColors,
    required this.primaryColor,
    required this.accentColor,
    this.isFree = false,
    this.requiredLevel = 1,
    this.isAdReward = false,
  });

  static const List<GameTheme> allThemes = [
    GameTheme(
      id: 'ocean_deep',
      name: 'Ocean Deep',
      description: 'Original deep ocean ambiance with aqua glow',
      backgroundColors: [Color(0xFF071A33), Color(0xFF041224), Color(0xFF030D1B)],
      primaryColor: Color(0xFF087ECA),
      accentColor: Color(0xFF38D9FF),
      isFree: true,
      requiredLevel: 1,
    ),
    GameTheme(
      id: 'neon_cyber',
      name: 'Neon Cyber',
      description: 'Futuristic synthwave glow and electric violet',
      backgroundColors: [Color(0xFF0D0320), Color(0xFF160838), Color(0xFF070114)],
      primaryColor: Color(0xFF9D4EDD),
      accentColor: Color(0xFF00E5FF),
      isFree: false,
      requiredLevel: 3,
    ),
    GameTheme(
      id: 'emerald_lagoon',
      name: 'Emerald Lagoon',
      description: 'Lush tropical water with bioluminescent glow',
      backgroundColors: [Color(0xFF021B1A), Color(0xFF032624), Color(0xFF010F0E)],
      primaryColor: Color(0xFF00897B),
      accentColor: Color(0xFF00E676),
      isFree: false,
      requiredLevel: 5,
    ),
    GameTheme(
      id: 'sunset_glow',
      name: 'Sunset Glow',
      description: 'Warm dusk light reflecting over calm waves',
      backgroundColors: [Color(0xFF260D1A), Color(0xFF381428), Color(0xFF14050D)],
      primaryColor: Color(0xFFE02475),
      accentColor: Color(0xFFFF9100),
      isFree: false,
      requiredLevel: 8,
    ),
    GameTheme(
      id: 'midnight_abyss',
      name: 'Midnight Abyss',
      description: 'Deep oceanic abyss with celestial highlights',
      backgroundColors: [Color(0xFF060919), Color(0xFF0C132E), Color(0xFF03050F)],
      primaryColor: Color(0xFF4361EE),
      accentColor: Color(0xFFB5179E),
      isFree: false,
      requiredLevel: 10,
    ),
    GameTheme(
      id: 'arctic_glacier',
      name: 'Arctic Glacier',
      description: 'Pristine frozen ice cavern with crystal water',
      backgroundColors: [Color(0xFF0A1E33), Color(0xFF102D4A), Color(0xFF051221)],
      primaryColor: Color(0xFF0284C7),
      accentColor: Color(0xFF67E8F9),
      isFree: false,
      requiredLevel: 15,
      isAdReward: true,
    ),
  ];

  static GameTheme getById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => allThemes.first,
    );
  }
}
