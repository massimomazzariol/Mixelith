import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final outputDirectory = Directory('assets/style_references');
  outputDirectory.createSync(recursive: true);

  _writePng(
    '${outputDirectory.path}/neon_heat_style.png',
    _neonHeat(),
  );
  _writePng(
    '${outputDirectory.path}/watercolor_wash_style.png',
    _watercolorWash(),
  );
  _writePng(
    '${outputDirectory.path}/mosaic_tiles_style.png',
    _mosaicTiles(),
  );
  _writePng(
    '${outputDirectory.path}/oil_night_style.png',
    _oilNight(),
  );
}

void _writePng(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image), flush: true);
}

img.Image _neonHeat() {
  final image = img.Image(width: 256, height: 256);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final dx = x - 128.0;
      final dy = y - 128.0;
      final radius = math.sqrt(dx * dx + dy * dy) / 181.0;
      final wave = math.sin(x / 12.0) * math.cos(y / 18.0);
      final heat = (1.0 - radius).clamp(0.0, 1.0);
      image.setPixelRgb(
        x,
        y,
        _channel(255 * heat + 255 * wave.abs() * 0.18),
        _channel(76 * heat + 194 * (1 - radius).clamp(0.0, 0.7)),
        _channel(20 + 60 * wave.abs()),
      );
    }
  }
  return img.gaussianBlur(image, radius: 2);
}

img.Image _watercolorWash() {
  final image = img.Image(width: 256, height: 256);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final wave = math.sin((x + y) / 22.0) + math.cos((x - y) / 31.0);
      final wash = (wave + 2.0) / 4.0;
      image.setPixelRgb(
        x,
        y,
        _channel(185 + 45 * wash),
        _channel(112 + 86 * (1 - wash)),
        _channel(144 + 72 * wash),
      );
    }
  }
  return img.gaussianBlur(image, radius: 6);
}

img.Image _mosaicTiles() {
  final image = img.Image(width: 256, height: 256);
  const tile = 24;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final tx = x ~/ tile;
      final ty = y ~/ tile;
      final palette = (tx * 3 + ty * 5) % 5;
      final edge = x % tile == 0 || y % tile == 0;
      final color = switch (palette) {
        0 => (245, 91, 35),
        1 => (255, 194, 71),
        2 => (217, 70, 239),
        3 => (31, 180, 138),
        _ => (240, 240, 240),
      };
      image.setPixelRgb(
        x,
        y,
        edge ? 22 : color.$1,
        edge ? 18 : color.$2,
        edge ? 28 : color.$3,
      );
    }
  }
  return image;
}

img.Image _oilNight() {
  final image = img.Image(width: 256, height: 256);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final swirl =
          math.sin((x + y * 0.8) / 14.0) + math.cos((x * 0.5 - y) / 18.0);
      final glow = math.exp(
        -((x - 172) * (x - 172) + (y - 82) * (y - 82)) / 2300.0,
      );
      image.setPixelRgb(
        x,
        y,
        _channel(22 + glow * 210 + swirl * 18),
        _channel(24 + glow * 140 + swirl * 14),
        _channel(70 + glow * 60 + swirl * 30),
      );
    }
  }
  return img.gaussianBlur(image, radius: 1);
}

int _channel(num value) => value.clamp(0, 255).round();
