import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/filters/domain/filter_engine_type.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/filters/registry/default_filter_registry.dart';

void main() {
  test('DefaultFilterRegistry exposes original and the five V1 filters', () {
    const registry = DefaultFilterRegistry();

    final presets = registry.getAllPresets();

    expect(presets.map((preset) => preset.id), [
      originalFilterId,
      neonPopFilterId,
      watercolorWashFilterId,
      mosaicTilesFilterId,
      starryOilFilterId,
      graphicPosterFilterId,
    ]);
    expect(registry.getById(starryOilFilterId)?.name, 'Starry Oil');
  });

  test('Default filter presets have unique ids and valid parameters', () {
    const registry = DefaultFilterRegistry();
    final presets = registry.getAllPresets();
    final ids = presets.map((preset) => preset.id).toSet();

    expect(ids, hasLength(presets.length));

    for (final preset in presets) {
      expect(preset.id, isNotEmpty);
      expect(preset.name, isNotEmpty);
      expect(preset.description, isNotEmpty);
      expect(preset.engineType, FilterEngineType.cpu);

      for (final parameter in preset.parameters) {
        expect(parameter.id, isNotEmpty);
        expect(parameter.name, isNotEmpty);
        expect(parameter.minValue, lessThanOrEqualTo(parameter.defaultValue));
        expect(parameter.defaultValue, lessThanOrEqualTo(parameter.maxValue));
      }
    }
  });
}
