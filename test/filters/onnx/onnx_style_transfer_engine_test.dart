import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_engine.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_result.dart';

import '../../fakes/fake_cache_service.dart';

void main() {
  const channel = MethodChannel('mixelith/onnx_style_transfer');
  late Directory baseDirectory;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    baseDirectory = await Directory.systemTemp.createTemp(
      'mixelith_onnx_test_',
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('ONNX engine reports unavailable on non-Android platforms', () async {
    final engine = OnnxStyleTransferEngine(
      cacheService: FakeCacheService(baseDirectory),
      isAndroid: false,
    );

    final result = await engine.run(inputPath: 'input.jpg');

    expect(result.status, OnnxStyleTransferStatus.unavailable);
    expect(result.message, contains('Android'));
  });

  test(
    'ONNX engine reports missing local model without invoking platform',
    () async {
      final engine = OnnxStyleTransferEngine(
        cacheService: FakeCacheService(baseDirectory),
        assetBundle: _MissingAssetBundle(),
        isAndroid: true,
      );

      final result = await engine.run(inputPath: 'input.jpg');

      expect(result.status, OnnxStyleTransferStatus.unavailable);
      expect(result.message, contains('not bundled'));
    },
  );

  test('ONNX engine maps platform success to full-frame result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'runStyleTransfer');
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          expect(args['modelPath'], isA<String>());
          expect(args['outputPath'], isA<String>());
          return {
            'success': true,
            'status': 'success',
            'message': 'ok',
            'modelName': 'local_style_model_1',
            'outputPath': args['outputPath'],
            'inputWidth': 320,
            'inputHeight': 240,
            'outputWidth': 320,
            'outputHeight': 240,
            'processingTimeMs': 123,
            'inputShape': [1, 3, 320, 240],
            'outputShape': [1, 3, 320, 240],
          };
        });

    final engine = OnnxStyleTransferEngine(
      cacheService: FakeCacheService(baseDirectory),
      assetBundle: _MemoryAssetBundle(Uint8List.fromList([1, 2, 3])),
      isAndroid: true,
    );

    final result = await engine.run(inputPath: 'input.jpg');

    expect(result.status, OnnxStyleTransferStatus.success);
    expect(result.isFullFrameOutput, isTrue);
    expect(result.processingTime, const Duration(milliseconds: 123));
  });

  test(
    'ONNX engine runs an imported local model without asset loading',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'runStyleTransfer');
            final args = Map<Object?, Object?>.from(call.arguments as Map);
            expect(args['modelPath'], 'private_model.onnx');
            expect(args['modelName'], 'Local ONNX model 1');
            return {
              'success': true,
              'status': 'success',
              'message': 'ok',
              'modelName': args['modelName'],
              'outputPath': args['outputPath'],
              'inputWidth': 480,
              'inputHeight': 720,
              'outputWidth': 480,
              'outputHeight': 720,
              'processingTimeMs': 456,
              'inputShape': [1, 3, -1, -1],
              'outputShape': [1, 3, -1, -1],
            };
          });

      final engine = OnnxStyleTransferEngine(
        cacheService: FakeCacheService(baseDirectory),
        assetBundle: _MissingAssetBundle(),
        isAndroid: true,
      );

      final result = await engine.runLocalModel(
        inputPath: 'input.jpg',
        modelPath: 'private_model.onnx',
        modelName: 'Local ONNX model 1',
      );

      expect(result.status, OnnxStyleTransferStatus.success);
      expect(result.isFullFrameOutput, isTrue);
      expect(result.processingTime, const Duration(milliseconds: 456));
    },
  );

  test('ONNX engine maps fixed-size rejection with tensor shapes', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return {
            'success': false,
            'status': 'fixed_size_rejected',
            'message': 'ONNX model input is fixed to 224x224.',
            'modelName': 'local_style_model_1',
            'inputWidth': 320,
            'inputHeight': 240,
            'inputShape': [1, 3, 224, 224],
            'outputShape': [1, 3, 224, 224],
          };
        });

    final engine = OnnxStyleTransferEngine(
      cacheService: FakeCacheService(baseDirectory),
      assetBundle: _MemoryAssetBundle(Uint8List.fromList([1, 2, 3])),
      isAndroid: true,
    );

    final result = await engine.run(inputPath: 'input.jpg');

    expect(result.status, OnnxStyleTransferStatus.fixedSizeRejected);
    expect(result.inputShape, [1, 3, 224, 224]);
    expect(result.isFullFrameOutput, isFalse);
  });

  test('model binaries are ignored and not tracked by Git', () async {
    final tracked = await Process.run('git', [
      'ls-files',
      '*.onnx',
      '*.ort',
      '*.tflite',
      '*.pt',
      '*.pth',
    ]);

    expect(tracked.exitCode, 0);
    expect((tracked.stdout as String).trim(), isEmpty);

    final gitignore = await File('.gitignore').readAsString();
    expect(gitignore, contains('*.onnx'));
    expect(gitignore, contains('*.ort'));

    final pubspec = await File('pubspec.yaml').readAsString();
    expect(pubspec, isNot(contains('assets/models/')));
  });
}

class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw FlutterError('missing $key');
  }
}

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.bytes);

  final Uint8List bytes;

  @override
  Future<ByteData> load(String key) async {
    final data = ByteData(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      data.setUint8(i, bytes[i]);
    }
    return data;
  }
}
