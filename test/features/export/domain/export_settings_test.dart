import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/core/policy/image_size_policy.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/media/domain/image_source_format.dart';

void main() {
  test('ExportSettings uses safe defaults', () {
    const settings = ExportSettings(format: ExportFormat.jpeg);

    expect(settings.format, ExportFormat.jpeg);
    expect(settings.jpegQuality, 90);
    expect(settings.maxLongSide, isNull);
    expect(
      settings.effectiveMaxLongSide,
      ImageSizePolicy.exportMaxLongSideDefault,
    );
    expect(settings.removeMetadata, isTrue);
    expect(settings.fileExtension, 'jpg');
    expect(settings.mimeType, 'image/jpeg');
  });

  test('ExportSettings exposes PNG metadata and large image warning', () {
    const settings = ExportSettings(format: ExportFormat.png);

    expect(settings.fileExtension, 'png');
    expect(settings.mimeType, 'image/png');
    expect(settings.shouldWarnForDimensions(7000, 3000), isTrue);
    expect(settings.shouldWarnForDimensions(3000, 3000), isFalse);
  });

  test('ExportSettings exposes HEIC and HEIF metadata', () {
    const heic = ExportSettings(format: ExportFormat.heic);
    const heif = ExportSettings(format: ExportFormat.heif);

    expect(heic.fileExtension, 'heic');
    expect(heic.mimeType, 'image/heic');
    expect(heic.format.requiresHeifEncoder, isTrue);
    expect(heif.fileExtension, 'heif');
    expect(heif.mimeType, 'image/heif');
  });

  test('default export format follows the source format', () {
    expect(
      defaultExportFormatForSourceFormat(ImageSourceFormat.jpeg),
      ExportFormat.jpeg,
    );
    expect(
      defaultExportFormatForSourceFormat(ImageSourceFormat.png),
      ExportFormat.png,
    );
    expect(
      defaultExportFormatForSourceFormat(ImageSourceFormat.heic),
      ExportFormat.heic,
    );
    expect(
      defaultExportFormatForSourceFormat(ImageSourceFormat.heif),
      ExportFormat.heif,
    );
    expect(
      defaultExportFormatForSourceFormat(ImageSourceFormat.webp),
      ExportFormat.jpeg,
    );
  });
}
