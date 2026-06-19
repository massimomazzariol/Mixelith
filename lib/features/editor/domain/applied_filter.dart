class AppliedFilter {
  const AppliedFilter({
    required this.presetId,
    this.parameterValues = const {},
    required this.appliedAt,
  });

  final String presetId;
  final Map<String, double> parameterValues;
  final DateTime appliedAt;
}
