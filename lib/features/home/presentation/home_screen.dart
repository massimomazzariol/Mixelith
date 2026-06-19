import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../features/batch/presentation/batch_export_screen.dart';
import '../../../features/batch/providers/batch_image_picker_provider.dart';
import '../../../features/camera/presentation/camera_capture_screen.dart';
import '../../../features/editor/presentation/editor_preview_screen.dart';
import '../../../features/import/domain/working_image_import_service.dart';
import '../../../features/import/providers/working_image_import_controller.dart';
import '../../../features/onnx_models/presentation/local_onnx_models_screen.dart';
import '../../../shared/widgets/mixelith_gradient_button.dart';
import '../../../shared/widgets/mixelith_gradient_logo.dart';
import '../../../shared/widgets/mixelith_loading_overlay.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';

const _homeVersionLabel = 'v0.1.0';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isOpeningPhoto = false;

  @override
  Widget build(BuildContext context) {
    return MixelithScreenScaffold(
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: _HomeMosaicBackground(key: Key('homeMosaicBackground')),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isAndroid =
                    defaultTargetPlatform == TargetPlatform.android;
                final isShort = constraints.maxHeight < 720;
                final padding = EdgeInsets.fromLTRB(
                  24,
                  isShort ? 16 : 24,
                  24,
                  isShort ? 16 : 20,
                );
                final visualBreathingRoom = math.min(
                  isShort ? 126.0 : 224.0,
                  constraints.maxHeight * (isShort ? 0.21 : 0.29),
                );

                return SingleChildScrollView(
                  key: const Key('homeScreen'),
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - padding.vertical,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MixelithGradientLogo(
                          size: 44,
                          showWordmark: true,
                        ),
                        SizedBox(height: isShort ? 18 : 28),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              children: [
                                SizedBox(height: visualBreathingRoom),
                                SizedBox(
                                  width: double.infinity,
                                  child: MixelithGradientButton(
                                    key: const Key('openGalleryButton'),
                                    label: _isOpeningPhoto
                                        ? 'Opening...'
                                        : 'Open photo',
                                    icon: Icons.photo_library_outlined,
                                    onPressed: _isOpeningPhoto
                                        ? null
                                        : _openPhoto,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SecondaryHomeAction(
                                        key: const Key('cameraCaptureButton'),
                                        label: 'Take photo now',
                                        caption: isAndroid
                                            ? 'Camera'
                                            : 'Android only',
                                        icon: Icons.photo_camera_outlined,
                                        onTap: isAndroid
                                            ? () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const CameraCaptureScreen(),
                                                ),
                                              )
                                            : () => _showComingSoonSheet(
                                                context,
                                                title: 'Android Camera',
                                                message:
                                                    'Camera capture is available on Android builds.',
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SecondaryHomeAction(
                                        key: const Key('batchExportButton'),
                                        label: 'More photos',
                                        caption: 'Batch',
                                        icon: Icons.grid_view_rounded,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const BatchExportScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: _SecondaryHomeAction(
                                    key: const Key('localOnnxModelsButton'),
                                    label: 'Local models',
                                    caption: 'ONNX',
                                    icon: Icons.memory_outlined,
                                    lowPriority: true,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const LocalOnnxModelsScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isShort ? 14 : 18),
                                const _HomeVersionLabel(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isOpeningPhoto)
            const MixelithLoadingOverlay(message: 'Preparing photo'),
        ],
      ),
    );
  }

  Future<void> _openPhoto() async {
    if (_isOpeningPhoto) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      _showComingSoonSheet(
        context,
        title: 'Android Photo Picker',
        message: 'Photo picking is available on Android builds.',
      );
      return;
    }

    setState(() => _isOpeningPhoto = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(batchImagePickerProvider).pickImage();
      if (!mounted) {
        return;
      }
      if (result.cancelled) {
        setState(() => _isOpeningPhoto = false);
        return;
      }
      if (result.hasError || result.items.isEmpty) {
        setState(() => _isOpeningPhoto = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Unable to open the selected photo.',
            ),
          ),
        );
        return;
      }

      final photo = result.items.first;
      final workingImage = await ref
          .read(workingImageImportServiceProvider)
          .importFromFilePath(
            sourcePath: photo.path,
            sourceAssetId: photo.id,
            extension: photo.extension,
          );
      if (!mounted) {
        return;
      }
      setState(() => _isOpeningPhoto = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditorPreviewScreen(workingImage: workingImage),
        ),
      );
    } on WorkingImageImportException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isOpeningPhoto = false);
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isOpeningPhoto = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open the selected photo.')),
      );
    }
  }
}

class _HomeMosaicBackground extends StatefulWidget {
  const _HomeMosaicBackground({super.key});

  @override
  State<_HomeMosaicBackground> createState() => _HomeMosaicBackgroundState();
}

class _HomeMosaicBackgroundState extends State<_HomeMosaicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations && _controller.isAnimating) {
      _controller.stop();
    } else if (!disableAnimations && !_controller.isAnimating) {
      _controller.repeat();
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _HomeMosaicBackgroundPainter(
              progress: disableAnimations ? 0 : _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _HomeMosaicBackgroundPainter extends CustomPainter {
  const _HomeMosaicBackgroundPainter({required this.progress});

  static const _layers = <_MosaicLayerSpec>[
    _MosaicLayerSpec(
      tileScale: 6.6,
      alphaScale: 0.14,
      verticalFactor: -0.18,
      driftFactor: 0.07,
      phase: 0.18,
      slant: 0.22,
      shadowAlpha: 0,
    ),
    _MosaicLayerSpec(
      tileScale: 4.8,
      alphaScale: 0.26,
      verticalFactor: -0.04,
      driftFactor: 0.11,
      phase: 0,
      slant: 0.16,
      shadowAlpha: 0.05,
    ),
    _MosaicLayerSpec(
      tileScale: 3.6,
      alphaScale: 0.16,
      verticalFactor: 0.24,
      driftFactor: 0.15,
      phase: 0.52,
      slant: 0.09,
      shadowAlpha: 0.04,
    ),
  ];

  static const _tileColors = <Color>[
    MixelithColors.orange,
    MixelithColors.red,
    MixelithColors.yellow,
    Color(0xFF30121A),
    Color(0xFF1A1016),
  ];

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldHeight = math.min(size.height * 0.54, 470.0);
    final fadeEnd = math.min(size.height, fieldHeight + size.height * 0.34);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, fadeEnd));

    _paintGlow(
      canvas,
      size,
      center: Offset(size.width * 0.72, fieldHeight * 0.20),
      radius: size.width * 0.72,
      color: MixelithColors.orange.withValues(alpha: 0.18),
    );
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width * 0.08, fieldHeight * 0.58),
      radius: size.width * 0.64,
      color: MixelithColors.red.withValues(alpha: 0.12),
    );

    for (final layer in _layers) {
      _paintLayer(canvas, size, fadeEnd: fadeEnd, layer: layer);
    }
    canvas.restore();

    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x11000000),
          Color(0x66000000),
          MixelithColors.background,
        ],
        stops: [0.0, 0.56, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, fadeEnd));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, fadeEnd), shade);
  }

  void _paintGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintLayer(
    Canvas canvas,
    Size size, {
    required double fadeEnd,
    required _MosaicLayerSpec layer,
  }) {
    final tile = size.width / layer.tileScale;
    final strideX = tile * 0.92;
    final strideY = tile * 0.84;
    final cols = (size.width / strideX).ceil() + 4;
    final rows = (fadeEnd / strideY).ceil() + 3;
    final drift =
        -size.width * layer.driftFactor * ((progress + layer.phase) % 1);
    final verticalOffset = fadeEnd * layer.verticalFactor;
    final tilePaint = Paint();
    final shadowPaint = Paint();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final index = (row * 5 + col * 3) % _tileColors.length;
        tilePaint.color = _tileColors[index].withValues(
          alpha:
              (index >= _tileColors.length - 2 ? 0.32 : 0.70) *
              layer.alphaScale,
        );
        final x = col * strideX - tile * 2.4 + row * tile * layer.slant + drift;
        final wrappedX =
            ((x + tile * 3) % (size.width + tile * 3)) - tile * 1.6;
        final rect = Rect.fromLTWH(
          wrappedX,
          verticalOffset +
              row * strideY +
              (col.isEven ? tile * 0.10 : -tile * 0.04),
          tile * 0.74,
          tile * 0.74,
        );
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(tile * 0.18),
        );
        if (layer.shadowAlpha > 0) {
          shadowPaint.color = Colors.black.withValues(
            alpha: layer.shadowAlpha * layer.alphaScale,
          );
          canvas.drawRRect(
            rrect.shift(Offset(tile * 0.05, tile * 0.08)),
            shadowPaint,
          );
        }
        canvas.drawRRect(rrect, tilePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeMosaicBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MosaicLayerSpec {
  const _MosaicLayerSpec({
    required this.tileScale,
    required this.alphaScale,
    required this.verticalFactor,
    required this.driftFactor,
    required this.phase,
    required this.slant,
    required this.shadowAlpha,
  });

  final double tileScale;
  final double alphaScale;
  final double verticalFactor;
  final double driftFactor;
  final double phase;
  final double slant;
  final double shadowAlpha;
}

class _HomeVersionLabel extends StatelessWidget {
  const _HomeVersionLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      _homeVersionLabel,
      key: const Key('homeVersionLabel'),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 11,
        color: MixelithColors.textSecondary.withValues(alpha: 0.42),
        height: 1,
      ),
    );
  }
}

class _SecondaryHomeAction extends StatelessWidget {
  const _SecondaryHomeAction({
    required this.label,
    required this.caption,
    required this.icon,
    required this.onTap,
    this.lowPriority = false,
    super.key,
  });

  final String label;
  final String caption;
  final IconData icon;
  final VoidCallback onTap;
  final bool lowPriority;

  @override
  Widget build(BuildContext context) {
    final labelColor = lowPriority
        ? MixelithColors.textPrimary.withValues(alpha: 0.74)
        : MixelithColors.textPrimary;
    final iconColor = lowPriority
        ? MixelithColors.textSecondary.withValues(alpha: 0.66)
        : MixelithColors.yellow.withValues(alpha: 0.88);
    final surfaceAlpha = lowPriority ? 0.52 : 0.76;
    final borderAlpha = lowPriority ? 0.05 : 0.075;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: MixelithColors.surface.withValues(alpha: surfaceAlpha),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderAlpha),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: lowPriority ? 19 : 20),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 2,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: labelColor),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: MixelithColors.textSecondary.withValues(
                      alpha: lowPriority ? 0.58 : 0.72,
                    ),
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

void _showComingSoonSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MixelithColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: MixelithGradientButton(
                    label: 'I understand',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
