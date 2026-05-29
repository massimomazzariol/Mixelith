import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../media/domain/media_asset.dart';
import '../../../media/domain/media_permission_status.dart';
import '../../../media/domain/media_repository.dart';
import '../domain/import_gallery_state.dart';

const int importGalleryPageSize = 60;

final importGalleryControllerProvider =
    NotifierProvider<ImportGalleryController, ImportGalleryState>(
      ImportGalleryController.new,
    );

final mediaThumbnailProvider = FutureProvider.autoDispose
    .family<Uint8List?, MediaThumbnailRequest>((ref, request) {
      final repository = ref.watch(mediaRepositoryProvider);
      return repository.getThumbnailData(
        request.asset,
        width: request.width,
        height: request.height,
      );
    });

class ImportGalleryController extends Notifier<ImportGalleryState> {
  @override
  ImportGalleryState build() => const ImportGalleryState.initial();

  MediaRepository get _repository => ref.read(mediaRepositoryProvider);

  Future<void> loadInitial() => _loadFirstPage(requestPermission: false);

  Future<void> requestAccess() => _loadFirstPage(requestPermission: true);

  Future<void> refresh() => _loadFirstPage(requestPermission: false);

  Future<void> loadMore() async {
    if (!state.canLoadMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    final nextPage = state.page + 1;

    try {
      final assets = await _repository.getRecentAssets(
        page: nextPage,
        pageSize: importGalleryPageSize,
      );

      state = state.copyWith(
        assets: [...state.assets, ...assets],
        page: assets.isEmpty ? state.page : nextPage,
        hasMore: assets.length >= importGalleryPageSize,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(
        status: ImportGalleryStatus.error,
        errorMessage: 'Unable to load more photos.',
        isLoadingMore: false,
      );
    }
  }

  Future<void> _loadFirstPage({required bool requestPermission}) async {
    state = state.copyWith(
      status: ImportGalleryStatus.loading,
      assets: const [],
      page: 0,
      hasMore: true,
      isLoadingMore: false,
      errorMessage: null,
    );

    try {
      final permissionStatus = requestPermission
          ? await _repository.requestPermissionStatus()
          : await _repository.getPermissionStatus();

      if (!permissionStatus.hasAccess) {
        state = state.copyWith(
          status: _permissionBlockedStatus(permissionStatus),
          permissionStatus: permissionStatus,
          assets: const [],
          hasMore: false,
        );
        return;
      }

      final assets = await _repository.getRecentAssets(
        page: 0,
        pageSize: importGalleryPageSize,
      );

      state = state.copyWith(
        status: _contentStatus(permissionStatus, assets),
        permissionStatus: permissionStatus,
        assets: assets,
        page: 0,
        hasMore: assets.length >= importGalleryPageSize,
      );
    } catch (_) {
      state = state.copyWith(
        status: ImportGalleryStatus.error,
        errorMessage: 'Unable to load photos.',
        hasMore: false,
      );
    }
  }

  ImportGalleryStatus _permissionBlockedStatus(
    MediaPermissionStatus permissionStatus,
  ) {
    return switch (permissionStatus) {
      MediaPermissionStatus.notDetermined =>
        ImportGalleryStatus.permissionRequired,
      MediaPermissionStatus.denied ||
      MediaPermissionStatus.restricted => ImportGalleryStatus.permissionDenied,
      MediaPermissionStatus.authorized ||
      MediaPermissionStatus.limited => ImportGalleryStatus.loading,
    };
  }

  ImportGalleryStatus _contentStatus(
    MediaPermissionStatus permissionStatus,
    List<MediaAsset> assets,
  ) {
    if (assets.isEmpty) {
      return permissionStatus.isLimited
          ? ImportGalleryStatus.limitedAccessEmpty
          : ImportGalleryStatus.empty;
    }

    return permissionStatus.isLimited
        ? ImportGalleryStatus.permissionLimited
        : ImportGalleryStatus.loaded;
  }
}

class MediaThumbnailRequest {
  const MediaThumbnailRequest({
    required this.asset,
    this.width = 200,
    this.height = 200,
  });

  final MediaAsset asset;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) {
    return other is MediaThumbnailRequest &&
        other.asset.id == asset.id &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(asset.id, width, height);
}
