import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../core/policy/image_size_policy.dart';
import '../../../media/domain/media_asset.dart';
import '../../../media/domain/media_asset_availability.dart';
import '../../../media/domain/media_repository.dart';
import '../../../storage/domain/cache_service.dart';
import '../../editor/domain/working_image.dart';

class WorkingImageImportService {
  const WorkingImageImportService({
    required MediaRepository mediaRepository,
    required CacheService cacheService,
  }) : _mediaRepository = mediaRepository,
       _cacheService = cacheService;

  final MediaRepository _mediaRepository;
  final CacheService _cacheService;

  Future<WorkingImage> importAsset(MediaAsset asset) async {
    final sourceFile = await _mediaRepository.getOriginalFile(asset);
    if (sourceFile == null) {
      throw const WorkingImageImportException(
        WorkingImageImportFailure.sourceUnavailable,
        'Unable to open this photo from local storage.',
      );
    }

    if (sourceFile.availability ==
        MediaAssetAvailability.unavailableCloudOnly) {
      throw const WorkingImageImportException(
        WorkingImageImportFailure.unavailableCloudOnly,
        'This photo is not available locally. Mixelith works offline and cannot download images from the cloud.',
      );
    }

    if (sourceFile.path.isEmpty) {
      throw const WorkingImageImportException(
        WorkingImageImportFailure.sourceUnavailable,
        'Unable to open this photo from local storage.',
      );
    }

    return _importLocalFile(
      sourcePath: sourceFile.path,
      sourceAssetId: asset.id,
      extension: sourceFile.extension,
    );
  }

  Future<WorkingImage> importFromFilePath({
    required String sourcePath,
    required String sourceAssetId,
    String? extension,
  }) async {
    if (sourcePath.trim().isEmpty) {
      throw const WorkingImageImportException(
        WorkingImageImportFailure.sourceUnavailable,
        'Unable to open this photo from local storage.',
      );
    }

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw const WorkingImageImportException(
          WorkingImageImportFailure.sourceUnavailable,
          'Unable to open this photo from local storage.',
        );
      }
    } on WorkingImageImportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw WorkingImageImportException(
        WorkingImageImportFailure.sourceUnavailable,
        'Unable to open this photo from local storage.',
        error,
      );
    }

    return _importLocalFile(
      sourcePath: sourcePath,
      sourceAssetId: sourceAssetId,
      extension: _resolveExtension(sourcePath, extension),
    );
  }

  Future<WorkingImage> _importLocalFile({
    required String sourcePath,
    required String sourceAssetId,
    required String extension,
  }) async {
    final originalTempPath = await _cacheService.copyTempFileFromPath(
      sourcePath,
      extension,
    );
    final preview = await _generatePreview(originalTempPath);
    final previewPath = await _cacheService.writeTempFile(
      preview.bytes,
      preview.extension,
    );

    return WorkingImage(
      sourceAssetId: sourceAssetId,
      originalTempPath: originalTempPath,
      previewPath: previewPath,
      originalWidth: preview.originalWidth,
      originalHeight: preview.originalHeight,
      previewWidth: preview.width,
      previewHeight: preview.height,
      createdAt: DateTime.now(),
      wasPreviewDownscaled: preview.wasDownscaled,
      originalExtension: extension,
    );
  }

  Future<_GeneratedPreview> _generatePreview(String sourcePath) async {
    try {
      final result = await compute(_generatePreviewInBackground, {
        'sourcePath': sourcePath,
        'maxLongSide': ImageSizePolicy.previewMaxLongSide.toInt(),
      });
      return _GeneratedPreview.fromMap(result);
    } on WorkingImageImportException {
      rethrow;
    } catch (error) {
      throw WorkingImageImportException(
        WorkingImageImportFailure.previewGenerationFailed,
        'Unable to prepare preview.',
        error,
      );
    }
  }
}

String _resolveExtension(String sourcePath, String? preferredExtension) {
  final preferred = preferredExtension?.trim().toLowerCase().replaceFirst(
    RegExp(r'^\.+'),
    '',
  );
  if (preferred != null &&
      preferred.isNotEmpty &&
      !preferred.contains('/') &&
      !preferred.contains(r'\')) {
    return preferred;
  }

  final filename = sourcePath.split(RegExp(r'[\\/]')).last;
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex >= 0 && dotIndex < filename.length - 1) {
    final extension = filename.substring(dotIndex + 1).toLowerCase();
    if (!extension.contains('/') && !extension.contains(r'\')) {
      return extension;
    }
  }

  return 'jpg';
}

Map<String, Object> _generatePreviewInBackground(Map<String, Object> request) {
  final sourcePath = request['sourcePath']! as String;
  final maxLongSide = request['maxLongSide']! as int;
  final bytes = File(sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    throw const WorkingImageImportException(
      WorkingImageImportFailure.previewGenerationFailed,
      'Unable to read this photo.',
    );
  }

  final originalWidth = decoded.width;
  final originalHeight = decoded.height;
  final longestSide = math.max(originalWidth, originalHeight);
  final wasDownscaled = longestSide > maxLongSide;
  final previewImage = wasDownscaled
      ? img.copyResize(
          decoded,
          width: originalWidth >= originalHeight ? maxLongSide : null,
          height: originalHeight > originalWidth ? maxLongSide : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final encoded = Uint8List.fromList(img.encodeJpg(previewImage, quality: 88));

  return {
    'bytes': encoded,
    'extension': 'jpg',
    'originalWidth': originalWidth,
    'originalHeight': originalHeight,
    'width': previewImage.width,
    'height': previewImage.height,
    'wasDownscaled': wasDownscaled,
  };
}

class _GeneratedPreview {
  const _GeneratedPreview({
    required this.bytes,
    required this.extension,
    required this.originalWidth,
    required this.originalHeight,
    required this.width,
    required this.height,
    required this.wasDownscaled,
  });

  factory _GeneratedPreview.fromMap(Map<String, Object> map) {
    return _GeneratedPreview(
      bytes: map['bytes']! as Uint8List,
      extension: map['extension']! as String,
      originalWidth: map['originalWidth']! as int,
      originalHeight: map['originalHeight']! as int,
      width: map['width']! as int,
      height: map['height']! as int,
      wasDownscaled: map['wasDownscaled']! as bool,
    );
  }

  final Uint8List bytes;
  final String extension;
  final int originalWidth;
  final int originalHeight;
  final int width;
  final int height;
  final bool wasDownscaled;
}

enum WorkingImageImportFailure {
  sourceUnavailable,
  unavailableCloudOnly,
  previewGenerationFailed,
}

class WorkingImageImportException implements Exception {
  const WorkingImageImportException(this.failure, this.message, [this.cause]);

  final WorkingImageImportFailure failure;
  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'WorkingImageImportException: $message';
    }
    return 'WorkingImageImportException: $message ($cause)';
  }
}
