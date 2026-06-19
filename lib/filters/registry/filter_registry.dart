import '../domain/filter_preset.dart';

abstract class FilterRegistry {
  List<FilterPreset> getAllPresets();

  FilterPreset? getById(String id);
}
