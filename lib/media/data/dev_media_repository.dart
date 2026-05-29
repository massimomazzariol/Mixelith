import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/media_asset.dart';
import '../domain/media_asset_availability.dart';
import '../domain/media_asset_file.dart';
import '../domain/media_permission_status.dart';
import '../domain/media_repository.dart';

class DevMediaRepository implements MediaRepository {
  const DevMediaRepository();

  static const int _assetCount = 12;

  @override
  Future<bool> checkPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<MediaPermissionStatus> getPermissionStatus() async {
    return MediaPermissionStatus.authorized;
  }

  @override
  Future<MediaPermissionStatus> requestPermissionStatus() async {
    return MediaPermissionStatus.authorized;
  }

  @override
  Future<List<MediaAsset>> getRecentAssets({
    int page = 0,
    int pageSize = 50,
  }) async {
    if (page < 0 || pageSize <= 0 || page > 0) {
      return const [];
    }

    return List.generate(_assetCount, (index) {
      return MediaAsset(
        id: 'dev-preview-${index + 1}',
        width: 1200 + index * 40,
        height: 900 + index * 24,
        availability: MediaAssetAvailability.localAvailable,
        createdAt: DateTime(2026, 1, 1).add(Duration(days: index)),
      );
    });
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
    if (asset.availability != MediaAssetAvailability.localAvailable) {
      return null;
    }

    try {
      final file = await _ensurePlaceholderFile(asset);
      return MediaAssetFile(
        path: file.path,
        extension: 'png',
        width: asset.width,
        height: asset.height,
        availability: MediaAssetAvailability.localAvailable,
      );
    } on FileSystemException {
      return null;
    } on img.ImageException {
      return null;
    }
  }

  Future<File> _ensurePlaceholderFile(MediaAsset asset) async {
    final directory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}mixelith_dev_media',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final filename = '${_safeFilename(asset.id)}.png';
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    if (await file.exists()) {
      return file;
    }

    final image = _buildPlaceholderImage(asset);
    await file.writeAsBytes(img.encodePng(image), flush: true);
    return file;
  }

  img.Image _buildPlaceholderImage(MediaAsset asset) {
    final width = asset.width.clamp(1, 1600).toInt();
    final height = asset.height.clamp(1, 1200).toInt();
    final hueShift = asset.id.hashCode.abs() % 64;
    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      final vertical = y / height;
      for (var x = 0; x < width; x++) {
        final horizontal = x / width;
        final tile = ((x ~/ 80) + (y ~/ 80)).isEven ? 18 : 34;
        final r = (18 + 70 * horizontal + tile + hueShift).clamp(0, 255);
        final g = (56 + 158 * (1 - vertical) + tile).clamp(0, 255);
        final b = (115 + 112 * vertical + 58 * horizontal).clamp(0, 255);
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  String _safeFilename(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
