import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/filters/ml/ml_style_transfer_engine.dart';
import 'package:mixelith/filters/ml/ml_style_transfer_model_paths.dart';
import 'package:mixelith/filters/ml/ml_style_transfer_result.dart';
import 'package:mixelith/filters/ml/style_reference_registry.dart';

import '../../fakes/fake_cache_service.dart';

const _runLocalValidation = bool.fromEnvironment(
  'MIXELITH_RUN_LOCAL_ML_VALIDATION',
);

void main() {
  test(
    'local TFLite style transfer model pair runs on Android',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mixelith_ml_validation_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final contentFile = File(
        '${directory.path}${Platform.pathSeparator}content.jpg',
      );
      await contentFile.writeAsBytes(img.encodeJpg(_contentImage()));

      final engine = MlStyleTransferEngine(
        cacheService: FakeCacheService(directory),
      );

      expect(await engine.areModelsAvailable(), isTrue);

      final info = await engine.inspectModels();
      expect(info, isNotNull);
      // Keep this visible in the device test output for the validation log.
      // ignore: avoid_print
      print('Mixelith local ML tensor summary: ${info!.summary}');

      final result = await engine.apply(
        contentImagePath: contentFile.path,
        styleReference: StyleReferenceRegistry.neonHeat,
      );

      expect(
        result.status,
        MlStyleTransferStatus.success,
        reason: '${result.message}\n${result.tensorSummary}',
      );
      expect(result.outputPath, isNotNull);

      final outputFile = File(result.outputPath!);
      expect(await outputFile.exists(), isTrue);

      final output = img.decodeImage(await outputFile.readAsBytes());
      expect(output, isNotNull);
      expect(output!.width, result.width);
      expect(output.height, result.height);

      final input = img.copyResize(_contentImage(), width: output.width);
      expect(_meanAbsoluteDifference(input, output), greaterThan(1.0));

      // ignore: avoid_print
      print(
        'Mixelith local ML output: ${output.width}x${output.height}, '
        'processing=${result.processingTime}',
      );
    },
    skip: !_runLocalValidation || !Platform.isAndroid
        ? 'Local model validation runs only on Android with '
              'MIXELITH_RUN_LOCAL_ML_VALIDATION=true.'
        : false,
  );

  test('local model files are not required for normal automated tests', () {
    expect(MlStyleTransferModelPaths.allModelAssets, hasLength(2));
  });
}

img.Image _contentImage() {
  final image = img.Image(width: 192, height: 144);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final sky = y < 72;
      image.setPixelRgb(
        x,
        y,
        sky ? 36 + x ~/ 4 : 32 + y ~/ 3,
        sky ? 62 + y ~/ 2 : 110 + x ~/ 5,
        sky ? 150 + x ~/ 8 : 62,
      );
    }
  }
  return image;
}

double _meanAbsoluteDifference(img.Image a, img.Image b) {
  final width = a.width < b.width ? a.width : b.width;
  final height = a.height < b.height ? a.height : b.height;
  var total = 0.0;
  var count = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pa = a.getPixel(x, y);
      final pb = b.getPixel(x, y);
      total += (pa.r - pb.r).abs();
      total += (pa.g - pb.g).abs();
      total += (pa.b - pb.b).abs();
      count += 3;
    }
  }

  return total / count;
}
