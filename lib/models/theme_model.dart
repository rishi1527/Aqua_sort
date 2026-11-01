import 'package:flutter/material.dart';

class GameTheme {
  final String id;
  final String name;
  final String description;
  final String assetPath;
  final List<Color> backgroundColors;
  final Color primaryColor;
  final Color accentColor;
  final bool isFree;
  final int requiredLevel;
  final int coinCost;
  final bool isAdReward;

  const GameTheme({
    required this.id,
    required this.name,
    required this.description,
    this.assetPath = '',
    this.backgroundColors = const [Color(0xFFFFFFFF), Color(0xFFF7F3FF)],
    this.primaryColor = const Color(0xFF5B21B6),
    this.accentColor = const Color(0xFF7C3AED),
    this.isFree = true,
    this.requiredLevel = 1,
    this.coinCost = 0,
    this.isAdReward = false,
  });

  Color get primary => primaryColor;
  Color get accent => accentColor;

  static const GameTheme defaultTheme = GameTheme(
    id: 'simple',
    name: 'Simple',
    description: 'Clean, minimal, and modern design with clear contrast',
    assetPath: 'assets/images/themes/simple.png',
    backgroundColors: [Color(0xFF020806), Color(0xFF04140C)],
    primaryColor: Color(0xFF5B21B6),
    accentColor: Color(0xFF7C3AED),
    isFree: true,
    requiredLevel: 1,
    coinCost: 0,
  );

  static const List<GameTheme> allThemes = [
    GameTheme(
      id: 'simple',
      name: 'Simple',
      description: 'Clean, minimal, and modern design with clear contrast',
      assetPath: 'assets/images/themes/simple.png',
      backgroundColors: [Color(0xFF020806), Color(0xFF04140C)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'moonlight_lake',
      name: 'Moonlight Lake',
      description:
          'Serene mountain lake with radiant full moon and lantern piers',
      assetPath: 'assets/images/themes/moonlight_lake.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'cherry_blossom',
      name: 'Cherry Blossom',
      description:
          'Japanese garden with sakura canopy, arched bridge, and pagoda',
      assetPath: 'assets/images/themes/cherry_blossom.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'sunset_beach',
      name: 'Sunset Beach',
      description: 'Tropical sunset over turquoise ocean waves with palm trees',
      assetPath: 'assets/images/themes/sunset_beach.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'sky_realm',
      name: 'Sky Realm',
      description:
          'Floating islands in the sky with castles and cloud waterfalls',
      assetPath: 'assets/images/themes/sky_realm.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'enchanted_forest',
      name: 'Enchanted Forest',
      description:
          'Magical ancient hollow trees with glowing lanterns and sunbeams',
      assetPath: 'assets/images/themes/enchanted_forest.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'ocean_valley',
      name: 'Ocean Valley',
      description:
          'Underwater coral reef with sunbeams, ruins, and vibrant sea life',
      assetPath: 'assets/images/themes/ocean_valley.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'alpine_valley',
      name: 'Alpine Valley',
      description:
          'Cozy winter wonderland with snow cabin, frozen river, and peaks',
      assetPath: 'assets/images/themes/alpine_valley.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'serenity_garden',
      name: 'Serenity Garden',
      description:
          'Peaceful water garden with blooming lotus, pagoda, and waterfall',
      assetPath: 'assets/images/themes/serenity_garden.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'crystal_cave',
      name: 'Crystal Cave',
      description:
          'Luminous purple and cyan crystal cavern with underground stream',
      assetPath: 'assets/images/themes/crystal_cave.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'dream_twilight',
      name: 'Dream Twilight',
      description:
          'Pastel dusk landscape with crescent moon and celestial pagodas',
      assetPath: 'assets/images/themes/dream_twilight.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'autumn_harmony',
      name: 'Autumn Harmony',
      description:
          'Golden autumn landscape with crimson maple trees and wooden bridge',
      assetPath: 'assets/images/themes/autumn_harmony.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'celestial_valley',
      name: 'Celestial Valley',
      description:
          'Floating cosmic islands orbiting a glowing spiral galaxy nebula',
      assetPath: 'assets/images/themes/celestial_valley.png',
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'desert_oasis',
      name: 'Desert Oasis',
      description:
          'Crystal-clear oasis pool with palm trees, dunes, and stone arch',
      assetPath: 'assets/images/themes/desert_oasis.png',
      backgroundColors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'night_city',
      name: 'Night City',
      description:
          'Neon city skyline at night with skyscrapers and bridge reflections',
      assetPath: 'assets/images/themes/night_city.png',
      backgroundColors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'northern_lights',
      name: 'Northern Lights',
      description:
          'Snowy cabin beneath dancing green and teal aurora borealis curtains',
      assetPath: 'assets/images/themes/northern_lights.png',
      backgroundColors: [Color(0xFF0F172A), Color(0xFF134E4A)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'spring_meadow',
      name: 'Spring Meadow',
      description: 'Rolling green meadow with wildflowers and rustic windmill',
      assetPath: 'assets/images/themes/spring_meadow.png',
      backgroundColors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'floating_islands',
      name: 'Floating Islands',
      description:
          'Levitating earth islands connected by rope bridges and waterfalls',
      assetPath: 'assets/images/themes/floating_islands.png',
      backgroundColors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'mystic_library',
      name: 'Mystic Library',
      description:
          'Magical wizard library with towering bookshelves and stained glass',
      assetPath: 'assets/images/themes/mystic_library.png',
      backgroundColors: [Color(0xFF451A03), Color(0xFF78350F)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
    GameTheme(
      id: 'galaxy_space',
      name: 'Galaxy Space',
      description:
          'Deep space vista with a swirling spiral galaxy and distant planets',
      assetPath: 'assets/images/themes/galaxy_space.png',
      backgroundColors: [Color(0xFF09090B), Color(0xFF2E1065)],
      isFree: true,
      requiredLevel: 1,
      coinCost: 0,
    ),
  ];

  static GameTheme getById(String id) {
    if (id == 'royal_castle') {
      return defaultTheme;
    }
    for (final theme in allThemes) {
      if (theme.id == id) return theme;
    }
    return defaultTheme;
  }
}
