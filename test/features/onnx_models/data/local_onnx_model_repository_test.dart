import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/onnx_models/data/local_onnx_model_repository.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_result.dart';

import '../../../fakes/fake_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mixelith/onnx_model_import');
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'mixelith_local_onnx_test_',
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test(
    'dynamic inspected model is accepted after runtime validation',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'pickAndImportModel');
            return {
              'success': true,
              'status': 'inspected',
              'id': 'local_onnx_1',
              'displayName': 'Local Style Model 2.onnx',
              'storedPath': _modelPath(directory),
              'fileSizeBytes': 6768798,
              'inputShape': [1, 3, -1, -1],
              'outputShape': [1, 3, -1, -1],
            };
          });

      final repository = MethodChannelLocalOnnxModelRepository(
        cacheService: FakeCacheService(directory),
        supportDirectoryProvider: () async => directory,
        runtimeValidator: ({required modelPath, required modelName}) async {
          expect(modelPath, _modelPath(directory));
          expect(modelName, 'Local Style Model 2');
          return const OnnxStyleTransferResult(
            status: OnnxStyleTransferStatus.success,
            modelName: 'Local Style Model 2',
            message: 'ok',
            inputWidth: 320,
            inputHeight: 240,
            outputWidth: 320,
            outputHeight: 240,
            processingTime: Duration(milliseconds: 37),
            inputShape: [1, 3, -1, -1],
            outputShape: [1, 3, -1, -1],
          );
        },
        now: () => DateTime(2026, 6, 4),
      );

      final imported = await repository.importModel();
      final stored = await repository.loadModels();

      expect(imported?.status, LocalOnnxModelStatus.usable);
      expect(imported?.displayLabel, 'Local Style Model 2');
      expect(imported?.isUsable, isTrue);
      expect(stored, hasLength(1));
      expect(stored.single.displayLabel, 'Local Style Model 2');
      expect(stored.single.inputShapeLabel, '1 x 3 x dynamic x dynamic');
    },
  );

  test(
    'fixed-size inspected model is rejected before runtime validation',
    () async {
      var validatorCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return {
              'success': true,
              'status': 'inspected',
              'id': 'local_onnx_fixed',
              'storedPath': _modelPath(directory),
              'fileSizeBytes': 6728029,
              'inputShape': [1, 3, 224, 224],
              'outputShape': [1, 3, 224, 224],
            };
          });

      final repository = MethodChannelLocalOnnxModelRepository(
        cacheService: FakeCacheService(directory),
        supportDirectoryProvider: () async => directory,
        runtimeValidator: ({required modelPath, required modelName}) async {
          validatorCalls++;
          return OnnxStyleTransferResult.error(
            modelName: modelName,
            message: 'should not run',
          );
        },
      );

      final imported = await repository.importModel();

      expect(imported?.status, LocalOnnxModelStatus.rejected);
      expect(imported?.rejectionReason, contains('224x224'));
      expect(validatorCalls, 0);
    },
  );

  test('cancelled platform import does not write metadata', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return {
            'success': false,
            'status': 'cancelled',
            'message': 'cancelled',
          };
        });

    final repository = MethodChannelLocalOnnxModelRepository(
      cacheService: FakeCacheService(directory),
      supportDirectoryProvider: () async => directory,
    );

    final imported = await repository.importModel();

    expect(imported, isNull);
    expect(await repository.loadModels(), isEmpty);
  });
}

String _modelPath(Directory directory) {
  return '${directory.path}${Platform.pathSeparator}model.onnx';
}
