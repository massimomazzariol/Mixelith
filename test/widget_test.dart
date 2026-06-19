import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/app/app.dart';
import 'package:mixelith/app/providers.dart';
import 'package:mixelith/features/batch/data/batch_image_picker.dart';
import 'package:mixelith/features/batch/providers/batch_image_picker_provider.dart';
import 'package:mixelith/features/onnx_models/data/local_onnx_model_repository.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';
import 'package:mixelith/features/onnx_models/providers/local_onnx_model_controller.dart';
import 'package:mixelith/shared/widgets/mixelith_gradient_logo.dart';

import 'fakes/fake_media_repository.dart';

void main() {
  Future<void> pumpMixelithApp(
    WidgetTester tester, {
    FakeMediaRepository? repository,
    BatchImagePicker? imagePicker,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaRepositoryProvider.overrideWithValue(
            repository ?? FakeMediaRepository(),
          ),
          localOnnxModelRepositoryProvider.overrideWithValue(
            const _FakeLocalOnnxModelRepository(),
          ),
          batchImagePickerProvider.overrideWithValue(
            imagePicker ?? _FakeBatchImagePicker(),
          ),
        ],
        child: const MixelithApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('App shell opens the Mixelith home screen', (tester) async {
    final versionLabel = _pubspecVersionLabel();

    await pumpMixelithApp(tester);

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.text('Mixelith'), findsOneWidget);
    expect(find.byType(MixelithGradientLogo), findsOneWidget);
    expect(find.byKey(const Key('homeMosaicBackground')), findsOneWidget);
    expect(find.byKey(const Key('openGalleryButton')), findsOneWidget);
    expect(find.byKey(const Key('cameraCaptureButton')), findsOneWidget);
    expect(find.byKey(const Key('batchExportButton')), findsOneWidget);
    expect(find.byKey(const Key('localOnnxModelsButton')), findsOneWidget);
    expect(find.byKey(const Key('homeVersionLabel')), findsOneWidget);
    expect(find.text('Open photo'), findsOneWidget);
    expect(find.text('Take photo now'), findsOneWidget);
    expect(find.text(versionLabel), findsOneWidget);
    expect(
      find.text('Neon art filters for local photos. No cloud. No account.'),
      findsNothing,
    );
    expect(find.text('Everything stays on this device.'), findsNothing);
  });

  testWidgets('Animated mosaic background renders without layout errors', (
    tester,
  ) async {
    await pumpMixelithApp(tester);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('homeMosaicBackground')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Camera CTA shows Android-only fallback on Windows preview', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpMixelithApp(tester);

      await tester.tap(find.byKey(const Key('cameraCaptureButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Android Camera'), findsOneWidget);
      expect(
        find.text('Camera capture is available on Android builds.'),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Open photo cancel leaves the home screen visible', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final picker = _FakeBatchImagePicker();
    try {
      await pumpMixelithApp(tester, imagePicker: picker);

      await tester.tap(find.byKey(const Key('openGalleryButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(picker.pickImageCalls, 1);
      expect(find.byKey(const Key('homeScreen')), findsOneWidget);
      expect(find.text('Preparing photo'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Open photo shows Android-only fallback on Windows preview', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpMixelithApp(tester);

      await tester.tap(find.byKey(const Key('openGalleryButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Android Photo Picker'), findsOneWidget);
      expect(
        find.text('Photo picking is available on Android builds.'),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Local models opens the no-model manager state', (tester) async {
    await pumpMixelithApp(tester);

    await tester.ensureVisible(find.byKey(const Key('localOnnxModelsButton')));
    await tester.tap(find.byKey(const Key('localOnnxModelsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('localOnnxModelsScreen')), findsOneWidget);
    expect(
      find.textContaining('This build does not include ONNX models.'),
      findsOneWidget,
    );
    expect(
      find.text('No compatible local ONNX models imported yet.'),
      findsOneWidget,
    );
  });

  testWidgets('Home remains scrollable on compact screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMixelithApp(tester);

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    expect(find.byKey(const Key('homeMosaicBackground')), findsOneWidget);
    expect(find.byKey(const Key('openGalleryButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android photo picker fallback remains usable on compact screens',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await tester.binding.setSurfaceSize(const Size(390, 640));
      try {
        await pumpMixelithApp(tester);

        await tester.tap(find.byKey(const Key('openGalleryButton')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Android Photo Picker'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        await tester.binding.setSurfaceSize(null);
      }
    },
  );

  test('Android splash and launcher icon assets stay configured', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final launchBackground = File(
      'android/app/src/main/res/drawable/launch_background.xml',
    ).readAsStringSync();
    final launchBackgroundV21 = File(
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    ).readAsStringSync();

    expect(
      File('assets/branding/mixelith_launcher_icon.png').existsSync(),
      true,
    );
    expect(File('assets/branding/mixelith_splash_icon.png').existsSync(), true);
    expect(
      File(
        'android/app/src/main/res/drawable-nodpi/mixelith_splash_icon.png',
      ).existsSync(),
      true,
    );
    expect(pubspec, contains('flutter_launcher_icons'));
    expect(pubspec, contains('assets/branding/mixelith_launcher_icon.png'));
    expect(launchBackground, contains('#070506'));
    expect(launchBackground, contains('@drawable/mixelith_splash_icon'));
    expect(launchBackgroundV21, contains('#070506'));
    expect(launchBackgroundV21, contains('@drawable/mixelith_splash_icon'));
  });
}

String _pubspecVersionLabel() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw StateError('pubspec.yaml version is missing.');
  }
  return 'v${match.group(1)}';
}

class _FakeLocalOnnxModelRepository implements LocalOnnxModelRepository {
  const _FakeLocalOnnxModelRepository();

  @override
  Future<LocalOnnxModel?> importModel() async => null;

  @override
  Future<List<LocalOnnxModel>> loadModels() async => const [];
}

class _FakeBatchImagePicker implements BatchImagePicker {
  int pickImageCalls = 0;
  int pickImagesCalls = 0;

  @override
  Future<BatchImagePickResult> pickImage() async {
    pickImageCalls++;
    return const BatchImagePickResult.cancelled();
  }

  @override
  Future<BatchImagePickResult> pickImages() async {
    pickImagesCalls++;
    return const BatchImagePickResult.cancelled();
  }
}
