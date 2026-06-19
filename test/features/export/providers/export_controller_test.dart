import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/features/editor/domain/applied_filter.dart';
import 'package:mixelith/app/providers.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/export/domain/export_prepared_file.dart';
import 'package:mixelith/features/export/domain/export_save_result.dart';
import 'package:mixelith/features/export/domain/export_service.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/features/export/domain/export_state.dart';
import 'package:mixelith/features/export/providers/export_controller.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/filters/registry/default_filter_registry.dart';

import '../../../fakes/fake_cache_service.dart';
import '../../../fakes/fake_export_repository.dart';

void main() {
  late Directory baseDirectory;
  late File sourceFile;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp(
      'mixelith_export_controller_test_',
    );
    sourceFile = File(
      '${baseDirectory.path}${Platform.pathSeparator}source.png',
    );
    await sourceFile.writeAsBytes(img.encodePng(_sourceImage()));
  });

  tearDown(() async {
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('ExportController reports success after repository save', () async {
    final repository = FakeExportRepository();
    final container = ProviderContainer(
      overrides: [
        cacheServiceProvider.overrideWithValue(FakeCacheService(baseDirectory)),
        exportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(exportControllerProvider.notifier)
        .exportImage(
          workingImage: _workingImage(sourceFile.path),
          filterStack: [_appliedFilter(neonHeatFilterId)],
          settings: const ExportSettings(format: ExportFormat.jpeg),
        );

    final state = container.read(exportControllerProvider);
    expect(state.status, ExportStatus.success);
    expect(state.message, 'Saved to gallery.');
    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.format, ExportFormat.jpeg);
  });

  test('ExportController reports repository failures', () async {
    final repository = FakeExportRepository(
      result: const ExportSaveResult.failure(message: 'Unable to save export.'),
    );
    final container = ProviderContainer(
      overrides: [
        cacheServiceProvider.overrideWithValue(FakeCacheService(baseDirectory)),
        exportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(exportControllerProvider.notifier)
        .exportImage(
          workingImage: _workingImage(sourceFile.path),
          filterStack: [_appliedFilter(popPosterFilterId)],
          settings: const ExportSettings(format: ExportFormat.png),
        );

    final state = container.read(exportControllerProvider);
    expect(state.status, ExportStatus.error);
    expect(state.message, 'Unable to save export.');
    expect(repository.requests.single.format, ExportFormat.png);
  });

  test(
    'ExportController does not save when the filter stack is empty',
    () async {
      final repository = FakeExportRepository();
      final container = ProviderContainer(
        overrides: [
          cacheServiceProvider.overrideWithValue(
            FakeCacheService(baseDirectory),
          ),
          exportRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(exportControllerProvider.notifier)
          .exportImage(
            workingImage: _workingImage(sourceFile.path),
            filterStack: const [],
            settings: const ExportSettings(format: ExportFormat.jpeg),
          );

      final state = container.read(exportControllerProvider);
      expect(state.status, ExportStatus.error);
      expect(state.message, 'Apply a filter before exporting.');
      expect(repository.requests, isEmpty);
    },
  );

  test(
    'ExportController passes the full filter stack to the service',
    () async {
      final repository = FakeExportRepository();
      final service = _RecordingExportService(baseDirectory);
      final stack = [
        _appliedFilter(neonHeatFilterId),
        _appliedFilter(watercolorFilterId),
        _appliedFilter(starryOilFilterId),
      ];
      final container = ProviderContainer(
        overrides: [
          exportServiceProvider.overrideWithValue(service),
          exportRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(exportControllerProvider.notifier)
          .exportImage(
            workingImage: _workingImage(sourceFile.path),
            filterStack: stack,
            settings: const ExportSettings(format: ExportFormat.jpeg),
          );

      expect(service.receivedStack.map((filter) => filter.presetId), [
        neonHeatFilterId,
        watercolorFilterId,
        starryOilFilterId,
      ]);
      expect(
        container.read(exportControllerProvider).status,
        ExportStatus.success,
      );
    },
  );

  test(
    'ExportController saves active ONNX result through ONNX export path',
    () async {
      final repository = FakeExportRepository();
      final service = _RecordingExportService(baseDirectory);
      final container = ProviderContainer(
        overrides: [
          exportServiceProvider.overrideWithValue(service),
          exportRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(exportControllerProvider.notifier)
          .exportOnnxResult(
            onnxOutputPath: sourceFile.path,
            settings: const ExportSettings(format: ExportFormat.png),
            usedPreviewFallback: true,
          );

      final state = container.read(exportControllerProvider);
      expect(state.status, ExportStatus.success);
      expect(state.message, 'Saved to gallery.');
      expect(service.receivedOnnxPath, sourceFile.path);
      expect(service.receivedStack, isEmpty);
      expect(state.usedPreviewFallback, isTrue);
      expect(repository.requests.single.format, ExportFormat.png);
    },
  );
}

AppliedFilter _appliedFilter(String presetId) {
  return AppliedFilter(presetId: presetId, appliedAt: DateTime(2026, 5, 31));
}

WorkingImage _workingImage(String sourcePath) {
  return WorkingImage(
    sourceAssetId: 'asset-1',
    originalTempPath: sourcePath,
    previewPath: sourcePath,
    originalWidth: 32,
    originalHeight: 24,
    previewWidth: 32,
    previewHeight: 24,
    createdAt: DateTime(2026, 5, 28),
    wasPreviewDownscaled: false,
    originalExtension: 'png',
  );
}

class _RecordingExportService extends ExportService {
  _RecordingExportService(Directory baseDirectory)
    : _baseDirectory = baseDirectory,
      super(
        cacheService: FakeCacheService(baseDirectory),
        filterRegistry: const DefaultFilterRegistry(),
      );

  final Directory _baseDirectory;
  List<AppliedFilter> receivedStack = const [];
  String? receivedOnnxPath;

  @override
  Future<ExportPreparedFile> prepareExport({
    required WorkingImage workingImage,
    required List<AppliedFilter> filterStack,
    required ExportSettings settings,
  }) async {
    receivedStack = List<AppliedFilter>.from(filterStack);
    final outputFile = File(
      '${_baseDirectory.path}${Platform.pathSeparator}prepared.${settings.fileExtension}',
    );
    await outputFile.writeAsBytes(img.encodeJpg(_sourceImage()), flush: true);
    return ExportPreparedFile(
      path: outputFile.path,
      format: settings.format,
      width: 32,
      height: 24,
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
    receivedOnnxPath = onnxOutputPath;
    final outputFile = File(
      '${_baseDirectory.path}${Platform.pathSeparator}prepared_onnx.${settings.fileExtension}',
    );
    await outputFile.writeAsBytes(img.encodePng(_sourceImage()), flush: true);
    return ExportPreparedFile(
      path: outputFile.path,
      format: settings.format,
      width: 32,
      height: 24,
      wasResized: false,
      usedPreviewFallback: usedPreviewFallback,
    );
  }
}

img.Image _sourceImage() {
  final image = img.Image(width: 32, height: 24);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(x, y, x * 6, y * 8, 120);
    }
  }
  return image;
}
