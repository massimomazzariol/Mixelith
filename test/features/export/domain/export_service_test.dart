import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/features/editor/domain/applied_filter.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/export/domain/export_service.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/filters/registry/default_filter_registry.dart';

import '../../../fakes/fake_cache_service.dart';

void main() {
  late Directory baseDirectory;
  late File sourceFile;
  late ExportService service;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp(
      'mixelith_export_test_',
    );
    sourceFile = File(
      '${baseDirectory.path}${Platform.pathSeparator}source.png',
    );
    await sourceFile.writeAsBytes(img.encodePng(_sourceImage(100, 50)));
    service = ExportService(
      cacheService: FakeCacheService(baseDirectory),
      filterRegistry: const DefaultFilterRegistry(),
    );
  });

  tearDown(() async {
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('exports JPEG by re-encoding the source image', () async {
    final prepared = await service.prepareExport(
      workingImage: _workingImage(sourceFile.path, 100, 50),
      filterStack: [_appliedFilter(neonHeatFilterId)],
      settings: const ExportSettings(format: ExportFormat.jpeg),
    );
    final outputFile = File(prepared.path);
    final outputBytes = await outputFile.readAsBytes();
    final sourceBytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(outputBytes);

    expect(await outputFile.exists(), isTrue);
    expect(prepared.path, isNot(sourceFile.path));
    expect(outputBytes, isNot(sourceBytes));
    expect(decoded, isNotNull);
    expect(decoded!.width, 100);
    expect(decoded.height, 50);
    expect(prepared.format, ExportFormat.jpeg);
  });

  test('exports PNG with the full filter stack applied', () async {
    final prepared = await service.prepareExport(
      workingImage: _workingImage(sourceFile.path, 100, 50),
      filterStack: [
        _appliedFilter(neonHeatFilterId),
        _appliedFilter(popPosterFilterId),
      ],
      settings: const ExportSettings(format: ExportFormat.png),
    );
    final outputFile = File(prepared.path);
    final decoded = img.decodeImage(await outputFile.readAsBytes());

    expect(await outputFile.exists(), isTrue);
    expect(decoded, isNotNull);
    expect(decoded!.width, 100);
    expect(decoded.height, 50);
    expect(prepared.format, ExportFormat.png);
  });

  test('resizes large exports to the requested max long side', () async {
    final prepared = await service.prepareExport(
      workingImage: _workingImage(sourceFile.path, 100, 50),
      filterStack: [_appliedFilter(mosaicFilterId)],
      settings: const ExportSettings(
        format: ExportFormat.jpeg,
        maxLongSide: 40,
      ),
    );
    final decoded = img.decodeImage(await File(prepared.path).readAsBytes());

    expect(prepared.wasResized, isTrue);
    expect(decoded, isNotNull);
    expect(decoded!.width, 40);
    expect(decoded.height, 20);
  });

  test('rejects export without an applied filter stack', () async {
    await expectLater(
      service.prepareExport(
        workingImage: _workingImage(sourceFile.path, 100, 50),
        filterStack: const [],
        settings: const ExportSettings(format: ExportFormat.jpeg),
      ),
      throwsA(isA<ExportServiceException>()),
    );
  });
}

AppliedFilter _appliedFilter(String presetId) {
  return AppliedFilter(presetId: presetId, appliedAt: DateTime(2026, 5, 31));
}

WorkingImage _workingImage(String sourcePath, int width, int height) {
  return WorkingImage(
    sourceAssetId: 'asset-1',
    originalTempPath: sourcePath,
    previewPath: sourcePath,
    originalWidth: width,
    originalHeight: height,
    previewWidth: width,
    previewHeight: height,
    createdAt: DateTime(2026, 5, 28),
    wasPreviewDownscaled: false,
    originalExtension: 'png',
  );
}

img.Image _sourceImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(x, y, x * 2, y * 4, 180 - x);
    }
  }
  return image;
}
