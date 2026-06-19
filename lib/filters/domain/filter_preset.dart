import 'filter_category.dart';
import 'filter_engine_type.dart';
import 'filter_parameter.dart';

class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.engineType,
    required this.parameters,
  });

  final String id;
  final String name;
  final String description;
  final FilterCategory category;
  final FilterEngineType engineType;
  final List<FilterParameter> parameters;
}
