import 'media_asset_availability.dart';

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.width,
    required this.height,
    required this.availability,
    this.createdAt,
  });

  final String id;
  final int width;
  final int height;
  final MediaAssetAvailability availability;
  final DateTime? createdAt;
}
