import '../../../core/policy/image_size_policy.dart';
import '../../../media/domain/image_source_format.dart';

enum ExportFormat { jpeg, png, heic, heif }

extension ExportFormatDetails on ExportFormat {
  String get fileExtension => switch (this) {
    ExportFormat.jpeg => 'jpg',
    ExportFormat.png => 'png',
    ExportFormat.heic => 'heic',
    ExportFormat.heif => 'heif',
  };

  String get mimeType => switch (this) {
    ExportFormat.jpeg => 'image/jpeg',
    ExportFormat.png => 'image/png',
    ExportFormat.heic => 'image/heic',
    ExportFormat.heif => 'image/heif',
  };

  String get label => switch (this) {
    ExportFormat.jpeg => 'JPEG',
    ExportFormat.png => 'PNG',
    ExportFormat.heic => 'HEIC',
    ExportFormat.heif => 'HEIF',
  };

  bool get requiresHeifEncoder {
    return this == ExportFormat.heic || this == ExportFormat.heif;
  }
}

ExportFormat defaultExportFormatForSourceFormat(ImageSourceFormat format) {
  return switch (format) {
    ImageSourceFormat.png => ExportFormat.png,
    ImageSourceFormat.heic => ExportFormat.heic,
    ImageSourceFormat.heif => ExportFormat.heif,
    _ => ExportFormat.jpeg,
  };
}

class ExportSettings {
  const ExportSettings({
    required this.format,
    this.jpegQuality = 90,
    this.maxLongSide,
    this.removeMetadata = true,
  });

  final ExportFormat format;
  final int jpegQuality;
  final double? maxLongSide;
  final bool removeMetadata;

  double get effectiveMaxLongSide =>
      maxLongSide ?? ImageSizePolicy.exportMaxLongSideDefault;

  String get fileExtension => format.fileExtension;

  String get mimeType => format.mimeType;

  bool shouldWarnForDimensions(int width, int height) {
    return width >= ImageSizePolicy.warningThreshold ||
        height >= ImageSizePolicy.warningThreshold;
  }

  ExportSettings copyWith({
    ExportFormat? format,
    int? jpegQuality,
    double? maxLongSide,
    bool? removeMetadata,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      maxLongSide: maxLongSide ?? this.maxLongSide,
      removeMetadata: removeMetadata ?? this.removeMetadata,
    );
  }
}
