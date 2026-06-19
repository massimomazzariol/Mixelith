class WorkingImage {
  const WorkingImage({
    required this.sourceAssetId,
    required this.originalTempPath,
    required this.previewPath,
    required this.originalWidth,
    required this.originalHeight,
    required this.previewWidth,
    required this.previewHeight,
    required this.createdAt,
    required this.wasPreviewDownscaled,
    required this.originalExtension,
  });

  final String sourceAssetId;
  final String originalTempPath;
  final String previewPath;
  final int originalWidth;
  final int originalHeight;
  final int previewWidth;
  final int previewHeight;
  final DateTime createdAt;
  final bool wasPreviewDownscaled;
  final String originalExtension;
}
