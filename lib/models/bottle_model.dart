enum BottleShape {
  classic,
  crystal,
  potion,
  beaker,
  diamond,
}

class BottleStyle {
  final String id;
  final String name;
  final String description;
  final BottleShape shape;
  final bool isFree;
  final int requiredLevel;
  final bool isAdReward;

  const BottleStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.shape,
    this.isFree = false,
    this.requiredLevel = 1,
    this.isAdReward = false,
  });

  static const List<BottleStyle> allBottles = [
    BottleStyle(
      id: 'classic_flask',
      name: 'Classic Flask',
      description: 'Standard cylindrical glass tube with rounded base',
      shape: BottleShape.classic,
      isFree: true,
      requiredLevel: 1,
    ),
    BottleStyle(
      id: 'crystal_tube',
      name: 'Crystal Prism',
      description: 'Sleek faceted glass with sharp geometric highlights',
      shape: BottleShape.crystal,
      isFree: false,
      requiredLevel: 2,
    ),
    BottleStyle(
      id: 'potion_vial',
      name: 'Elixir Vial',
      description: 'Bulbous alchemical flask with curved waist',
      shape: BottleShape.potion,
      isFree: false,
      requiredLevel: 4,
    ),
    BottleStyle(
      id: 'beaker_glass',
      name: 'Curved Beaker',
      description: 'Modern laboratory beaker with ergonomic flare',
      shape: BottleShape.beaker,
      isFree: false,
      requiredLevel: 7,
    ),
    BottleStyle(
      id: 'diamond_gem',
      name: 'Diamond Relic',
      description: 'Luxury crystalline vessel with gem-cut facets',
      shape: BottleShape.diamond,
      isFree: false,
      requiredLevel: 12,
      isAdReward: true,
    ),
  ];

  static BottleStyle getById(String id) {
    return allBottles.firstWhere(
      (bottle) => bottle.id == id,
      orElse: () => allBottles.first,
    );
  }
}
