import 'media_asset_availability.dart';

class MediaAssetFile {
  const MediaAssetFile({
    required this.path,
    required this.extension,
    required this.width,
    required this.height,
    required this.availability,
  });

  final String path;
  final String extension;
  final int width;
  final int height;
  final MediaAssetAvailability availability;
}
