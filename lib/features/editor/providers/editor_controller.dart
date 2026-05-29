import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../filters/engines/cpu_filter_engine.dart';
import '../../../filters/engines/filter_engine.dart';
import '../../../filters/engines/image_filter_processor.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../filters/registry/default_filter_registry.dart';
import '../../../filters/registry/filter_registry.dart';
import '../domain/editor_state.dart';
import '../domain/working_image.dart';

final filterRegistryProvider = Provider<FilterRegistry>(
  (ref) => const DefaultFilterRegistry(),
);

final filterEngineProvider = Provider<FilterEngine>(
  (ref) => CpuFilterEngine(cacheService: ref.watch(cacheServiceProvider)),
);

final editorControllerProvider =
    NotifierProvider<EditorController, EditorState>(EditorController.new);

final filterThumbnailProvider = FutureProvider.autoDispose
    .family<String?, FilterThumbnailRequest>((ref, request) async {
      if (request.previewPath.isEmpty) {
        return null;
      }

      final registry = ref.watch(filterRegistryProvider);
      final cacheService = ref.watch(cacheServiceProvider);
      final preset = registry.getById(request.filterId);
      if (preset == null) {
        return null;
      }

      if (request.filterId == originalFilterId) {
        return request.previewPath;
      }

      final processed = await processFilterImage(
        inputPath: request.previewPath,
        preset: preset,
        jpegQuality: 78,
        maxLongSide: 180,
      );

      return cacheService.writeTempFile(processed.bytes, 'jpg');
    });

class EditorController extends Notifier<EditorState> {
  int _requestCounter = 0;

  @override
  EditorState build() {
    final presets = ref.watch(filterRegistryProvider).getAllPresets();
    return EditorState(
      presets: presets,
      selectedFilterId: originalFilterId,
      isApplyingFilter: false,
    );
  }

  void open(WorkingImage workingImage) {
    _requestCounter++;
    state = state.copyWith(
      workingImage: workingImage,
      presets: ref.read(filterRegistryProvider).getAllPresets(),
      selectedFilterId: originalFilterId,
      isApplyingFilter: false,
      filteredPreviewPath: null,
      errorMessage: null,
    );
  }

  Future<void> selectFilter(String filterId) async {
    final workingImage = state.workingImage;
    if (workingImage == null) {
      return;
    }

    final requestId = ++_requestCounter;

    if (filterId == originalFilterId) {
      state = state.copyWith(
        selectedFilterId: originalFilterId,
        isApplyingFilter: false,
        filteredPreviewPath: null,
        errorMessage: null,
      );
      return;
    }

    final preset = ref.read(filterRegistryProvider).getById(filterId);
    if (preset == null) {
      state = state.copyWith(
        selectedFilterId: filterId,
        isApplyingFilter: false,
        errorMessage: 'This filter is not available.',
      );
      return;
    }

    state = state.copyWith(
      selectedFilterId: filterId,
      isApplyingFilter: true,
      errorMessage: null,
    );

    try {
      final result = await ref
          .read(filterEngineProvider)
          .apply(inputPath: workingImage.previewPath, preset: preset);

      if (requestId != _requestCounter) {
        return;
      }

      state = state.copyWith(
        isApplyingFilter: false,
        filteredPreviewPath: result.outputPath,
        errorMessage: null,
      );
    } catch (_) {
      if (requestId != _requestCounter) {
        return;
      }

      state = state.copyWith(
        isApplyingFilter: false,
        errorMessage: 'Unable to apply this filter.',
      );
    }
  }
}

class FilterThumbnailRequest {
  const FilterThumbnailRequest({
    required this.previewPath,
    required this.filterId,
  });

  final String previewPath;
  final String filterId;

  @override
  bool operator ==(Object other) {
    return other is FilterThumbnailRequest &&
        other.previewPath == previewPath &&
        other.filterId == filterId;
  }

  @override
  int get hashCode => Object.hash(previewPath, filterId);
}
