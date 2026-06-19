import '../../../filters/engines/image_filter_processor.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../filters/registry/filter_registry.dart';
import '../../../storage/domain/cache_service.dart';
import '../../editor/domain/applied_filter.dart';
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
    required List<AppliedFilter> filterStack,
    required ExportSettings settings,
  }) async {
    if (filterStack.isEmpty) {
      throw const ExportServiceException(
        'Apply at least one filter before exporting.',
      );
    }

    try {
      return await _prepareFromPath(
        sourcePath: workingImage.originalTempPath,
        filterStack: filterStack,
        settings: settings,
        usedPreviewFallback: false,
      );
    } catch (_) {
      return _prepareFromPath(
        sourcePath: workingImage.previewPath,
        filterStack: filterStack,
        settings: settings,
        usedPreviewFallback: true,
      );
    }
  }

  Future<ExportPreparedFile> prepareOnnxExport({
    required String onnxOutputPath,
    required ExportSettings settings,
    required bool usedPreviewFallback,
  }) async {
    try {
      final originalPreset = _filterRegistry.getById(originalFilterId);
      if (originalPreset == null) {
        throw const ExportServiceException(
          'Original export preset is not available.',
        );
      }

      final processed = await processFilterImage(
        inputPath: onnxOutputPath,
        preset: originalPreset,
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
      throw ExportServiceException(
        'Unable to prepare ONNX export image.',
        error,
      );
    }
  }

  Future<ExportPreparedFile> _prepareFromPath({
    required String sourcePath,
    required List<AppliedFilter> filterStack,
    required ExportSettings settings,
    required bool usedPreviewFallback,
  }) async {
    try {
      var inputPath = sourcePath;
      var wasResized = false;
      var outputWidth = 0;
      var outputHeight = 0;
      var outputPath = sourcePath;
      var outputFormat = settings.format;

      for (var index = 0; index < filterStack.length; index++) {
        final appliedFilter = filterStack[index];
        if (appliedFilter.presetId == originalFilterId) {
          continue;
        }

        final preset = _filterRegistry.getById(appliedFilter.presetId);
        if (preset == null) {
          throw const ExportServiceException(
            'Selected filter is not available.',
          );
        }

        final isLastFilter = index == filterStack.length - 1;
        outputFormat = isLastFilter ? settings.format : ExportFormat.jpeg;
        final processed = await processFilterImage(
          inputPath: inputPath,
          preset: preset,
          parameterValues: appliedFilter.parameterValues,
          format: outputFormat,
          jpegQuality: isLastFilter ? settings.jpegQuality : 90,
          maxLongSide: settings.effectiveMaxLongSide,
        );

        outputPath = await _cacheService.writeTempFile(
          processed.bytes,
          isLastFilter ? settings.fileExtension : 'jpg',
        );
        inputPath = outputPath;
        outputWidth = processed.width;
        outputHeight = processed.height;
        wasResized = wasResized || processed.wasDownscaled;
      }

      if (outputPath == sourcePath) {
        throw const ExportServiceException(
          'Apply at least one filter before exporting.',
        );
      }

      return ExportPreparedFile(
        path: outputPath,
        format: outputFormat,
        width: outputWidth,
        height: outputHeight,
        wasResized: wasResized,
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
