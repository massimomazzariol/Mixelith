import 'export_settings.dart';

class ExportPreparedFile {
  const ExportPreparedFile({
    required this.path,
    required this.format,
    required this.width,
    required this.height,
    required this.wasResized,
    required this.usedPreviewFallback,
  });

  final String path;
  final ExportFormat format;
  final int width;
  final int height;
  final bool wasResized;
  final bool usedPreviewFallback;
}
