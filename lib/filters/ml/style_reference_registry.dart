class StyleReference {
  const StyleReference({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.projectGenerated,
  });

  final String id;
  final String name;
  final String assetPath;
  final bool projectGenerated;
}

class StyleReferenceRegistry {
  const StyleReferenceRegistry();

  static const neonHeat = StyleReference(
    id: 'neon_heat',
    name: 'Neon Heat',
    assetPath: 'assets/style_references/neon_heat_style.png',
    projectGenerated: true,
  );

  static const watercolorWash = StyleReference(
    id: 'watercolor_wash',
    name: 'Watercolor Wash',
    assetPath: 'assets/style_references/watercolor_wash_style.png',
    projectGenerated: true,
  );

  static const mosaicTiles = StyleReference(
    id: 'mosaic_tiles',
    name: 'Mosaic Tiles',
    assetPath: 'assets/style_references/mosaic_tiles_style.png',
    projectGenerated: true,
  );

  static const oilNight = StyleReference(
    id: 'oil_night',
    name: 'Oil Night',
    assetPath: 'assets/style_references/oil_night_style.png',
    projectGenerated: true,
  );

  List<StyleReference> getAll() => const [
    neonHeat,
    watercolorWash,
    mosaicTiles,
    oilNight,
  ];

  StyleReference? getById(String id) {
    for (final reference in getAll()) {
      if (reference.id == id) {
        return reference;
      }
    }
    return null;
  }
}
