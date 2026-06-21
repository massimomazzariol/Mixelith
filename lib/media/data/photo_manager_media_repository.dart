import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart' as pm;

import '../domain/media_asset.dart';
import '../domain/media_asset_availability.dart';
import '../domain/media_asset_file.dart';
import '../domain/media_permission_status.dart';
import '../domain/media_repository.dart';

class PhotoManagerMediaRepository implements MediaRepository {
  const PhotoManagerMediaRepository();

  static const pm.PermissionRequestOption _permissionRequestOption =
      pm.PermissionRequestOption(
        androidPermission: pm.AndroidPermission(
          type: pm.RequestType.image,
          mediaLocation: false,
        ),
      );

  @override
  Future<bool> checkPermissions() async {
    final status = await getPermissionStatus();
    return status.hasAccess;
  }

  @override
  Future<bool> requestPermissions() async {
    final status = await requestPermissionStatus();
    return status.hasAccess;
  }

  @override
  Future<MediaPermissionStatus> getPermissionStatus() async {
    try {
      final state = await pm.PhotoManager.getPermissionState(
        requestOption: _permissionRequestOption,
      );
      return _mapPermissionState(state);
    } catch (_) {
      return MediaPermissionStatus.denied;
    }
  }

  @override
  Future<MediaPermissionStatus> requestPermissionStatus() async {
    try {
      final state = await pm.PhotoManager.requestPermissionExtend(
        requestOption: _permissionRequestOption,
      );
      return _mapPermissionState(state);
    } catch (_) {
      return MediaPermissionStatus.denied;
    }
  }

  @override
  Future<List<MediaAsset>> getRecentAssets({
    int page = 0,
    int pageSize = 50,
  }) async {
    if (page < 0 || pageSize <= 0) {
      return const [];
    }

    final hasAccess = await checkPermissions();
    if (!hasAccess) {
      return const [];
    }

    try {
      final paths = await pm.PhotoManager.getAssetPathList(
        onlyAll: true,
        type: pm.RequestType.image,
      );
      if (paths.isEmpty) {
        return _getRecentAssetsFromGlobalList(page: page, pageSize: pageSize);
      }

      final entities = await paths.first.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (entities.isEmpty) {
        return _getRecentAssetsFromGlobalList(page: page, pageSize: pageSize);
      }

      return Future.wait(entities.map(_mapAsset));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Uint8List?> getThumbnailData(
    MediaAsset asset, {
    int width = 200,
    int height = 200,
  }) async {
    if (width <= 0 || height <= 0) {
      return null;
    }

    try {
      final entity = await pm.AssetEntity.fromId(asset.id);
      if (entity == null) {
        return null;
      }

      return entity.thumbnailDataWithSize(
        pm.ThumbnailSize(width, height),
        quality: 85,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MediaAssetFile?> getOriginalFile(MediaAsset asset) async {
    if (asset.availability != MediaAssetAvailability.localAvailable) {
      return null;
    }

    final hasAccess = await checkPermissions();
    if (!hasAccess) {
      return null;
    }

    try {
      final entity = await pm.AssetEntity.fromId(asset.id);
      if (entity == null) {
        return null;
      }

      final availability = await _resolveAvailability(entity);
      if (availability != MediaAssetAvailability.localAvailable) {
        return MediaAssetFile(
          path: '',
          extension: _fallbackExtension(entity),
          width: entity.orientatedWidth,
          height: entity.orientatedHeight,
          availability: availability,
        );
      }

      final file = await entity.originFile ?? await entity.file;
      if (file == null || !await file.exists()) {
        return null;
      }

      return MediaAssetFile(
        path: file.path,
        extension: await _resolveExtension(file, entity),
        width: entity.orientatedWidth,
        height: entity.orientatedHeight,
        availability: availability,
      );
    } catch (_) {
      return null;
    }
  }

  Future<MediaAsset> _mapAsset(pm.AssetEntity entity) async {
    final availability = await _resolveAvailability(entity);

    return MediaAsset(
      id: entity.id,
      width: entity.orientatedWidth,
      height: entity.orientatedHeight,
      availability: availability,
      createdAt: entity.createDateTime,
    );
  }

  Future<List<MediaAsset>> _getRecentAssetsFromGlobalList({
    required int page,
    required int pageSize,
  }) async {
    try {
      final entities = await pm.PhotoManager.getAssetListPaged(
        page: page,
        pageCount: pageSize,
        type: pm.RequestType.image,
      );
      return Future.wait(entities.map(_mapAsset));
    } catch (_) {
      return const [];
    }
  }

  Future<MediaAssetAvailability> _resolveAvailability(
    pm.AssetEntity entity,
  ) async {
    try {
      final isAvailable = await entity.isLocallyAvailable();
      return isAvailable
          ? MediaAssetAvailability.localAvailable
          : MediaAssetAvailability.unavailableCloudOnly;
    } catch (_) {
      return MediaAssetAvailability.unsupportedFormat;
    }
  }

  MediaPermissionStatus _mapPermissionState(pm.PermissionState state) {
    return switch (state) {
      pm.PermissionState.authorized => MediaPermissionStatus.authorized,
      pm.PermissionState.limited => MediaPermissionStatus.limited,
      pm.PermissionState.restricted => MediaPermissionStatus.restricted,
      pm.PermissionState.denied => MediaPermissionStatus.denied,
      pm.PermissionState.notDetermined => MediaPermissionStatus.notDetermined,
    };
  }

  Future<String> _resolveExtension(File file, pm.AssetEntity entity) async {
    final pathExtension = _extensionFromPath(file.path);
    if (pathExtension != null) {
      return pathExtension;
    }

    final mimeType = entity.mimeType ?? await entity.mimeTypeAsync;
    return _extensionFromMimeType(mimeType) ?? _fallbackExtension(entity);
  }

  String _fallbackExtension(pm.AssetEntity entity) {
    return _extensionFromMimeType(entity.mimeType) ?? 'jpg';
  }

  String? _extensionFromPath(String path) {
    final filename = path.split(RegExp(r'[\\/]')).last;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filename.length - 1) {
      return null;
    }

    final extension = filename.substring(dotIndex + 1).toLowerCase();
    if (extension.isEmpty || extension.contains(RegExp(r'[^a-z0-9]'))) {
      return null;
    }

    return extension == 'jpeg' ? 'jpg' : extension;
  }

  String? _extensionFromMimeType(String? mimeType) {
    return switch (mimeType?.toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => null,
    };
  }
}
