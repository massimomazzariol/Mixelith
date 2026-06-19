import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../features/onnx_models/providers/local_onnx_model_controller.dart';
import '../../../filters/presets/default_filter_presets.dart';
import '../../../shared/widgets/mixelith_gradient_logo.dart';
import '../../../shared/widgets/mixelith_loading_overlay.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';
import '../../editor/domain/applied_filter.dart';
import '../domain/batch_export_state.dart';
import '../providers/batch_export_controller.dart';

class BatchExportScreen extends ConsumerStatefulWidget {
  const BatchExportScreen({super.key});

  @override
  ConsumerState<BatchExportScreen> createState() => _BatchExportScreenState();
}

class _BatchExportScreenState extends ConsumerState<BatchExportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(localOnnxModelControllerProvider.notifier).load();
      final controller = ref.read(batchExportControllerProvider.notifier);
      controller.selectProceduralStack([_applied(neonHeatFilterId)]);
      controller.pickImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final batch = ref.watch(batchExportControllerProvider);

    return MixelithScreenScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MixelithGradientLogo(size: 28),
            SizedBox(width: 10),
            Text('Batch export'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Choose photos',
            onPressed: batch.isBusy
                ? null
                : () => ref
                      .read(batchExportControllerProvider.notifier)
                      .pickImages(),
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _BatchHeader(batch: batch),
              _ModePanel(batch: batch),
              Expanded(child: _PhotoSelectionPanel(batch: batch)),
              _QueuePanel(batch: batch),
            ],
          ),
          if (batch.isProcessing || batch.isPickingPhotos)
            MixelithLoadingOverlay(
              message: batch.isPickingPhotos
                  ? 'Opening photo picker'
                  : 'Batch ${batch.currentIndex} of ${batch.totalCount}: ${_currentLabel(batch)}',
            ),
        ],
      ),
    );
  }

  static AppliedFilter _applied(String presetId) {
    return AppliedFilter(presetId: presetId, appliedAt: DateTime.now());
  }

  static String _currentLabel(BatchExportState state) {
    final index = state.currentIndex - 1;
    if (index < 0 || index >= state.queue.length) {
      return 'preparing';
    }
    return state.queue[index].label;
  }
}

class _PhotoSelectionPanel extends ConsumerWidget {
  const _PhotoSelectionPanel({required this.batch});

  final BatchExportState batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(batchExportControllerProvider.notifier);
    if (batch.queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: MixelithColors.yellow,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                'Choose photos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the Android picker to add one or more local images.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MixelithColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: batch.isBusy ? null : controller.pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Choose'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: batch.queue.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: batch.isBusy ? null : controller.pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add photos'),
            ),
          );
        }
        final item = batch.queue[index - 1];
        return _SelectedPhotoRow(
          item: item,
          isBusy: batch.isBusy,
          onRemove: () => controller.removeAsset(item.asset.id),
        );
      },
    );
  }
}

class _SelectedPhotoRow extends StatelessWidget {
  const _SelectedPhotoRow({
    required this.item,
    required this.isBusy,
    required this.onRemove,
  });

  final BatchQueueItem item;
  final bool isBusy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            const Icon(
              Icons.photo_outlined,
              color: MixelithColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sizeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MixelithColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: isBusy ? null : onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchHeader extends ConsumerWidget {
  const _BatchHeader({required this.batch});

  final BatchExportState batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MixelithColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.dynamic_feed_outlined,
                color: MixelithColors.yellow,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  batch.hasCompletedBatch
                      ? batch.summaryLabel
                      : '${batch.totalCount} selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: batch.isBusy || batch.queue.isEmpty
                    ? null
                    : ref
                          .read(batchExportControllerProvider.notifier)
                          .clearQueue,
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: batch.isBusy
                    ? null
                    : () => ref
                          .read(batchExportControllerProvider.notifier)
                          .startBatch(),
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePanel extends ConsumerWidget {
  const _ModePanel({required this.batch});

  final BatchExportState batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(localOnnxModelControllerProvider).usableModels;
    final selectedModel = batch.selectedOnnxModel;
    final selectedFilterId = batch.filterStack.isNotEmpty
        ? batch.filterStack.first.presetId
        : neonHeatFilterId;
    final controller = ref.read(batchExportControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MixelithColors.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<BatchProcessingMode>(
                segments: const [
                  ButtonSegment(
                    value: BatchProcessingMode.procedural,
                    label: Text('Procedural'),
                    icon: Icon(Icons.auto_awesome_outlined),
                  ),
                  ButtonSegment(
                    value: BatchProcessingMode.onnx,
                    label: Text('ONNX'),
                    icon: Icon(Icons.memory_outlined),
                  ),
                ],
                selected: {batch.mode ?? BatchProcessingMode.procedural},
                onSelectionChanged: batch.isBusy
                    ? null
                    : (selection) {
                        final mode = selection.single;
                        if (mode == BatchProcessingMode.procedural) {
                          controller.selectProceduralStack([
                            _BatchExportScreenState._applied(selectedFilterId),
                          ]);
                        } else {
                          controller.selectOnnxModel(
                            selectedModel ??
                                (models.isEmpty ? null : models.first),
                          );
                        }
                      },
              ),
              const SizedBox(height: 10),
              if ((batch.mode ?? BatchProcessingMode.procedural) ==
                  BatchProcessingMode.procedural)
                DropdownButtonFormField<String>(
                  initialValue: selectedFilterId,
                  decoration: const InputDecoration(labelText: 'Filter'),
                  items: const [
                    DropdownMenuItem(
                      value: neonHeatFilterId,
                      child: Text('Neon Heat'),
                    ),
                    DropdownMenuItem(
                      value: popPosterFilterId,
                      child: Text('Pop Poster'),
                    ),
                    DropdownMenuItem(
                      value: watercolorFilterId,
                      child: Text('Watercolor'),
                    ),
                    DropdownMenuItem(
                      value: mosaicFilterId,
                      child: Text('Mosaic'),
                    ),
                    DropdownMenuItem(
                      value: starryOilFilterId,
                      child: Text('Starry Oil'),
                    ),
                  ],
                  onChanged: batch.isBusy
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          controller.selectProceduralStack([
                            _BatchExportScreenState._applied(value),
                          ]);
                        },
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedModel?.id,
                      decoration: const InputDecoration(
                        labelText: 'Compatible local ONNX model',
                      ),
                      items: [
                        for (final model in models)
                          DropdownMenuItem(
                            value: model.id,
                            child: Text(model.displayLabel),
                          ),
                      ],
                      onChanged: batch.isBusy
                          ? null
                          : (value) {
                              final model = models
                                  .where((item) => item.id == value)
                                  .firstOrNull;
                              controller.selectOnnxModel(model);
                            },
                    ),
                    if (models.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'This build does not include ONNX models. Import a compatible local model for testing.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MixelithColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              if (batch.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  batch.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: MixelithColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.batch});

  final BatchExportState batch;

  @override
  Widget build(BuildContext context) {
    if (batch.queue.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleItems = batch.queue.take(4).toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in visibleItems) _QueueRow(item: item),
              if (batch.queue.length > visibleItems.length)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+${batch.queue.length - visibleItems.length} more',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item});

  final BatchQueueItem item;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (item.status) {
      BatchQueueItemStatus.pending => 'Pending',
      BatchQueueItemStatus.processing => 'Processing',
      BatchQueueItemStatus.exported => 'Exported',
      BatchQueueItemStatus.failed => 'Failed',
    };
    final statusColor = switch (item.status) {
      BatchQueueItemStatus.exported => MixelithColors.yellow,
      BatchQueueItemStatus.failed => MixelithColors.red,
      BatchQueueItemStatus.processing => MixelithColors.orange,
      BatchQueueItemStatus.pending => MixelithColors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.photo_outlined, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.label} - ${item.sizeLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.processingTimeLabel.isEmpty
                ? statusLabel
                : '$statusLabel ${item.processingTimeLabel}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
}
