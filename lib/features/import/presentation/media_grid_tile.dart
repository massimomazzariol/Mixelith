import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../media/domain/media_asset.dart';
import '../../../media/domain/media_asset_availability.dart';
import '../providers/import_gallery_controller.dart';

class MediaGridTile extends ConsumerWidget {
  const MediaGridTile({required this.asset, required this.onTap, super.key});

  final MediaAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = ref.watch(
      mediaThumbnailProvider(MediaThumbnailRequest(asset: asset)),
    );
    final isCloudOnly =
        asset.availability == MediaAssetAvailability.unavailableCloudOnly;

    return Semantics(
      button: true,
      label: 'Photo ${asset.width} by ${asset.height}',
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: MixelithColors.surfaceElevated,
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: thumbnail.when(
                data: (bytes) {
                  if (bytes == null) {
                    return _MissingThumbnail(assetId: asset.id);
                  }

                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.low,
                  );
                },
                error: (_, _) => _MissingThumbnail(assetId: asset.id),
                loading: () => const Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x22000000)],
                ),
              ),
            ),
            if (isCloudOnly) const _CloudOnlyOverlay(),
          ],
        ),
      ),
    );
  }
}

class _MissingThumbnail extends StatelessWidget {
  const _MissingThumbnail({required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    final hue = (assetId.hashCode % 360).abs().toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, (18 + hue * 0.08) % 360, 0.88, 0.48).toColor(),
            HSLColor.fromAHSL(
              1,
              (348 + hue * 0.05) % 360,
              0.78,
              0.24,
            ).toColor(),
            const Color(0xFF1B1017),
          ],
        ),
      ),
      child: Center(
        child: const Icon(
          Icons.image_outlined,
          color: MixelithColors.textPrimary,
        ),
      ),
    );
  }
}

class _CloudOnlyOverlay extends StatelessWidget {
  const _CloudOnlyOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.56)),
      child: const Center(
        child: Icon(Icons.cloud_off_outlined, color: Colors.white, size: 26),
      ),
    );
  }
}
