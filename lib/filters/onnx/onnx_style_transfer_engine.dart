import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../storage/domain/cache_service.dart';
import 'onnx_style_transfer_model.dart';
import 'onnx_style_transfer_result.dart';

class OnnxStyleTransferEngine {
  OnnxStyleTransferEngine({
    required CacheService cacheService,
    MethodChannel channel = const MethodChannel(_channelName),
    AssetBundle? assetBundle,
    bool? isAndroid,
  }) : _cacheService = cacheService,
       _channel = channel,
       _assetBundle = assetBundle ?? rootBundle,
       _isAndroid = isAndroid ?? Platform.isAndroid;

  static const _channelName = 'mixelith/onnx_style_transfer';

  final CacheService _cacheService;
  final MethodChannel _channel;
  final AssetBundle _assetBundle;
  final bool _isAndroid;

  Future<OnnxStyleTransferResult> run({
    required String inputPath,
    OnnxStyleTransferModel model = localStyleModel1OnnxModel,
  }) async {
    if (!_isAndroid) {
      return OnnxStyleTransferResult.unavailable(
        modelName: model.id,
        message: 'ONNX style transfer is available only on Android.',
      );
    }

    final localModelPath = await _copyModelAssetToCache(model);
    if (localModelPath == null) {
      return OnnxStyleTransferResult.unavailable(
        modelName: model.id,
        message:
            'Local ONNX model asset is not bundled. Import a compatible ONNX model on Android for local evaluation.',
      );
    }

    return _runWithModelPath(
      inputPath: inputPath,
      modelPath: localModelPath,
      modelName: model.id,
    );
  }

  Future<OnnxStyleTransferResult> runLocalModel({
    required String inputPath,
    required String modelPath,
    required String modelName,
  }) async {
    if (!_isAndroid) {
      return OnnxStyleTransferResult.unavailable(
        modelName: modelName,
        message: 'ONNX style transfer is available only on Android.',
      );
    }

    return _runWithModelPath(
      inputPath: inputPath,
      modelPath: modelPath,
      modelName: modelName,
    );
  }

  Future<OnnxStyleTransferResult> _runWithModelPath({
    required String inputPath,
    required String modelPath,
    required String modelName,
  }) async {
    final outputPath = await _cacheService.writeTempFile(const [], 'jpg');
    try {
      final response = await _channel
          .invokeMapMethod<Object?, Object?>('runStyleTransfer', {
            'modelName': modelName,
            'modelPath': modelPath,
            'inputPath': inputPath,
            'outputPath': outputPath,
          });
      if (response == null) {
        return OnnxStyleTransferResult.error(
          modelName: modelName,
          message: 'ONNX style transfer returned an empty response.',
        );
      }
      return OnnxStyleTransferResult.fromMap(response);
    } on MissingPluginException {
      return OnnxStyleTransferResult.unavailable(
        modelName: modelName,
        message: 'ONNX style transfer is not available on this platform.',
      );
    } on PlatformException catch (error) {
      return OnnxStyleTransferResult.error(
        modelName: modelName,
        message: error.message ?? 'ONNX style transfer failed.',
      );
    }
  }

  Future<String?> _copyModelAssetToCache(OnnxStyleTransferModel model) async {
    final bytes = await _loadOptionalAsset(model.assetPath);
    if (bytes == null) {
      return null;
    }
    return _cacheService.writeTempFile(bytes.buffer.asUint8List(), 'onnx');
  }

  Future<ByteData?> _loadOptionalAsset(String assetPath) async {
    try {
      return await _assetBundle.load(assetPath);
    } on FlutterError {
      return null;
    }
  }
}
