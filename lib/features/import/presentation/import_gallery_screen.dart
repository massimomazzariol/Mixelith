import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../editor/presentation/editor_preview_screen.dart';
import '../../../media/domain/media_asset.dart';
import '../../../media/domain/media_asset_availability.dart';
import '../../../shared/widgets/mixelith_gradient_logo.dart';
import '../../../shared/widgets/mixelith_loading_overlay.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';
import '../domain/import_gallery_state.dart';
import '../domain/working_image_import_state.dart';
import '../providers/import_gallery_controller.dart';
import '../providers/working_image_import_controller.dart';
import 'media_grid.dart';
import 'permission_message.dart';

class ImportGalleryScreen extends ConsumerStatefulWidget {
  const ImportGalleryScreen({super.key});

  @override
  ConsumerState<ImportGalleryScreen> createState() =>
      _ImportGalleryScreenState();
}

class _ImportGalleryScreenState extends ConsumerState<ImportGalleryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(importGalleryControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importGalleryControllerProvider);
    final importState = ref.watch(workingImageImportControllerProvider);

    return MixelithScreenScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MixelithGradientLogo(size: 28),
            SizedBox(width: 10),
            Text('Choose a photo'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh gallery',
            onPressed: () =>
                ref.read(importGalleryControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: Stack(
        children: [
          _buildBody(context, state),
          if (importState.isImporting)
            const MixelithLoadingOverlay(message: 'Preparing preview'),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ImportGalleryState state) {
    return switch (state.status) {
      ImportGalleryStatus.initial ||
      ImportGalleryStatus.loading => const _GalleryLoadingState(),
      ImportGalleryStatus.permissionRequired => PermissionMessage(
        title: 'Photo access',
        message:
            'Allow access to photos to choose a local image. Everything stays on this device.',
        icon: Icons.photo_library_outlined,
        actionLabel: 'Allow access',
        onAction: () =>
            ref.read(importGalleryControllerProvider.notifier).requestAccess(),
      ),
      ImportGalleryStatus.permissionDenied => PermissionMessage(
        title: 'Photo access is off',
        message:
            'Mixelith needs photo access to show the local gallery. You can authorize it from Android settings.',
        icon: Icons.lock_outline_rounded,
        actionLabel: 'Try again',
        onAction: () =>
            ref.read(importGalleryControllerProvider.notifier).requestAccess(),
      ),
      ImportGalleryStatus.empty => Column(
        children: [
          if (state.hasLimitedAccess) const _LimitedAccessBanner(),
          const Expanded(
            child: PermissionMessage(
              title: 'No photos found',
              message: 'There are no local images available for Mixelith.',
              icon: Icons.photo_outlined,
            ),
          ),
        ],
      ),
      ImportGalleryStatus.limitedAccessEmpty => Column(
        children: [
          const _LimitedAccessBanner(),
          Expanded(
            child: PermissionMessage(
              title: 'Limited access unavailable',
              message:
                  'Limited access is active, but Android did not return selected photos to Mixelith on this device. For this version, choose full access to use the gallery.',
              icon: Icons.photo_library_outlined,
              actionLabel: 'Use full access',
              onAction: () => ref
                  .read(importGalleryControllerProvider.notifier)
                  .requestAccess(),
            ),
          ),
        ],
      ),
      ImportGalleryStatus.error => PermissionMessage(
        title: 'Unable to load photos',
        message: state.errorMessage ?? 'Try again shortly.',
        icon: Icons.error_outline_rounded,
        actionLabel: 'Try again',
        onAction: () =>
            ref.read(importGalleryControllerProvider.notifier).refresh(),
      ),
      ImportGalleryStatus.loaded ||
      ImportGalleryStatus.permissionLimited => Column(
        children: [
          if (state.hasLimitedAccess) const _LimitedAccessBanner(),
          const _GalleryIntro(),
          Expanded(
            child: MediaGrid(
              assets: state.assets,
              scrollController: _scrollController,
              isLoadingMore: state.isLoadingMore,
              onAssetSelected: _handleAssetSelected,
            ),
          ),
        ],
      ),
    };
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(importGalleryControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _handleAssetSelected(MediaAsset asset) async {
    if (asset.availability == MediaAssetAvailability.unavailableCloudOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This photo is not available locally. Mixelith works offline and cannot download images from the cloud.',
          ),
        ),
      );
      return;
    }

    final result = await ref
        .read(workingImageImportControllerProvider.notifier)
        .importAsset(asset);

    if (!mounted) {
      return;
    }

    if (result.status == WorkingImageImportStatus.imported &&
        result.workingImage != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              EditorPreviewScreen(workingImage: result.workingImage!),
        ),
      );
      ref.read(workingImageImportControllerProvider.notifier).reset();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              'Unable to prepare preview. Try another photo.',
        ),
      ),
    );
  }
}

class _GalleryLoadingState extends StatelessWidget {
  const _GalleryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MixelithColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 14),
              Text('Loading photos'),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryIntro extends StatelessWidget {
  const _GalleryIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MixelithColors.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: MixelithColors.hotGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF080509),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open photo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose a single image. Multi-selection will arrive later.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitedAccessBanner extends StatelessWidget {
  const _LimitedAccessBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MixelithColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: MixelithColors.orange.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: MixelithColors.yellow,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Limited photo access active',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
