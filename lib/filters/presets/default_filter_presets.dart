import '../domain/filter_category.dart';
import '../domain/filter_engine_type.dart';
import '../domain/filter_parameter.dart';
import '../domain/filter_preset.dart';

const String originalFilterId = 'original';
const String neonPopFilterId = 'neon_pop';
const String watercolorWashFilterId = 'watercolor_wash';
const String mosaicTilesFilterId = 'mosaic_tiles';
const String starryOilFilterId = 'starry_oil';
const String graphicPosterFilterId = 'graphic_poster';

const List<FilterPreset> defaultFilterPresets = [
  FilterPreset(
    id: originalFilterId,
    name: 'Original',
    description: 'Preview without an artistic filter.',
    category: FilterCategory.graphic,
    engineType: FilterEngineType.cpu,
    parameters: [],
  ),
  FilterPreset(
    id: neonPopFilterId,
    name: 'Neon Pop',
    description: 'Saturated cyber-neon color with luminous contrast.',
    category: FilterCategory.colorPop,
    engineType: FilterEngineType.cpu,
    parameters: [
      FilterParameter(
        id: 'intensity',
        name: 'Intensity',
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
      ),
      FilterParameter(
        id: 'saturation',
        name: 'Saturation',
        defaultValue: 1.6,
        minValue: 0.5,
        maxValue: 2.0,
      ),
      FilterParameter(
        id: 'contrast',
        name: 'Contrast',
        defaultValue: 1.25,
        minValue: 0.5,
        maxValue: 2.0,
      ),
    ],
  ),
  FilterPreset(
    id: watercolorWashFilterId,
    name: 'Watercolor Wash',
    description: 'Soft washed color with reduced detail and gentle light.',
    category: FilterCategory.painting,
    engineType: FilterEngineType.cpu,
    parameters: [
      FilterParameter(
        id: 'intensity',
        name: 'Intensity',
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
      ),
      FilterParameter(
        id: 'softness',
        name: 'Softness',
        defaultValue: 0.7,
        minValue: 0.0,
        maxValue: 1.0,
      ),
      FilterParameter(
        id: 'color_levels',
        name: 'Color levels',
        defaultValue: 7.0,
        minValue: 3.0,
        maxValue: 12.0,
      ),
    ],
  ),
  FilterPreset(
    id: mosaicTilesFilterId,
    name: 'Mosaic Tiles',
    description: 'Blocky tile averaging with simplified color fields.',
    category: FilterCategory.mosaic,
    engineType: FilterEngineType.cpu,
    parameters: [
      FilterParameter(
        id: 'tile_size',
        name: 'Tile size',
        defaultValue: 18.0,
        minValue: 6.0,
        maxValue: 48.0,
      ),
      FilterParameter(
        id: 'color_depth',
        name: 'Color depth',
        defaultValue: 8.0,
        minValue: 2.0,
        maxValue: 24.0,
      ),
      FilterParameter(
        id: 'intensity',
        name: 'Intensity',
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
      ),
    ],
  ),
  FilterPreset(
    id: starryOilFilterId,
    name: 'Starry Oil',
    description: 'Painterly oil color with graphic texture and bright edges.',
    category: FilterCategory.painting,
    engineType: FilterEngineType.cpu,
    parameters: [
      FilterParameter(
        id: 'intensity',
        name: 'Intensity',
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
      ),
      FilterParameter(
        id: 'brush_detail',
        name: 'Brush detail',
        defaultValue: 0.7,
        minValue: 0.0,
        maxValue: 1.0,
      ),
      FilterParameter(
        id: 'color_boost',
        name: 'Color boost',
        defaultValue: 1.4,
        minValue: 1.0,
        maxValue: 2.0,
      ),
    ],
  ),
  FilterPreset(
    id: graphicPosterFilterId,
    name: 'Graphic Poster',
    description: 'High-contrast pop poster print with strong color areas.',
    category: FilterCategory.poster,
    engineType: FilterEngineType.cpu,
    parameters: [
      FilterParameter(
        id: 'levels',
        name: 'Levels',
        defaultValue: 5.0,
        minValue: 2.0,
        maxValue: 8.0,
      ),
      FilterParameter(
        id: 'contrast',
        name: 'Contrast',
        defaultValue: 1.35,
        minValue: 0.8,
        maxValue: 1.8,
      ),
      FilterParameter(
        id: 'edge_detail',
        name: 'Edge detail',
        defaultValue: 0.45,
        minValue: 0.0,
        maxValue: 1.0,
      ),
    ],
  ),
];
