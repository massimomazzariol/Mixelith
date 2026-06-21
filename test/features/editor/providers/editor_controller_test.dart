import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/editor/domain/editor_state.dart';
import 'package:mixelith/features/editor/domain/onnx_source_image.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/editor/providers/editor_controller.dart';
import 'package:mixelith/features/editor/providers/onnx_source_image_preparer.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_engine.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_result.dart';
import 'package:mixelith/filters/domain/filter_engine_type.dart';
import 'package:mixelith/filters/domain/filter_preset.dart';
import 'package:mixelith/filters/domain/filter_result.dart';
import 'package:mixelith/filters/engines/filter_engine.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/storage/domain/cache_service.dart';

void main() {
  test(
    'EditorController adds filters in order and applies them cumulatively',
    () async {
      final engine = _ImmediateFilterEngine();
      final container = ProviderContainer(
        overrides: [filterEngineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);

      final controller = container.read(editorControllerProvider.notifier);
      controller.open(_workingImage());

      await controller.selectFilter(neonHeatFilterId);
      await controller.selectFilter(watercolorFilterId);

      final state = container.read(editorControllerProvider);
      expect(state.filterStack.map((filter) => filter.presetId), [
        neonHeatFilterId,
        watercolorFilterId,
      ]);
      expect(state.selectedFilterId, watercolorFilterId);
      expect(state.filteredPreviewPath, engine.requests.last.outputPath);
      expect(engine.requests.map((request) => request.preset.id), [
        neonHeatFilterId,
        neonHeatFilterId,
        watercolorFilterId,
      ]);
      expect(engine.requests[0].inputPath, 'preview.jpg');
      expect(engine.requests[1].inputPath, 'preview.jpg');
      expect(engine.requests[2].inputPath, engine.requests[1].outputPath);
    },
  );

  test(
    'EditorController replaces a consecutive duplicate filter tap',
    () async {
      final engine = _ImmediateFilterEngine();
      final container = ProviderContainer(
        overrides: [filterEngineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);

      final controller = container.read(editorControllerProvider.notifier);
      controller.open(_workingImage());

      await controller.selectFilter(neonHeatFilterId);
      await controller.selectFilter(neonHeatFilterId);

      final state = container.read(editorControllerProvider);
      expect(state.filterStack.map((filter) => filter.presetId), [
        neonHeatFilterId,
      ]);
      expect(state.visiblePreviewPath, engine.requests.last.outputPath);
    },
  );

  test(
    'EditorController clears stack through Clear all and Original',
    () async {
      final engine = _ImmediateFilterEngine();
      final container = ProviderContainer(
        overrides: [filterEngineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);

      final controller = container.read(editorControllerProvider.notifier);
      controller.open(_workingImage());

      await controller.selectFilter(popPosterFilterId);
      controller.clearAllFilters();

      var state = container.read(editorControllerProvider);
      expect(state.filterStack, isEmpty);
      expect(state.selectedFilterId, originalFilterId);
      expect(state.filteredPreviewPath, isNull);
      expect(state.visiblePreviewPath, 'preview.jpg');

      await controller.selectFilter(mosaicFilterId);
      await controller.selectFilter(originalFilterId);

      state = container.read(editorControllerProvider);
      expect(state.filterStack, isEmpty);
      expect(state.selectedFilterId, originalFilterId);
      expect(state.filteredPreviewPath, isNull);
    },
  );

  test('EditorController ignores stale stack results', () async {
    final engine = _DelayedFilterEngine();
    final container = ProviderContainer(
      overrides: [filterEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);

    final controller = container.read(editorControllerProvider.notifier);
    controller.open(_workingImage());

    final first = controller.selectFilter(neonHeatFilterId);
    final second = controller.selectFilter(mosaicFilterId);

    expect(engine.requests.map((request) => request.preset.id), [
      neonHeatFilterId,
      neonHeatFilterId,
    ]);

    engine.requests[1].complete('current-neon.jpg');
    await Future<void>.delayed(Duration.zero);
    expect(engine.requests.map((request) => request.preset.id), [
      neonHeatFilterId,
      neonHeatFilterId,
      mosaicFilterId,
    ]);

    engine.requests[2].complete('current-mosaic.jpg');
    await second;

    expect(
      container.read(editorControllerProvider).selectedFilterId,
      mosaicFilterId,
    );
    expect(
      container.read(editorControllerProvider).filteredPreviewPath,
      'current-mosaic.jpg',
    );

    engine.requests[0].complete('stale-neon.jpg');
    await first;

    expect(
      container.read(editorControllerProvider).selectedFilterId,
      mosaicFilterId,
    );
    expect(
      container.read(editorControllerProvider).filteredPreviewPath,
      'current-mosaic.jpg',
    );
  });

  test(
    'EditorController runs ONNX mode without changing procedural stack',
    () async {
      final filterEngine = _ImmediateFilterEngine();
      final onnxEngine = _FakeOnnxEngine(
        const OnnxStyleTransferResult(
          status: OnnxStyleTransferStatus.success,
          modelName: 'Local ONNX model 1',
          message: 'ok',
          outputPath: 'onnx-output.jpg',
          inputWidth: 1080,
          inputHeight: 810,
          outputWidth: 1080,
          outputHeight: 810,
          processingTime: Duration(milliseconds: 222),
        ),
      );
      final sourcePreparer = _FakeOnnxSourceImagePreparer();
      final container = ProviderContainer(
        overrides: [
          filterEngineProvider.overrideWithValue(filterEngine),
          onnxStyleTransferEngineProvider.overrideWithValue(onnxEngine),
          onnxSourceImagePreparerProvider.overrideWithValue(sourcePreparer),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(editorControllerProvider.notifier);
      controller.open(_workingImage());

      await controller.selectFilter(neonHeatFilterId);
      await controller.applyOnnxModel(_usableModel());

      final state = container.read(editorControllerProvider);
      expect(state.filterStack.map((filter) => filter.presetId), [
        neonHeatFilterId,
      ]);
      expect(state.hasActiveOnnxResult, isTrue);
      expect(state.visiblePreviewPath, 'onnx-output.jpg');
      expect(state.onnxResult?.inputSizeLabel, '1080 x 810');
      expect(state.onnxResult?.outputSizeLabel, '1080 x 810');
      expect(
        state.onnxResult?.processingTime,
        const Duration(milliseconds: 222),
      );
      expect(onnxEngine.requests.single.inputPath, 'full-photo.jpg');
      expect(onnxEngine.requests.single.modelPath, 'private-model.onnx');
      expect(state.onnxResult?.sourceLabel, 'Full photo 2048 max');
      expect(state.onnxResult?.originalSizeLabel, '1200 x 900');
      expect(state.onnxResult?.usedPreviewSource, isFalse);

      await controller.selectFilter(watercolorFilterId);

      final proceduralState = container.read(editorControllerProvider);
      expect(proceduralState.activeMode, EditorOutputMode.procedural);
      expect(proceduralState.filterStack.map((filter) => filter.presetId), [
        neonHeatFilterId,
        watercolorFilterId,
      ]);
      expect(
        proceduralState.visiblePreviewPath,
        filterEngine.requests.last.outputPath,
      );
    },
  );

  test('EditorController uses full-photo source for ONNX', () async {
    final onnxEngine = _FakeOnnxEngine(
      const OnnxStyleTransferResult(
        status: OnnxStyleTransferStatus.success,
        modelName: 'Local ONNX model 1',
        message: 'ok',
        outputPath: 'onnx-output.jpg',
        inputWidth: 2048,
        inputHeight: 1536,
        outputWidth: 2048,
        outputHeight: 1536,
      ),
    );
    final sourcePreparer = _FakeOnnxSourceImagePreparer(
      source: const OnnxSourceImage(
        path: 'full-photo-2048.jpg',
        width: 2048,
        height: 1536,
        originalWidth: 4000,
        originalHeight: 3000,
        sourceLabel: 'Full photo 2048 max',
        usedPreviewSource: false,
        wasDownscaled: true,
        maxLongSide: 2048,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        onnxStyleTransferEngineProvider.overrideWithValue(onnxEngine),
        onnxSourceImagePreparerProvider.overrideWithValue(sourcePreparer),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(editorControllerProvider.notifier);
    controller.open(
      _workingImage(
        originalTempPath: 'raw-exif-original.jpg',
        previewPath: 'normalized-preview.jpg',
        originalWidth: 4000,
        originalHeight: 3000,
        previewWidth: 810,
        previewHeight: 1080,
      ),
    );

    await controller.applyOnnxModel(_usableModel());

    final state = container.read(editorControllerProvider);
    expect(
      sourcePreparer.requests.single.originalTempPath,
      'raw-exif-original.jpg',
    );
    expect(onnxEngine.requests.single.inputPath, 'full-photo-2048.jpg');
    expect(state.onnxResult?.usedPreviewSource, isFalse);
    expect(state.onnxResult?.sourceLabel, 'Full photo 2048 max');
    expect(state.onnxResult?.originalSizeLabel, '4000 x 3000');
    expect(state.onnxResult?.inputSizeLabel, '2048 x 1536');
    expect(state.onnxResult?.outputSizeLabel, '2048 x 1536');
  });

  test('EditorController does not run rejected ONNX models', () async {
    final onnxEngine = _FakeOnnxEngine(
      OnnxStyleTransferResult.error(
        modelName: 'Local ONNX model 1',
        message: 'should not run',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        onnxStyleTransferEngineProvider.overrideWithValue(onnxEngine),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(editorControllerProvider.notifier);
    controller.open(_workingImage());

    await controller.applyOnnxModel(
      _usableModel(status: LocalOnnxModelStatus.rejected),
    );

    final state = container.read(editorControllerProvider);
    expect(onnxEngine.requests, isEmpty);
    expect(state.hasActiveOnnxResult, isFalse);
    expect(state.onnxErrorMessage, contains('not compatible'));
  });
}

WorkingImage _workingImage({
  String originalTempPath = 'original.jpg',
  String previewPath = 'preview.jpg',
  int originalWidth = 1200,
  int originalHeight = 900,
  int previewWidth = 1080,
  int previewHeight = 810,
}) {
  return WorkingImage(
    sourceAssetId: 'asset-1',
    originalTempPath: originalTempPath,
    previewPath: previewPath,
    originalWidth: originalWidth,
    originalHeight: originalHeight,
    previewWidth: previewWidth,
    previewHeight: previewHeight,
    createdAt: DateTime(2026, 5, 28),
    wasPreviewDownscaled: true,
    originalExtension: 'jpg',
  );
}

class _ImmediateFilterEngine implements FilterEngine {
  final List<_ImmediateFilterRequest> requests = [];

  @override
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues = const {},
  }) async {
    final request = _ImmediateFilterRequest(
      inputPath: inputPath,
      preset: preset,
      outputPath: '${preset.id}_${requests.length}.jpg',
    );
    requests.add(request);
    return _result(request.outputPath);
  }
}

class _ImmediateFilterRequest {
  const _ImmediateFilterRequest({
    required this.inputPath,
    required this.preset,
    required this.outputPath,
  });

  final String inputPath;
  final FilterPreset preset;
  final String outputPath;
}

class _DelayedFilterEngine implements FilterEngine {
  final List<_FilterRequest> requests = [];

  @override
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues = const {},
  }) {
    final request = _FilterRequest(inputPath, preset);
    requests.add(request);
    return request.future;
  }
}

class _FilterRequest {
  _FilterRequest(this.inputPath, this.preset);

  final String inputPath;
  final FilterPreset preset;
  final Completer<FilterResult> _completer = Completer<FilterResult>();

  Future<FilterResult> get future => _completer.future;

  void complete(String outputPath) {
    _completer.complete(_result(outputPath));
  }
}

FilterResult _result(String outputPath) {
  return FilterResult(
    outputPath: outputPath,
    width: 1080,
    height: 810,
    mimeType: 'image/jpeg',
    processingTime: const Duration(milliseconds: 12),
    engineUsed: FilterEngineType.cpu,
    wasDownscaled: false,
    outputFormat: ExportFormat.jpeg,
  );
}

LocalOnnxModel _usableModel({
  LocalOnnxModelStatus status = LocalOnnxModelStatus.usable,
}) {
  return LocalOnnxModel(
    id: 'local-onnx-1',
    displayLabel: 'Local ONNX model 1',
    storedPath: 'private-model.onnx',
    fileSizeBytes: 6768798,
    inputShape: const [1, 3, -1, -1],
    outputShape: const [1, 3, -1, -1],
    status: status,
    importedAt: DateTime(2026, 6, 4),
    rejectionReason: status == LocalOnnxModelStatus.usable
        ? null
        : 'fixed-size rejected',
  );
}

class _FakeOnnxEngine extends OnnxStyleTransferEngine {
  _FakeOnnxEngine(this.result) : super(cacheService: _NoopCacheService());

  final OnnxStyleTransferResult result;
  final List<_OnnxRequest> requests = [];

  @override
  Future<OnnxStyleTransferResult> runLocalModel({
    required String inputPath,
    required String modelPath,
    required String modelName,
  }) async {
    requests.add(_OnnxRequest(inputPath, modelPath, modelName));
    return result;
  }
}

class _FakeOnnxSourceImagePreparer extends OnnxSourceImagePreparer {
  _FakeOnnxSourceImagePreparer({
    this.source = const OnnxSourceImage(
      path: 'full-photo.jpg',
      width: 1080,
      height: 810,
      originalWidth: 1200,
      originalHeight: 900,
      sourceLabel: 'Full photo 2048 max',
      usedPreviewSource: false,
      wasDownscaled: true,
      maxLongSide: 2048,
    ),
  }) : super(cacheService: _NoopCacheService());

  final OnnxSourceImage source;
  final List<WorkingImage> requests = [];

  @override
  Future<OnnxSourceImage> prepare(WorkingImage workingImage) async {
    requests.add(workingImage);
    return source;
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
    return 'unused.$extension';
  }

  @override
  Future<String> reserveTempFilePath(String extension) async {
    return 'reserved.$extension';
  }
}
