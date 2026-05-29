import '../../features/export/domain/export_settings.dart';
import '../../storage/domain/cache_service.dart';
import '../domain/filter_engine_type.dart';
import '../domain/filter_preset.dart';
import '../domain/filter_result.dart';
import 'filter_engine.dart';
import 'image_filter_processor.dart';

class CpuFilterEngine implements FilterEngine {
  const CpuFilterEngine({required CacheService cacheService})
    : _cacheService = cacheService;

  final CacheService _cacheService;

  @override
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues = const {},
  }) async {
    final startedAt = DateTime.now();

    try {
      final processed = await processFilterImage(
        inputPath: inputPath,
        preset: preset,
        parameterValues: parameterValues,
      );
      final outputPath = await _cacheService.writeTempFile(
        processed.bytes,
        'jpg',
      );

      return FilterResult(
        outputPath: outputPath,
        width: processed.width,
        height: processed.height,
        mimeType: processed.mimeType,
        processingTime: DateTime.now().difference(startedAt),
        engineUsed: FilterEngineType.cpu,
        wasDownscaled: processed.wasDownscaled,
        outputFormat: ExportFormat.jpeg,
      );
    } catch (error) {
      throw FilterEngineException('Unable to apply filter.', error);
    }
  }
}

class FilterEngineException implements Exception {
  const FilterEngineException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'FilterEngineException: $message';
    }
    return 'FilterEngineException: $message ($cause)';
  }
}
