import '../../../filters/domain/filter_preset.dart';
import '../../../filters/presets/default_filter_presets.dart';
import 'working_image.dart';

class EditorState {
  const EditorState({
    required this.presets,
    required this.selectedFilterId,
    required this.isApplyingFilter,
    this.workingImage,
    this.filteredPreviewPath,
    this.errorMessage,
  });

  const EditorState.initial()
    : presets = const [],
      selectedFilterId = originalFilterId,
      isApplyingFilter = false,
      workingImage = null,
      filteredPreviewPath = null,
      errorMessage = null;

  final WorkingImage? workingImage;
  final List<FilterPreset> presets;
  final String selectedFilterId;
  final bool isApplyingFilter;
  final String? filteredPreviewPath;
  final String? errorMessage;

  bool get isReady => workingImage != null;

  String? get visiblePreviewPath {
    if (filteredPreviewPath != null) {
      return filteredPreviewPath;
    }
    return workingImage?.previewPath;
  }

  EditorState copyWith({
    WorkingImage? workingImage,
    List<FilterPreset>? presets,
    String? selectedFilterId,
    bool? isApplyingFilter,
    Object? filteredPreviewPath = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return EditorState(
      workingImage: workingImage ?? this.workingImage,
      presets: presets ?? this.presets,
      selectedFilterId: selectedFilterId ?? this.selectedFilterId,
      isApplyingFilter: isApplyingFilter ?? this.isApplyingFilter,
      filteredPreviewPath: identical(filteredPreviewPath, _sentinel)
          ? this.filteredPreviewPath
          : filteredPreviewPath as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
