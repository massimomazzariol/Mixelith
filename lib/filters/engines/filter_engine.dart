import '../domain/filter_preset.dart';
import '../domain/filter_result.dart';

abstract class FilterEngine {
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues = const {},
  });
}
