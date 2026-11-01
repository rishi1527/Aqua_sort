import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// BOTTLE CAPS
/// ---------------------------------------------------------------------------
enum CapType {
  none,
  classicCork,
  royalAmethyst,
  prismDiamond,
  rubyHeart,
  imperialEmerald,
  flamingAmber,
  celestialStar,
}

class BottleCapStyle {
  final String id;
  final String name;
  final String description;
  final CapType type;
  final Color gemColor;
  final bool isFree;
  final int requiredLevel;
  final int coinCost;

  const BottleCapStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.gemColor,
    this.isFree = false,
    this.requiredLevel = 1,
    this.coinCost = 0,
  });

  static const List<BottleCapStyle> allCaps = [
    BottleCapStyle(
      id: 'cap_none',
      name: 'No Cap',
      description: 'Open rim without a stopper',
      type: CapType.none,
      gemColor: Colors.transparent,
      isFree: true,
      requiredLevel: 1,
    ),
    BottleCapStyle(
      id: 'cap_cork',
      name: 'Classic Cork',
      description: 'Traditional natural wood cork stopper',
      type: CapType.classicCork,
      gemColor: Color(0xFFC49A6C),
      isFree: true,
      requiredLevel: 1,
    ),
    BottleCapStyle(
      id: 'cap_amethyst',
      name: 'Royal Amethyst',
      description: 'Crown-cut deep purple crystal gem',
      type: CapType.royalAmethyst,
      gemColor: Color(0xFF9D4EDD),
      requiredLevel: 5,
      coinCost: 300,
    ),
    BottleCapStyle(
      id: 'cap_diamond',
      name: 'Prism Diamond',
      description: 'Brilliant faceted cut diamond gem',
      type: CapType.prismDiamond,
      gemColor: Color(0xFF38D9FF),
      requiredLevel: 15,
      coinCost: 500,
    ),
    BottleCapStyle(
      id: 'cap_ruby',
      name: 'Ruby Heart',
      description: 'Luminous scarlet heart-shaped crystal',
      type: CapType.rubyHeart,
      gemColor: Color(0xFFE11D48),
      requiredLevel: 25,
      coinCost: 600,
    ),
    BottleCapStyle(
      id: 'cap_emerald',
      name: 'Imperial Emerald',
      description: 'Regal teardrop emerald jewel',
      type: CapType.imperialEmerald,
      gemColor: Color(0xFF00E676),
      requiredLevel: 35,
      coinCost: 750,
    ),
    BottleCapStyle(
      id: 'cap_amber',
      name: 'Flaming Amber',
      description: 'Warm glowing solar amber jewel',
      type: CapType.flamingAmber,
      gemColor: Color(0xFFFF9100),
      requiredLevel: 45,
      coinCost: 900,
    ),
    BottleCapStyle(
      id: 'cap_star',
      name: 'Celestial Star',
      description: 'Glowing five-point golden star topper',
      type: CapType.celestialStar,
      gemColor: Color(0xFFFBBF24),
      requiredLevel: 50,
      coinCost: 1000,
    ),
  ];

  static BottleCapStyle getById(String id) {
    return allCaps.firstWhere((c) => c.id == id, orElse: () => allCaps.first);
  }
}

/// ---------------------------------------------------------------------------
/// BUBBLE FX
/// ---------------------------------------------------------------------------
enum BubbleFxType {
  none,
  sodaFizz,
  champagneSparkle,
  loveHearts,
  cosmicStars,
  crystalPrism,
  bubbleTrails,
  celestialParticles,
}

class BubbleFxStyle {
  final String id;
  final String name;
  final String description;
  final BubbleFxType type;
  final IconData icon;
  final bool isFree;
  final int requiredLevel;
  final int coinCost;

  const BubbleFxStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    this.isFree = false,
    this.requiredLevel = 1,
    this.coinCost = 0,
  });

  static const List<BubbleFxStyle> allFx = allEffects;
  static const List<BubbleFxStyle> allEffects = [
    BubbleFxStyle(
      id: 'fx_soda_fizz',
      name: 'Soda Fizz',
      description: 'Crisp effervescent micro-bubbles rising through liquid',
      type: BubbleFxType.sodaFizz,
      icon: Icons.bubble_chart_rounded,
      isFree: true,
      requiredLevel: 1,
    ),
    BubbleFxStyle(
      id: 'fx_champagne',
      name: 'Champagne Sparkle',
      description: 'Delicate streaming beads with subtle glint flashes',
      type: BubbleFxType.champagneSparkle,
      icon: Icons.auto_awesome_rounded,
      requiredLevel: 5,
      coinCost: 350,
    ),
    BubbleFxStyle(
      id: 'fx_love_hearts',
      name: 'Love Hearts',
      description: 'Floating pastel romantic hearts gently bobbing upward',
      type: BubbleFxType.loveHearts,
      icon: Icons.favorite_rounded,
      requiredLevel: 15,
      coinCost: 500,
    ),
    BubbleFxStyle(
      id: 'fx_cosmic_stars',
      name: 'Cosmic Stars',
      description: 'Twinkling four-point starlight particles drifting upward',
      type: BubbleFxType.cosmicStars,
      icon: Icons.star_rounded,
      requiredLevel: 25,
      coinCost: 650,
    ),
    BubbleFxStyle(
      id: 'fx_crystal_prism',
      name: 'Crystal Prism',
      description: 'Sharp diamond glints refracting light inside the liquid',
      type: BubbleFxType.crystalPrism,
      icon: Icons.diamond_rounded,
      requiredLevel: 35,
      coinCost: 800,
    ),
    BubbleFxStyle(
      id: 'fx_bubble_trails',
      name: 'Bubble Trails',
      description: 'Continuous spiral bubble columns ascending each pour',
      type: BubbleFxType.bubbleTrails,
      icon: Icons.water_drop_rounded,
      requiredLevel: 45,
      coinCost: 950,
    ),
    BubbleFxStyle(
      id: 'fx_celestial',
      name: 'Celestial Particles',
      description: 'Glowing golden stardust dust swirling gently',
      type: BubbleFxType.celestialParticles,
      icon: Icons.flare_rounded,
      requiredLevel: 50,
      coinCost: 1100,
    ),
    BubbleFxStyle(
      id: 'fx_none',
      name: 'None',
      description: 'Calm still liquid surface without bubble animations',
      type: BubbleFxType.none,
      icon: Icons.block_rounded,
      isFree: true,
      requiredLevel: 1,
    ),
  ];

  static BubbleFxStyle getById(String id) {
    return allEffects.firstWhere(
      (fx) => fx.id == id,
      orElse: () => allEffects.first,
    );
  }
}

/// ---------------------------------------------------------------------------
/// BACKGROUNDS
/// ---------------------------------------------------------------------------
enum BackgroundSceneType {
  purpleCanvas,
  alpineValley,
  dreamTwilight,
  enchantedForest,
  sunsetCastle,
  celestialValley,
  oceanValley,
  doodleDark,
}

class BackgroundStyle {
  final String id;
  final String name;
  final String description;
  final BackgroundSceneType sceneType;
  final List<Color> gradientColors;
  final Color overlayColor;
  final bool isFree;
  final int requiredLevel;
  final int coinCost;

  const BackgroundStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.sceneType,
    required this.gradientColors,
    this.overlayColor = Colors.transparent,
    this.isFree = false,
    this.requiredLevel = 1,
    this.coinCost = 0,
  });

  static const List<BackgroundStyle> allBackgrounds = [
    BackgroundStyle(
      id: 'bg_purple_white',
      name: 'Pure Canvas',
      description: 'AquaSort signature deep radiant dark-green backdrop',
      sceneType: BackgroundSceneType.purpleCanvas,
      gradientColors: [Color(0xFF020806), Color(0xFF04140C)],
      isFree: true,
      requiredLevel: 1,
    ),
    BackgroundStyle(
      id: 'bg_alpine_valley',
      name: 'Alpine Valley',
      description: 'Sunlit mountain valley with lush meadows and peaks',
      sceneType: BackgroundSceneType.alpineValley,
      gradientColors: [Color(0xFFE0F2FE), Color(0xFFBBF7D0)],
      overlayColor: Color(0x10FFFFFF),
      requiredLevel: 4,
      coinCost: 400,
    ),
    BackgroundStyle(
      id: 'bg_dream_twilight',
      name: 'Dream Twilight',
      description: 'Ethereal dusk twilight with floating starlight whispers',
      sceneType: BackgroundSceneType.dreamTwilight,
      gradientColors: [Color(0xFF2E1065), Color(0xFF581C87)],
      overlayColor: Color(0x15FFFFFF),
      requiredLevel: 12,
      coinCost: 550,
    ),
    BackgroundStyle(
      id: 'bg_enchanted_forest',
      name: 'Enchanted Forest',
      description: 'Mystic deep canopy with filtered emerald sunbeams',
      sceneType: BackgroundSceneType.enchantedForest,
      gradientColors: [Color(0xFF064E3B), Color(0xFF022C22)],
      overlayColor: Color(0x18FFFFFF),
      requiredLevel: 20,
      coinCost: 700,
    ),
    BackgroundStyle(
      id: 'bg_sunset_castle',
      name: 'Sunset Castle',
      description: 'Golden hour clouds framing distant castle battlements',
      sceneType: BackgroundSceneType.sunsetCastle,
      gradientColors: [Color(0xFF7C2D12), Color(0xFFC2410C)],
      overlayColor: Color(0x15FFFFFF),
      requiredLevel: 30,
      coinCost: 850,
    ),
    BackgroundStyle(
      id: 'bg_celestial_valley',
      name: 'Celestial Valley',
      description: 'Cosmic star nebula canopy over silent sleeping peaks',
      sceneType: BackgroundSceneType.celestialValley,
      gradientColors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
      overlayColor: Color(0x20FFFFFF),
      requiredLevel: 40,
      coinCost: 1000,
    ),
    BackgroundStyle(
      id: 'bg_ocean_valley',
      name: 'Ocean Valley',
      description: 'Sunlit turquoise shallow reefs with gentle caustic rays',
      sceneType: BackgroundSceneType.oceanValley,
      gradientColors: [Color(0xFF0891B2), Color(0xFF0E7490)],
      overlayColor: Color(0x15FFFFFF),
      requiredLevel: 48,
      coinCost: 1100,
    ),
    BackgroundStyle(
      id: 'bg_doodle_dark',
      name: 'Doodle Dark',
      description: 'Modern slate dark surface with subtle line illustrations',
      sceneType: BackgroundSceneType.doodleDark,
      gradientColors: [Color(0xFF1E1E24), Color(0xFF121216)],
      overlayColor: Color(0x10FFFFFF),
      requiredLevel: 50,
      coinCost: 1200,
    ),
  ];

  static BackgroundStyle getById(String id) {
    return allBackgrounds.firstWhere(
      (bg) => bg.id == id,
      orElse: () => allBackgrounds.first,
    );
  }
}

/// ---------------------------------------------------------------------------
/// COLOR PALETTES
/// ---------------------------------------------------------------------------
class ColorPaletteStyle {
  final String id;
  final String name;
  final String description;
  final List<Color> colors;
  final bool isFree;
  final int requiredLevel;
  final int coinCost;

  const ColorPaletteStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.colors,
    this.isFree = false,
    this.requiredLevel = 1,
    this.coinCost = 0,
  });

  Color getColor(int index) {
    if (colors.isEmpty) return const Color(0xFF38BDF8);
    return colors[index % colors.length];
  }

  static const List<ColorPaletteStyle> allPalettes = [
    ColorPaletteStyle(
      id: 'palette_vibrant_pop',
      name: 'Vibrant Pop',
      description: 'Original bright, saturated high-contrast liquid tones',
      colors: [
        Color(0xFF38BDF8), // 0: Cyan Sky
        Color(0xFFFB7185), // 1: Rose Pink
        Color(0xFFA78BFA), // 2: Lavender Violet
        Color(0xFF34D399), // 3: Emerald Mint
        Color(0xFFFBBF24), // 4: Amber Gold
        Color(0xFFFB923C), // 5: Sunset Orange
        Color(0xFF3B82F6), // 6: Sapphire Blue
        Color(0xFFE11D48), // 7: Ruby Crimson
        Color(0xFFA3E635), // 8: Lime Chartreuse
        Color(0xFFD946EF), // 9: Vivid Magenta
      ],
      isFree: true,
      requiredLevel: 1,
    ),
    ColorPaletteStyle(
      id: 'palette_pastel_dream',
      name: 'Pastel Dream',
      description: 'Gentle creamy French macaron and dessert hues',
      colors: [
        Color(0xFFBAE6FD), // 0: Powder Blue
        Color(0xFFFECDD3), // 1: Baby Pink
        Color(0xFFDDD6FE), // 2: Soft Lilac
        Color(0xFFA7F3D0), // 3: Mint Cream
        Color(0xFFFEF08A), // 4: Butter Yellow
        Color(0xFFFED7AA), // 5: Peach Sorbet
        Color(0xFFBFDBFE), // 6: Periwinkle
        Color(0xFFFDA4AF), // 7: Rose Petal
        Color(0xFFD9F99D), // 8: Pistachio
        Color(0xFFF5D0FE), // 9: Cotton Candy
      ],
      requiredLevel: 6,
      coinCost: 400,
    ),
    ColorPaletteStyle(
      id: 'palette_sunset_glow',
      name: 'Sunset Glow',
      description: 'Radiant dusk warmth with amber, rose, and twilight violet',
      colors: [
        Color(0xFFF59E0B), // 0: Sun Gold
        Color(0xFFEF4444), // 1: Crimson Flare
        Color(0xFF8B5CF6), // 2: Twilight Violet
        Color(0xFFF97316), // 3: Orange Glow
        Color(0xFFEC4899), // 4: Hot Coral
        Color(0xFF6366F1), // 5: Dusk Indigo
        Color(0xFFD97706), // 6: Ochre Warmth
        Color(0xFFBE185D), // 7: Magenta Dusk
        Color(0xFFE11D48), // 8: Deep Rose
        Color(0xFF4F46E5), // 9: Midnight Sky
      ],
      requiredLevel: 14,
      coinCost: 550,
    ),
    ColorPaletteStyle(
      id: 'palette_ocean_wave',
      name: 'Ocean Wave',
      description: 'Deep oceanic currents, aquamarine, seafoam, and cyan',
      colors: [
        Color(0xFF06B6D4), // 0: Cyan Tide
        Color(0xFF0284C7), // 1: Cerulean Sea
        Color(0xFF14B8A6), // 2: Turquoise Wave
        Color(0xFF0D9488), // 3: Deep Teal
        Color(0xFF38BDF8), // 4: Coral Shimmer
        Color(0xFF2563EB), // 5: Marine Blue
        Color(0xFF2DD4BF), // 6: Seafoam Green
        Color(0xFF1D4ED8), // 7: Deep Trench
        Color(0xFF67E8F9), // 8: Glacial Splash
        Color(0xFF0369A1), // 9: Abyssal Blue
      ],
      requiredLevel: 22,
      coinCost: 700,
    ),
    ColorPaletteStyle(
      id: 'palette_cyber_neon',
      name: 'Cyber Neon',
      description: 'Electrifying synthwave neon lasers and arcade glow',
      colors: [
        Color(0xFF00F5FF), // 0: Laser Cyan
        Color(0xFFFF007F), // 1: Hot Neon Pink
        Color(0xFF7B2CBF), // 2: Electric Purple
        Color(0xFF00FF66), // 3: Acid Green
        Color(0xFFFFEE00), // 4: Cyber Yellow
        Color(0xFFFF5400), // 5: Plasma Orange
        Color(0xFF0077FE), // 6: Neon Cobalt
        Color(0xFFFF0055), // 7: Laser Crimson
        Color(0xFF70FF00), // 8: Radioactive Lime
        Color(0xFFCC00FF), // 9: Ultraviolet
      ],
      requiredLevel: 32,
      coinCost: 850,
    ),
    ColorPaletteStyle(
      id: 'palette_forest_earth',
      name: 'Forest Earth',
      description: 'Earthy woodland tones with moss, terra cotta, and bark',
      colors: [
        Color(0xFF4D7C0F), // 0: Olive Moss
        Color(0xFFB45309), // 1: Terra Cotta
        Color(0xFF65A30D), // 2: Leaf Green
        Color(0xFF854D0E), // 3: Warm Cedar
        Color(0xFF15803D), // 4: Pine Forest
        Color(0xFFC2410C), // 5: Clay Rust
        Color(0xFF047857), // 6: Deep Fern
        Color(0xFF78350F), // 7: Roasted Amber
        Color(0xFF166534), // 8: Canopy Green
        Color(0xFF9A3412), // 9: Burnt Sienna
      ],
      requiredLevel: 42,
      coinCost: 950,
    ),
    ColorPaletteStyle(
      id: 'palette_royal_jewel',
      name: 'Royal Jewel',
      description:
          'Opulent regal gemstones: amethyst, ruby, sapphire, and topaz',
      colors: [
        Color(0xFF7C3AED), // 0: Amethyst Crown
        Color(0xFFE11D48), // 1: Ruby Gem
        Color(0xFF2563EB), // 2: Sapphire Relic
        Color(0xFF059669), // 3: Emerald Jewel
        Color(0xFFD97706), // 4: Imperial Topaz
        Color(0xFF9333EA), // 5: Royal Purple
        Color(0xFF0284C7), // 6: Lapis Lazuli
        Color(0xFFBE123C), // 7: Garnet Stone
        Color(0xFF0F766E), // 8: Jade Scepter
        Color(0xFFB45309), // 9: Sovereign Gold
      ],
      requiredLevel: 48,
      coinCost: 1100,
    ),
    ColorPaletteStyle(
      id: 'palette_candy_splash',
      name: 'Candy Splash',
      description: 'Sweet bubblegum, jellybean, and confectionery treats',
      colors: [
        Color(0xFFFF4D94), // 0: Bubblegum Pink
        Color(0xFF38D9FF), // 1: Blue Raspberry
        Color(0xFFFFDD00), // 2: Lemon Drops
        Color(0xFF48DF7B), // 3: Green Apple
        Color(0xFFFF7A00), // 4: Orange Gummy
        Color(0xFFB038FF), // 5: Grape Taffy
        Color(0xFFFF1493), // 6: Strawberry Jam
        Color(0xFF00D2D3), // 7: Mint Candy
        Color(0xFFFF9FF3), // 8: Marshmallow
        Color(0xFF54A0FF), // 9: Cotton Candy
      ],
      requiredLevel: 50,
      coinCost: 1200,
    ),
  ];

  static ColorPaletteStyle getById(String id) {
    return allPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => allPalettes.first,
    );
  }
}
