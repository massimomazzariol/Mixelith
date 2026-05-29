import 'dart:typed_data';

import 'media_asset.dart';
import 'media_asset_file.dart';
import 'media_permission_status.dart';

abstract class MediaRepository {
  Future<bool> checkPermissions();

  Future<bool> requestPermissions();

  Future<MediaPermissionStatus> getPermissionStatus();

  Future<MediaPermissionStatus> requestPermissionStatus();

  Future<List<MediaAsset>> getRecentAssets({int page = 0, int pageSize = 50});

  Future<Uint8List?> getThumbnailData(
    MediaAsset asset, {
    int width = 200,
    int height = 200,
  });

  Future<MediaAssetFile?> getOriginalFile(MediaAsset asset);
}
