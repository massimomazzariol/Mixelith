import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/filters/engines/cpu_filter_engine.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/filters/registry/default_filter_registry.dart';

import '../../fakes/fake_cache_service.dart';

void main() {
  late Directory baseDirectory;
  late File sourceFile;
  late CpuFilterEngine engine;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp(
      'mixelith_filter_test_',
    );
    sourceFile = File(
      '${baseDirectory.path}${Platform.pathSeparator}source.jpg',
    );
    await sourceFile.writeAsBytes(img.encodeJpg(_sourceImage()));
    engine = CpuFilterEngine(cacheService: FakeCacheService(baseDirectory));
  });

  tearDown(() async {
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('CPU engine applies all default artistic filters', () async {
    const registry = DefaultFilterRegistry();

    for (final preset in registry.getAllPresets()) {
      if (preset.id == originalFilterId) {
        continue;
      }

      final result = await engine.apply(
        inputPath: sourceFile.path,
        preset: preset,
      );
      final outputFile = File(result.outputPath!);
      final output = img.decodeImage(await outputFile.readAsBytes());

      expect(await outputFile.exists(), isTrue);
      expect(result.width, 40);
      expect(result.height, 28);
      expect(output, isNotNull);
      expect(output!.width, 40);
      expect(output.height, 28);
    }
  });

  test('Mosaic Tiles keeps output dimensions', () async {
    const registry = DefaultFilterRegistry();
    final preset = registry.getById(mosaicTilesFilterId)!;

    final result = await engine.apply(
      inputPath: sourceFile.path,
      preset: preset,
    );

    expect(result.width, 40);
    expect(result.height, 28);
  });

  test('Neon Pop produces a valid JPEG output file', () async {
    const registry = DefaultFilterRegistry();
    final preset = registry.getById(neonPopFilterId)!;

    final result = await engine.apply(
      inputPath: sourceFile.path,
      preset: preset,
    );
    final outputFile = File(result.outputPath!);
    final outputBytes = await outputFile.readAsBytes();

    expect(await outputFile.exists(), isTrue);
    expect(outputBytes, isNotEmpty);
    expect(img.decodeImage(outputBytes), isNotNull);
  });
}

img.Image _sourceImage() {
  final image = img.Image(width: 40, height: 28);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(x, y, x * 6, y * 8, 180 - x * 2);
    }
  }
  return image;
}
