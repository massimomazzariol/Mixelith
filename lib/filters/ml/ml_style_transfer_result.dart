enum MlStyleTransferStatus { success, unavailable, unsupported, error }

class MlStyleTransferResult {
  const MlStyleTransferResult({
    required this.status,
    this.outputPath,
    this.width,
    this.height,
    this.message,
    this.tensorSummary,
    this.processingTime,
  });

  factory MlStyleTransferResult.success({
    required String outputPath,
    required int width,
    required int height,
    required Duration processingTime,
    String? tensorSummary,
  }) {
    return MlStyleTransferResult(
      status: MlStyleTransferStatus.success,
      outputPath: outputPath,
      width: width,
      height: height,
      processingTime: processingTime,
      tensorSummary: tensorSummary,
    );
  }

  factory MlStyleTransferResult.unavailable(String message) {
    return MlStyleTransferResult(
      status: MlStyleTransferStatus.unavailable,
      message: message,
    );
  }

  factory MlStyleTransferResult.unsupported({
    required String message,
    String? tensorSummary,
  }) {
    return MlStyleTransferResult(
      status: MlStyleTransferStatus.unsupported,
      message: message,
      tensorSummary: tensorSummary,
    );
  }

  factory MlStyleTransferResult.error(String message) {
    return MlStyleTransferResult(
      status: MlStyleTransferStatus.error,
      message: message,
    );
  }

  final MlStyleTransferStatus status;
  final String? outputPath;
  final int? width;
  final int? height;
  final String? message;
  final String? tensorSummary;
  final Duration? processingTime;

  bool get isSuccess => status == MlStyleTransferStatus.success;
}
