import 'dart:typed_data';

import 'package:mixelith/media/domain/media_asset.dart';
import 'package:mixelith/media/domain/media_asset_file.dart';
import 'package:mixelith/media/domain/media_permission_status.dart';
import 'package:mixelith/media/domain/media_repository.dart';

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({
    this.permissionStatus = MediaPermissionStatus.notDetermined,
    MediaPermissionStatus? requestPermissionResult,
    Map<int, List<MediaAsset>>? pages,
    Map<String, MediaAssetFile?>? originalFiles,
  }) : requestPermissionResult = requestPermissionResult ?? permissionStatus,
       pages = pages ?? const {},
       originalFiles = originalFiles ?? const {};

  MediaPermissionStatus permissionStatus;
  MediaPermissionStatus requestPermissionResult;
  Map<int, List<MediaAsset>> pages;
  Map<String, MediaAssetFile?> originalFiles;

  int requestedPermissions = 0;
  final List<int> requestedPages = [];

  @override
  Future<bool> checkPermissions() async => permissionStatus.hasAccess;

  @override
  Future<bool> requestPermissions() async {
    final status = await requestPermissionStatus();
    return status.hasAccess;
  }

  @override
  Future<MediaPermissionStatus> getPermissionStatus() async => permissionStatus;

  @override
  Future<MediaPermissionStatus> requestPermissionStatus() async {
    requestedPermissions++;
    permissionStatus = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<List<MediaAsset>> getRecentAssets({
    int page = 0,
    int pageSize = 50,
  }) async {
    requestedPages.add(page);
    return pages[page] ?? const [];
  }

  @override
  Future<Uint8List?> getThumbnailData(
    MediaAsset asset, {
    int width = 200,
    int height = 200,
  }) async {
    return null;
  }

  @override
  Future<MediaAssetFile?> getOriginalFile(MediaAsset asset) async {
    return originalFiles[asset.id];
  }
}
