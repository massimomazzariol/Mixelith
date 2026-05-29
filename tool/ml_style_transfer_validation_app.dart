import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:mixelith/filters/ml/ml_style_transfer_engine.dart';
import 'package:mixelith/filters/ml/ml_style_transfer_result.dart';
import 'package:mixelith/filters/ml/style_reference_registry.dart';
import 'package:mixelith/storage/data/path_provider_cache_service.dart';

const _runValidation = bool.fromEnvironment('MIXELITH_RUN_LOCAL_ML_VALIDATION');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lines = <String>[];
  if (!_runValidation) {
    lines.add(
      'Local ML validation disabled. Set '
      'MIXELITH_RUN_LOCAL_ML_VALIDATION=true.',
    );
  } else {
    lines.addAll(await _runLocalValidation());
  }

  for (final line in lines) {
    debugPrint('MIXELITH_ML_VALIDATION: $line');
  }

  runApp(_ValidationApp(lines: lines));
}

Future<List<String>> _runLocalValidation() async {
  final lines = <String>[];
  final cacheService = PathProviderCacheService(
    expirationAge: const Duration(days: 1),
  );
  final engine = MlStyleTransferEngine(cacheService: cacheService);
  final modelsAvailable = await engine.areModelsAvailable();
  lines.add('modelsAvailable=$modelsAvailable');

  if (!modelsAvailable) {
    return lines;
  }

  final modelInfo = await engine.inspectModels();
  lines.add('tensorSummary=${modelInfo?.summary ?? 'unavailable'}');

  final contentFile = await _writeContentImage(cacheService);
  final source = img.decodeImage(await contentFile.readAsBytes());
  final startedAt = DateTime.now();
  final result = await engine.apply(
    contentImagePath: contentFile.path,
    styleReference: StyleReferenceRegistry.neonHeat,
  );

  lines.add('status=${result.status.name}');
  lines.add('message=${result.message ?? ''}');
  lines.add(
    'processing=${result.processingTime ?? DateTime.now().difference(startedAt)}',
  );
  lines.add('outputPath=${result.outputPath ?? ''}');

  if (result.status == MlStyleTransferStatus.success &&
      result.outputPath != null &&
      source != null) {
    final outputFile = File(result.outputPath!);
    final output = img.decodeImage(await outputFile.readAsBytes());
    lines.add('outputExists=${await outputFile.exists()}');
    lines.add('outputSize=${output?.width}x${output?.height}');
    if (output != null) {
      final resizedSource = img.copyResize(source, width: output.width);
      lines.add(
        'meanAbsoluteDifference=${_meanAbsoluteDifference(resizedSource, output).toStringAsFixed(3)}',
      );
    }
  }

  return lines;
}

Future<File> _writeContentImage(PathProviderCacheService cacheService) async {
  final encoded = img.encodeJpg(_contentImage(), quality: 92);
  final path = await cacheService.writeTempFile(encoded, 'jpg');
  return File(path);
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

class _ValidationApp extends StatelessWidget {
  const _ValidationApp({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text(
                  'Mixelith ML Validation',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 16),
                for (final line in lines)
                  Text(line, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
