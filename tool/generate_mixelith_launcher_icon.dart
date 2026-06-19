import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const launcherSize = 1024;
  const splashSize = 512;
  const launcherOutputPath = 'assets/branding/mixelith_launcher_icon.png';
  const splashOutputPath = 'assets/branding/mixelith_splash_icon.png';
  const androidSplashOutputPath =
      'android/app/src/main/res/drawable-nodpi/mixelith_splash_icon.png';

  final launcher = _RgbCanvas(launcherSize);
  _paintBackground(launcher);
  _paintMosaicMark(launcher);

  final splash = _RgbCanvas(splashSize);
  _paintBackground(splash, glowMix: 0.28);
  _paintMosaicMark(splash, markScale: 0.82);

  Directory('assets/branding').createSync(recursive: true);
  Directory(
    'android/app/src/main/res/drawable-nodpi',
  ).createSync(recursive: true);
  final launcherBytes = img.encodePng(launcher.toImage());
  final splashBytes = img.encodePng(splash.toImage());
  File(launcherOutputPath).writeAsBytesSync(launcherBytes);
  File(splashOutputPath).writeAsBytesSync(splashBytes);
  File(androidSplashOutputPath).writeAsBytesSync(splashBytes);
  stdout.writeln('Generated $launcherOutputPath');
  stdout.writeln('Generated $splashOutputPath');
  stdout.writeln('Generated $androidSplashOutputPath');
}

void _paintBackground(_RgbCanvas canvas, {double glowMix = 0.38}) {
  final size = canvas.size;
  const top = _Rgb(34, 13, 18);
  const bottom = _Rgb(6, 5, 9);
  const glow = _Rgb(255, 90, 31);

  for (var y = 0; y < size; y++) {
    final vertical = y / (size - 1);
    for (var x = 0; x < size; x++) {
      final horizontal = x / (size - 1);
      final base = _Rgb.lerp(
        top,
        bottom,
        (vertical * 0.82 + horizontal * 0.18),
      );
      final glowDistance = math.sqrt(
        math.pow(horizontal - 0.68, 2) + math.pow(vertical - 0.28, 2),
      );
      final glowFalloff = (1 - glowDistance / 0.72).clamp(0.0, 1.0);
      final vignetteDistance = math.sqrt(
        math.pow(horizontal - 0.5, 2) + math.pow(vertical - 0.5, 2),
      );
      final vignette = (vignetteDistance / 0.78).clamp(0.0, 1.0);
      final warm = _Rgb.lerp(base, glow, glowFalloff * glowMix);
      final shaded = _Rgb.lerp(warm, const _Rgb(0, 0, 0), vignette * 0.30);
      canvas.set(x, y, shaded);
    }
  }
}

void _paintMosaicMark(_RgbCanvas canvas, {double markScale = 1}) {
  final size = canvas.size.toDouble();
  final markSize = size * 0.72 * markScale;
  final markLeft = (size - markSize) / 2;
  final markTop = (size - markSize) / 2;
  final frame = _RectSpec(
    x: markLeft,
    y: markTop,
    width: markSize,
    height: markSize,
    radius: markSize * 0.22,
  );
  canvas.drawRoundedRect(
    frame.inflate(markSize * 0.055),
    const _Rgb(255, 90, 31),
    alpha: 0.055,
  );
  canvas.drawRoundedRect(
    frame.translate(size * 0.018, size * 0.030),
    const _Rgb(0, 0, 0),
    alpha: 0.32,
  );

  canvas.drawRoundedRect(frame, const _Rgb(255, 194, 71), alpha: 0.10);
  canvas.strokeRoundedRect(
    frame,
    const _Rgb(255, 194, 71),
    alpha: 0.34,
    width: math.max(8, (size * 0.014).round()),
  );

  final tile = markSize * 0.31;
  final gap = markSize * 0.055;
  final radius = markSize * 0.072;
  final startX = markLeft + markSize * 0.17;
  final startY = markTop + markSize * 0.18;
  final tiles = <_TileSpec>[
    _TileSpec(startX, startY, tile, radius, const _Rgb(255, 90, 31)),
    _TileSpec(
      startX + tile + gap,
      startY - markSize * 0.04,
      tile,
      radius,
      const _Rgb(255, 194, 71),
    ),
    _TileSpec(
      startX - markSize * 0.04,
      startY + tile + gap,
      tile,
      radius,
      const _Rgb(255, 45, 85),
    ),
    _TileSpec(
      startX + tile + gap * 0.86,
      startY + tile + gap * 0.78,
      tile,
      radius,
      const _Rgb(122, 28, 36),
    ),
  ];

  for (final tileSpec in tiles) {
    canvas.drawRoundedRect(
      tileSpec.rect.translate(size * 0.018, size * 0.028),
      const _Rgb(0, 0, 0),
      alpha: 0.30,
    );
  }

  for (final tileSpec in tiles) {
    canvas.drawGradientRoundedRect(tileSpec.rect, tileSpec.color, radius);
    canvas.strokeRoundedRect(
      tileSpec.rect,
      const _Rgb(255, 242, 220),
      alpha: 0.16,
      width: math.max(5, (size * 0.010).round()),
    );
  }

  canvas.drawRoundedRect(
    _RectSpec(
      x: markLeft + markSize * 0.18,
      y: markTop + markSize * 0.19,
      width: markSize * 0.54,
      height: markSize * 0.10,
      radius: markSize * 0.05,
    ),
    const _Rgb(255, 244, 214),
    alpha: 0.055,
  );
}

class _RgbCanvas {
  _RgbCanvas(this.size) : _data = List<int>.filled(size * size * 3, 0);

  final int size;
  final List<int> _data;

  void set(int x, int y, _Rgb color) {
    final index = (y * size + x) * 3;
    _data[index] = color.r;
    _data[index + 1] = color.g;
    _data[index + 2] = color.b;
  }

  void blend(int x, int y, _Rgb color, double alpha) {
    if (x < 0 || y < 0 || x >= size || y >= size || alpha <= 0) {
      return;
    }
    final clamped = alpha.clamp(0.0, 1.0);
    final index = (y * size + x) * 3;
    _data[index] = (_data[index] * (1 - clamped) + color.r * clamped).round();
    _data[index + 1] = (_data[index + 1] * (1 - clamped) + color.g * clamped)
        .round();
    _data[index + 2] = (_data[index + 2] * (1 - clamped) + color.b * clamped)
        .round();
  }

  void drawRoundedRect(_RectSpec rect, _Rgb color, {required double alpha}) {
    final minX = rect.x.floor().clamp(0, size - 1).toInt();
    final maxX = (rect.x + rect.width).ceil().clamp(0, size - 1).toInt();
    final minY = rect.y.floor().clamp(0, size - 1).toInt();
    final maxY = (rect.y + rect.height).ceil().clamp(0, size - 1).toInt();
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        if (_insideRoundedRect(x + 0.5, y + 0.5, rect)) {
          blend(x, y, color, alpha);
        }
      }
    }
  }

  void drawGradientRoundedRect(_RectSpec rect, _Rgb color, double radius) {
    final minX = rect.x.floor().clamp(0, size - 1).toInt();
    final maxX = (rect.x + rect.width).ceil().clamp(0, size - 1).toInt();
    final minY = rect.y.floor().clamp(0, size - 1).toInt();
    final maxY = (rect.y + rect.height).ceil().clamp(0, size - 1).toInt();
    final shape = rect.copyWith(radius: radius);
    for (var y = minY; y <= maxY; y++) {
      final vertical = ((y - rect.y) / rect.height).clamp(0.0, 1.0);
      for (var x = minX; x <= maxX; x++) {
        if (!_insideRoundedRect(x + 0.5, y + 0.5, shape)) {
          continue;
        }
        final horizontal = ((x - rect.x) / rect.width).clamp(0.0, 1.0);
        final highlight = ((1 - horizontal) * 0.42 + (1 - vertical) * 0.58)
            .clamp(0.0, 1.0);
        final shaded = _Rgb.lerp(
          _Rgb.lerp(color, const _Rgb(18, 8, 12), 0.22 + vertical * 0.26),
          const _Rgb(255, 232, 186),
          highlight * 0.26,
        );
        blend(x, y, shaded, 0.94);
      }
    }
  }

  void strokeRoundedRect(
    _RectSpec rect,
    _Rgb color, {
    required double alpha,
    required int width,
  }) {
    for (var inset = 0; inset < width; inset++) {
      final outer = rect.deflate(inset.toDouble());
      final inner = rect.deflate(inset + 1.0);
      final minX = outer.x.floor().clamp(0, size - 1).toInt();
      final maxX = (outer.x + outer.width).ceil().clamp(0, size - 1).toInt();
      final minY = outer.y.floor().clamp(0, size - 1).toInt();
      final maxY = (outer.y + outer.height).ceil().clamp(0, size - 1).toInt();
      for (var y = minY; y <= maxY; y++) {
        for (var x = minX; x <= maxX; x++) {
          final px = x + 0.5;
          final py = y + 0.5;
          if (_insideRoundedRect(px, py, outer) &&
              !_insideRoundedRect(px, py, inner)) {
            blend(x, y, color, alpha);
          }
        }
      }
    }
  }

  img.Image toImage() {
    final image = img.Image(width: size, height: size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final index = (y * size + x) * 3;
        image.setPixelRgb(
          x,
          y,
          _data[index],
          _data[index + 1],
          _data[index + 2],
        );
      }
    }
    return image;
  }
}

bool _insideRoundedRect(double x, double y, _RectSpec rect) {
  final left = rect.x + rect.radius;
  final right = rect.x + rect.width - rect.radius;
  final top = rect.y + rect.radius;
  final bottom = rect.y + rect.height - rect.radius;
  final dx = x < left
      ? left - x
      : x > right
      ? x - right
      : 0.0;
  final dy = y < top
      ? top - y
      : y > bottom
      ? y - bottom
      : 0.0;
  return dx * dx + dy * dy <= rect.radius * rect.radius;
}

class _TileSpec {
  const _TileSpec(this.x, this.y, this.size, this.radius, this.color);

  final double x;
  final double y;
  final double size;
  final double radius;
  final _Rgb color;

  _RectSpec get rect =>
      _RectSpec(x: x, y: y, width: size, height: size, radius: radius);
}

class _RectSpec {
  const _RectSpec({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.radius,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double radius;

  _RectSpec translate(double dx, double dy) => _RectSpec(
    x: x + dx,
    y: y + dy,
    width: width,
    height: height,
    radius: radius,
  );

  _RectSpec deflate(double amount) => _RectSpec(
    x: x + amount,
    y: y + amount,
    width: width - amount * 2,
    height: height - amount * 2,
    radius: math.max(0, radius - amount),
  );

  _RectSpec inflate(double amount) => _RectSpec(
    x: x - amount,
    y: y - amount,
    width: width + amount * 2,
    height: height + amount * 2,
    radius: radius + amount,
  );

  _RectSpec copyWith({double? radius}) => _RectSpec(
    x: x,
    y: y,
    width: width,
    height: height,
    radius: radius ?? this.radius,
  );
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;

  static _Rgb lerp(_Rgb a, _Rgb b, double amount) {
    final t = amount.clamp(0.0, 1.0);
    return _Rgb(
      (a.r + (b.r - a.r) * t).round().clamp(0, 255).toInt(),
      (a.g + (b.g - a.g) * t).round().clamp(0, 255).toInt(),
      (a.b + (b.b - a.b) * t).round().clamp(0, 255).toInt(),
    );
  }
}
