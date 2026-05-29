import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/app/providers.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/export/domain/export_save_result.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/features/export/domain/export_state.dart';
import 'package:mixelith/features/export/providers/export_controller.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';

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
          selectedFilterId: originalFilterId,
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
          selectedFilterId: originalFilterId,
          settings: const ExportSettings(format: ExportFormat.png),
        );

    final state = container.read(exportControllerProvider);
    expect(state.status, ExportStatus.error);
    expect(state.message, 'Unable to save export.');
    expect(repository.requests.single.format, ExportFormat.png);
  });
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

img.Image _sourceImage() {
  final image = img.Image(width: 32, height: 24);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(x, y, x * 6, y * 8, 120);
    }
  }
  return image;
}
