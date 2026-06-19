import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/app/theme.dart';
import 'package:mixelith/features/onnx_models/data/local_onnx_model_repository.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';
import 'package:mixelith/features/onnx_models/presentation/local_onnx_models_screen.dart';
import 'package:mixelith/features/onnx_models/providers/local_onnx_model_controller.dart';

void main() {
  testWidgets('local ONNX model screen shows no-model state without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localOnnxModelRepositoryProvider.overrideWithValue(
            const _FakeLocalOnnxModelRepository(),
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: const LocalOnnxModelsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('localOnnxModelsScreen')), findsOneWidget);
    expect(find.byKey(const Key('importOnnxModelButton')), findsOneWidget);
    expect(
      find.textContaining('This build does not include ONNX models.'),
      findsOneWidget,
    );
    expect(
      find.text('No compatible local ONNX models imported yet.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('local ONNX model screen lists imported metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localOnnxModelRepositoryProvider.overrideWithValue(
            _FakeLocalOnnxModelRepository(
              models: [
                LocalOnnxModel(
                  id: 'local_onnx_1',
                  displayLabel: 'Local ONNX model 1',
                  storedPath: '',
                  fileSizeBytes: 6768798,
                  inputShape: const [1, 3, -1, -1],
                  outputShape: const [1, 3, -1, -1],
                  status: LocalOnnxModelStatus.usable,
                  importedAt: DateTime(2026, 6, 4),
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: const LocalOnnxModelsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local ONNX model 1'), findsOneWidget);
    expect(find.text('Usable'), findsOneWidget);
    expect(find.text('1 x 3 x dynamic x dynamic'), findsAtLeastNWidgets(1));
  });
}

class _FakeLocalOnnxModelRepository implements LocalOnnxModelRepository {
  const _FakeLocalOnnxModelRepository({this.models = const []});

  final List<LocalOnnxModel> models;

  @override
  Future<LocalOnnxModel?> importModel() async => null;

  @override
  Future<List<LocalOnnxModel>> loadModels() async => models;
}
