import 'package:flutter/services.dart';

import '../../../media/domain/image_source_format.dart';

abstract class BatchImagePicker {
  Future<BatchImagePickResult> pickImage();

  Future<BatchImagePickResult> pickImages();
}

class MethodChannelBatchImagePicker implements BatchImagePicker {
  const MethodChannelBatchImagePicker({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'mixelith/batch_image_picker';

  final MethodChannel _channel;

  @override
  Future<BatchImagePickResult> pickImage() => _pick('pickImage');

  @override
  Future<BatchImagePickResult> pickImages() => _pick('pickImages');

  Future<BatchImagePickResult> _pick(String method) async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(method);
      if (response == null) {
        return const BatchImagePickResult.failed(
          'Image picker returned an empty response.',
        );
      }
      return BatchImagePickResult.fromMap(response);
    } on MissingPluginException {
      return const BatchImagePickResult.failed(
        'Native photo picker is available on Android builds.',
      );
    } on PlatformException catch (error) {
      return BatchImagePickResult.failed(
        error.message ?? 'Unable to open the native photo picker.',
      );
    }
  }
}

class BatchImagePickResult {
  const BatchImagePickResult({
    required this.items,
    this.pickerApi = ImagePickerApi.unknown,
    this.cancelled = false,
    this.errorMessage,
  });

  const BatchImagePickResult.cancelled({
    this.pickerApi = ImagePickerApi.unknown,
  }) : items = const [],
       cancelled = true,
       errorMessage = null;

  const BatchImagePickResult.failed(String message)
    : items = const [],
      pickerApi = ImagePickerApi.unknown,
      cancelled = false,
      errorMessage = message;

  factory BatchImagePickResult.fromMap(Map<Object?, Object?> map) {
    final status = map['status'] as String? ?? 'failed';
    final pickerApi = ImagePickerApi.fromPlatformValue(
      map['pickerApi'] as String?,
    );
    if (status == 'cancelled') {
      return BatchImagePickResult.cancelled(pickerApi: pickerApi);
    }

    final rawItems = map['items'];
    final items = rawItems is List
        ? [
            for (final item in rawItems)
              if (item is Map)
                BatchPickedImage.fromMap(
                  item.map((key, value) => MapEntry('$key', value)),
                ),
          ]
        : const <BatchPickedImage>[];
    final success = map['success'] == true;
    final message = map['message'] as String?;
    final rawErrors = map['errors'];
    final errors = rawErrors is List
        ? rawErrors.whereType<String>().toList(growable: false)
        : const <String>[];
    final errorMessage =
        message ??
        (errors.isEmpty ? null : errors.join('\n')) ??
        (success ? null : 'Unable to import selected photos.');

    return BatchImagePickResult(
      items: items,
      pickerApi: pickerApi,
      errorMessage: errorMessage,
    );
  }

  final List<BatchPickedImage> items;
  final ImagePickerApi pickerApi;
  final bool cancelled;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
}

enum ImagePickerApi {
  androidPhotoPicker,
  actionOpenDocument,
  unknown;

  String get label {
    return switch (this) {
      ImagePickerApi.androidPhotoPicker => 'Android Photo Picker',
      ImagePickerApi.actionOpenDocument => 'ACTION_OPEN_DOCUMENT',
      ImagePickerApi.unknown => 'Unknown',
    };
  }

  static ImagePickerApi fromPlatformValue(String? value) {
    return switch (value) {
      'android_photo_picker' => ImagePickerApi.androidPhotoPicker,
      'action_open_document' => ImagePickerApi.actionOpenDocument,
      _ => ImagePickerApi.unknown,
    };
  }
}

class BatchPickedImage {
  const BatchPickedImage({
    required this.id,
    required this.path,
    required this.displayName,
    required this.extension,
    this.mimeType,
    required this.width,
    required this.height,
  });

  factory BatchPickedImage.fromMap(Map<String, Object?> map) {
    return BatchPickedImage(
      id: map['id'] as String? ?? 'picked_image',
      path: map['path'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Picked photo',
      extension: map['extension'] as String? ?? 'jpg',
      mimeType: map['mimeType'] as String?,
      width: _asInt(map['width']) ?? 0,
      height: _asInt(map['height']) ?? 0,
    );
  }

  final String id;
  final String path;
  final String displayName;
  final String extension;
  final String? mimeType;
  final int width;
  final int height;

  ImageSourceFormat get sourceFormat {
    final byMime = imageSourceFormatFromMimeType(mimeType);
    if (byMime != ImageSourceFormat.unknown) {
      return byMime;
    }
    return imageSourceFormatFromExtension(extension);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return null;
  }
}
