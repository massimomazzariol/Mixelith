class ImageNormalizationResult {
  const ImageNormalizationResult({
    required this.originalPath,
    required this.previewPath,
    required this.originalWidth,
    required this.originalHeight,
    required this.previewWidth,
    required this.previewHeight,
    required this.wasPreviewDownscaled,
  });

  factory ImageNormalizationResult.fromMap(Map<Object?, Object?> map) {
    return ImageNormalizationResult(
      originalPath: map['originalPath'] as String? ?? '',
      previewPath: map['previewPath'] as String? ?? '',
      originalWidth: _asInt(map['originalWidth']) ?? 0,
      originalHeight: _asInt(map['originalHeight']) ?? 0,
      previewWidth: _asInt(map['previewWidth']) ?? 0,
      previewHeight: _asInt(map['previewHeight']) ?? 0,
      wasPreviewDownscaled: map['wasPreviewDownscaled'] == true,
    );
  }

  final String originalPath;
  final String previewPath;
  final int originalWidth;
  final int originalHeight;
  final int previewWidth;
  final int previewHeight;
  final bool wasPreviewDownscaled;

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return null;
  }
}

abstract class ImageNormalizer {
  Future<ImageNormalizationResult> normalizeHeif({
    required String sourcePath,
    required int previewMaxLongSide,
  });
}

class ImageNormalizerException implements Exception {
  const ImageNormalizerException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'ImageNormalizerException: $message';
    }
    return 'ImageNormalizerException: $message ($cause)';
  }
}
