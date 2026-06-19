import '../domain/filter_preset.dart';
import '../presets/default_filter_presets.dart';
import 'filter_registry.dart';

class DefaultFilterRegistry implements FilterRegistry {
  const DefaultFilterRegistry();

  @override
  List<FilterPreset> getAllPresets() => defaultFilterPresets;

  @override
  FilterPreset? getById(String id) {
    for (final preset in defaultFilterPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}
