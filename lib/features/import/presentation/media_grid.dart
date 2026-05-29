import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../media/domain/media_asset.dart';
import 'media_grid_tile.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    required this.assets,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onAssetSelected,
    super.key,
  });

  final List<MediaAsset> assets;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final ValueChanged<MediaAsset> onAssetSelected;

  @override
  Widget build(BuildContext context) {
    final itemCount = assets.length + (isLoadingMore ? 1 : 0);

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      cacheExtent: 800,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= assets.length) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: MixelithColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: MediaGridTile(
            asset: assets[index],
            onTap: () => onAssetSelected(assets[index]),
          ),
        );
      },
    );
  }
}
