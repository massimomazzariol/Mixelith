import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../features/export/domain/export_settings.dart';
import '../../../features/export/domain/export_state.dart';
import '../../../features/export/providers/export_controller.dart';
import '../../../filters/domain/filter_preset.dart';
import '../../../shared/widgets/mixelith_gradient_button.dart';
import '../../../shared/widgets/mixelith_loading_overlay.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';
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
            tooltip: state.isApplyingFilter
                ? 'Filter is still applying'
                : 'Export',
            onPressed: state.isApplyingFilter
                ? null
                : () => _showExportSheet(
                    context: context,
                    ref: ref,
                    state: state,
                    workingImage: workingImage,
                  ),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _PreviewStage(
                        originalPath: workingImage.previewPath,
                        modifiedPath: previewPath,
                        isApplyingFilter: state.isApplyingFilter,
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
                      child: _ImageDetails(
                        workingImage: workingImage,
                        state: state,
                      ),
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
    ref.read(exportControllerProvider.notifier).reset();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportBottomSheet(
        workingImage: workingImage,
        selectedFilterId: state.selectedFilterId,
      ),
    );
  }
}

class _ExportBottomSheet extends ConsumerStatefulWidget {
  const _ExportBottomSheet({
    required this.workingImage,
    required this.selectedFilterId,
  });

  final WorkingImage workingImage;
  final String selectedFilterId;

  @override
  ConsumerState<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends ConsumerState<_ExportBottomSheet> {
  ExportFormat _format = ExportFormat.jpeg;
  double _jpegQuality = 90;

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportControllerProvider);
    final settings = ExportSettings(
      format: _format,
      jpegQuality: _jpegQuality.round(),
    );
    final shouldWarnForSize = settings.shouldWarnForDimensions(
      widget.workingImage.originalWidth,
      widget.workingImage.originalHeight,
    );

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
                  segments: const [
                    ButtonSegment(
                      value: ExportFormat.jpeg,
                      label: Text('JPEG'),
                    ),
                    ButtonSegment(value: ExportFormat.png, label: Text('PNG')),
                  ],
                  selected: {_format},
                  onSelectionChanged: exportState.isBusy
                      ? null
                      : (selection) {
                          setState(() => _format = selection.first);
                          ref.read(exportControllerProvider.notifier).reset();
                        },
                ),
                if (_format == ExportFormat.jpeg) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'JPEG quality',
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
                  label: exportState.isBusy ? 'Saving...' : 'Save to gallery',
                  icon: Icons.save_alt_outlined,
                  onPressed: exportState.isBusy
                      ? null
                      : () => ref
                            .read(exportControllerProvider.notifier)
                            .exportImage(
                              workingImage: widget.workingImage,
                              selectedFilterId: widget.selectedFilterId,
                              settings: settings,
                            ),
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
    required this.isApplyingFilter,
  });

  final String originalPath;
  final String modifiedPath;
  final bool isApplyingFilter;

  @override
  State<_PreviewStage> createState() => _PreviewStageState();
}

class _PreviewStageState extends State<_PreviewStage> {
  double _comparePosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final stageHeight = math.min(560.0, math.max(320.0, screenHeight * 0.52));
    final canCompare = widget.modifiedPath != widget.originalPath;

    return GestureDetector(
      onHorizontalDragUpdate: canCompare
          ? (details) =>
                _updateComparePosition(context, details.localPosition.dx)
          : null,
      onTapDown: canCompare
          ? (details) =>
                _updateComparePosition(context, details.localPosition.dx)
          : null,
      child: DecoratedBox(
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
            child: SizedBox(
              height: stageHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final handleLeft =
                      constraints.maxWidth * _comparePosition - 1;

                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Image.file(
                            File(widget.modifiedPath),
                            key: ValueKey(widget.modifiedPath),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                      if (canCompare)
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _comparePosition,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: Center(
                                child: Image.file(
                                  File(widget.originalPath),
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (canCompare)
                        Positioned(
                          left: handleLeft,
                          top: 0,
                          bottom: 0,
                          child: const _CompareHandle(),
                        ),
                      if (canCompare) const _CompareLabels(),
                      if (widget.isApplyingFilter)
                        const MixelithLoadingOverlay(
                          message: 'Applying filter',
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateComparePosition(BuildContext context, double localX) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 1;
    final nextPosition = (localX / width).clamp(0.06, 0.94).toDouble();
    setState(() => _comparePosition = nextPosition);
  }
}

class _CompareHandle extends StatelessWidget {
  const _CompareHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 2,
              color: MixelithColors.yellow.withValues(alpha: 0.9),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: MixelithColors.accentGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: Color(0xFF080509),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareLabels extends StatelessWidget {
  const _CompareLabels();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _CompareBadge(label: 'Original'),
                  const Spacer(),
                  _CompareBadge(label: 'Modified'),
                ],
              ),
              const Spacer(),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      'Drag to compare',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: MixelithColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareBadge extends StatelessWidget {
  const _CompareBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: MixelithColors.textPrimary,
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

class _ImageDetails extends StatelessWidget {
  const _ImageDetails({required this.workingImage, required this.state});

  final WorkingImage workingImage;
  final EditorState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      (
        'Original',
        '${workingImage.originalWidth} x ${workingImage.originalHeight}',
      ),
      (
        'Preview',
        '${workingImage.previewWidth} x ${workingImage.previewHeight}',
      ),
      ('Format', workingImage.originalExtension.toUpperCase()),
      ('Filter', _selectedFilterName()),
      ('Downscaled', workingImage.wasPreviewDownscaled ? 'Yes' : 'No'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Working image',
              style: theme.textTheme.titleMedium?.copyWith(
                color: MixelithColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final detail in details)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.$1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(detail.$2, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _selectedFilterName() {
    for (final preset in state.presets) {
      if (preset.id == state.selectedFilterId) {
        return preset.name;
      }
    }
    return 'Original';
  }
}
