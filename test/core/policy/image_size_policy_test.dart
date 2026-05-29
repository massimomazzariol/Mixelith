import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/core/policy/image_size_policy.dart';

void main() {
  test('ImageSizePolicy exposes expected V1 limits', () {
    expect(ImageSizePolicy.previewMaxLongSide, 1080.0);
    expect(ImageSizePolicy.exportMaxLongSideDefault, 4096.0);
    expect(ImageSizePolicy.warningThreshold, 6000.0);
  });
}
