import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../features/onnx_models/domain/local_onnx_model.dart';
import '../../../filters/engines/cpu_filter_engine.dart';
import '../../../filters/engines/filter_engine.dart';
import '../../../filters/engines/image_filter_processor.dart';
import '../../../filters/onnx/onnx_style_transfer_engine.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../filters/registry/default_filter_registry.dart';
import '../../../filters/registry/filter_registry.dart';
import '../domain/applied_filter.dart';
import '../domain/editor_state.dart';
import '../domain/working_image.dart';
import 'onnx_source_image_preparer.dart';

final filterRegistryProvider = Provider<FilterRegistry>(
  (ref) => const DefaultFilterRegistry(),
);

final filterEngineProvider = Provider<FilterEngine>(
  (ref) => CpuFilterEngine(cacheService: ref.watch(cacheServiceProvider)),
);

final onnxStyleTransferEngineProvider = Provider<OnnxStyleTransferEngine>(
  (ref) =>
      OnnxStyleTransferEngine(cacheService: ref.watch(cacheServiceProvider)),
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
      filterStack: const [],
      isApplyingFilter: false,
    );
  }

  void open(WorkingImage workingImage) {
    _requestCounter++;
    state = state.copyWith(
      workingImage: workingImage,
      presets: ref.read(filterRegistryProvider).getAllPresets(),
      selectedFilterId: originalFilterId,
      filterStack: const [],
      isApplyingFilter: false,
      filteredPreviewPath: null,
      errorMessage: null,
      activeMode: EditorOutputMode.procedural,
      isApplyingOnnx: false,
      selectedOnnxModelId: null,
      selectedOnnxModelLabel: null,
      onnxResult: null,
      onnxErrorMessage: null,
    );
  }

  Future<void> selectFilter(String filterId) async {
    final workingImage = state.workingImage;
    if (workingImage == null) {
      return;
    }

    if (filterId == originalFilterId) {
      clearAllFilters();
      return;
    }

    final registry = ref.read(filterRegistryProvider);
    final preset = registry.getById(filterId);
    if (preset == null) {
      state = state.copyWith(
        selectedFilterId: filterId,
        isApplyingFilter: false,
        errorMessage: 'This filter is not available.',
        activeMode: EditorOutputMode.procedural,
      );
      return;
    }

    final requestId = ++_requestCounter;
    final nextStack = _nextStackFor(filterId);

    state = state.copyWith(
      selectedFilterId: filterId,
      filterStack: nextStack,
      isApplyingFilter: true,
      errorMessage: null,
      activeMode: EditorOutputMode.procedural,
    );

    try {
      var currentPath = workingImage.previewPath;
      for (final appliedFilter in nextStack) {
        final stackPreset = registry.getById(appliedFilter.presetId);
        if (stackPreset == null) {
          throw StateError('Filter is not available.');
        }

        final result = await ref
            .read(filterEngineProvider)
            .apply(
              inputPath: currentPath,
              preset: stackPreset,
              parameterValues: appliedFilter.parameterValues,
            );

        if (requestId != _requestCounter) {
          return;
        }

        final outputPath = result.outputPath;
        if (outputPath == null) {
          throw StateError('Filter did not return an output path.');
        }
        currentPath = outputPath;
      }

      if (requestId != _requestCounter) {
        return;
      }

      state = state.copyWith(
        isApplyingFilter: false,
        filteredPreviewPath: currentPath,
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

  void clearAllFilters() {
    _requestCounter++;
    state = state.copyWith(
      selectedFilterId: originalFilterId,
      filterStack: const [],
      isApplyingFilter: false,
      filteredPreviewPath: null,
      errorMessage: null,
      activeMode: EditorOutputMode.procedural,
    );
  }

  Future<void> applyOnnxModel(LocalOnnxModel model) async {
    final workingImage = state.workingImage;
    if (workingImage == null) {
      return;
    }

    if (!model.isUsable) {
      state = state.copyWith(
        onnxErrorMessage: 'This ONNX model is not compatible.',
      );
      return;
    }

    final requestId = ++_requestCounter;
    state = state.copyWith(
      activeMode: EditorOutputMode.onnx,
      isApplyingOnnx: true,
      selectedOnnxModelId: model.id,
      selectedOnnxModelLabel: model.displayLabel,
      onnxResult: null,
      onnxErrorMessage: null,
      errorMessage: null,
    );

    try {
      final source = await ref
          .read(onnxSourceImagePreparerProvider)
          .prepare(workingImage);
      if (requestId != _requestCounter) {
        return;
      }
      final result = await ref
          .read(onnxStyleTransferEngineProvider)
          .runLocalModel(
            inputPath: source.path,
            modelPath: model.storedPath,
            modelName: model.displayLabel,
          );

      if (requestId != _requestCounter) {
        return;
      }

      if (!result.isSuccess || result.outputPath == null) {
        state = state.copyWith(
          isApplyingOnnx: false,
          onnxErrorMessage: result.message,
        );
        return;
      }

      final inputWidth = result.inputWidth ?? source.width;
      final inputHeight = result.inputHeight ?? source.height;
      final outputWidth = result.outputWidth;
      final outputHeight = result.outputHeight;
      if (outputWidth == null ||
          outputHeight == null ||
          outputWidth != inputWidth ||
          outputHeight != inputHeight) {
        state = state.copyWith(
          isApplyingOnnx: false,
          onnxErrorMessage:
              'ONNX output dimensions did not match the processed input dimensions.',
        );
        return;
      }

      state = state.copyWith(
        activeMode: EditorOutputMode.onnx,
        isApplyingOnnx: false,
        onnxResult: OnnxEditorResult(
          modelId: model.id,
          modelLabel: model.displayLabel,
          outputPath: result.outputPath!,
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          outputWidth: outputWidth,
          outputHeight: outputHeight,
          usedPreviewSource: source.usedPreviewSource,
          sourceLabel: source.sourceLabel,
          originalWidth: source.originalWidth,
          originalHeight: source.originalHeight,
          processingTime: result.processingTime,
        ),
        onnxErrorMessage: null,
      );
    } catch (_) {
      if (requestId != _requestCounter) {
        return;
      }
      state = state.copyWith(
        isApplyingOnnx: false,
        onnxErrorMessage: 'Unable to run this ONNX model.',
      );
    }
  }

  List<AppliedFilter> _nextStackFor(String filterId) {
    final nextFilter = AppliedFilter(
      presetId: filterId,
      appliedAt: DateTime.now(),
    );
    final currentStack = state.filterStack;

    if (currentStack.isNotEmpty && currentStack.last.presetId == filterId) {
      return [...currentStack.take(currentStack.length - 1), nextFilter];
    }

    return [...currentStack, nextFilter];
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
