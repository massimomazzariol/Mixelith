import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../filters/onnx/onnx_style_transfer_engine.dart';
import '../../../filters/onnx/onnx_style_transfer_result.dart';
import '../../../storage/domain/cache_service.dart';
import '../domain/local_onnx_model.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

typedef OnnxRuntimeValidator =
    Future<OnnxStyleTransferResult> Function({
      required String modelPath,
      required String modelName,
    });

abstract class LocalOnnxModelRepository {
  Future<List<LocalOnnxModel>> loadModels();

  Future<LocalOnnxModel?> importModel();
}

class MethodChannelLocalOnnxModelRepository
    implements LocalOnnxModelRepository {
  MethodChannelLocalOnnxModelRepository({
    required CacheService cacheService,
    MethodChannel channel = const MethodChannel(_channelName),
    SupportDirectoryProvider? supportDirectoryProvider,
    OnnxRuntimeValidator? runtimeValidator,
    DateTime Function()? now,
  }) : _cacheService = cacheService,
       _channel = channel,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _runtimeValidator = runtimeValidator,
       _now = now ?? DateTime.now;

  static const _channelName = 'mixelith/onnx_model_import';

  final CacheService _cacheService;
  final MethodChannel _channel;
  final SupportDirectoryProvider _supportDirectoryProvider;
  final OnnxRuntimeValidator? _runtimeValidator;
  final DateTime Function() _now;

  @override
  Future<List<LocalOnnxModel>> loadModels() async {
    final file = await _metadataFile();
    if (!await file.exists()) {
      return const [];
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final item in decoded)
          if (item is Map)
            LocalOnnxModel.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
      ];
    } on FormatException {
      return const [];
    } on FileSystemException {
      return const [];
    }
  }

  @override
  Future<LocalOnnxModel?> importModel() async {
    final existing = await loadModels();
    final response = await _channel.invokeMapMethod<Object?, Object?>(
      'pickAndImportModel',
    );
    if (response == null) {
      throw const LocalOnnxModelImportException(
        'ONNX model import returned an empty response.',
      );
    }

    final status = response['status'] as String? ?? 'failed_validation';
    if (status == 'cancelled') {
      return null;
    }

    final imported = _modelFromResponse(response, existing.length + 1);
    final validated = await _validateIfPossible(imported, nativeStatus: status);
    await _saveModels([...existing, validated]);
    return validated;
  }

  LocalOnnxModel _modelFromResponse(
    Map<Object?, Object?> response,
    int sequence,
  ) {
    final inputShape = _shape(response['inputShape']);
    final outputShape = _shape(response['outputShape']);
    final nativeStatus = response['status'] as String? ?? 'failed_validation';
    final nativeReason = response['message'] as String?;
    final fixedReason = LocalOnnxModel.fixedInputRejection(inputShape);
    final status = switch (nativeStatus) {
      'rejected' => LocalOnnxModelStatus.rejected,
      'inspected' when fixedReason == null =>
        LocalOnnxModelStatus.failedValidation,
      'inspected' => LocalOnnxModelStatus.rejected,
      _ => LocalOnnxModelStatus.failedValidation,
    };

    return LocalOnnxModel(
      id:
          response['id'] as String? ??
          'local_onnx_${_now().millisecondsSinceEpoch}',
      displayLabel: _displayLabelFromResponse(response, sequence),
      storedPath: response['storedPath'] as String? ?? '',
      fileSizeBytes: _asInt(response['fileSizeBytes']) ?? 0,
      inputShape: inputShape,
      outputShape: outputShape,
      status: status,
      importedAt: _now(),
      rejectionReason: nativeReason ?? fixedReason,
    );
  }

  Future<LocalOnnxModel> _validateIfPossible(
    LocalOnnxModel model, {
    required String nativeStatus,
  }) async {
    if (nativeStatus != 'inspected' ||
        model.status == LocalOnnxModelStatus.rejected) {
      return model;
    }

    final fixedReason = LocalOnnxModel.fixedInputRejection(model.inputShape);
    if (fixedReason != null) {
      return model.copyWith(
        status: LocalOnnxModelStatus.rejected,
        rejectionReason: fixedReason,
      );
    }

    final validator = _runtimeValidator ?? _defaultRuntimeValidator;
    final result = await validator(
      modelPath: model.storedPath,
      modelName: model.displayLabel,
    );
    if (result.isSuccess && result.isFullFrameOutput) {
      return model.copyWith(
        status: LocalOnnxModelStatus.usable,
        inputShape: result.inputShape.isEmpty
            ? model.inputShape
            : result.inputShape,
        outputShape: result.outputShape.isEmpty
            ? model.outputShape
            : result.outputShape,
      );
    }

    return model.copyWith(
      status: result.status == OnnxStyleTransferStatus.fixedSizeRejected
          ? LocalOnnxModelStatus.rejected
          : LocalOnnxModelStatus.failedValidation,
      rejectionReason: result.isSuccess
          ? 'ONNX runtime output dimensions did not match the input dimensions.'
          : result.message,
    );
  }

  Future<OnnxStyleTransferResult> _defaultRuntimeValidator({
    required String modelPath,
    required String modelName,
  }) async {
    final imagePath = await _writeValidationImage();
    return OnnxStyleTransferEngine(cacheService: _cacheService).runLocalModel(
      inputPath: imagePath,
      modelPath: modelPath,
      modelName: modelName,
    );
  }

  Future<String> _writeValidationImage() async {
    final image = img.Image(width: 320, height: 240);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgb(x, y, (x + y) % 255, (x * 2) % 255, (y * 3) % 255);
      }
    }
    return _cacheService.writeTempFile(img.encodeJpg(image), 'jpg');
  }

  Future<File> _metadataFile() async {
    final directory = await _supportDirectoryProvider();
    final modelsDirectory = Directory(
      _joinPath(directory.path, 'local_onnx_models'),
    );
    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(recursive: true);
    }
    return File(_joinPath(modelsDirectory.path, 'models.json'));
  }

  Future<void> _saveModels(List<LocalOnnxModel> models) async {
    final file = await _metadataFile();
    final encoded = jsonEncode([for (final model in models) model.toJson()]);
    await file.writeAsString(encoded, flush: true);
  }

  List<int> _shape(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<num>().map((item) => item.round()).toList();
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return null;
  }

  String _joinPath(String parent, String child) {
    final separator = Platform.pathSeparator;
    return parent.endsWith(separator)
        ? '$parent$child'
        : '$parent$separator$child';
  }

  String _displayLabelFromResponse(
    Map<Object?, Object?> response,
    int sequence,
  ) {
    final displayName = response['displayName'] as String?;
    final fileName = displayName?.split(RegExp(r'[\\/]')).last.trim();
    final label = fileName
        ?.replaceFirst(RegExp(r'\.onnx$', caseSensitive: false), '')
        .trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return 'Local model $sequence';
  }
}

class LocalOnnxModelImportException implements Exception {
  const LocalOnnxModelImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
