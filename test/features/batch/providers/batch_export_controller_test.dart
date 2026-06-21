import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/batch/data/batch_image_picker.dart';
import 'package:mixelith/features/batch/domain/batch_export_state.dart';
import 'package:mixelith/features/batch/providers/batch_export_controller.dart';
import 'package:mixelith/features/batch/providers/batch_image_picker_provider.dart';
import 'package:mixelith/features/editor/domain/applied_filter.dart';
import 'package:mixelith/features/editor/domain/onnx_source_image.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/editor/providers/editor_controller.dart';
import 'package:mixelith/features/editor/providers/onnx_source_image_preparer.dart';
import 'package:mixelith/features/export/domain/export_prepared_file.dart';
import 'package:mixelith/features/export/domain/export_repository.dart';
import 'package:mixelith/features/export/domain/export_save_result.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/features/export/domain/export_service.dart';
import 'package:mixelith/features/export/providers/export_controller.dart';
import 'package:mixelith/features/import/domain/working_image_import_service.dart';
import 'package:mixelith/features/import/providers/working_image_import_controller.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_engine.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_result.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/filters/registry/default_filter_registry.dart';
import 'package:mixelith/media/domain/media_asset.dart';
import 'package:mixelith/media/domain/media_asset_availability.dart';
import 'package:mixelith/media/domain/media_asset_file.dart';
import 'package:mixelith/media/domain/media_permission_status.dart';
import 'package:mixelith/media/domain/media_repository.dart';
import 'package:mixelith/storage/domain/cache_service.dart';

void main() {
  test('selecting multiple media assets creates queue items', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    controller.toggleAsset(_asset('b', width: 24, height: 32));

    final state = container.read(batchExportControllerProvider);
    expect(state.queue.map((item) => item.asset.id), ['a', 'b']);
    expect(state.selectionOrderByAssetId, {'a': 1, 'b': 2});
  });

  test('native picker adds multiple file-backed images to queue', () async {
    final picker = _FakeBatchImagePicker(
      BatchImagePickResult(items: [_picked('picked-a'), _picked('picked-b')]),
    );
    final container = _container(imagePicker: picker);
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    await controller.pickImages();

    final state = container.read(batchExportControllerProvider);
    expect(picker.calls, 1);
    expect(state.queue.map((item) => item.asset.id), ['picked-a', 'picked-b']);
    expect(state.queue.first.sourcePath, '/cache/picked-a.jpg');
    expect(state.queue.first.sourceExtension, 'jpg');
    expect(state.queue.first.usesLocalFileSource, isTrue);
    expect(state.selectionOrderByAssetId, {'picked-a': 1, 'picked-b': 2});
  });

  test(
    'native picker accepts HEIC file-backed images in the batch queue',
    () async {
      final picker = _FakeBatchImagePicker(
        BatchImagePickResult(
          items: [
            _picked('picked-heic', extension: 'heic', mimeType: 'image/heic'),
          ],
        ),
      );
      final container = _container(imagePicker: picker);
      addTearDown(container.dispose);
      final controller = container.read(batchExportControllerProvider.notifier);

      await controller.pickImages();

      final item = container.read(batchExportControllerProvider).queue.single;
      expect(item.sourcePath, '/cache/picked-heic.heic');
      expect(item.sourceExtension, 'heic');
      expect(item.usesLocalFileSource, isTrue);
    },
  );

  test('native picker cancel leaves queue unchanged', () async {
    final picker = _FakeBatchImagePicker(
      const BatchImagePickResult.cancelled(),
    );
    final container = _container(imagePicker: picker);
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    await controller.pickImages();

    final state = container.read(batchExportControllerProvider);
    expect(state.status, BatchExportStatus.idle);
    expect(state.errorMessage, isNull);
    expect(state.queue.map((item) => item.asset.id), ['a']);
  });

  test('native picker unreadable image reports clear error', () async {
    final picker = _FakeBatchImagePicker(
      const BatchImagePickResult.failed(
        'Unable to read image dimensions for broken.jpg.',
      ),
    );
    final container = _container(imagePicker: picker);
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    await controller.pickImages();

    final state = container.read(batchExportControllerProvider);
    expect(state.status, BatchExportStatus.error);
    expect(state.queue, isEmpty);
    expect(state.errorMessage, contains('broken.jpg'));
  });

  test('remove and clear work for native picked images', () async {
    final picker = _FakeBatchImagePicker(
      BatchImagePickResult(items: [_picked('picked-a'), _picked('picked-b')]),
    );
    final container = _container(imagePicker: picker);
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    await controller.pickImages();
    controller.removeAsset('picked-a');

    expect(
      container.read(batchExportControllerProvider).queue.single.asset.id,
      'picked-b',
    );

    controller.clearQueue();

    expect(container.read(batchExportControllerProvider).queue, isEmpty);
  });

  test('removing item works', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    controller.toggleAsset(_asset('b'));
    controller.removeAsset('a');

    expect(
      container.read(batchExportControllerProvider).queue.single.asset.id,
      'b',
    );
  });

  test('batch start blocked when no processing mode is selected', () async {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    await controller.startBatch();

    final state = container.read(batchExportControllerProvider);
    expect(state.status, BatchExportStatus.error);
    expect(state.errorMessage, contains('Choose a procedural filter'));
  });

  test('batch start blocked when ONNX mode has no usable model', () async {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    controller.selectOnnxModel(null);
    await controller.startBatch();

    final state = container.read(batchExportControllerProvider);
    expect(state.status, BatchExportStatus.error);
    expect(state.errorMessage, contains('compatible local ONNX model'));
  });

  test('procedural batch exports sequentially', () async {
    final importService = _FakeImportService();
    final exportService = _FakeExportService();
    final repo = _RecordingExportRepository();
    final container = _container(
      importService: importService,
      exportService: exportService,
      exportRepository: repo,
    );
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    controller.toggleAsset(_asset('b'));
    controller.selectProceduralStack([_filter(neonHeatFilterId)]);
    await controller.startBatch();

    expect(importService.calls, ['a', 'b']);
    expect(exportService.proceduralCalls, ['a', 'b']);
    expect(repo.requests.map((request) => request.fileName), [
      startsWith('mixelith_batch_'),
      startsWith('mixelith_batch_'),
    ]);
    final state = container.read(batchExportControllerProvider);
    expect(state.status, BatchExportStatus.completed);
    expect(state.exportedCount, 2);
    expect(state.failedCount, 0);
  });

  test(
    'procedural batch imports native picked files from cache path',
    () async {
      final importService = _FakeImportService();
      final exportService = _FakeExportService();
      final repo = _RecordingExportRepository();
      final picker = _FakeBatchImagePicker(
        BatchImagePickResult(items: [_picked('picked-a')]),
      );
      final container = _container(
        importService: importService,
        exportService: exportService,
        exportRepository: repo,
        imagePicker: picker,
      );
      addTearDown(container.dispose);
      final controller = container.read(batchExportControllerProvider.notifier);

      await controller.pickImages();
      controller.selectProceduralStack([_filter(neonHeatFilterId)]);
      await controller.startBatch();

      expect(importService.calls, isEmpty);
      expect(importService.fileCalls, ['/cache/picked-a.jpg']);
      expect(exportService.proceduralCalls, ['picked-a']);
      expect(container.read(batchExportControllerProvider).exportedCount, 1);
    },
  );

  test('procedural batch defaults HEIC inputs to HEIC export', () async {
    final importService = _FakeImportService();
    final exportService = _FakeExportService();
    final repo = _RecordingExportRepository();
    final picker = _FakeBatchImagePicker(
      BatchImagePickResult(
        items: [
          _picked('picked-heic', extension: 'heic', mimeType: 'image/heic'),
        ],
      ),
    );
    final container = _container(
      importService: importService,
      exportService: exportService,
      exportRepository: repo,
      imagePicker: picker,
    );
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    await controller.pickImages();
    controller.selectProceduralStack([_filter(neonHeatFilterId)]);
    await controller.startBatch();

    expect(importService.fileCalls, ['/cache/picked-heic.heic']);
    expect(exportService.proceduralFormats.single, ExportFormat.heic);
    expect(repo.requests.single.format, ExportFormat.heic);
  });

  test('ONNX batch uses selected model and full-photo input', () async {
    final importService = _FakeImportService();
    final exportService = _FakeExportService();
    final onnxEngine = _FakeOnnxEngine();
    final sourcePreparer = _FakeOnnxSourceImagePreparer();
    final repo = _RecordingExportRepository();
    final container = _container(
      importService: importService,
      exportService: exportService,
      exportRepository: repo,
      onnxEngine: onnxEngine,
      sourcePreparer: sourcePreparer,
    );
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a', width: 720, height: 1080));
    controller.selectOnnxModel(_model());
    await controller.startBatch();

    expect(sourcePreparer.requests.single.sourceAssetId, 'a');
    expect(onnxEngine.requests.single.inputPath, 'onnx-source-a.jpg');
    expect(onnxEngine.requests.single.modelPath, 'model-a.onnx');
    expect(exportService.onnxCalls.single, 'onnx-a.jpg');
    final item = container.read(batchExportControllerProvider).queue.single;
    expect(item.status, BatchQueueItemStatus.exported);
    expect(item.inputWidth, 720);
    expect(item.inputHeight, 1080);
    expect(item.outputWidth, 720);
    expect(item.outputHeight, 1080);
    expect(item.usedPreviewSource, isFalse);
  });

  test('ONNX batch works with native picked file-backed images', () async {
    final importService = _FakeImportService();
    final exportService = _FakeExportService();
    final onnxEngine = _FakeOnnxEngine();
    final sourcePreparer = _FakeOnnxSourceImagePreparer();
    final repo = _RecordingExportRepository();
    final picker = _FakeBatchImagePicker(
      BatchImagePickResult(items: [_picked('picked-a')]),
    );
    final container = _container(
      importService: importService,
      exportService: exportService,
      exportRepository: repo,
      onnxEngine: onnxEngine,
      imagePicker: picker,
      sourcePreparer: sourcePreparer,
    );
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    await controller.pickImages();
    controller.selectOnnxModel(_model());
    await controller.startBatch();

    expect(importService.fileCalls, ['/cache/picked-a.jpg']);
    expect(
      sourcePreparer.requests.single.originalTempPath,
      '/cache/picked-a.jpg',
    );
    expect(onnxEngine.requests.single.inputPath, 'onnx-source-picked-a.jpg');
    expect(onnxEngine.requests.single.modelPath, 'model-a.onnx');
    expect(exportService.onnxCalls.single, 'onnx-a.jpg');
    expect(container.read(batchExportControllerProvider).exportedCount, 1);
  });

  test('one failed item does not stop the whole batch', () async {
    final importService = _FakeImportService(failIds: {'b'});
    final exportService = _FakeExportService();
    final container = _container(
      importService: importService,
      exportService: exportService,
      exportRepository: _RecordingExportRepository(),
    );
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    controller.toggleAsset(_asset('b'));
    controller.toggleAsset(_asset('c'));
    controller.selectProceduralStack([_filter(popPosterFilterId)]);
    await controller.startBatch();

    final state = container.read(batchExportControllerProvider);
    expect(importService.calls, ['a', 'b', 'c']);
    expect(exportService.proceduralCalls, ['a', 'c']);
    expect(state.exportedCount, 2);
    expect(state.failedCount, 1);
    expect(state.queue[1].status, BatchQueueItemStatus.failed);
  });

  test('repeated start does not trigger parallel processing', () async {
    final gate = Completer<void>();
    final importService = _FakeImportService(gate: gate);
    final container = _container(
      importService: importService,
      exportService: _FakeExportService(),
      exportRepository: _RecordingExportRepository(),
    );
    addTearDown(container.dispose);
    final controller = container.read(batchExportControllerProvider.notifier);

    controller.toggleAsset(_asset('a'));
    controller.toggleAsset(_asset('b'));
    controller.selectProceduralStack([_filter(watercolorFilterId)]);

    final firstRun = controller.startBatch();
    await Future<void>.delayed(Duration.zero);
    await controller.startBatch();
    gate.complete();
    await firstRun;

    expect(importService.calls, ['a', 'b']);
    expect(container.read(batchExportControllerProvider).exportedCount, 2);
  });
}

ProviderContainer _container({
  _FakeImportService? importService,
  _FakeExportService? exportService,
  _RecordingExportRepository? exportRepository,
  _FakeOnnxEngine? onnxEngine,
  BatchImagePicker? imagePicker,
  _FakeOnnxSourceImagePreparer? sourcePreparer,
}) {
  return ProviderContainer(
    overrides: [
      batchImagePickerProvider.overrideWithValue(
        imagePicker ??
            _FakeBatchImagePicker(const BatchImagePickResult.cancelled()),
      ),
      workingImageImportServiceProvider.overrideWithValue(
        importService ?? _FakeImportService(),
      ),
      exportServiceProvider.overrideWithValue(
        exportService ?? _FakeExportService(),
      ),
      exportRepositoryProvider.overrideWithValue(
        exportRepository ?? _RecordingExportRepository(),
      ),
      onnxStyleTransferEngineProvider.overrideWithValue(
        onnxEngine ?? _FakeOnnxEngine(),
      ),
      onnxSourceImagePreparerProvider.overrideWithValue(
        sourcePreparer ?? _FakeOnnxSourceImagePreparer(),
      ),
    ],
  );
}

BatchPickedImage _picked(
  String id, {
  int width = 40,
  int height = 30,
  String extension = 'jpg',
  String? mimeType,
}) {
  return BatchPickedImage(
    id: id,
    path: '/cache/$id.$extension',
    displayName: '$id.$extension',
    extension: extension,
    mimeType: mimeType,
    width: width,
    height: height,
  );
}

MediaAsset _asset(String id, {int width = 32, int height = 24}) {
  return MediaAsset(
    id: id,
    width: width,
    height: height,
    availability: MediaAssetAvailability.localAvailable,
  );
}

AppliedFilter _filter(String presetId) {
  return AppliedFilter(presetId: presetId, appliedAt: DateTime(2026, 6, 9));
}

LocalOnnxModel _model() {
  return LocalOnnxModel(
    id: 'model-a',
    displayLabel: 'Model A',
    storedPath: 'model-a.onnx',
    fileSizeBytes: 123,
    inputShape: const [1, 3, -1, -1],
    outputShape: const [1, 3, -1, -1],
    status: LocalOnnxModelStatus.usable,
    importedAt: DateTime(2026, 6, 9),
  );
}

class _FakeImportService extends WorkingImageImportService {
  _FakeImportService({this.failIds = const {}, this.gate})
    : super(
        mediaRepository: _NoopMediaRepository(),
        cacheService: _NoopCacheService(),
      );

  final Set<String> failIds;
  final Completer<void>? gate;
  final List<String> calls = [];
  final List<String> fileCalls = [];

  @override
  Future<WorkingImage> importAsset(MediaAsset asset) async {
    calls.add(asset.id);
    if (gate != null) {
      await gate!.future;
    }
    if (failIds.contains(asset.id)) {
      throw const WorkingImageImportException(
        WorkingImageImportFailure.sourceUnavailable,
        'Unable to open this photo from local storage.',
      );
    }
    return WorkingImage(
      sourceAssetId: asset.id,
      originalTempPath: 'original-${asset.id}.jpg',
      previewPath: 'preview-${asset.id}.jpg',
      originalWidth: asset.width,
      originalHeight: asset.height,
      previewWidth: asset.width,
      previewHeight: asset.height,
      createdAt: DateTime(2026, 6, 9),
      wasPreviewDownscaled: false,
      originalExtension: 'jpg',
    );
  }

  @override
  Future<WorkingImage> importFromFilePath({
    required String sourcePath,
    required String sourceAssetId,
    String? extension,
  }) async {
    fileCalls.add(sourcePath);
    if (failIds.contains(sourceAssetId)) {
      throw const WorkingImageImportException(
        WorkingImageImportFailure.sourceUnavailable,
        'Unable to open this photo from local storage.',
      );
    }
    return WorkingImage(
      sourceAssetId: sourceAssetId,
      originalTempPath: sourcePath,
      previewPath: 'preview-$sourceAssetId.jpg',
      originalWidth: 40,
      originalHeight: 30,
      previewWidth: 40,
      previewHeight: 30,
      createdAt: DateTime(2026, 6, 9),
      wasPreviewDownscaled: false,
      originalExtension: extension ?? 'jpg',
    );
  }
}

class _FakeBatchImagePicker implements BatchImagePicker {
  _FakeBatchImagePicker(this.result);

  final BatchImagePickResult result;
  int calls = 0;

  @override
  Future<BatchImagePickResult> pickImage() async {
    calls++;
    return result;
  }

  @override
  Future<BatchImagePickResult> pickImages() async {
    calls++;
    return result;
  }
}

class _FakeOnnxSourceImagePreparer extends OnnxSourceImagePreparer {
  _FakeOnnxSourceImagePreparer() : super(cacheService: _NoopCacheService());

  final List<WorkingImage> requests = [];

  @override
  Future<OnnxSourceImage> prepare(WorkingImage workingImage) async {
    requests.add(workingImage);
    return OnnxSourceImage(
      path: 'onnx-source-${workingImage.sourceAssetId}.jpg',
      width: workingImage.originalWidth,
      height: workingImage.originalHeight,
      originalWidth: workingImage.originalWidth,
      originalHeight: workingImage.originalHeight,
      sourceLabel: 'Full photo 2048 max',
      usedPreviewSource: false,
      wasDownscaled: true,
      maxLongSide: 2048,
    );
  }
}

class _FakeExportService extends ExportService {
  _FakeExportService()
    : super(
        cacheService: _NoopCacheService(),
        filterRegistry: const DefaultFilterRegistry(),
      );

  final List<String> proceduralCalls = [];
  final List<ExportFormat> proceduralFormats = [];
  final List<String> onnxCalls = [];

  @override
  Future<ExportPreparedFile> prepareExport({
    required WorkingImage workingImage,
    required List<AppliedFilter> filterStack,
    required ExportSettings settings,
  }) async {
    proceduralCalls.add(workingImage.sourceAssetId);
    proceduralFormats.add(settings.format);
    return ExportPreparedFile(
      path: 'prepared-${workingImage.sourceAssetId}.${settings.fileExtension}',
      format: settings.format,
      width: workingImage.originalWidth,
      height: workingImage.originalHeight,
      wasResized: false,
      usedPreviewFallback: false,
    );
  }

  @override
  Future<ExportPreparedFile> prepareOnnxExport({
    required String onnxOutputPath,
    required ExportSettings settings,
    required bool usedPreviewFallback,
  }) async {
    onnxCalls.add(onnxOutputPath);
    return ExportPreparedFile(
      path: 'prepared-onnx.${settings.fileExtension}',
      format: settings.format,
      width: 720,
      height: 1080,
      wasResized: false,
      usedPreviewFallback: usedPreviewFallback,
    );
  }
}

class _RecordingExportRepository implements ExportRepository {
  final List<_SaveRequest> requests = [];

  @override
  Future<ExportSaveResult> saveImage({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  }) async {
    requests.add(_SaveRequest(filePath, fileName, format));
    return ExportSaveResult.success(savedPath: '/gallery/$fileName');
  }
}

class _SaveRequest {
  const _SaveRequest(this.filePath, this.fileName, this.format);

  final String filePath;
  final String fileName;
  final ExportFormat format;
}

class _FakeOnnxEngine extends OnnxStyleTransferEngine {
  _FakeOnnxEngine() : super(cacheService: _NoopCacheService(), isAndroid: true);

  final List<_OnnxRequest> requests = [];

  @override
  Future<OnnxStyleTransferResult> runLocalModel({
    required String inputPath,
    required String modelPath,
    required String modelName,
  }) async {
    requests.add(_OnnxRequest(inputPath, modelPath, modelName));
    return OnnxStyleTransferResult(
      status: OnnxStyleTransferStatus.success,
      modelName: modelName,
      message: 'ok',
      outputPath: 'onnx-a.jpg',
      inputWidth: 720,
      inputHeight: 1080,
      outputWidth: 720,
      outputHeight: 1080,
      processingTime: const Duration(milliseconds: 10),
    );
  }
}

class _OnnxRequest {
  const _OnnxRequest(this.inputPath, this.modelPath, this.modelName);

  final String inputPath;
  final String modelPath;
  final String modelName;
}

class _NoopCacheService implements CacheService {
  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearExpiredCache() async {}

  @override
  Future<String> copyTempFileFromPath(
    String sourcePath,
    String extension,
  ) async {
    return sourcePath;
  }

  @override
  Future<String> writeTempFile(List<int> bytes, String extension) async {
    return 'temp.$extension';
  }

  @override
  Future<String> reserveTempFilePath(String extension) async {
    return 'reserved.$extension';
  }
}

class _NoopMediaRepository implements MediaRepository {
  @override
  Future<bool> checkPermissions() async => true;

  @override
  Future<List<MediaAsset>> getRecentAssets({
    int page = 0,
    int pageSize = 50,
  }) async {
    return const [];
  }

  @override
  Future<MediaAssetFile?> getOriginalFile(MediaAsset asset) async => null;

  @override
  Future<MediaPermissionStatus> getPermissionStatus() async {
    return MediaPermissionStatus.authorized;
  }

  @override
  Future<Uint8List?> getThumbnailData(
    MediaAsset asset, {
    int width = 200,
    int height = 200,
  }) async {
    return null;
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<MediaPermissionStatus> requestPermissionStatus() async {
    return MediaPermissionStatus.authorized;
  }
}
