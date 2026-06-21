import 'export_settings.dart';

class ExportPreparedFile {
  const ExportPreparedFile({
    required this.path,
    required this.format,
    required this.width,
    required this.height,
    required this.wasResized,
    required this.usedPreviewFallback,
    this.fallbackPath,
    this.fallbackFormat,
    this.fallbackMessage,
  });

  final String path;
  final ExportFormat format;
  final int width;
  final int height;
  final bool wasResized;
  final bool usedPreviewFallback;
  final String? fallbackPath;
  final ExportFormat? fallbackFormat;
  final String? fallbackMessage;

  bool get hasFallback => fallbackPath != null && fallbackFormat != null;
}
