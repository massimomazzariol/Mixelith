import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/core/policy/image_size_policy.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';

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
}
