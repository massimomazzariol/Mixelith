import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/export/domain/export_repository.dart';
import '../../../features/export/domain/export_settings.dart';
import '../../../features/export/providers/export_controller.dart';
import '../../../features/import/domain/working_image_import_service.dart';
import '../../../features/import/providers/working_image_import_controller.dart';
import '../../../features/onnx_models/domain/local_onnx_model.dart';
import '../../../filters/onnx/onnx_style_transfer_engine.dart';
import '../../../media/domain/media_asset.dart';
import '../../../media/domain/media_asset_availability.dart';
import '../../editor/domain/applied_filter.dart';
import '../../editor/domain/working_image.dart';
import '../../editor/providers/editor_controller.dart';
import '../../editor/providers/onnx_source_image_preparer.dart';
import '../data/batch_image_picker.dart';
import '../domain/batch_export_state.dart';
import 'batch_image_picker_provider.dart';

final batchExportControllerProvider =
    NotifierProvider<BatchExportController, BatchExportState>(
      BatchExportController.new,
    );

class BatchExportController extends Notifier<BatchExportState> {
  @override
  BatchExportState build() => const BatchExportState();

  WorkingImageImportService get _importService =>
      ref.read(workingImageImportServiceProvider);

  ExportRepository get _exportRepository => ref.read(exportRepositoryProvider);

  OnnxStyleTransferEngine get _onnxEngine =>
      ref.read(onnxStyleTransferEngineProvider);

  BatchImagePicker get _imagePicker => ref.read(batchImagePickerProvider);

  Future<void> pickImages() async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: BatchExportStatus.idle,
      isPickingPhotos: true,
      errorMessage: null,
    );

    final result = await _imagePicker.pickImages();
    if (result.cancelled) {
      state = state.copyWith(isPickingPhotos: false, errorMessage: null);
      return;
    }

    if (result.items.isEmpty) {
      state = state.copyWith(
        status: result.hasError
            ? BatchExportStatus.error
            : BatchExportStatus.idle,
        isPickingPhotos: false,
        errorMessage: result.hasError
            ? result.errorMessage
            : 'No photos were selected.',
      );
      return;
    }

    final existingIds = state.queue.map((item) => item.asset.id).toSet();
    final additions = [
      for (final image in result.items)
        if (!existingIds.contains(image.id)) _queueItemFromPickedImage(image),
    ];

    state = state.copyWith(
      status: result.hasError
          ? BatchExportStatus.error
          : BatchExportStatus.idle,
      isPickingPhotos: false,
      queue: [...state.queue, ...additions],
      errorMessage: result.errorMessage,
      completedAt: null,
    );
  }

  void toggleAsset(MediaAsset asset) {
    if (state.isBusy) {
      return;
    }
    if (asset.availability == MediaAssetAvailability.unavailableCloudOnly) {
      state = state.copyWith(
        status: BatchExportStatus.error,
        errorMessage:
            'This photo is not available locally. Mixelith cannot batch-export cloud-only photos.',
      );
      return;
    }
    final existingIndex = state.queue.indexWhere(
      (item) => item.asset.id == asset.id,
    );
    if (existingIndex >= 0) {
      removeAsset(asset.id);
      return;
    }
    state = state.copyWith(
      status: BatchExportStatus.idle,
      queue: [
        ...state.queue,
        BatchQueueItem(asset: asset, label: _assetLabel(asset)),
      ],
      errorMessage: null,
      completedAt: null,
    );
  }

  void removeAsset(String assetId) {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(
      status: BatchExportStatus.idle,
      queue: state.queue
          .where((item) => item.asset.id != assetId)
          .toList(growable: false),
      errorMessage: null,
      completedAt: null,
    );
  }

  void clearQueue() {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(
      status: BatchExportStatus.idle,
      queue: const [],
      currentIndex: 0,
      errorMessage: null,
      completedAt: null,
    );
  }

  void selectProceduralStack(List<AppliedFilter> filterStack) {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(
      status: BatchExportStatus.idle,
      mode: filterStack.isEmpty ? null : BatchProcessingMode.procedural,
      filterStack: filterStack,
      selectedOnnxModel: null,
      errorMessage: null,
      completedAt: null,
    );
  }

  void selectOnnxModel(LocalOnnxModel? model) {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(
      status: BatchExportStatus.idle,
      mode: BatchProcessingMode.onnx,
      filterStack: const [],
      selectedOnnxModel: model,
      errorMessage: null,
      completedAt: null,
    );
  }

  Future<void> startBatch({
    ExportSettings settings = const ExportSettings(format: ExportFormat.jpeg),
  }) async {
    if (state.isBusy) {
      return;
    }
    final validationMessage = _validateStart();
    if (validationMessage != null) {
      state = state.copyWith(
        status: BatchExportStatus.error,
        errorMessage: validationMessage,
      );
      return;
    }

    state = state.copyWith(
      status: BatchExportStatus.processing,
      currentIndex: 0,
      startedAt: DateTime.now(),
      completedAt: null,
      errorMessage: null,
      queue: [
        for (final item in state.queue)
          BatchQueueItem(
            asset: item.asset,
            label: item.label,
            sourcePath: item.sourcePath,
            sourceExtension: item.sourceExtension,
          ),
      ],
    );

    for (var index = 0; index < state.queue.length; index++) {
      _updateItem(
        index,
        state.queue[index].copyWith(status: BatchQueueItemStatus.processing),
        currentIndex: index + 1,
      );

      final started = DateTime.now();
      final result = await _processItem(state.queue[index], settings, index);
      final elapsed = DateTime.now().difference(started);
      _updateItem(index, result.copyWith(processingTime: elapsed));
    }

    state = state.copyWith(
      status: BatchExportStatus.completed,
      currentIndex: state.queue.length,
      completedAt: DateTime.now(),
      errorMessage: null,
    );
  }

  String? _validateStart() {
    if (state.queue.isEmpty) {
      return 'Select at least one photo before starting batch export.';
    }
    return switch (state.mode) {
      BatchProcessingMode.procedural =>
        state.filterStack.isEmpty
            ? 'Choose a procedural filter before starting batch export.'
            : null,
      BatchProcessingMode.onnx =>
        state.selectedOnnxModel?.isUsable == true
            ? null
            : 'Import and choose a compatible local ONNX model before starting batch export. This build does not include ONNX models.',
      null =>
        'Choose a procedural filter or compatible local ONNX model before starting batch export.',
    };
  }

  Future<BatchQueueItem> _processItem(
    BatchQueueItem item,
    ExportSettings settings,
    int index,
  ) async {
    try {
      final workingImage = await _importWorkingImage(item);
      final mode = state.mode;
      if (mode == BatchProcessingMode.procedural) {
        final prepared = await ref
            .read(exportServiceProvider)
            .prepareExport(
              workingImage: workingImage,
              filterStack: state.filterStack,
              settings: settings,
            );
        final result = await _exportRepository.saveImage(
          filePath: prepared.path,
          fileName: _batchFileName(index),
          format: prepared.format,
        );
        if (!result.success) {
          return item.copyWith(
            status: BatchQueueItemStatus.failed,
            message: result.batchMessage,
            inputWidth: workingImage.originalWidth,
            inputHeight: workingImage.originalHeight,
            outputWidth: prepared.width,
            outputHeight: prepared.height,
          );
        }
        return item.copyWith(
          status: BatchQueueItemStatus.exported,
          message: result.batchMessage,
          savedPath: result.savedPath,
          inputWidth: workingImage.originalWidth,
          inputHeight: workingImage.originalHeight,
          outputWidth: prepared.width,
          outputHeight: prepared.height,
          usedPreviewSource: prepared.usedPreviewFallback,
        );
      }

      final model = state.selectedOnnxModel;
      if (mode != BatchProcessingMode.onnx ||
          model == null ||
          !model.isUsable) {
        return item.copyWith(
          status: BatchQueueItemStatus.failed,
          message: 'No compatible local ONNX model selected.',
        );
      }

      final source = await ref
          .read(onnxSourceImagePreparerProvider)
          .prepare(workingImage);
      final onnxResult = await _onnxEngine.runLocalModel(
        inputPath: source.path,
        modelPath: model.storedPath,
        modelName: model.displayLabel,
      );
      final inputWidth = onnxResult.inputWidth ?? source.width;
      final inputHeight = onnxResult.inputHeight ?? source.height;
      if (!onnxResult.isSuccess ||
          onnxResult.outputPath == null ||
          onnxResult.outputWidth != inputWidth ||
          onnxResult.outputHeight != inputHeight) {
        return item.copyWith(
          status: BatchQueueItemStatus.failed,
          message: onnxResult.message,
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          outputWidth: onnxResult.outputWidth,
          outputHeight: onnxResult.outputHeight,
          usedPreviewSource: source.usedPreviewSource,
        );
      }

      final prepared = await ref
          .read(exportServiceProvider)
          .prepareOnnxExport(
            onnxOutputPath: onnxResult.outputPath!,
            settings: settings,
            usedPreviewFallback: source.usedPreviewSource,
          );
      final result = await _exportRepository.saveImage(
        filePath: prepared.path,
        fileName: _batchFileName(index),
        format: prepared.format,
      );
      if (!result.success) {
        return item.copyWith(
          status: BatchQueueItemStatus.failed,
          message: result.batchMessage,
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          outputWidth: prepared.width,
          outputHeight: prepared.height,
          usedPreviewSource: source.usedPreviewSource,
        );
      }
      return item.copyWith(
        status: BatchQueueItemStatus.exported,
        message: result.batchMessage,
        savedPath: result.savedPath,
        inputWidth: inputWidth,
        inputHeight: inputHeight,
        outputWidth: prepared.width,
        outputHeight: prepared.height,
        usedPreviewSource: source.usedPreviewSource,
      );
    } on WorkingImageImportException catch (error) {
      return item.copyWith(
        status: BatchQueueItemStatus.failed,
        message: error.message,
      );
    } catch (_) {
      return item.copyWith(
        status: BatchQueueItemStatus.failed,
        message: 'Unable to export this photo.',
      );
    }
  }

  Future<WorkingImage> _importWorkingImage(BatchQueueItem item) {
    final sourcePath = item.sourcePath;
    if (sourcePath != null) {
      return _importService.importFromFilePath(
        sourcePath: sourcePath,
        sourceAssetId: item.asset.id,
        extension: item.sourceExtension,
      );
    }
    return _importService.importAsset(item.asset);
  }

  void _updateItem(int index, BatchQueueItem updated, {int? currentIndex}) {
    final next = [...state.queue];
    next[index] = updated;
    state = state.copyWith(
      queue: next,
      currentIndex: currentIndex ?? state.currentIndex,
    );
  }

  String _batchFileName(int index) {
    return 'mixelith_batch_${DateTime.now().millisecondsSinceEpoch}_${index + 1}';
  }

  String _assetLabel(MediaAsset asset) {
    return 'Photo ${asset.width} x ${asset.height}';
  }

  BatchQueueItem _queueItemFromPickedImage(BatchPickedImage image) {
    final asset = MediaAsset(
      id: image.id,
      width: image.width,
      height: image.height,
      availability: MediaAssetAvailability.localAvailable,
    );
    final displayName = image.displayName.trim();
    return BatchQueueItem(
      asset: asset,
      label: displayName.isEmpty ? _assetLabel(asset) : displayName,
      sourcePath: image.path,
      sourceExtension: image.extension,
    );
  }
}
