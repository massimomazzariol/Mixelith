import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/editor/domain/working_image.dart';
import 'package:mixelith/features/editor/providers/editor_controller.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';
import 'package:mixelith/filters/domain/filter_engine_type.dart';
import 'package:mixelith/filters/domain/filter_preset.dart';
import 'package:mixelith/filters/domain/filter_result.dart';
import 'package:mixelith/filters/engines/filter_engine.dart';
import 'package:mixelith/filters/presets/default_filter_presets.dart';

void main() {
  test('EditorController ignores stale filter results', () async {
    final engine = _DelayedFilterEngine();
    final container = ProviderContainer(
      overrides: [filterEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);

    final controller = container.read(editorControllerProvider.notifier);
    controller.open(_workingImage());

    final first = controller.selectFilter(neonPopFilterId);
    final second = controller.selectFilter(mosaicTilesFilterId);

    expect(engine.requests.map((request) => request.preset.id), [
      neonPopFilterId,
      mosaicTilesFilterId,
    ]);

    engine.requests[1].complete('mosaic.jpg');
    await second;

    expect(
      container.read(editorControllerProvider).selectedFilterId,
      mosaicTilesFilterId,
    );
    expect(
      container.read(editorControllerProvider).filteredPreviewPath,
      'mosaic.jpg',
    );

    engine.requests[0].complete('neon.jpg');
    await first;

    expect(
      container.read(editorControllerProvider).selectedFilterId,
      mosaicTilesFilterId,
    );
    expect(
      container.read(editorControllerProvider).filteredPreviewPath,
      'mosaic.jpg',
    );
  });
}

WorkingImage _workingImage() {
  return WorkingImage(
    sourceAssetId: 'asset-1',
    originalTempPath: 'original.jpg',
    previewPath: 'preview.jpg',
    originalWidth: 1200,
    originalHeight: 900,
    previewWidth: 1080,
    previewHeight: 810,
    createdAt: DateTime(2026, 5, 28),
    wasPreviewDownscaled: true,
    originalExtension: 'jpg',
  );
}

class _DelayedFilterEngine implements FilterEngine {
  final List<_FilterRequest> requests = [];

  @override
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues = const {},
  }) {
    final request = _FilterRequest(preset);
    requests.add(request);
    return request.future;
  }
}

class _FilterRequest {
  _FilterRequest(this.preset);

  final FilterPreset preset;
  final Completer<FilterResult> _completer = Completer<FilterResult>();

  Future<FilterResult> get future => _completer.future;

  void complete(String outputPath) {
    _completer.complete(
      FilterResult(
        outputPath: outputPath,
        width: 1080,
        height: 810,
        mimeType: 'image/jpeg',
        processingTime: const Duration(milliseconds: 12),
        engineUsed: FilterEngineType.cpu,
        wasDownscaled: false,
        outputFormat: ExportFormat.jpeg,
      ),
    );
  }
}
