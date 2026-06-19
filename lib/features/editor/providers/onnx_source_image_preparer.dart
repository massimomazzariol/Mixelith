import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/policy/image_size_policy.dart';
import '../../../features/export/domain/export_settings.dart';
import '../../../filters/engines/image_filter_processor.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../storage/domain/cache_service.dart';
import '../domain/onnx_source_image.dart';
import '../domain/working_image.dart';

final onnxSourceImagePreparerProvider = Provider<OnnxSourceImagePreparer>(
  (ref) =>
      OnnxSourceImagePreparer(cacheService: ref.watch(cacheServiceProvider)),
);

class OnnxSourceImagePreparer {
  const OnnxSourceImagePreparer({
    required CacheService cacheService,
    this.maxLongSide = ImageSizePolicy.onnxInputMaxLongSide,
  }) : _cacheService = cacheService;

  final CacheService _cacheService;
  final double maxLongSide;

  Future<OnnxSourceImage> prepare(WorkingImage workingImage) async {
    final originalPreset = defaultFilterPresets.firstWhere(
      (preset) => preset.id == originalFilterId,
    );
    final processed = await processFilterImage(
      inputPath: workingImage.originalTempPath,
      preset: originalPreset,
      format: ExportFormat.jpeg,
      jpegQuality: 92,
      maxLongSide: maxLongSide,
    );
    final path = await _cacheService.writeTempFile(processed.bytes, 'jpg');
    return OnnxSourceImage(
      path: path,
      width: processed.width,
      height: processed.height,
      originalWidth: workingImage.originalWidth,
      originalHeight: workingImage.originalHeight,
      sourceLabel: processed.wasDownscaled
          ? 'Full photo ${maxLongSide.round()} max'
          : 'Original',
      usedPreviewSource: false,
      wasDownscaled: processed.wasDownscaled,
      maxLongSide: maxLongSide,
    );
  }
}
