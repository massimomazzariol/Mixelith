class HeifExportResult {
  const HeifExportResult({
    required this.path,
    required this.width,
    required this.height,
  });

  factory HeifExportResult.fromMap(Map<Object?, Object?> map) {
    return HeifExportResult(
      path: map['path'] as String? ?? '',
      width: _asInt(map['width']) ?? 0,
      height: _asInt(map['height']) ?? 0,
    );
  }

  final String path;
  final int width;
  final int height;

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

abstract class HeifExportEncoder {
  Future<HeifExportResult> encode({
    required String inputPath,
    required String outputPath,
    required int quality,
  });
}

class HeifExportEncoderException implements Exception {
  const HeifExportEncoderException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'HeifExportEncoderException: $message';
    }
    return 'HeifExportEncoderException: $message ($cause)';
  }
}
