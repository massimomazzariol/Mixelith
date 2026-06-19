import '../../../features/export/domain/export_save_result.dart';
import '../../../features/onnx_models/domain/local_onnx_model.dart';
import '../../../media/domain/media_asset.dart';
import '../../editor/domain/applied_filter.dart';

enum BatchProcessingMode { procedural, onnx }

enum BatchExportStatus { idle, processing, completed, error }

enum BatchQueueItemStatus { pending, processing, exported, failed }

class BatchQueueItem {
  const BatchQueueItem({
    required this.asset,
    required this.label,
    this.sourcePath,
    this.sourceExtension,
    this.status = BatchQueueItemStatus.pending,
    this.message,
    this.savedPath,
    this.processingTime,
    this.inputWidth,
    this.inputHeight,
    this.outputWidth,
    this.outputHeight,
    this.usedPreviewSource = false,
  });

  final MediaAsset asset;
  final String label;
  final String? sourcePath;
  final String? sourceExtension;
  final BatchQueueItemStatus status;
  final String? message;
  final String? savedPath;
  final Duration? processingTime;
  final int? inputWidth;
  final int? inputHeight;
  final int? outputWidth;
  final int? outputHeight;
  final bool usedPreviewSource;

  bool get isDone =>
      status == BatchQueueItemStatus.exported ||
      status == BatchQueueItemStatus.failed;

  bool get dimensionsMatch =>
      inputWidth != null &&
      inputHeight != null &&
      inputWidth == outputWidth &&
      inputHeight == outputHeight;

  bool get usesLocalFileSource => sourcePath != null;

  String get sizeLabel {
    if (inputWidth == null || inputHeight == null) {
      return '${asset.width} x ${asset.height}';
    }
    final output = outputWidth != null && outputHeight != null
        ? ' -> $outputWidth x $outputHeight'
        : '';
    return '$inputWidth x $inputHeight$output';
  }

  String get processingTimeLabel {
    final time = processingTime;
    if (time == null) {
      return '';
    }
    return '${time.inMilliseconds} ms';
  }

  BatchQueueItem copyWith({
    BatchQueueItemStatus? status,
    String? message,
    Object? savedPath = _sentinel,
    Object? processingTime = _sentinel,
    Object? inputWidth = _sentinel,
    Object? inputHeight = _sentinel,
    Object? outputWidth = _sentinel,
    Object? outputHeight = _sentinel,
    bool? usedPreviewSource,
  }) {
    return BatchQueueItem(
      asset: asset,
      label: label,
      sourcePath: sourcePath,
      sourceExtension: sourceExtension,
      status: status ?? this.status,
      message: message ?? this.message,
      savedPath: identical(savedPath, _sentinel)
          ? this.savedPath
          : savedPath as String?,
      processingTime: identical(processingTime, _sentinel)
          ? this.processingTime
          : processingTime as Duration?,
      inputWidth: identical(inputWidth, _sentinel)
          ? this.inputWidth
          : inputWidth as int?,
      inputHeight: identical(inputHeight, _sentinel)
          ? this.inputHeight
          : inputHeight as int?,
      outputWidth: identical(outputWidth, _sentinel)
          ? this.outputWidth
          : outputWidth as int?,
      outputHeight: identical(outputHeight, _sentinel)
          ? this.outputHeight
          : outputHeight as int?,
      usedPreviewSource: usedPreviewSource ?? this.usedPreviewSource,
    );
  }
}

class BatchExportState {
  const BatchExportState({
    this.status = BatchExportStatus.idle,
    this.queue = const [],
    this.isPickingPhotos = false,
    this.mode,
    this.filterStack = const [],
    this.selectedOnnxModel,
    this.currentIndex = 0,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  final BatchExportStatus status;
  final List<BatchQueueItem> queue;
  final bool isPickingPhotos;
  final BatchProcessingMode? mode;
  final List<AppliedFilter> filterStack;
  final LocalOnnxModel? selectedOnnxModel;
  final int currentIndex;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  bool get isProcessing => status == BatchExportStatus.processing;

  bool get isBusy => isProcessing || isPickingPhotos;

  bool get hasSelection => queue.isNotEmpty;

  int get totalCount => queue.length;

  int get exportedCount => queue
      .where((item) => item.status == BatchQueueItemStatus.exported)
      .length;

  int get failedCount =>
      queue.where((item) => item.status == BatchQueueItemStatus.failed).length;

  int get completedCount => exportedCount + failedCount;

  bool get hasCompletedBatch => status == BatchExportStatus.completed;

  bool get hasProcessingMode {
    return switch (mode) {
      BatchProcessingMode.procedural => filterStack.isNotEmpty,
      BatchProcessingMode.onnx => selectedOnnxModel?.isUsable == true,
      null => false,
    };
  }

  String get summaryLabel =>
      '$exportedCount exported, $failedCount failed of $totalCount';

  Map<String, int> get selectionOrderByAssetId {
    final order = <String, int>{};
    for (var index = 0; index < queue.length; index++) {
      order[queue[index].asset.id] = index + 1;
    }
    return order;
  }

  BatchExportState copyWith({
    BatchExportStatus? status,
    List<BatchQueueItem>? queue,
    bool? isPickingPhotos,
    Object? mode = _sentinel,
    List<AppliedFilter>? filterStack,
    Object? selectedOnnxModel = _sentinel,
    int? currentIndex,
    Object? startedAt = _sentinel,
    Object? completedAt = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return BatchExportState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      isPickingPhotos: isPickingPhotos ?? this.isPickingPhotos,
      mode: identical(mode, _sentinel)
          ? this.mode
          : mode as BatchProcessingMode?,
      filterStack: filterStack ?? this.filterStack,
      selectedOnnxModel: identical(selectedOnnxModel, _sentinel)
          ? this.selectedOnnxModel
          : selectedOnnxModel as LocalOnnxModel?,
      currentIndex: currentIndex ?? this.currentIndex,
      startedAt: identical(startedAt, _sentinel)
          ? this.startedAt
          : startedAt as DateTime?,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

extension BatchExportSaveResultMessage on ExportSaveResult {
  String get batchMessage {
    return message ?? (success ? 'Saved to gallery.' : 'Unable to save.');
  }
}
