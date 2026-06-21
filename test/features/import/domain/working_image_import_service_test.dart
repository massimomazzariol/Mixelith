import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/features/import/domain/image_normalizer.dart';
import 'package:mixelith/features/import/domain/working_image_import_service.dart';
import 'package:mixelith/media/domain/image_source_format.dart';
import 'package:mixelith/media/domain/media_asset.dart';
import 'package:mixelith/media/domain/media_asset_availability.dart';
import 'package:mixelith/media/domain/media_asset_file.dart';
import 'package:mixelith/media/domain/media_permission_status.dart';

import '../../../fakes/fake_cache_service.dart';
import '../../../fakes/fake_media_repository.dart';

void main() {
  late Directory baseDirectory;
  late FakeCacheService cacheService;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp(
      'mixelith_import_test_',
    );
    cacheService = FakeCacheService(baseDirectory);
  });

  tearDown(() async {
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('imports original file and creates a 1080px preview', () async {
    final sourceFile = File(
      '${baseDirectory.path}${Platform.pathSeparator}source.jpg',
    );
    final sourceImage = img.Image(width: 1600, height: 800);
    img.fill(sourceImage, color: img.ColorRgb8(40, 120, 220));
    await sourceFile.writeAsBytes(img.encodeJpg(sourceImage));

    final asset = _asset('asset-1', width: 1600, height: 800);
    final service = WorkingImageImportService(
      mediaRepository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.authorized,
        originalFiles: {
          asset.id: MediaAssetFile(
            path: sourceFile.path,
            extension: 'jpg',
            width: asset.width,
            height: asset.height,
            availability: MediaAssetAvailability.localAvailable,
          ),
        },
      ),
      cacheService: cacheService,
    );

    final workingImage = await service.importAsset(asset);
    final previewBytes = await File(workingImage.previewPath).readAsBytes();
    final preview = img.decodeImage(previewBytes);

    expect(await File(workingImage.originalTempPath).exists(), isTrue);
    expect(preview, isNotNull);
    expect(preview!.width, 1080);
    expect(preview.height, 540);
    expect(workingImage.originalWidth, 1600);
    expect(workingImage.originalHeight, 800);
    expect(workingImage.previewWidth, 1080);
    expect(workingImage.previewHeight, 540);
    expect(workingImage.wasPreviewDownscaled, isTrue);
    expect(workingImage.originalExtension, 'jpg');
  });

  test(
    'imports a captured file path through the same preview pipeline',
    () async {
      final capturedFile = File(
        '${baseDirectory.path}${Platform.pathSeparator}camera_capture.jpg',
      );
      final capturedImage = img.Image(width: 900, height: 1400);
      img.fill(capturedImage, color: img.ColorRgb8(240, 80, 30));
      await capturedFile.writeAsBytes(img.encodeJpg(capturedImage));

      final service = WorkingImageImportService(
        mediaRepository: FakeMediaRepository(
          permissionStatus: MediaPermissionStatus.authorized,
        ),
        cacheService: cacheService,
      );

      final workingImage = await service.importFromFilePath(
        sourcePath: capturedFile.path,
        sourceAssetId: 'camera-test',
        extension: 'jpg',
      );
      final previewBytes = await File(workingImage.previewPath).readAsBytes();
      final preview = img.decodeImage(previewBytes);

      expect(await File(workingImage.originalTempPath).exists(), isTrue);
      expect(preview, isNotNull);
      expect(preview!.width, 694);
      expect(preview.height, 1080);
      expect(workingImage.sourceAssetId, 'camera-test');
      expect(workingImage.originalWidth, 900);
      expect(workingImage.originalHeight, 1400);
      expect(workingImage.previewWidth, 694);
      expect(workingImage.previewHeight, 1080);
      expect(workingImage.wasPreviewDownscaled, isTrue);
      expect(workingImage.originalExtension, 'jpg');
    },
  );

  test('routes HEIC imports through native normalization', () async {
    final sourceFile = File(
      '${baseDirectory.path}${Platform.pathSeparator}source.heic',
    );
    await sourceFile.writeAsBytes([1, 2, 3, 4], flush: true);
    final normalizedOriginal = File(
      '${baseDirectory.path}${Platform.pathSeparator}normalized.jpg',
    );
    final normalizedPreview = File(
      '${baseDirectory.path}${Platform.pathSeparator}preview.jpg',
    );
    await normalizedOriginal.writeAsBytes(
      img.encodeJpg(img.Image(width: 64, height: 48)),
    );
    await normalizedPreview.writeAsBytes(
      img.encodeJpg(img.Image(width: 32, height: 24)),
    );
    final normalizer = _FakeImageNormalizer(
      result: ImageNormalizationResult(
        originalPath: normalizedOriginal.path,
        previewPath: normalizedPreview.path,
        originalWidth: 4000,
        originalHeight: 3000,
        previewWidth: 1080,
        previewHeight: 810,
        wasPreviewDownscaled: true,
      ),
    );
    final service = WorkingImageImportService(
      mediaRepository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.authorized,
      ),
      cacheService: cacheService,
      imageNormalizer: normalizer,
    );

    final workingImage = await service.importFromFilePath(
      sourcePath: sourceFile.path,
      sourceAssetId: 'heic-test',
      extension: 'heic',
    );

    expect(normalizer.calls, hasLength(1));
    expect(normalizer.calls.single, endsWith('.heic'));
    expect(workingImage.originalTempPath, normalizedOriginal.path);
    expect(workingImage.previewPath, normalizedPreview.path);
    expect(workingImage.originalWidth, 4000);
    expect(workingImage.previewWidth, 1080);
    expect(workingImage.originalExtension, 'heic');
    expect(workingImage.effectiveSourceFormat, ImageSourceFormat.heic);
    expect(await sourceFile.readAsBytes(), [1, 2, 3, 4]);
  });

  test('reports a clear HEIC import error when normalization fails', () async {
    final sourceFile = File(
      '${baseDirectory.path}${Platform.pathSeparator}broken.heif',
    );
    await sourceFile.writeAsBytes([9, 8, 7], flush: true);
    final service = WorkingImageImportService(
      mediaRepository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.authorized,
      ),
      cacheService: cacheService,
      imageNormalizer: const _FailingImageNormalizer(),
    );

    await expectLater(
      service.importFromFilePath(
        sourcePath: sourceFile.path,
        sourceAssetId: 'heif-broken',
        extension: 'heif',
      ),
      throwsA(
        isA<WorkingImageImportException>().having(
          (error) => error.message,
          'message',
          'This HEIC photo could not be imported on this device.',
        ),
      ),
    );
  });

  test('reports cloud-only assets without writing cache files', () async {
    final asset = _asset(
      'asset-cloud',
      availability: MediaAssetAvailability.unavailableCloudOnly,
    );
    final service = WorkingImageImportService(
      mediaRepository: FakeMediaRepository(
        permissionStatus: MediaPermissionStatus.authorized,
        originalFiles: {
          asset.id: MediaAssetFile(
            path: '',
            extension: 'jpg',
            width: asset.width,
            height: asset.height,
            availability: MediaAssetAvailability.unavailableCloudOnly,
          ),
        },
      ),
      cacheService: cacheService,
    );

    expect(
      () => service.importAsset(asset),
      throwsA(
        isA<WorkingImageImportException>().having(
          (error) => error.failure,
          'failure',
          WorkingImageImportFailure.unavailableCloudOnly,
        ),
      ),
    );
  });
}

class _FakeImageNormalizer implements ImageNormalizer {
  _FakeImageNormalizer({required this.result});

  final ImageNormalizationResult result;
  final List<String> calls = [];

  @override
  Future<ImageNormalizationResult> normalizeHeif({
    required String sourcePath,
    required int previewMaxLongSide,
  }) async {
    calls.add(sourcePath);
    return result;
  }
}

class _FailingImageNormalizer implements ImageNormalizer {
  const _FailingImageNormalizer();

  @override
  Future<ImageNormalizationResult> normalizeHeif({
    required String sourcePath,
    required int previewMaxLongSide,
  }) async {
    throw const ImageNormalizerException(
      'This HEIC photo could not be imported on this device.',
    );
  }
}

MediaAsset _asset(
  String id, {
  int width = 1200,
  int height = 900,
  MediaAssetAvailability availability = MediaAssetAvailability.localAvailable,
}) {
  return MediaAsset(
    id: id,
    width: width,
    height: height,
    availability: availability,
  );
}
