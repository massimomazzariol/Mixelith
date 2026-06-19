import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mixelith/app/providers.dart';
import 'package:mixelith/features/editor/domain/applied_filter.dart';
import 'package:mixelith/app/theme.dart';
import 'package:mixelith/features/editor/domain/onnx_source_image.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/editor/presentation/editor_preview_screen.dart';
import 'package:mixelith/features/editor/providers/editor_controller.dart';
import 'package:mixelith/features/editor/providers/onnx_source_image_preparer.dart';
import 'package:mixelith/features/export/domain/export_prepared_file.dart';
import 'package:mixelith/features/export/domain/export_service.dart';
import 'package:mixelith/features/export/providers/export_controller.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/features/onnx_models/data/local_onnx_model_repository.dart';
import 'package:mixelith/features/onnx_models/domain/local_onnx_model.dart';
import 'package:mixelith/features/onnx_models/providers/local_onnx_model_controller.dart';
import 'package:mixelith/filters/domain/filter_engine_type.dart';
import 'package:mixelith/filters/domain/filter_preset.dart';
import 'package:mixelith/filters/domain/filter_result.dart';
import 'package:mixelith/filters/engines/filter_engine.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_engine.dart';
import 'package:mixelith/filters/onnx/onnx_style_transfer_result.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';
import 'package:mixelith/filters/registry/default_filter_registry.dart';
import 'package:mixelith/shared/widgets/mixelith_gradient_button.dart';

import '../../../fakes/fake_cache_service.dart';
import '../../../fakes/fake_export_repository.dart';

void main() {
  testWidgets('filter selection updates the main editor preview', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'mixelith_editor_widget_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final originalPath = _writeImage(
      directory: directory,
      filename: 'original.jpg',
      red: 24,
      green: 90,
      blue: 170,
    );
    final filteredPath = _writeImage(
      directory: directory,
      filename: 'filtered.jpg',
      red: 240,
      green: 88,
      blue: 38,
    );
    final engine = _ImmediateFilterEngine(outputPath: filteredPath);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cacheServiceProvider.overrideWithValue(FakeCacheService(directory)),
          localOnnxModelRepositoryProvider.overrideWithValue(
            const _FakeLocalOnnxModelRepository(),
          ),
          filterEngineProvider.overrideWithValue(engine),
          filterThumbnailProvider.overrideWith(
            (ref, request) async => request.previewPath,
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: EditorPreviewScreen(
            workingImage: _workingImage(previewPath: originalPath),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(_displayedPreviewPath(tester), originalPath);
    await tester.tap(find.byKey(ValueKey('filterCard:$neonHeatFilterId')));
    await tester.pump();
    await tester.pump();

    expect(engine.selectedIds, [neonHeatFilterId]);
    expect(_displayedPreviewPath(tester), filteredPath);
    expect(find.byKey(const Key('clearAllFiltersButton')), findsOneWidget);
    expect(find.byKey(const Key('compareShowEditedButton')), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    expect(
      find.text(
        'Drag'
        ' to compare',
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('compareShowOriginalButton')));
    await tester.pump();
    expect(_displayedPreviewPath(tester), originalPath);

    await tester.tap(find.byKey(const Key('compareShowEditedButton')));
    await tester.pump();
    expect(_displayedPreviewPath(tester), filteredPath);

    await tester.tap(find.byKey(const Key('clearAllFiltersButton')));
    await tester.pump();
    await tester.pump();
    expect(_displayedPreviewPath(tester), originalPath);
    expect(find.byKey(const Key('clearAllFiltersButton')), findsNothing);
    expect(_exportButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(ValueKey('filterCard:$neonHeatFilterId')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('filterCard:$originalFilterId')));
    await tester.pump();
    await tester.pump();

    expect(_displayedPreviewPath(tester), originalPath);
    expect(find.byKey(const Key('compareShowEditedButton')), findsNothing);
    expect(find.byKey(const Key('clearAllFiltersButton')), findsNothing);
    expect(_exportButton(tester).onPressed, isNull);
  });

  testWidgets('image info sheet opens from the editor header', (tester) async {
    final directory = Directory.systemTemp.createTempSync(
      'mixelith_editor_info_widget_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final originalPath = _writeImage(
      directory: directory,
      filename: 'original.jpg',
      red: 24,
      green: 90,
      blue: 170,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cacheServiceProvider.overrideWithValue(FakeCacheService(directory)),
          localOnnxModelRepositoryProvider.overrideWithValue(
            const _FakeLocalOnnxModelRepository(),
          ),
          filterThumbnailProvider.overrideWith(
            (ref, request) async => request.previewPath,
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: EditorPreviewScreen(
            workingImage: _workingImage(previewPath: originalPath),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('imageInfoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('imageInfoSheet')), findsOneWidget);
    expect(find.text('Image info'), findsOneWidget);
    expect(find.text('Original size'), findsOneWidget);
    expect(find.text('Current stack'), findsOneWidget);
  });

  testWidgets('export stays enabled by stack while compare shows original', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'mixelith_editor_export_widget_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final originalPath = _writeImage(
      directory: directory,
      filename: 'original.jpg',
      red: 24,
      green: 90,
      blue: 170,
    );
    final filteredPath = _writeImage(
      directory: directory,
      filename: 'filtered.jpg',
      red: 240,
      green: 88,
      blue: 38,
    );
    final engine = _ImmediateFilterEngine(outputPath: filteredPath);
    final repository = FakeExportRepository();
    final exportService = _ImmediateExportService(directory);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cacheServiceProvider.overrideWithValue(FakeCacheService(directory)),
          localOnnxModelRepositoryProvider.overrideWithValue(
            const _FakeLocalOnnxModelRepository(),
          ),
          filterEngineProvider.overrideWithValue(engine),
          exportServiceProvider.overrideWithValue(exportService),
          exportRepositoryProvider.overrideWithValue(repository),
          filterThumbnailProvider.overrideWith(
            (ref, request) async => request.previewPath,
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: EditorPreviewScreen(
            workingImage: _workingImage(previewPath: originalPath),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(_exportButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(ValueKey('filterCard:$neonHeatFilterId')));
    await tester.pump();
    await tester.pump();
    expect(_exportButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('compareShowOriginalButton')));
    await tester.pump();
    expect(_displayedPreviewPath(tester), originalPath);

    await tester.tap(find.byKey(const Key('editorExportButton')));
    await tester.pumpAndSettle();
    final saveButton = tester.widget<MixelithGradientButton>(
      find.byKey(const Key('saveToGalleryButton')),
    );
    expect(saveButton.onPressed, isNotNull);
    saveButton.onPressed!();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 250));

    expect(exportService.calls, 1);
    expect(repository.requests, hasLength(1));
    expect(find.text('Saved to gallery.'), findsOneWidget);
  });

  testWidgets('usable local ONNX model appears and updates editor preview', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'mixelith_editor_onnx_widget_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final originalPath = _writeImage(
      directory: directory,
      filename: 'original.jpg',
      red: 24,
      green: 90,
      blue: 170,
    );
    final onnxPath = _writeImage(
      directory: directory,
      filename: 'onnx.jpg',
      red: 42,
      green: 220,
      blue: 120,
    );
    final onnxEngine = _FakeOnnxEngine(
      OnnxStyleTransferResult(
        status: OnnxStyleTransferStatus.success,
        modelName: 'Local ONNX model 1',
        message: 'ok',
        outputPath: onnxPath,
        inputWidth: 32,
        inputHeight: 24,
        outputWidth: 32,
        outputHeight: 24,
        processingTime: const Duration(milliseconds: 77),
      ),
      cacheService: FakeCacheService(directory),
    );
    final onnxSourcePath =
        '${directory.path}${Platform.pathSeparator}onnx-source.jpg';
    final sourcePreparer = _FakeOnnxSourceImagePreparer(
      cacheService: FakeCacheService(directory),
      sourcePath: onnxSourcePath,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cacheServiceProvider.overrideWithValue(FakeCacheService(directory)),
          localOnnxModelRepositoryProvider.overrideWithValue(
            _FakeLocalOnnxModelRepository(models: [_localOnnxModel()]),
          ),
          onnxStyleTransferEngineProvider.overrideWithValue(onnxEngine),
          onnxSourceImagePreparerProvider.overrideWithValue(sourcePreparer),
          filterThumbnailProvider.overrideWith(
            (ref, request) async => request.previewPath,
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: EditorPreviewScreen(
            workingImage: _workingImage(previewPath: originalPath),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final editorScrollable = find.descendant(
      of: find.byKey(const Key('editorContentList')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Local ONNX model 1'),
      240,
      scrollable: editorScrollable,
    );
    await tester.pump();

    expect(find.text('Local ONNX model 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('runOnnxModel:local-onnx-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(_displayedPreviewPath(tester), onnxPath);
    expect(sourcePreparer.requests.single.originalTempPath, originalPath);
    expect(onnxEngine.requests.single.inputPath, onnxSourcePath);
    expect(onnxEngine.requests.single.modelPath, 'private-model.onnx');
    expect(find.text('77 ms'), findsOneWidget);
    expect(find.text('Output dimensions match input.'), findsOneWidget);
    expect(_exportButton(tester).onPressed, isNotNull);
  });

  testWidgets('rejected ONNX models are not shown in editor usable list', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'mixelith_editor_onnx_rejected_widget_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final originalPath = _writeImage(
      directory: directory,
      filename: 'original.jpg',
      red: 24,
      green: 90,
      blue: 170,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cacheServiceProvider.overrideWithValue(FakeCacheService(directory)),
          localOnnxModelRepositoryProvider.overrideWithValue(
            _FakeLocalOnnxModelRepository(
              models: [
                _localOnnxModel(
                  id: 'fixed',
                  label: 'Local ONNX model 2',
                  status: LocalOnnxModelStatus.rejected,
                ),
              ],
            ),
          ),
          filterThumbnailProvider.overrideWith(
            (ref, request) async => request.previewPath,
          ),
        ],
        child: MaterialApp(
          theme: buildMixelithTheme(),
          home: EditorPreviewScreen(
            workingImage: _workingImage(previewPath: originalPath),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final editorScrollable = find.descendant(
      of: find.byKey(const Key('editorContentList')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.textContaining('This build does not include ONNX models.'),
      240,
      scrollable: editorScrollable,
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This build does not include ONNX models.'),
      findsOneWidget,
    );
    expect(find.text('Local ONNX model 2'), findsNothing);
  });
}

IconButton _exportButton(WidgetTester tester) {
  return tester.widget<IconButton>(find.byKey(const Key('editorExportButton')));
}

String _displayedPreviewPath(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.byKey(const Key('editorPreviewImage')),
  );
  final provider = image.image as FileImage;
  return provider.file.path;
}

String _writeImage({
  required Directory directory,
  required String filename,
  required int red,
  required int green,
  required int blue,
}) {
  final image = img.Image(width: 32, height: 24);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(x, y, red, green, blue);
    }
  }

  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  file.writeAsBytesSync(img.encodeJpg(image), flush: true);
  return file.path;
}

WorkingImage _workingImage({required String previewPath}) {
  return WorkingImage(
    sourceAssetId: 'asset-1',
    originalTempPath: previewPath,
    previewPath: previewPath,
    originalWidth: 32,
    originalHeight: 24,
    previewWidth: 32,
    previewHeight: 24,
    createdAt: DateTime(2026, 5, 31),
    wasPreviewDownscaled: false,
    originalExtension: 'jpg',
  );
}

class _ImmediateFilterEngine implements FilterEngine {
  _ImmediateFilterEngine({required this.outputPath});

  final String outputPath;
  final List<String> selectedIds = [];

  @override
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues = const {},
  }) async {
    selectedIds.add(preset.id);
    return FilterResult(
      outputPath: outputPath,
      width: 32,
      height: 24,
      mimeType: 'image/jpeg',
      processingTime: const Duration(milliseconds: 8),
      engineUsed: FilterEngineType.cpu,
      wasDownscaled: false,
      outputFormat: ExportFormat.jpeg,
    );
  }
}

class _ImmediateExportService extends ExportService {
  _ImmediateExportService(Directory directory)
    : _directory = directory,
      super(
        cacheService: FakeCacheService(directory),
        filterRegistry: const DefaultFilterRegistry(),
      );

  final Directory _directory;
  int calls = 0;

  @override
  Future<ExportPreparedFile> prepareExport({
    required WorkingImage workingImage,
    required List<AppliedFilter> filterStack,
    required ExportSettings settings,
  }) async {
    calls++;
    final output = File(
      '${_directory.path}${Platform.pathSeparator}prepared.${settings.fileExtension}',
    );
    output.writeAsBytesSync(img.encodeJpg(img.Image(width: 8, height: 8)));
    return ExportPreparedFile(
      path: output.path,
      format: settings.format,
      width: 8,
      height: 8,
      wasResized: false,
      usedPreviewFallback: false,
    );
  }
}

class _FakeLocalOnnxModelRepository implements LocalOnnxModelRepository {
  const _FakeLocalOnnxModelRepository({this.models = const []});

  final List<LocalOnnxModel> models;

  @override
  Future<LocalOnnxModel?> importModel() async => null;

  @override
  Future<List<LocalOnnxModel>> loadModels() async => models;
}

class _FakeOnnxEngine extends OnnxStyleTransferEngine {
  _FakeOnnxEngine(this.result, {required super.cacheService});

  final OnnxStyleTransferResult result;
  final List<_OnnxRequest> requests = [];

  @override
  Future<OnnxStyleTransferResult> runLocalModel({
    required String inputPath,
    required String modelPath,
    required String modelName,
  }) async {
    requests.add(_OnnxRequest(inputPath, modelPath, modelName));
    return result;
  }
}

class _FakeOnnxSourceImagePreparer extends OnnxSourceImagePreparer {
  _FakeOnnxSourceImagePreparer({
    required FakeCacheService cacheService,
    required this.sourcePath,
  }) : super(cacheService: cacheService);

  final String sourcePath;
  final List<WorkingImage> requests = [];

  @override
  Future<OnnxSourceImage> prepare(WorkingImage workingImage) async {
    requests.add(workingImage);
    return OnnxSourceImage(
      path: sourcePath,
      width: workingImage.originalWidth,
      height: workingImage.originalHeight,
      originalWidth: workingImage.originalWidth,
      originalHeight: workingImage.originalHeight,
      sourceLabel: 'Original',
      usedPreviewSource: false,
      wasDownscaled: false,
      maxLongSide: 2048,
    );
  }
}

class _OnnxRequest {
  const _OnnxRequest(this.inputPath, this.modelPath, this.modelName);

  final String inputPath;
  final String modelPath;
  final String modelName;
}

LocalOnnxModel _localOnnxModel({
  String id = 'local-onnx-1',
  String label = 'Local ONNX model 1',
  LocalOnnxModelStatus status = LocalOnnxModelStatus.usable,
}) {
  return LocalOnnxModel(
    id: id,
    displayLabel: label,
    storedPath: 'private-model.onnx',
    fileSizeBytes: 6768798,
    inputShape: const [1, 3, -1, -1],
    outputShape: const [1, 3, -1, -1],
    status: status,
    importedAt: DateTime(2026, 6, 4),
    rejectionReason: status == LocalOnnxModelStatus.usable
        ? null
        : 'Fixed-size rejected.',
  );
}
