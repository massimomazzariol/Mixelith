import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/media/domain/image_source_format.dart';

void main() {
  test('detects JPEG, PNG, WebP, HEIC, and HEIF extensions', () {
    expect(imageSourceFormatFromExtension('jpg'), ImageSourceFormat.jpeg);
    expect(imageSourceFormatFromExtension('.jpeg'), ImageSourceFormat.jpeg);
    expect(imageSourceFormatFromExtension('PNG'), ImageSourceFormat.png);
    expect(imageSourceFormatFromExtension('webp'), ImageSourceFormat.webp);
    expect(imageSourceFormatFromExtension('heic'), ImageSourceFormat.heic);
    expect(imageSourceFormatFromExtension('HEIF'), ImageSourceFormat.heif);
  });

  test('detects HEIC and HEIF MIME types', () {
    expect(imageSourceFormatFromMimeType('image/heic'), ImageSourceFormat.heic);
    expect(imageSourceFormatFromMimeType('image/heif'), ImageSourceFormat.heif);
    expect(imageSourceFormatFromMimeType('image/jpeg'), ImageSourceFormat.jpeg);
    expect(imageSourceFormatFromMimeType('image/png'), ImageSourceFormat.png);
  });

  test('rejects unknown or unsafe formats', () {
    expect(imageSourceFormatFromExtension('txt'), ImageSourceFormat.unknown);
    expect(
      imageSourceFormatFromMimeType('application/octet-stream'),
      ImageSourceFormat.unknown,
    );
    expect(
      imageSourceFormatFromPath('/tmp/photo.heic'),
      ImageSourceFormat.heic,
    );
  });
}
