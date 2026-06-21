import '../../../filters/engines/image_filter_processor.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../filters/registry/filter_registry.dart';
import '../../../storage/domain/cache_service.dart';
import '../../editor/domain/applied_filter.dart';
import '../../editor/domain/working_image.dart';
import 'export_prepared_file.dart';
import 'export_settings.dart';
import 'heif_export_encoder.dart';

class ExportService {
  const ExportService({
    required CacheService cacheService,
    required FilterRegistry filterRegistry,
    HeifExportEncoder? heifExportEncoder,
  }) : _cacheService = cacheService,
       _filterRegistry = filterRegistry,
       _heifExportEncoder = heifExportEncoder;

  final CacheService _cacheService;
  final FilterRegistry _filterRegistry;
  final HeifExportEncoder? _heifExportEncoder;

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

      final processingFormat = settings.format.requiresHeifEncoder
          ? ExportFormat.jpeg
          : settings.format;
      final processed = await processFilterImage(
        inputPath: onnxOutputPath,
        preset: originalPreset,
        format: processingFormat,
        jpegQuality: settings.jpegQuality,
        maxLongSide: settings.effectiveMaxLongSide,
      );
      final outputPath = await _cacheService.writeTempFile(
        processed.bytes,
        processingFormat.fileExtension,
      );

      if (settings.format.requiresHeifEncoder) {
        return _prepareHeifOutput(
          jpegPath: outputPath,
          requestedFormat: settings.format,
          width: processed.width,
          height: processed.height,
          wasResized: processed.wasDownscaled,
          usedPreviewFallback: usedPreviewFallback,
          quality: settings.jpegQuality,
        );
      }

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
        outputFormat = isLastFilter && !settings.format.requiresHeifEncoder
            ? settings.format
            : ExportFormat.jpeg;
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
          outputFormat.fileExtension,
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

      if (settings.format.requiresHeifEncoder) {
        return _prepareHeifOutput(
          jpegPath: outputPath,
          requestedFormat: settings.format,
          width: outputWidth,
          height: outputHeight,
          wasResized: wasResized,
          usedPreviewFallback: usedPreviewFallback,
          quality: settings.jpegQuality,
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

  Future<ExportPreparedFile> _prepareHeifOutput({
    required String jpegPath,
    required ExportFormat requestedFormat,
    required int width,
    required int height,
    required bool wasResized,
    required bool usedPreviewFallback,
    required int quality,
  }) async {
    final fallbackMessage = _heifFallbackMessage(requestedFormat);
    final encoder = _heifExportEncoder;
    if (encoder == null) {
      return ExportPreparedFile(
        path: jpegPath,
        format: ExportFormat.jpeg,
        width: width,
        height: height,
        wasResized: wasResized,
        usedPreviewFallback: usedPreviewFallback,
        fallbackMessage: fallbackMessage,
      );
    }

    try {
      final heifPath = await _cacheService.reserveTempFilePath(
        requestedFormat.fileExtension,
      );
      final encoded = await encoder.encode(
        inputPath: jpegPath,
        outputPath: heifPath,
        quality: quality,
      );
      return ExportPreparedFile(
        path: encoded.path,
        format: requestedFormat,
        width: encoded.width,
        height: encoded.height,
        wasResized: wasResized,
        usedPreviewFallback: usedPreviewFallback,
        fallbackPath: jpegPath,
        fallbackFormat: ExportFormat.jpeg,
        fallbackMessage: fallbackMessage,
      );
    } catch (_) {
      return ExportPreparedFile(
        path: jpegPath,
        format: ExportFormat.jpeg,
        width: width,
        height: height,
        wasResized: wasResized,
        usedPreviewFallback: usedPreviewFallback,
        fallbackMessage: fallbackMessage,
      );
    }
  }

  String _heifFallbackMessage(ExportFormat requestedFormat) {
    return 'This photo was exported as JPEG because ${requestedFormat.label} export is not available on this device.';
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
