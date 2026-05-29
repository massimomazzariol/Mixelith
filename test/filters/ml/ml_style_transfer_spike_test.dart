import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/filters/ml/ml_style_transfer_engine.dart';
import 'package:mixelith/filters/ml/ml_style_transfer_model_paths.dart';
import 'package:mixelith/filters/ml/ml_style_transfer_result.dart';
import 'package:mixelith/filters/ml/style_reference_registry.dart';

import '../../fakes/fake_cache_service.dart';

void main() {
  test('model binary patterns are ignored by Git', () {
    final gitignore = File('.gitignore').readAsStringSync();

    expect(gitignore, contains('/assets/models/style_transfer/*.tflite'));
    expect(gitignore, contains('/assets/models/style_transfer/*.onnx'));
    expect(gitignore, contains('/.local/models/'));
  });

  test('style reference assets are project-owned and present', () {
    const registry = StyleReferenceRegistry();

    for (final reference in registry.getAll()) {
      expect(reference.projectGenerated, isTrue);
      expect(File(reference.assetPath).existsSync(), isTrue);
      expect(reference.name, isNotEmpty);
    }
  });

  test('ML engine reports unavailable when model assets are missing', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mixelith_ml_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final engine = MlStyleTransferEngine(
      cacheService: FakeCacheService(directory),
      assetLoader: (_) async => throw Exception('Missing test asset'),
      isAndroidOverride: true,
    );

    final result = await engine.apply(
      contentImagePath: 'unused.jpg',
      styleReference: StyleReferenceRegistry.neonHeat,
    );

    expect(result.status, MlStyleTransferStatus.unavailable);
    expect(result.message, contains('not installed'));
  });

  test('ML model paths point to local ignored assets', () {
    expect(
      MlStyleTransferModelPaths.predictionAsset,
      'assets/models/style_transfer/style_prediction_int8.tflite',
    );
    expect(
      MlStyleTransferModelPaths.transferAsset,
      'assets/models/style_transfer/style_transfer_int8.tflite',
    );
    expect(MlStyleTransferModelPaths.predictionExpectedBytes, 2828838);
    expect(MlStyleTransferModelPaths.transferExpectedBytes, 284398);
  });

  test('UI and non-ML layers do not import tflite_flutter', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => !file.path.replaceAll('\\', '/').contains('/filters/ml/'),
        );

    for (final file in files) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(contains('package:tflite_flutter')),
        reason: '${file.path} must not import TensorFlow Lite directly.',
      );
    }
  });
}
