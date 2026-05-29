import 'export_save_result.dart';
import 'export_settings.dart';

enum ExportStatus { idle, preparing, exporting, success, error }

class ExportState {
  const ExportState({
    required this.status,
    required this.settings,
    this.result,
    this.message,
    this.outputWidth,
    this.outputHeight,
    this.wasResized = false,
    this.usedPreviewFallback = false,
  });

  const ExportState.idle()
    : status = ExportStatus.idle,
      settings = const ExportSettings(format: ExportFormat.jpeg),
      result = null,
      message = null,
      outputWidth = null,
      outputHeight = null,
      wasResized = false,
      usedPreviewFallback = false;

  final ExportStatus status;
  final ExportSettings settings;
  final ExportSaveResult? result;
  final String? message;
  final int? outputWidth;
  final int? outputHeight;
  final bool wasResized;
  final bool usedPreviewFallback;

  bool get isBusy =>
      status == ExportStatus.preparing || status == ExportStatus.exporting;

  ExportState copyWith({
    ExportStatus? status,
    ExportSettings? settings,
    Object? result = _sentinel,
    Object? message = _sentinel,
    Object? outputWidth = _sentinel,
    Object? outputHeight = _sentinel,
    bool? wasResized,
    bool? usedPreviewFallback,
  }) {
    return ExportState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      result: identical(result, _sentinel)
          ? this.result
          : result as ExportSaveResult?,
      message: identical(message, _sentinel)
          ? this.message
          : message as String?,
      outputWidth: identical(outputWidth, _sentinel)
          ? this.outputWidth
          : outputWidth as int?,
      outputHeight: identical(outputHeight, _sentinel)
          ? this.outputHeight
          : outputHeight as int?,
      wasResized: wasResized ?? this.wasResized,
      usedPreviewFallback: usedPreviewFallback ?? this.usedPreviewFallback,
    );
  }
}

const Object _sentinel = Object();
