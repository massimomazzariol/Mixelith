import '../../features/export/domain/export_settings.dart';
import 'filter_engine_type.dart';

class FilterResult {
  const FilterResult({
    this.imageBytes,
    this.outputPath,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.processingTime,
    required this.engineUsed,
    required this.wasDownscaled,
    required this.outputFormat,
  });

  final List<int>? imageBytes;
  final String? outputPath;
  final int width;
  final int height;
  final String mimeType;
  final Duration processingTime;
  final FilterEngineType engineUsed;
  final bool wasDownscaled;
  final ExportFormat outputFormat;
}
