import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' deferred as tfl
    hide ListShape;

import '../../storage/domain/cache_service.dart';
import 'ml_style_transfer_model_paths.dart';
import 'ml_style_transfer_result.dart';
import 'style_reference_registry.dart';

typedef BinaryAssetLoader = Future<ByteData> Function(String assetPath);

class MlStyleTransferEngine {
  MlStyleTransferEngine({
    required CacheService cacheService,
    BinaryAssetLoader? assetLoader,
    bool? isAndroidOverride,
  }) : _cacheService = cacheService,
       _assetLoader = assetLoader ?? rootBundle.load,
       _isAndroidOverride = isAndroidOverride;

  final CacheService _cacheService;
  final BinaryAssetLoader _assetLoader;
  final bool? _isAndroidOverride;

  bool get _canRunOnCurrentPlatform => _isAndroidOverride ?? Platform.isAndroid;

  Future<bool> areModelsAvailable() async {
    for (final assetPath in MlStyleTransferModelPaths.allModelAssets) {
      if (!await _assetExists(assetPath)) {
        return false;
      }
    }
    return true;
  }

  Future<MlStyleTransferResult> apply({
    required String contentImagePath,
    required StyleReference styleReference,
  }) async {
    if (!await areModelsAvailable()) {
      return MlStyleTransferResult.unavailable(
        'Local style transfer models are not installed.',
      );
    }

    if (!_canRunOnCurrentPlatform) {
      return MlStyleTransferResult.unavailable(
        'Local style transfer is currently enabled only on Android.',
      );
    }

    if (!await _assetExists(styleReference.assetPath)) {
      return MlStyleTransferResult.unavailable(
        'The selected style reference is not available.',
      );
    }

    final startedAt = DateTime.now();
    dynamic predictionInterpreter;
    dynamic transferInterpreter;

    try {
      await tfl.loadLibrary();

      final predictionBytes = await _readAssetBytes(
        MlStyleTransferModelPaths.predictionAsset,
      );
      final transferBytes = await _readAssetBytes(
        MlStyleTransferModelPaths.transferAsset,
      );
      final styleBytes = await _readAssetBytes(styleReference.assetPath);

      predictionInterpreter = tfl.Interpreter.fromBuffer(predictionBytes);
      transferInterpreter = tfl.Interpreter.fromBuffer(transferBytes);

      final predictionInputs = predictionInterpreter.getInputTensors() as List;
      final predictionOutputs =
          predictionInterpreter.getOutputTensors() as List;
      final transferInputs = transferInterpreter.getInputTensors() as List;
      final transferOutputs = transferInterpreter.getOutputTensors() as List;

      final tensorSummary = _summarizeTensors(
        predictionInputs: predictionInputs,
        predictionOutputs: predictionOutputs,
        transferInputs: transferInputs,
        transferOutputs: transferOutputs,
      );

      if (predictionInputs.length != 1 || predictionOutputs.length != 1) {
        return MlStyleTransferResult.unsupported(
          message: 'Unexpected style prediction tensor count.',
          tensorSummary: tensorSummary,
        );
      }

      final predictionInput = predictionInputs.single;
      final predictionOutput = predictionOutputs.single;
      if (!_isImageTensor(predictionInput)) {
        return MlStyleTransferResult.unsupported(
          message: 'Style prediction input is not an image tensor.',
          tensorSummary: tensorSummary,
        );
      }

      final styleInputBytes = _imageBytesToTensorBytes(
        imageBytes: styleBytes,
        tensor: predictionInput,
      );
      predictionInput.data = styleInputBytes;
      predictionInterpreter.invoke();
      final styleEmbedding = Uint8List.fromList(predictionOutput.data);

      final contentInputIndex = _findImageTensorIndex(transferInputs);
      final outputIndex = _findImageTensorIndex(transferOutputs);
      if (contentInputIndex == -1 || outputIndex == -1) {
        return MlStyleTransferResult.unsupported(
          message: 'Transfer model does not expose the expected image tensors.',
          tensorSummary: tensorSummary,
        );
      }

      final styleInputIndex = _findStyleTensorIndex(
        transferInputs,
        contentInputIndex,
        styleEmbedding.length,
      );
      if (styleInputIndex == -1) {
        return MlStyleTransferResult.unsupported(
          message:
              'Transfer model style tensor does not match prediction output.',
          tensorSummary: tensorSummary,
        );
      }

      final contentInput = transferInputs[contentInputIndex];
      final styleInput = transferInputs[styleInputIndex];
      final outputTensor = transferOutputs[outputIndex];
      final contentTensorBytes = _imageFileToTensorBytes(
        imagePath: contentImagePath,
        tensor: contentInput,
      );

      contentInput.data = contentTensorBytes;
      styleInput.data = styleEmbedding;
      transferInterpreter.invoke();

      final outputImage = _tensorBytesToImage(
        tensorBytes: Uint8List.fromList(outputTensor.data),
        tensor: outputTensor,
      );
      final encoded = Uint8List.fromList(img.encodeJpg(outputImage, quality: 90));
      final outputPath = await _cacheService.writeTempFile(encoded, 'jpg');

      return MlStyleTransferResult.success(
        outputPath: outputPath,
        width: outputImage.width,
        height: outputImage.height,
        processingTime: DateTime.now().difference(startedAt),
        tensorSummary: tensorSummary,
      );
    } catch (error) {
      return MlStyleTransferResult.error(
        'Unable to run local style transfer: $error',
      );
    } finally {
      predictionInterpreter?.close();
      transferInterpreter?.close();
    }
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await _assetLoader(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> _readAssetBytes(String assetPath) async {
    final data = await _assetLoader(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  String _summarizeTensors({
    required List predictionInputs,
    required List predictionOutputs,
    required List transferInputs,
    required List transferOutputs,
  }) {
    return [
      'prediction inputs: ${_tensorListSummary(predictionInputs)}',
      'prediction outputs: ${_tensorListSummary(predictionOutputs)}',
      'transfer inputs: ${_tensorListSummary(transferInputs)}',
      'transfer outputs: ${_tensorListSummary(transferOutputs)}',
    ].join('; ');
  }

  String _tensorListSummary(List tensors) {
    return tensors
        .map(
          (tensor) =>
              '${tensor.name} ${tensor.type} shape=${tensor.shape} bytes=${tensor.numBytes()}',
        )
        .join(', ');
  }

  int _findImageTensorIndex(List tensors) {
    return tensors.indexWhere(_isImageTensor);
  }

  int _findStyleTensorIndex(
    List tensors,
    int contentInputIndex,
    int expectedBytes,
  ) {
    for (var i = 0; i < tensors.length; i++) {
      if (i == contentInputIndex) {
        continue;
      }
      final tensor = tensors[i];
      if (tensor.numBytes() == expectedBytes) {
        return i;
      }
    }
    return -1;
  }

  bool _isImageTensor(dynamic tensor) {
    final shape = List<int>.from(tensor.shape as List);
    return shape.length == 4 && shape.last == 3 && tensor.numBytes() > 0;
  }

  Uint8List _imageFileToTensorBytes({
    required String imagePath,
    required dynamic tensor,
  }) {
    return _imageBytesToTensorBytes(
      imageBytes: File(imagePath).readAsBytesSync(),
      tensor: tensor,
    );
  }

  Uint8List _imageBytesToTensorBytes({
    required Uint8List imageBytes,
    required dynamic tensor,
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw StateError('Unable to decode style transfer image.');
    }

    final shape = List<int>.from(tensor.shape as List);
    final targetHeight = shape[1];
    final targetWidth = shape[2];
    final oriented = img.bakeOrientation(decoded);
    final resized = img.copyResize(
      oriented,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
    final byteCount = tensor.numBytes() as int;
    final bytes = Uint8List(byteCount);
    final byteData = ByteData.sublistView(bytes);
    var offset = 0;

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        offset = _writeTensorChannel(bytes, byteData, offset, tensor, pixel.r);
        offset = _writeTensorChannel(bytes, byteData, offset, tensor, pixel.g);
        offset = _writeTensorChannel(bytes, byteData, offset, tensor, pixel.b);
      }
    }

    return bytes;
  }

  int _writeTensorChannel(
    Uint8List bytes,
    ByteData byteData,
    int offset,
    dynamic tensor,
    num channelValue,
  ) {
    final typeValue = tensor.type.value as int;
    final params = tensor.params;
    if (typeValue == tfl.TfLiteType.kTfLiteFloat32) {
      byteData.setFloat32(offset, channelValue / 255.0, Endian.little);
      return offset + 4;
    }

    if (typeValue == tfl.TfLiteType.kTfLiteUInt8) {
      bytes[offset] = _quantizeUnsigned(channelValue, params);
      return offset + 1;
    }

    if (typeValue == tfl.TfLiteType.kTfLiteInt8) {
      byteData.setInt8(offset, _quantizeSigned(channelValue, params));
      return offset + 1;
    }

    throw UnsupportedError('Unsupported input tensor type: ${tensor.type}');
  }

  int _quantizeUnsigned(num channelValue, dynamic params) {
    final normalized = channelValue / 255.0;
    final scale = params.scale as double;
    final zeroPoint = params.zeroPoint as int;
    if (scale > 0 && scale < 1) {
      return (normalized / scale + zeroPoint).round().clamp(0, 255);
    }
    return channelValue.round().clamp(0, 255);
  }

  int _quantizeSigned(num channelValue, dynamic params) {
    final normalized = channelValue / 255.0;
    final scale = params.scale as double;
    final zeroPoint = params.zeroPoint as int;
    if (scale > 0 && scale < 1) {
      return (normalized / scale + zeroPoint).round().clamp(-128, 127);
    }
    return (channelValue - 128).round().clamp(-128, 127);
  }

  img.Image _tensorBytesToImage({
    required Uint8List tensorBytes,
    required dynamic tensor,
  }) {
    final shape = List<int>.from(tensor.shape as List);
    final height = shape[1];
    final width = shape[2];
    final output = img.Image(width: width, height: height);
    final byteData = ByteData.sublistView(tensorBytes);
    var offset = 0;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final r = _readTensorChannel(tensorBytes, byteData, offset, tensor);
        offset += _tensorChannelByteWidth(tensor);
        final g = _readTensorChannel(tensorBytes, byteData, offset, tensor);
        offset += _tensorChannelByteWidth(tensor);
        final b = _readTensorChannel(tensorBytes, byteData, offset, tensor);
        offset += _tensorChannelByteWidth(tensor);
        output.setPixelRgb(x, y, r, g, b);
      }
    }

    return output;
  }

  int _readTensorChannel(
    Uint8List bytes,
    ByteData byteData,
    int offset,
    dynamic tensor,
  ) {
    final typeValue = tensor.type.value as int;
    final params = tensor.params;
    if (typeValue == tfl.TfLiteType.kTfLiteFloat32) {
      final value = byteData.getFloat32(offset, Endian.little);
      return _channelToByte(value);
    }

    if (typeValue == tfl.TfLiteType.kTfLiteUInt8) {
      final raw = bytes[offset];
      final scale = params.scale as double;
      final zeroPoint = params.zeroPoint as int;
      if (scale > 0 && scale < 1) {
        return _channelToByte(scale * (raw - zeroPoint));
      }
      return raw;
    }

    if (typeValue == tfl.TfLiteType.kTfLiteInt8) {
      final raw = byteData.getInt8(offset);
      final scale = params.scale as double;
      final zeroPoint = params.zeroPoint as int;
      if (scale > 0 && scale < 1) {
        return _channelToByte(scale * (raw - zeroPoint));
      }
      return (raw + 128).clamp(0, 255);
    }

    throw UnsupportedError('Unsupported output tensor type: ${tensor.type}');
  }

  int _tensorChannelByteWidth(dynamic tensor) {
    final typeValue = tensor.type.value as int;
    if (typeValue == tfl.TfLiteType.kTfLiteFloat32) {
      return 4;
    }
    return 1;
  }

  int _channelToByte(num value) {
    if (value >= 0.0 && value <= 1.5) {
      return (value * 255.0).round().clamp(0, 255);
    }
    return value.round().clamp(0, 255);
  }
}
