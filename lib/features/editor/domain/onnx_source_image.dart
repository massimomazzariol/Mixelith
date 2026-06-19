class OnnxSourceImage {
  const OnnxSourceImage({
    required this.path,
    required this.width,
    required this.height,
    required this.originalWidth,
    required this.originalHeight,
    required this.sourceLabel,
    required this.usedPreviewSource,
    required this.wasDownscaled,
    required this.maxLongSide,
  });

  final String path;
  final int width;
  final int height;
  final int originalWidth;
  final int originalHeight;
  final String sourceLabel;
  final bool usedPreviewSource;
  final bool wasDownscaled;
  final double maxLongSide;

  String get originalSizeLabel => '$originalWidth x $originalHeight';
}
