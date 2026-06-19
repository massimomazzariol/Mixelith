import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';

void main() {
  test('local ONNX model metadata serializes status and tensor shapes', () {
    final model = LocalOnnxModel(
      id: 'local_onnx_1',
      displayLabel: 'Local ONNX model 1',
      storedPath: '/app/private/local_onnx_1.onnx',
      fileSizeBytes: 6 * 1024 * 1024,
      inputShape: const [1, 3, -1, -1],
      outputShape: const [1, 3, -1, -1],
      status: LocalOnnxModelStatus.usable,
      importedAt: DateTime(2026, 6, 4),
    );

    final restored = LocalOnnxModel.fromJson(model.toJson());

    expect(restored.displayLabel, 'Local ONNX model 1');
    expect(restored.status, LocalOnnxModelStatus.usable);
    expect(restored.inputShapeLabel, '1 x 3 x dynamic x dynamic');
    expect(restored.fileSizeLabel, '6.0 MB');
  });

  test('dynamic height and width are accepted by metadata inspection', () {
    final reason = LocalOnnxModel.fixedInputRejection(const [1, 3, -1, -1]);

    expect(reason, isNull);
  });

  test('fixed square input is rejected by metadata inspection', () {
    final reason = LocalOnnxModel.fixedInputRejection(const [1, 3, 224, 224]);

    expect(reason, contains('224x224'));
    expect(reason, contains('dynamic full-frame input'));
  });
}
