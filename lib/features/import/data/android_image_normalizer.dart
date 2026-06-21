import 'package:flutter/services.dart';

import '../domain/image_normalizer.dart';

class AndroidImageNormalizer implements ImageNormalizer {
  const AndroidImageNormalizer({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'mixelith/image_normalizer';

  final MethodChannel _channel;

  @override
  Future<ImageNormalizationResult> normalizeHeif({
    required String sourcePath,
    required int previewMaxLongSide,
  }) async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'normalizeHeif',
        {'sourcePath': sourcePath, 'previewMaxLongSide': previewMaxLongSide},
      );
      if (response == null) {
        throw const ImageNormalizerException(
          'This HEIC photo could not be imported on this device.',
        );
      }
      final normalized = ImageNormalizationResult.fromMap(response);
      if (normalized.originalPath.isEmpty || normalized.previewPath.isEmpty) {
        throw const ImageNormalizerException(
          'This HEIC photo could not be imported on this device.',
        );
      }
      return normalized;
    } on ImageNormalizerException {
      rethrow;
    } on PlatformException catch (error) {
      throw ImageNormalizerException(
        error.message ??
            'This HEIC photo could not be imported on this device.',
        error,
      );
    } on MissingPluginException catch (error) {
      throw ImageNormalizerException(
        'This HEIC photo could not be imported on this device.',
        error,
      );
    }
  }
}
