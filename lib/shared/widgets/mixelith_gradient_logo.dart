import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MixelithGradientLogo extends StatelessWidget {
  const MixelithGradientLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.wordmarkSize = 28,
  });

  final double size;
  final bool showWordmark;
  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MosaicLogoPainter()),
    );

    if (!showWordmark) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              MixelithColors.accentGradient.createShader(bounds),
          child: Text(
            'Mixelith',
            style: TextStyle(
              color: MixelithColors.textPrimary,
              fontSize: wordmarkSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _MosaicLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final tile = shortest * 0.31;
    final radius = Radius.circular(shortest * 0.08);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.035
      ..color = Colors.white.withValues(alpha: 0.16);

    final tiles = <({Offset offset, Color color})>[
      (
        offset: Offset(shortest * 0.08, shortest * 0.17),
        color: MixelithColors.orange,
      ),
      (
        offset: Offset(shortest * 0.40, shortest * 0.08),
        color: MixelithColors.yellow,
      ),
      (
        offset: Offset(shortest * 0.22, shortest * 0.48),
        color: MixelithColors.red,
      ),
      (
        offset: Offset(shortest * 0.56, shortest * 0.40),
        color: MixelithColors.magenta,
      ),
    ];

    for (final item in tiles) {
      final rect = item.offset & Size.square(tile);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.color.withValues(alpha: 0.95),
            item.color.withValues(alpha: 0.52),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
