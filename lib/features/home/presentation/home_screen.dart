import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../features/camera/presentation/camera_capture_screen.dart';
import '../../../features/import/presentation/import_gallery_screen.dart';
import '../../../shared/widgets/mixelith_gradient_button.dart';
import '../../../shared/widgets/mixelith_gradient_logo.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MixelithScreenScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isAndroid = defaultTargetPlatform == TargetPlatform.android;
            final isShort = constraints.maxHeight < 720;
            final padding = EdgeInsets.fromLTRB(
              24,
              isShort ? 16 : 24,
              24,
              isShort ? 16 : 20,
            );
            final previewMaxHeight = math.min(
              isShort ? 188.0 : 320.0,
              constraints.maxHeight * (isShort ? 0.32 : 0.36),
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
                    const MixelithGradientLogo(size: 44, showWordmark: true),
                    SizedBox(height: isShort ? 18 : 40),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 420,
                          maxHeight: previewMaxHeight,
                        ),
                        child: const _PreviewMosaic(),
                      ),
                    ),
                    SizedBox(height: isShort ? 18 : 24),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          MixelithColors.accentGradient.createShader(bounds),
                      child: Text(
                        'Mixelith',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    SizedBox(height: isShort ? 10 : 14),
                    Text(
                      'Neon art filters for local photos. No cloud. No account.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: MixelithColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: isShort ? 18 : 24),
                    SizedBox(
                      width: double.infinity,
                      child: MixelithGradientButton(
                        key: const Key('openGalleryButton'),
                        label: 'Open photo',
                        icon: Icons.photo_library_outlined,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ImportGalleryScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryHomeAction(
                            key: const Key('cameraCaptureButton'),
                            label: 'Take photo now',
                            caption: isAndroid ? 'Camera' : 'Android only',
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
                            key: const Key('batchComingSoonButton'),
                            label: 'More photos',
                            caption: 'Future batch',
                            icon: Icons.grid_view_rounded,
                            onTap: () => _showComingSoonSheet(
                              context,
                              title: 'More photos',
                              message:
                                  'Multi-selection and batch processing will arrive in a subsequent version. The current grid remains for a single photo.',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Everything stays on this device.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: MixelithColors.textSecondary.withValues(
                          alpha: 0.72,
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
    );
  }
}

class _PreviewMosaic extends StatelessWidget {
  const _PreviewMosaic();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: MixelithColors.red.withValues(alpha: 0.20),
              blurRadius: 40,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: CustomPaint(painter: _PreviewMosaicPainter()),
        ),
      ),
    );
  }
}

class _PreviewMosaicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF090A10);
    canvas.drawRect(Offset.zero & size, background);

    final tile = size.width / 5.6;
    final colors = [
      MixelithColors.orange,
      MixelithColors.red,
      MixelithColors.yellow,
      MixelithColors.magenta,
      const Color(0xFF2B1A20),
    ];

    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 6; col++) {
        final index = (row * 3 + col * 2) % colors.length;
        final color = colors[index].withValues(
          alpha: index == colors.length - 1 ? 0.64 : 0.82,
        );
        final rect = Rect.fromLTWH(
          col * tile - tile * 0.2,
          row * tile * 0.92 + (col.isEven ? tile * 0.12 : 0),
          tile * 0.84,
          tile * 0.84,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(tile * 0.18)),
          Paint()..color = color,
        );
      }
    }

    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0xCC000000)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SecondaryHomeAction extends StatelessWidget {
  const _SecondaryHomeAction({
    required this.label,
    required this.caption,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final String caption;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: MixelithColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: MixelithColors.yellow, size: 20),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: MixelithColors.textSecondary.withValues(alpha: 0.78),
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
