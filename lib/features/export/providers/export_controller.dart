import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../editor/domain/working_image.dart';
import '../../editor/providers/editor_controller.dart';
import '../data/dev_export_repository.dart';
import '../data/gal_export_repository.dart';
import '../domain/export_repository.dart';
import '../domain/export_service.dart';
import '../domain/export_settings.dart';
import '../domain/export_state.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => const GalExportRepository(),
    TargetPlatform.windows => DevExportRepository(cacheService: cacheService),
    _ => DevExportRepository(cacheService: cacheService),
  };
});

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(
    cacheService: ref.watch(cacheServiceProvider),
    filterRegistry: ref.watch(filterRegistryProvider),
  ),
);

final exportControllerProvider =
    NotifierProvider<ExportController, ExportState>(ExportController.new);

class ExportController extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState.idle();

  void reset() {
    state = const ExportState.idle();
  }

  Future<void> exportImage({
    required WorkingImage workingImage,
    required String selectedFilterId,
    required ExportSettings settings,
  }) async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: ExportStatus.preparing,
      settings: settings,
      result: null,
      message: 'Preparing export.',
      outputWidth: null,
      outputHeight: null,
      wasResized: false,
      usedPreviewFallback: false,
    );

    try {
      final prepared = await ref
          .read(exportServiceProvider)
          .prepareExport(
            workingImage: workingImage,
            selectedFilterId: selectedFilterId,
            settings: settings,
          );

      state = state.copyWith(
        status: ExportStatus.exporting,
        message: 'Saving export.',
        outputWidth: prepared.width,
        outputHeight: prepared.height,
        wasResized: prepared.wasResized,
        usedPreviewFallback: prepared.usedPreviewFallback,
      );

      final result = await ref
          .read(exportRepositoryProvider)
          .saveImage(
            filePath: prepared.path,
            fileName: _exportFileName(),
            format: prepared.format,
          );

      state = state.copyWith(
        status: result.success ? ExportStatus.success : ExportStatus.error,
        result: result,
        message:
            result.message ??
            (result.success ? 'Saved to gallery.' : 'Unable to save export.'),
      );
    } catch (_) {
      state = state.copyWith(
        status: ExportStatus.error,
        message: 'Unable to prepare this export.',
      );
    }
  }

  String _exportFileName() {
    return 'mixelith_${DateTime.now().millisecondsSinceEpoch}';
  }
}
