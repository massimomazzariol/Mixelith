import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/app/app.dart';
import 'package:mixelith/app/providers.dart';
import 'package:mixelith/features/import/presentation/media_grid_tile.dart';
import 'package:mixelith/media/domain/media_asset.dart';
import 'package:mixelith/media/domain/media_asset_availability.dart';
import 'package:mixelith/media/domain/media_permission_status.dart';

import 'fakes/fake_media_repository.dart';

void main() {
  Future<void> pumpMixelithApp(
    WidgetTester tester, {
    FakeMediaRepository? repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaRepositoryProvider.overrideWithValue(
            repository ?? FakeMediaRepository(),
          ),
        ],
        child: const MixelithApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('App shell opens the Mixelith home screen', (tester) async {
    await pumpMixelithApp(tester);

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.text('Mixelith'), findsWidgets);
    expect(find.byKey(const Key('openGalleryButton')), findsOneWidget);
    expect(find.byKey(const Key('cameraCaptureButton')), findsOneWidget);
    expect(find.text('Open photo'), findsOneWidget);
    expect(find.text('Take photo now'), findsOneWidget);
    expect(
      find.text('Neon art filters for local photos. No cloud. No account.'),
      findsOneWidget,
    );
  });

  testWidgets('Camera CTA shows Android-only fallback on Windows preview', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpMixelithApp(tester);

      await tester.tap(find.byKey(const Key('cameraCaptureButton')));
      await tester.pumpAndSettle();

      expect(find.text('Android Camera'), findsOneWidget);
      expect(
        find.text('Camera capture is available on Android builds.'),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Open gallery shows the photo access request', (tester) async {
    await pumpMixelithApp(tester);

    await tester.tap(find.byKey(const Key('openGalleryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Photo access'), findsOneWidget);
    expect(find.text('Allow access'), findsOneWidget);
  });

  testWidgets('Limited empty access shows the dedicated fallback', (
    tester,
  ) async {
    await pumpMixelithApp(
      tester,
      repository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.limited,
      ),
    );

    await tester.tap(find.byKey(const Key('openGalleryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Limited access unavailable'), findsOneWidget);
    expect(
      find.text(
        'Limited access is active, but Android did not return selected photos to Mixelith on this device. For this version, choose full access to use the gallery.',
      ),
      findsOneWidget,
    );
    expect(find.text('Use full access'), findsOneWidget);
    expect(find.text('No photos found'), findsNothing);
  });

  testWidgets('Denied access still shows the denied permission state', (
    tester,
  ) async {
    await pumpMixelithApp(
      tester,
      repository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.denied,
      ),
    );

    await tester.tap(find.byKey(const Key('openGalleryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Photo access is off'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Full access with assets still shows the media grid', (
    tester,
  ) async {
    final asset = MediaAsset(
      id: 'real-photo-1',
      width: 1200,
      height: 900,
      availability: MediaAssetAvailability.localAvailable,
    );

    await pumpMixelithApp(
      tester,
      repository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.authorized,
        pages: {
          0: [asset],
        },
      ),
    );

    await tester.tap(find.byKey(const Key('openGalleryButton')));
    await tester.pumpAndSettle();

    expect(find.byType(MediaGridTile), findsOneWidget);
    expect(find.text('No photos found'), findsNothing);
    expect(find.text('Limited access unavailable'), findsNothing);
  });

  testWidgets('Home remains scrollable on compact screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMixelithApp(tester);

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.byKey(const Key('openGalleryButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gallery permission state remains usable on compact screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(520, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMixelithApp(tester);

    await tester.tap(find.byKey(const Key('openGalleryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Photo access'), findsOneWidget);
    expect(find.text('Allow access'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
