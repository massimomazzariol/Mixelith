import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/filters/onnx/onnx_style_transfer_engine.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_model.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_result.dart';
import 'package:mixelith/storage/data/path_provider_cache_service.dart';

void main() {
  runApp(const OnnxValidationApp());
}

class OnnxValidationApp extends StatefulWidget {
  const OnnxValidationApp({super.key});

  @override
  State<OnnxValidationApp> createState() => _OnnxValidationAppState();
}

class _OnnxValidationAppState extends State<OnnxValidationApp> {
  final List<_ValidationRun> _runs = [];
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _runValidation();
  }

  Future<void> _runValidation() async {
    final cache = PathProviderCacheService();
    final engine = OnnxStyleTransferEngine(cacheService: cache);
    final runs = <_ValidationRun>[];
    for (final model in onnxStyleTransferCandidates) {
      for (final size in _validationSizes) {
        final inputPath = await cache.writeTempFile(
          img.encodeJpg(_sampleImage(width: size.width, height: size.height)),
          'jpg',
        );
        final result = await engine.run(inputPath: inputPath, model: model);
        debugPrint(
          'MIXELITH_ONNX_VALIDATION status=${result.status.name} '
          'model=${result.modelName} '
          'requested=${size.width}x${size.height} '
          'input=${result.inputWidth}x${result.inputHeight} '
          'output=${result.outputWidth}x${result.outputHeight} '
          'fullFrame=${result.isFullFrameOutput} '
          'timeMs=${result.processingTime?.inMilliseconds} '
          'message=${result.message}',
        );
        runs.add(_ValidationRun(model.displayName, size, inputPath, result));
      }
    }
    if (mounted) {
      setState(() {
        _runs
          ..clear()
          ..addAll(runs);
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0B10),
        appBar: AppBar(
          backgroundColor: const Color(0xFF17141C),
          foregroundColor: Colors.white,
          title: const Text('ONNX validation'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _running
              ? const Center(child: CircularProgressIndicator())
              : ListView(children: _runs.map(_RunTile.new).toList()),
        ),
      ),
    );
  }
}

class _ValidationSize {
  const _ValidationSize(this.width, this.height);

  final int width;
  final int height;
}

const _validationSizes = <_ValidationSize>[
  _ValidationSize(320, 240),
  _ValidationSize(640, 480),
  _ValidationSize(480, 720),
];

class _ValidationRun {
  const _ValidationRun(this.modelName, this.size, this.inputPath, this.result);

  final String modelName;
  final _ValidationSize size;
  final String inputPath;
  final OnnxStyleTransferResult result;
}

class _RunTile extends StatelessWidget {
  const _RunTile(this.run);

  final _ValidationRun run;

  @override
  Widget build(BuildContext context) {
    final result = run.result;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF17141C),
          border: Border.all(color: const Color(0xFF30273A)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${run.modelName} - ${run.size.width}x${run.size.height}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(result.message, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Status: ${result.status.name}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Input: ${result.inputWidth}x${result.inputHeight}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Output: ${result.outputWidth}x${result.outputHeight}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Full frame: ${result.isFullFrameOutput}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Processing: ${result.processingTime?.inMilliseconds}ms',
                style: const TextStyle(color: Colors.white70),
              ),
              if (result.outputPath != null) ...[
                const SizedBox(height: 14),
                Image.file(File(result.outputPath!), fit: BoxFit.contain),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

img.Image _sampleImage({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final red = (x / image.width * 255).round();
      final green = (y / image.height * 180).round();
      final blue = ((x + y) / (image.width + image.height) * 220).round();
      image.setPixelRgb(x, y, red, green, blue);
    }
  }
  return image;
}
