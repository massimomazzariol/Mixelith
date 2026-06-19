import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/mixelith_gradient_button.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';
import '../domain/local_onnx_model.dart';
import '../providers/local_onnx_model_controller.dart';

class LocalOnnxModelsScreen extends ConsumerStatefulWidget {
  const LocalOnnxModelsScreen({super.key});

  @override
  ConsumerState<LocalOnnxModelsScreen> createState() =>
      _LocalOnnxModelsScreenState();
}

class _LocalOnnxModelsScreenState extends ConsumerState<LocalOnnxModelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(localOnnxModelControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localOnnxModelControllerProvider);

    return MixelithScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Local models'),
      ),
      child: SafeArea(
        child: ListView(
          key: const Key('localOnnxModelsScreen'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'ONNX models',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const _DevPreviewNotice(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: MixelithGradientButton(
                key: const Key('importOnnxModelButton'),
                label: state.isImporting
                    ? 'Importing...'
                    : 'Import local ONNX model',
                icon: Icons.file_open_outlined,
                onPressed: state.isImporting
                    ? null
                    : () => ref
                          .read(localOnnxModelControllerProvider.notifier)
                          .importModel(),
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 14),
              _StatusMessage(
                icon: Icons.error_outline_rounded,
                message: state.errorMessage!,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
            const SizedBox(height: 18),
            if (state.status == LocalOnnxModelLoadStatus.loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 14),
            ],
            if (state.models.isEmpty)
              const _NoModelsPanel()
            else
              for (final model in state.models) ...[
                _LocalOnnxModelTile(model: model),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _DevPreviewNotice extends StatelessWidget {
  const _DevPreviewNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'This build does not include ONNX models. Import a compatible local ONNX model for testing. Model files stay local to this device.',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: MixelithColors.textSecondary),
    );
  }
}

class _NoModelsPanel extends StatelessWidget {
  const _NoModelsPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.memory_outlined, color: MixelithColors.yellow),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No compatible local ONNX models imported yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MixelithColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalOnnxModelTile extends StatelessWidget {
  const _LocalOnnxModelTile({required this.model});

  final LocalOnnxModel model;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(model.status, context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixelithColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    model.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusPill(label: model.statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            _ModelDetail(label: 'Size', value: model.fileSizeLabel),
            _ModelDetail(label: 'Input', value: model.inputShapeLabel),
            _ModelDetail(label: 'Output', value: model.outputShapeLabel),
            if (model.rejectionReason != null) ...[
              const SizedBox(height: 10),
              _StatusMessage(
                icon: Icons.info_outline_rounded,
                message: model.rejectionReason!,
                color: statusColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(LocalOnnxModelStatus status, BuildContext context) {
    return switch (status) {
      LocalOnnxModelStatus.usable => MixelithColors.yellow,
      LocalOnnxModelStatus.rejected => Theme.of(context).colorScheme.error,
      LocalOnnxModelStatus.failedValidation => MixelithColors.textSecondary,
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.52)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: color, fontSize: 12),
        ),
      ),
    );
  }
}

class _ModelDetail extends StatelessWidget {
  const _ModelDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MixelithColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
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
