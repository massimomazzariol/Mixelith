import '../../../core/policy/image_size_policy.dart';

enum ExportFormat { jpeg, png }

extension ExportFormatDetails on ExportFormat {
  String get fileExtension => switch (this) {
    ExportFormat.jpeg => 'jpg',
    ExportFormat.png => 'png',
  };

  String get mimeType => switch (this) {
    ExportFormat.jpeg => 'image/jpeg',
    ExportFormat.png => 'image/png',
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
