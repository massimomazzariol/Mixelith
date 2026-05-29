class CapturedImage {
  const CapturedImage({
    required this.path,
    required this.extension,
    required this.capturedAt,
  });

  final String path;
  final String extension;
  final DateTime capturedAt;
}
