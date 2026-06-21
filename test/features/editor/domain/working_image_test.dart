import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/media/domain/image_source_format.dart';

void main() {
  test('WorkingImage stores import preview metadata', () {
    final createdAt = DateTime(2026, 5, 27);
    final workingImage = WorkingImage(
      sourceAssetId: 'asset-1',
      originalTempPath: 'original.jpg',
      previewPath: 'preview.jpg',
      originalWidth: 1600,
      originalHeight: 900,
      previewWidth: 1080,
      previewHeight: 608,
      createdAt: createdAt,
      wasPreviewDownscaled: true,
      originalExtension: 'jpg',
    );

    expect(workingImage.sourceAssetId, 'asset-1');
    expect(workingImage.originalTempPath, 'original.jpg');
    expect(workingImage.previewPath, 'preview.jpg');
    expect(workingImage.originalWidth, 1600);
    expect(workingImage.originalHeight, 900);
    expect(workingImage.previewWidth, 1080);
    expect(workingImage.previewHeight, 608);
    expect(workingImage.createdAt, createdAt);
    expect(workingImage.wasPreviewDownscaled, isTrue);
    expect(workingImage.originalExtension, 'jpg');
    expect(workingImage.effectiveSourceFormat, ImageSourceFormat.jpeg);
  });

  test('WorkingImage preserves explicit HEIC source format metadata', () {
    final workingImage = WorkingImage(
      sourceAssetId: 'asset-heic',
      originalTempPath: 'normalized.jpg',
      previewPath: 'preview.jpg',
      originalWidth: 1200,
      originalHeight: 900,
      previewWidth: 1080,
      previewHeight: 810,
      createdAt: DateTime(2026, 6, 19),
      wasPreviewDownscaled: true,
      originalExtension: 'heic',
      sourceFormat: ImageSourceFormat.heic,
    );

    expect(workingImage.originalTempPath, 'normalized.jpg');
    expect(workingImage.originalExtension, 'heic');
    expect(workingImage.effectiveSourceFormat, ImageSourceFormat.heic);
  });
}
