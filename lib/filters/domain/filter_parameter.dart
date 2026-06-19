class FilterParameter {
  const FilterParameter({
    required this.id,
    required this.name,
    required this.defaultValue,
    required this.minValue,
    required this.maxValue,
  });

  final String id;
  final String name;
  final double defaultValue;
  final double minValue;
  final double maxValue;
}
