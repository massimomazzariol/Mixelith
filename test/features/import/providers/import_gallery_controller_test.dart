import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/app/providers.dart';
import 'package:mixelith/features/import/domain/import_gallery_state.dart';
import 'package:mixelith/features/import/providers/import_gallery_controller.dart';
import 'package:mixelith/media/domain/media_asset.dart';
import 'package:mixelith/media/domain/media_asset_availability.dart';
import 'package:mixelith/media/domain/media_permission_status.dart';

import '../../../fakes/fake_media_repository.dart';

void main() {
  test(
    'loadInitial asks the UI to request permission when undetermined',
    () async {
      final repository = FakeMediaRepository();
      final container = _container(repository);

      await container
          .read(importGalleryControllerProvider.notifier)
          .loadInitial();

      final state = container.read(importGalleryControllerProvider);
      expect(state.status, ImportGalleryStatus.permissionRequired);
      expect(state.assets, isEmpty);
    },
  );

  test('requestAccess loads assets and marks limited access', () async {
    final asset = _asset('limited-1');
    final repository = FakeMediaRepository(
      requestPermissionResult: MediaPermissionStatus.limited,
      pages: {
        0: [asset],
      },
    );
    final container = _container(repository);

    await container
        .read(importGalleryControllerProvider.notifier)
        .requestAccess();

    final state = container.read(importGalleryControllerProvider);
    expect(state.status, ImportGalleryStatus.permissionLimited);
    expect(state.hasLimitedAccess, isTrue);
    expect(state.assets, [asset]);
    expect(repository.requestedPermissions, 1);
  });

  test(
    'loadInitial separates limited empty from a normal empty gallery',
    () async {
      final repository = FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.limited,
      );
      final container = _container(repository);

      await container
          .read(importGalleryControllerProvider.notifier)
          .loadInitial();

      final state = container.read(importGalleryControllerProvider);
      expect(state.status, ImportGalleryStatus.limitedAccessEmpty);
      expect(state.hasLimitedAccess, isTrue);
      expect(state.assets, isEmpty);
    },
  );

  test(
    'loadInitial keeps authorized empty galleries as normal empty',
    () async {
      final repository = FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.authorized,
      );
      final container = _container(repository);

      await container
          .read(importGalleryControllerProvider.notifier)
          .loadInitial();

      final state = container.read(importGalleryControllerProvider);
      expect(state.status, ImportGalleryStatus.empty);
      expect(state.hasLimitedAccess, isFalse);
      expect(state.assets, isEmpty);
    },
  );

  test('loadMore appends the next page', () async {
    final firstPage = List.generate(
      importGalleryPageSize,
      (index) => _asset('asset-$index'),
    );
    final nextAsset = _asset('asset-next');
    final repository = FakeMediaRepository(
      permissionStatus: MediaPermissionStatus.authorized,
      pages: {
        0: firstPage,
        1: [nextAsset],
      },
    );
    final container = _container(repository);

    await container
        .read(importGalleryControllerProvider.notifier)
        .loadInitial();
    await container.read(importGalleryControllerProvider.notifier).loadMore();

    final state = container.read(importGalleryControllerProvider);
    expect(state.status, ImportGalleryStatus.loaded);
    expect(state.assets.length, importGalleryPageSize + 1);
    expect(state.assets.last, nextAsset);
    expect(state.hasMore, isFalse);
    expect(repository.requestedPages, [0, 1]);
  });
}

ProviderContainer _container(FakeMediaRepository repository) {
  final container = ProviderContainer(
    overrides: [mediaRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

MediaAsset _asset(String id) {
  return MediaAsset(
    id: id,
    width: 1200,
    height: 900,
    availability: MediaAssetAvailability.localAvailable,
  );
}
