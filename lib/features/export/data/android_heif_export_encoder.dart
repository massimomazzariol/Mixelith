import 'package:flutter/services.dart';

import '../domain/heif_export_encoder.dart';

class AndroidHeifExportEncoder implements HeifExportEncoder {
  const AndroidHeifExportEncoder({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'mixelith/heif_export';

  final MethodChannel _channel;

  @override
  Future<HeifExportResult> encode({
    required String inputPath,
    required String outputPath,
    required int quality,
  }) async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'encodeHeif',
        {'inputPath': inputPath, 'outputPath': outputPath, 'quality': quality},
      );
      if (response == null) {
        throw const HeifExportEncoderException(
          'HEIC export is not available on this device.',
        );
      }
      final result = HeifExportResult.fromMap(response);
      if (result.path.isEmpty || result.width <= 0 || result.height <= 0) {
        throw const HeifExportEncoderException(
          'HEIC export is not available on this device.',
        );
      }
      return result;
    } on HeifExportEncoderException {
      rethrow;
    } on PlatformException catch (error) {
      throw HeifExportEncoderException(
        error.message ?? 'HEIC export is not available on this device.',
        error,
      );
    } on MissingPluginException catch (error) {
      throw HeifExportEncoderException(
        'HEIC export is not available on this device.',
        error,
      );
    }
  }
}
