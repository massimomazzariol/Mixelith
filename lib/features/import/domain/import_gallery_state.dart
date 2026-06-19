import '../../../media/domain/media_asset.dart';
import '../../../media/domain/media_permission_status.dart';

enum ImportGalleryStatus {
  initial,
  loading,
  permissionRequired,
  permissionDenied,
  permissionLimited,
  loaded,
  empty,
  limitedAccessEmpty,
  error,
}

class ImportGalleryState {
  const ImportGalleryState({
    required this.status,
    required this.permissionStatus,
    required this.assets,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    this.errorMessage,
  });

  const ImportGalleryState.initial()
    : status = ImportGalleryStatus.initial,
      permissionStatus = MediaPermissionStatus.notDetermined,
      assets = const [],
      page = 0,
      hasMore = true,
      isLoadingMore = false,
      errorMessage = null;

  final ImportGalleryStatus status;
  final MediaPermissionStatus permissionStatus;
  final List<MediaAsset> assets;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasLimitedAccess =>
      permissionStatus == MediaPermissionStatus.limited ||
      status == ImportGalleryStatus.permissionLimited ||
      status == ImportGalleryStatus.limitedAccessEmpty;

  bool get canShowGrid =>
      status == ImportGalleryStatus.loaded ||
      status == ImportGalleryStatus.permissionLimited;

  bool get canLoadMore => canShowGrid && hasMore && !isLoadingMore;

  ImportGalleryState copyWith({
    ImportGalleryStatus? status,
    MediaPermissionStatus? permissionStatus,
    List<MediaAsset>? assets,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Object? errorMessage = _errorMessageSentinel,
  }) {
    return ImportGalleryState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      assets: assets ?? this.assets,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _errorMessageSentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _errorMessageSentinel = Object();
