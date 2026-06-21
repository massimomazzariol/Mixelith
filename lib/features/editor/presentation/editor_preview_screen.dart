import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../features/export/domain/export_settings.dart';
import '../../../features/export/domain/export_state.dart';
import '../../../features/export/providers/export_controller.dart';
import '../../../features/onnx_models/domain/local_onnx_model.dart';
import '../../../features/onnx_models/providers/local_onnx_model_controller.dart';
import '../../../filters/domain/filter_preset.dart';
import '../../../shared/widgets/mixelith_gradient_button.dart';
import '../../../shared/widgets/mixelith_loading_overlay.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';
import '../domain/applied_filter.dart';
import '../domain/editor_state.dart';
import '../domain/working_image.dart';
import '../providers/editor_controller.dart';

class EditorPreviewScreen extends ConsumerStatefulWidget {
  const EditorPreviewScreen({required this.workingImage, super.key});

  final WorkingImage workingImage;

  @override
  ConsumerState<EditorPreviewScreen> createState() =>
      _EditorPreviewScreenState();
}

class _EditorPreviewScreenState extends ConsumerState<EditorPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(editorControllerProvider.notifier).open(widget.workingImage);
      ref.read(localOnnxModelControllerProvider.notifier).load();
    });
  }

  @override
  void didUpdateWidget(EditorPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workingImage.previewPath != widget.workingImage.previewPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(editorControllerProvider.notifier).open(widget.workingImage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider);
    final workingImage = state.workingImage ?? widget.workingImage;
    final previewPath = state.visiblePreviewPath ?? workingImage.previewPath;
    final canExport = state.canExport;

    return MixelithScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Editor'),
        actions: [
          IconButton(
            key: const Key('imageInfoButton'),
            tooltip: 'Image info',
            onPressed: () => _showImageInfoSheet(
              context: context,
              state: state,
              workingImage: workingImage,
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            key: const Key('editorExportButton'),
            tooltip: !state.hasFilters && !state.hasActiveOnnxResult
                ? 'Apply a filter or run an ONNX model before exporting'
                : state.isBusy
                ? 'Processing is still running'
                : 'Export',
            onPressed: canExport
                ? () => _showExportSheet(
                    context: context,
                    ref: ref,
                    state: state,
                    workingImage: workingImage,
                  )
                : null,
            icon: const Icon(Icons.file_download_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('editorContentList'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _PreviewStage(
                        originalPath: workingImage.previewPath,
                        modifiedPath: previewPath,
                        loadingMessage: state.isApplyingOnnx
                            ? 'Running ONNX model'
                            : state.isApplyingFilter
                            ? 'Applying filter'
                            : null,
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _ErrorMessage(message: state.errorMessage!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _FilterStackSummary(
                        state: state,
                        onClearAll: () => ref
                            .read(editorControllerProvider.notifier)
                            .clearAllFilters(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: const _OnnxModelSection(),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: MixelithColors.background.withValues(alpha: 0.96),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: _FilterPreviewRail(
                  previewPath: workingImage.previewPath,
                  presets: state.presets,
                  selectedFilterId: state.selectedFilterId,
                  onSelected: (filterId) => ref
                      .read(editorControllerProvider.notifier)
                      .selectFilter(filterId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportSheet({
    required BuildContext context,
    required WidgetRef ref,
    required EditorState state,
    required WorkingImage workingImage,
  }) async {
    if (!state.canExport) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Apply a filter or run an ONNX model before exporting.',
          ),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    ref.read(exportControllerProvider.notifier).reset();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportBottomSheet(
        workingImage: workingImage,
        filterStack: List<AppliedFilter>.unmodifiable(state.filterStack),
        onnxResult: state.hasActiveOnnxResult ? state.onnxResult : null,
      ),
    );
    final exportState = ref.read(exportControllerProvider);
    if (exportState.status == ExportStatus.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(exportState.message ?? 'Saved to gallery.')),
      );
    }
  }

  Future<void> _showImageInfoSheet({
    required BuildContext context,
    required EditorState state,
    required WorkingImage workingImage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageInfoSheet(workingImage: workingImage, state: state),
    );
  }
}

class _ExportBottomSheet extends ConsumerStatefulWidget {
  const _ExportBottomSheet({
    required this.workingImage,
    required this.filterStack,
    required this.onnxResult,
  });

  final WorkingImage workingImage;
  final List<AppliedFilter> filterStack;
  final OnnxEditorResult? onnxResult;

  @override
  ConsumerState<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends ConsumerState<_ExportBottomSheet> {
  late ExportFormat _format;
  double _jpegQuality = 90;

  @override
  void initState() {
    super.initState();
    _format = defaultExportFormatForSourceFormat(
      widget.workingImage.effectiveSourceFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ExportState>(exportControllerProvider, (previous, next) {
      if (previous?.status != ExportStatus.success &&
          next.status == ExportStatus.success &&
          mounted) {
        Navigator.of(context).pop();
      }
    });

    final exportState = ref.watch(exportControllerProvider);
    final settings = ExportSettings(
      format: _format,
      jpegQuality: _jpegQuality.round(),
    );
    final shouldWarnForSize = settings.shouldWarnForDimensions(
      widget.onnxResult?.outputWidth ?? widget.workingImage.originalWidth,
      widget.onnxResult?.outputHeight ?? widget.workingImage.originalHeight,
    );
    final isOnnxExport = widget.onnxResult != null;
    final canSave = isOnnxExport || widget.filterStack.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MixelithColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Export',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: exportState.isBusy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedButton<ExportFormat>(
                  segments: _formatSegments(),
                  selected: {_format},
                  onSelectionChanged: exportState.isBusy
                      ? null
                      : (selection) {
                          setState(() => _format = selection.first);
                          ref.read(exportControllerProvider.notifier).reset();
                        },
                ),
                if (_format != ExportFormat.png) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_format.label} quality',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _jpegQuality.round().toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: _jpegQuality,
                    min: 60,
                    max: 100,
                    divisions: 40,
                    label: _jpegQuality.round().toString(),
                    onChanged: exportState.isBusy
                        ? null
                        : (value) {
                            setState(() => _jpegQuality = value);
                            ref.read(exportControllerProvider.notifier).reset();
                          },
                  ),
                ],
                const SizedBox(height: 12),
                const _ExportInfoBox(
                  icon: Icons.privacy_tip_outlined,
                  message: 'Exports are re-encoded without original metadata.',
                ),
                if (isOnnxExport) ...[
                  const SizedBox(height: 10),
                  const _ExportInfoBox(
                    icon: Icons.memory_outlined,
                    message: 'Saving the active ONNX result.',
                  ),
                ],
                if (shouldWarnForSize) ...[
                  const SizedBox(height: 10),
                  const _ExportInfoBox(
                    icon: Icons.memory_outlined,
                    message:
                        'This image is large. Mixelith will resize the export to protect memory and performance.',
                  ),
                ],
                const SizedBox(height: 18),
                MixelithGradientButton(
                  key: const Key('saveToGalleryButton'),
                  label: exportState.isBusy ? 'Saving...' : 'Save to gallery',
                  icon: Icons.save_alt_outlined,
                  onPressed: exportState.isBusy || !canSave
                      ? null
                      : () {
                          final onnxResult = widget.onnxResult;
                          if (onnxResult != null) {
                            ref
                                .read(exportControllerProvider.notifier)
                                .exportOnnxResult(
                                  onnxOutputPath: onnxResult.outputPath,
                                  settings: settings,
                                  usedPreviewFallback:
                                      onnxResult.usedPreviewSource,
                                );
                            return;
                          }
                          ref
                              .read(exportControllerProvider.notifier)
                              .exportImage(
                                workingImage: widget.workingImage,
                                filterStack: widget.filterStack,
                                settings: settings,
                              );
                        },
                ),
                if (exportState.status != ExportStatus.idle) ...[
                  const SizedBox(height: 14),
                  _ExportStatusMessage(state: exportState),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ButtonSegment<ExportFormat>> _formatSegments() {
    final sourceDefault = defaultExportFormatForSourceFormat(
      widget.workingImage.effectiveSourceFormat,
    );
    return [
      const ButtonSegment(value: ExportFormat.jpeg, label: Text('JPEG')),
      const ButtonSegment(value: ExportFormat.png, label: Text('PNG')),
      if (sourceDefault.requiresHeifEncoder)
        ButtonSegment(value: sourceDefault, label: Text(sourceDefault.label)),
    ];
  }
}

class _ExportInfoBox extends StatelessWidget {
  const _ExportInfoBox({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: MixelithColors.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportStatusMessage extends StatelessWidget {
  const _ExportStatusMessage({required this.state});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final isError = state.status == ExportStatus.error;
    final isSuccess = state.status == ExportStatus.success;
    final color = isError
        ? Theme.of(context).colorScheme.error
        : isSuccess
        ? MixelithColors.cyan
        : MixelithColors.textSecondary;
    final message = state.message ?? 'Preparing export.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isBusy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.hourglass_empty_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _detailMessage(message),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _detailMessage(String message) {
    final parts = <String>[message];
    if (state.wasResized &&
        state.outputWidth != null &&
        state.outputHeight != null) {
      parts.add(
        'Export resized to ${state.outputWidth} x ${state.outputHeight}.',
      );
    }
    if (state.usedPreviewFallback) {
      parts.add('Saved from preview cache.');
    }
    return parts.join(' ');
  }
}

class _PreviewStage extends StatefulWidget {
  const _PreviewStage({
    required this.originalPath,
    required this.modifiedPath,
    required this.loadingMessage,
  });

  final String originalPath;
  final String modifiedPath;
  final String? loadingMessage;

  @override
  State<_PreviewStage> createState() => _PreviewStageState();
}

class _PreviewStageState extends State<_PreviewStage> {
  bool _showOriginal = false;

  @override
  void didUpdateWidget(_PreviewStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modifiedPath != widget.modifiedPath ||
        widget.modifiedPath == widget.originalPath) {
      _showOriginal = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final stageHeight = math.min(560.0, math.max(320.0, screenHeight * 0.52));
    final canCompare = widget.modifiedPath != widget.originalPath;
    final visiblePath = canCompare && _showOriginal
        ? widget.originalPath
        : widget.modifiedPath;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: MixelithColors.red.withValues(alpha: 0.16),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: GestureDetector(
            key: const Key('editorPreviewGestureArea'),
            onHorizontalDragEnd: canCompare
                ? (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 120) {
                      return;
                    }
                    setState(() => _showOriginal = velocity > 0);
                  }
                : null,
            child: SizedBox(
              height: stageHeight,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Image.file(
                        File(visiblePath),
                        key: const Key('editorPreviewImage'),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  if (canCompare)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _CompareToggle(
                        showingOriginal: _showOriginal,
                        onShowOriginal: () {
                          setState(() => _showOriginal = true);
                        },
                        onShowEdited: () {
                          setState(() => _showOriginal = false);
                        },
                      ),
                    ),
                  if (widget.loadingMessage != null)
                    MixelithLoadingOverlay(message: widget.loadingMessage!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareToggle extends StatelessWidget {
  const _CompareToggle({
    required this.showingOriginal,
    required this.onShowOriginal,
    required this.onShowEdited,
  });

  final bool showingOriginal;
  final VoidCallback onShowOriginal;
  final VoidCallback onShowEdited;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompareToggleButton(
              key: const Key('compareShowOriginalButton'),
              label: 'Original',
              selected: showingOriginal,
              onTap: onShowOriginal,
            ),
            _CompareToggleButton(
              key: const Key('compareShowEditedButton'),
              label: 'Edited',
              selected: !showingOriginal,
              onTap: onShowEdited,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareToggleButton extends StatelessWidget {
  const _CompareToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? MixelithColors.yellow : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: selected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              color: selected
                  ? const Color(0xFF080509)
                  : MixelithColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPreviewRail extends StatelessWidget {
  const _FilterPreviewRail({
    required this.previewPath,
    required this.presets,
    required this.selectedFilterId,
    required this.onSelected,
  });

  final String previewPath;
  final List<FilterPreset> presets;
  final String selectedFilterId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        primary: false,
        itemBuilder: (context, index) {
          final preset = presets[index];
          return _FilterPreviewCard(
            previewPath: previewPath,
            preset: preset,
            selected: preset.id == selectedFilterId,
            onTap: () => onSelected(preset.id),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: presets.length,
      ),
    );
  }
}

class _FilterPreviewCard extends ConsumerWidget {
  const _FilterPreviewCard({
    required this.previewPath,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final String previewPath;
  final FilterPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final thumbnail = ref.watch(
      filterThumbnailProvider(
        FilterThumbnailRequest(previewPath: previewPath, filterId: preset.id),
      ),
    );

    return Material(
      key: ValueKey('filterCard:${preset.id}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? MixelithColors.yellow
                  : Colors.white.withValues(alpha: 0.10),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? MixelithColors.surfaceElevated
                : MixelithColors.surface,
          ),
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 92,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: selected
                                ? MixelithColors.hotGradient
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF2A1B20),
                                      Color(0xFF130D15),
                                    ],
                                  ),
                          ),
                        ),
                        thumbnail.when(
                          data: (path) {
                            if (path == null) {
                              return const Icon(Icons.image_outlined);
                            }
                            return Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.low,
                            );
                          },
                          loading: () => const Center(
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, _) =>
                              const Center(child: Icon(Icons.image_outlined)),
                        ),
                        if (selected)
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0x66000000)],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  preset.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    height: 1.08,
                    color: selected
                        ? MixelithColors.yellow
                        : MixelithColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      message,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}

class _OnnxModelSection extends ConsumerWidget {
  const _OnnxModelSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(localOnnxModelControllerProvider);
    final editorState = ref.watch(editorControllerProvider);
    final usableModels = modelState.usableModels;
    final hasUsableModels = usableModels.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasUsableModels
                      ? Icons.check_circle_outline_rounded
                      : Icons.memory_outlined,
                  color: hasUsableModels
                      ? MixelithColors.yellow
                      : MixelithColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasUsableModels
                        ? 'Local ONNX models'
                        : 'No compatible local ONNX models imported. This build does not include ONNX models.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasUsableModels
                          ? MixelithColors.textPrimary
                          : MixelithColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (modelState.status == LocalOnnxModelLoadStatus.loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (hasUsableModels) ...[
              const SizedBox(height: 12),
              for (final model in usableModels) ...[
                _OnnxModelRow(
                  model: model,
                  editorState: editorState,
                  onRun: editorState.isBusy
                      ? null
                      : () => ref
                            .read(editorControllerProvider.notifier)
                            .applyOnnxModel(model),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (editorState.isApplyingOnnx) ...[
              const SizedBox(height: 2),
              const LinearProgressIndicator(),
            ],
            if (editorState.onnxErrorMessage != null) ...[
              const SizedBox(height: 10),
              _OnnxInlineMessage(
                icon: Icons.error_outline_rounded,
                message: editorState.onnxErrorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
            if (editorState.onnxResult != null) ...[
              const SizedBox(height: 10),
              _OnnxResultDetails(result: editorState.onnxResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnnxModelRow extends StatelessWidget {
  const _OnnxModelRow({
    required this.model,
    required this.editorState,
    required this.onRun,
  });

  final LocalOnnxModel model;
  final EditorState editorState;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    final isSelected = editorState.selectedOnnxModelId == model.id;
    final isRunning = isSelected && editorState.isApplyingOnnx;
    final label = isRunning
        ? 'Running'
        : isSelected
        ? 'Re-run'
        : 'Run';

    return DecoratedBox(
      key: ValueKey('editorOnnxModel:${model.id}'),
      decoration: BoxDecoration(
        color: MixelithColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? MixelithColors.yellow.withValues(alpha: 0.58)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${model.inputShapeLabel} -> ${model.outputShapeLabel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: MixelithColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              key: ValueKey('runOnnxModel:${model.id}'),
              onPressed: isRunning ? null : onRun,
              icon: Icon(
                isRunning
                    ? Icons.hourglass_empty_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnnxResultDetails extends StatelessWidget {
  const _OnnxResultDetails({required this.result});

  final OnnxEditorResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.dimensionsMatchInput
        ? MixelithColors.yellow
        : Theme.of(context).colorScheme.error;
    final details = [
      ('Model', result.modelLabel),
      ('Original', result.originalSizeLabel),
      ('Input', result.inputSizeLabel),
      ('Output', result.outputSizeLabel),
      ('Elapsed', result.processingTimeLabel),
      ('Source', result.sourceLabel),
    ];

    return Column(
      children: [
        for (final detail in details)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(
                    detail.$1,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    detail.$2,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MixelithColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _OnnxInlineMessage(
          icon: result.dimensionsMatchInput
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          message: result.dimensionsMatchInput
              ? 'Output dimensions match input.'
              : 'Output dimensions do not match input.',
          color: color,
        ),
      ],
    );
  }
}

class _OnnxInlineMessage extends StatelessWidget {
  const _OnnxInlineMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _FilterStackSummary extends StatelessWidget {
  const _FilterStackSummary({required this.state, required this.onClearAll});

  final EditorState state;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = _stackNames(state);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: state.hasFilters
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < filters.length; index++)
                          _StackChip(
                            label: '${index + 1}. ${filters[index]}',
                            active: index == filters.length - 1,
                          ),
                      ],
                    )
                  : Text(
                      'Original preview. Apply a filter to start editing.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: MixelithColors.textSecondary,
                      ),
                    ),
            ),
            if (state.hasFilters) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                key: const Key('clearAllFiltersButton'),
                onPressed: state.isApplyingFilter ? null : onClearAll,
                icon: const Icon(Icons.layers_clear_outlined, size: 18),
                label: const Text('Clear all'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StackChip extends StatelessWidget {
  const _StackChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? MixelithColors.yellow.withValues(alpha: 0.18)
            : MixelithColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? MixelithColors.yellow.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: active ? MixelithColors.yellow : MixelithColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ImageInfoSheet extends StatelessWidget {
  const _ImageInfoSheet({required this.workingImage, required this.state});

  final WorkingImage workingImage;
  final EditorState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stackLabel = _stackNames(state).join(' -> ');
    final onnxResult = state.onnxResult;
    final details = [
      (
        'Original size',
        '${workingImage.originalWidth} x ${workingImage.originalHeight}',
      ),
      (
        'Preview size',
        '${workingImage.previewWidth} x ${workingImage.previewHeight}',
      ),
      ('Format', workingImage.effectiveSourceFormat.displayLabel),
      (
        'Mode',
        state.activeMode == EditorOutputMode.onnx ? 'ONNX' : 'Procedural',
      ),
      ('Current stack', stackLabel.isEmpty ? 'Original' : stackLabel),
      ('Downscaled', workingImage.wasPreviewDownscaled ? 'Yes' : 'No'),
      if (onnxResult != null) ...[
        ('ONNX model', onnxResult.modelLabel),
        ('ONNX input', onnxResult.inputSizeLabel),
        ('ONNX output', onnxResult.outputSizeLabel),
        ('ONNX elapsed', onnxResult.processingTimeLabel),
        ('ONNX source', onnxResult.sourceLabel),
      ],
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          key: const Key('imageInfoSheet'),
          decoration: BoxDecoration(
            color: MixelithColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Image info',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final detail in details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            detail.$1,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            detail.$2,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _stackNames(EditorState state) {
  return [
    for (final appliedFilter in state.filterStack)
      _filterName(state, appliedFilter.presetId),
  ];
}

String _filterName(EditorState state, String presetId) {
  for (final preset in state.presets) {
    if (preset.id == presetId) {
      return preset.name;
    }
  }
  return 'Unknown filter';
}
