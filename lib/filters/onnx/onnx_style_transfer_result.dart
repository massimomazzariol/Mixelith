enum OnnxStyleTransferStatus { unavailable, fixedSizeRejected, success, error }

class OnnxStyleTransferResult {
  const OnnxStyleTransferResult({
    required this.status,
    required this.modelName,
    required this.message,
    this.outputPath,
    this.inputWidth,
    this.inputHeight,
    this.outputWidth,
    this.outputHeight,
    this.processingTime,
    this.inputShape = const [],
    this.outputShape = const [],
  });

  final OnnxStyleTransferStatus status;
  final String modelName;
  final String message;
  final String? outputPath;
  final int? inputWidth;
  final int? inputHeight;
  final int? outputWidth;
  final int? outputHeight;
  final Duration? processingTime;
  final List<int> inputShape;
  final List<int> outputShape;

  bool get isSuccess => status == OnnxStyleTransferStatus.success;

  bool get isFullFrameOutput =>
      inputWidth != null &&
      inputHeight != null &&
      outputWidth == inputWidth &&
      outputHeight == inputHeight;

  factory OnnxStyleTransferResult.unavailable({
    required String modelName,
    required String message,
  }) {
    return OnnxStyleTransferResult(
      status: OnnxStyleTransferStatus.unavailable,
      modelName: modelName,
      message: message,
    );
  }

  factory OnnxStyleTransferResult.error({
    required String modelName,
    required String message,
  }) {
    return OnnxStyleTransferResult(
      status: OnnxStyleTransferStatus.error,
      modelName: modelName,
      message: message,
    );
  }

  factory OnnxStyleTransferResult.fromMap(Map<Object?, Object?> map) {
    final statusValue = map['status'] as String? ?? 'error';
    final status = switch (statusValue) {
      'success' => OnnxStyleTransferStatus.success,
      'unavailable' => OnnxStyleTransferStatus.unavailable,
      'fixed_size_rejected' => OnnxStyleTransferStatus.fixedSizeRejected,
      _ => OnnxStyleTransferStatus.error,
    };

    return OnnxStyleTransferResult(
      status: status,
      modelName: map['modelName'] as String? ?? 'unknown',
      message: map['message'] as String? ?? 'ONNX style transfer finished.',
      outputPath: map['outputPath'] as String?,
      inputWidth: _asInt(map['inputWidth']),
      inputHeight: _asInt(map['inputHeight']),
      outputWidth: _asInt(map['outputWidth']),
      outputHeight: _asInt(map['outputHeight']),
      processingTime: _duration(map['processingTimeMs']),
      inputShape: _shape(map['inputShape']),
      outputShape: _shape(map['outputShape']),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return null;
  }

  static Duration? _duration(Object? value) {
    final milliseconds = _asInt(value);
    if (milliseconds == null) {
      return null;
    }
    return Duration(milliseconds: milliseconds);
  }

  static List<int> _shape(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<num>().map((item) => item.round()).toList();
  }
}
