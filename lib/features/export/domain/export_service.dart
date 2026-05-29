import '../../../filters/engines/image_filter_processor.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../filters/registry/filter_registry.dart';
import '../../../storage/domain/cache_service.dart';
import '../../editor/domain/working_image.dart';
import 'export_prepared_file.dart';
import 'export_settings.dart';

class ExportService {
  const ExportService({
    required CacheService cacheService,
    required FilterRegistry filterRegistry,
  }) : _cacheService = cacheService,
       _filterRegistry = filterRegistry;

  final CacheService _cacheService;
  final FilterRegistry _filterRegistry;

  Future<ExportPreparedFile> prepareExport({
    required WorkingImage workingImage,
    required String selectedFilterId,
    required ExportSettings settings,
  }) async {
    final preset =
        _filterRegistry.getById(selectedFilterId) ??
        _filterRegistry.getById(originalFilterId);
    if (preset == null) {
      throw const ExportServiceException('Selected filter is not available.');
    }

    try {
      return await _prepareFromPath(
        sourcePath: workingImage.originalTempPath,
        presetId: selectedFilterId,
        settings: settings,
        usedPreviewFallback: false,
      );
    } catch (_) {
      return _prepareFromPath(
        sourcePath: workingImage.previewPath,
        presetId: selectedFilterId,
        settings: settings,
        usedPreviewFallback: true,
      );
    }
  }

  Future<ExportPreparedFile> _prepareFromPath({
    required String sourcePath,
    required String presetId,
    required ExportSettings settings,
    required bool usedPreviewFallback,
  }) async {
    final preset =
        _filterRegistry.getById(presetId) ??
        _filterRegistry.getById(originalFilterId);
    if (preset == null) {
      throw const ExportServiceException('Selected filter is not available.');
    }

    try {
      final processed = await processFilterImage(
        inputPath: sourcePath,
        preset: preset,
        format: settings.format,
        jpegQuality: settings.jpegQuality,
        maxLongSide: settings.effectiveMaxLongSide,
      );
      final outputPath = await _cacheService.writeTempFile(
        processed.bytes,
        settings.fileExtension,
      );

      return ExportPreparedFile(
        path: outputPath,
        format: settings.format,
        width: processed.width,
        height: processed.height,
        wasResized: processed.wasDownscaled,
        usedPreviewFallback: usedPreviewFallback,
      );
    } catch (error) {
      throw ExportServiceException('Unable to prepare export image.', error);
    }
  }
}

class ExportServiceException implements Exception {
  const ExportServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'ExportServiceException: $message';
    }
    return 'ExportServiceException: $message ($cause)';
  }
}
