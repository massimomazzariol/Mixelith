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
    final tile = shortest * 0.265;
    final gap = shortest * 0.045;
    final radius = Radius.circular(shortest * 0.085);
    final backplate = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        shortest * 0.07,
        shortest * 0.07,
        shortest * 0.86,
        shortest * 0.86,
      ),
      Radius.circular(shortest * 0.24),
    );
    final backplatePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1C0C10).withValues(alpha: 0.98),
          const Color(0xFF070506).withValues(alpha: 0.98),
        ],
      ).createShader(backplate.outerRect);
    final backplateStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.018
      ..color = Colors.white.withValues(alpha: 0.12);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.028
      ..color = Colors.white.withValues(alpha: 0.18);

    canvas.drawRRect(
      backplate.shift(Offset(0, shortest * 0.025)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawRRect(backplate, backplatePaint);
    canvas.drawRRect(backplate, backplateStroke);

    final tiles = <({Offset offset, Color color})>[
      (
        offset: Offset(shortest * 0.22, shortest * 0.25),
        color: MixelithColors.orange,
      ),
      (
        offset: Offset(shortest * 0.22 + tile + gap, shortest * 0.21),
        color: MixelithColors.yellow,
      ),
      (
        offset: Offset(shortest * 0.18, shortest * 0.25 + tile + gap),
        color: MixelithColors.red,
      ),
      (
        offset: Offset(
          shortest * 0.22 + tile + gap * 0.82,
          shortest * 0.25 + tile + gap * 0.72,
        ),
        color: const Color(0xFF9B2430),
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
