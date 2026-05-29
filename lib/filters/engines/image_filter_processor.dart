import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../features/export/domain/export_settings.dart';
import '../domain/filter_preset.dart';
import '../presets/default_filter_presets.dart';

class ProcessedFilterImage {
  const ProcessedFilterImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.wasDownscaled,
    required this.outputFormat,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String mimeType;
  final bool wasDownscaled;
  final ExportFormat outputFormat;
}

Future<ProcessedFilterImage> processFilterImage({
  required String inputPath,
  required FilterPreset preset,
  Map<String, double> parameterValues = const {},
  ExportFormat format = ExportFormat.jpeg,
  int jpegQuality = 90,
  double? maxLongSide,
}) {
  return compute(_processFilterImageInBackground, {
    'inputPath': inputPath,
    'presetId': preset.id,
    'parameters': resolveFilterParameters(preset, parameterValues),
    'format': format.name,
    'jpegQuality': jpegQuality,
    'maxLongSide': maxLongSide,
  });
}

Map<String, double> resolveFilterParameters(
  FilterPreset preset,
  Map<String, double> parameterValues,
) {
  return {
    for (final parameter in preset.parameters)
      parameter.id: (parameterValues[parameter.id] ?? parameter.defaultValue)
          .clamp(parameter.minValue, parameter.maxValue)
          .toDouble(),
  };
}

ProcessedFilterImage _processFilterImageInBackground(
  Map<String, Object?> request,
) {
  final inputPath = request['inputPath']! as String;
  final presetId = request['presetId']! as String;
  final parameters = Map<String, double>.from(
    request['parameters']! as Map<dynamic, dynamic>,
  );
  final format = ExportFormat.values.byName(request['format']! as String);
  final jpegQuality = request['jpegQuality']! as int;
  final maxLongSide = request['maxLongSide'] as double?;

  final bytes = File(inputPath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Unable to decode image.');
  }

  final oriented = img.bakeOrientation(decoded);
  final resized = _resizeIfNeeded(oriented, maxLongSide);
  final output = switch (presetId) {
    originalFilterId => img.Image.from(resized.image),
    neonPopFilterId => _neonPop(resized.image, parameters),
    watercolorWashFilterId => _watercolorWash(resized.image, parameters),
    mosaicTilesFilterId => _mosaicTiles(resized.image, parameters),
    starryOilFilterId => _starryOil(resized.image, parameters),
    graphicPosterFilterId => _graphicPoster(resized.image, parameters),
    _ => throw ArgumentError.value(presetId, 'presetId', 'Unknown filter'),
  };

  final encoded = switch (format) {
    ExportFormat.jpeg => Uint8List.fromList(
      img.encodeJpg(output, quality: jpegQuality.clamp(1, 100)),
    ),
    ExportFormat.png => Uint8List.fromList(img.encodePng(output)),
  };

  return ProcessedFilterImage(
    bytes: encoded,
    width: output.width,
    height: output.height,
    mimeType: switch (format) {
      ExportFormat.jpeg => 'image/jpeg',
      ExportFormat.png => 'image/png',
    },
    wasDownscaled: resized.wasDownscaled,
    outputFormat: format,
  );
}

({img.Image image, bool wasDownscaled}) _resizeIfNeeded(
  img.Image source,
  double? maxLongSide,
) {
  if (maxLongSide == null || maxLongSide <= 0) {
    return (image: source, wasDownscaled: false);
  }

  final longestSide = math.max(source.width, source.height).toDouble();
  if (longestSide <= maxLongSide) {
    return (image: source, wasDownscaled: false);
  }

  final scale = maxLongSide / longestSide;
  final targetWidth = math.max(1, (source.width * scale).round());
  final targetHeight = math.max(1, (source.height * scale).round());

  return (
    image: img.copyResize(source, width: targetWidth, height: targetHeight),
    wasDownscaled: true,
  );
}

img.Image _neonPop(img.Image source, Map<String, double> parameters) {
  final intensity = parameters['intensity'] ?? 1.0;
  final saturation = parameters['saturation'] ?? 1.6;
  final contrast = parameters['contrast'] ?? 1.25;
  final adjusted = img.adjustColor(
    img.Image.from(source),
    saturation: saturation,
    contrast: contrast,
    brightness: 1.02 + intensity * 0.04,
    amount: intensity,
  );
  final glow = img.gaussianBlur(img.Image.from(adjusted), radius: 3);
  final output = img.Image.from(adjusted);

  for (var y = 0; y < output.height; y++) {
    for (var x = 0; x < output.width; x++) {
      final base = adjusted.getPixel(x, y);
      final blur = glow.getPixel(x, y);
      final r = _mix(base.r, _screen(base.r, blur.b * 1.16), intensity * 0.36);
      final g = _mix(base.g, _screen(base.g, blur.g * 1.08), intensity * 0.22);
      final b = _mix(base.b, _screen(base.b, blur.r * 1.18), intensity * 0.42);
      output.setPixelRgb(x, y, _clamp255(r), _clamp255(g), _clamp255(b));
    }
  }

  return output;
}

img.Image _watercolorWash(img.Image source, Map<String, double> parameters) {
  final intensity = parameters['intensity'] ?? 1.0;
  final softness = parameters['softness'] ?? 0.7;
  final colorLevels = (parameters['color_levels'] ?? 7.0).round();
  final radius = math.max(1, (softness * 4).round());
  final softened = img.gaussianBlur(img.Image.from(source), radius: radius);
  final washed = img.adjustColor(
    softened,
    saturation: 0.82 + intensity * 0.18,
    contrast: 0.82 + intensity * 0.08,
    brightness: 1.06 + intensity * 0.05,
  );
  final posterized = _posterize(washed, colorLevels);
  return _blendImages(source, posterized, intensity);
}

img.Image _mosaicTiles(img.Image source, Map<String, double> parameters) {
  final tileSize = math.max(1, (parameters['tile_size'] ?? 18.0).round());
  final colorDepth = math.max(2, (parameters['color_depth'] ?? 8.0).round());
  final intensity = parameters['intensity'] ?? 1.0;
  final output = img.Image(width: source.width, height: source.height);

  for (var tileY = 0; tileY < source.height; tileY += tileSize) {
    for (var tileX = 0; tileX < source.width; tileX += tileSize) {
      final maxX = math.min(tileX + tileSize, source.width);
      final maxY = math.min(tileY + tileSize, source.height);
      var sumR = 0.0;
      var sumG = 0.0;
      var sumB = 0.0;
      var count = 0;

      for (var y = tileY; y < maxY; y++) {
        for (var x = tileX; x < maxX; x++) {
          final pixel = source.getPixel(x, y);
          sumR += pixel.r;
          sumG += pixel.g;
          sumB += pixel.b;
          count++;
        }
      }

      final tileR = _quantize(sumR / count, colorDepth);
      final tileG = _quantize(sumG / count, colorDepth);
      final tileB = _quantize(sumB / count, colorDepth);

      for (var y = tileY; y < maxY; y++) {
        for (var x = tileX; x < maxX; x++) {
          final original = source.getPixel(x, y);
          output.setPixelRgb(
            x,
            y,
            _clamp255(_mix(original.r, tileR, intensity)),
            _clamp255(_mix(original.g, tileG, intensity)),
            _clamp255(_mix(original.b, tileB, intensity)),
          );
        }
      }
    }
  }

  return output;
}

img.Image _starryOil(img.Image source, Map<String, double> parameters) {
  final intensity = parameters['intensity'] ?? 1.0;
  final brushDetail = parameters['brush_detail'] ?? 0.7;
  final colorBoost = parameters['color_boost'] ?? 1.4;
  final boosted = img.adjustColor(
    img.Image.from(source),
    saturation: colorBoost,
    contrast: 1.08 + intensity * 0.22,
    brightness: 1.02,
  );
  final posterized = _posterize(boosted, 9);
  final output = img.Image.from(posterized);

  for (var y = 0; y < output.height; y++) {
    for (var x = 0; x < output.width; x++) {
      final pixel = posterized.getPixel(x, y);
      final edge = _edgeAmount(boosted, x, y);
      final flow =
          math.sin((x + y * 0.65) / 18.0) * 0.5 +
          math.cos((x * 0.55 - y) / 24.0) * 0.5;
      final texture = flow * brushDetail * intensity * 24.0;
      final edgeBoost = edge * brushDetail * intensity * 0.42;

      output.setPixelRgb(
        x,
        y,
        _clamp255(pixel.r + texture + edgeBoost),
        _clamp255(pixel.g + texture * 0.55 + edgeBoost * 0.45),
        _clamp255(pixel.b + texture * 1.15 + edgeBoost),
      );
    }
  }

  return _blendImages(source, output, intensity);
}

img.Image _graphicPoster(img.Image source, Map<String, double> parameters) {
  final levels = math.max(2, (parameters['levels'] ?? 5.0).round());
  final contrast = parameters['contrast'] ?? 1.35;
  final edgeDetail = parameters['edge_detail'] ?? 0.45;
  final adjusted = img.adjustColor(
    img.Image.from(source),
    saturation: 1.18,
    contrast: contrast,
    brightness: 1.01,
  );
  final posterized = _posterize(adjusted, levels);
  final output = img.Image.from(posterized);

  for (var y = 0; y < output.height; y++) {
    for (var x = 0; x < output.width; x++) {
      final pixel = posterized.getPixel(x, y);
      final edge = _edgeAmount(adjusted, x, y);
      final edgeMask = edge > 22 ? edgeDetail : edgeDetail * 0.25;
      output.setPixelRgb(
        x,
        y,
        _clamp255(pixel.r - edge * edgeMask),
        _clamp255(pixel.g - edge * edgeMask),
        _clamp255(pixel.b - edge * edgeMask),
      );
    }
  }

  return output;
}

img.Image _posterize(img.Image source, int levels) {
  final output = img.Image(width: source.width, height: source.height);
  final clampedLevels = math.max(2, levels);

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      output.setPixelRgb(
        x,
        y,
        _quantize(pixel.r, clampedLevels),
        _quantize(pixel.g, clampedLevels),
        _quantize(pixel.b, clampedLevels),
      );
    }
  }

  return output;
}

img.Image _blendImages(img.Image base, img.Image effect, double amount) {
  final output = img.Image(width: base.width, height: base.height);
  final clampedAmount = amount.clamp(0.0, 1.0).toDouble();

  for (var y = 0; y < base.height; y++) {
    for (var x = 0; x < base.width; x++) {
      final basePixel = base.getPixel(x, y);
      final effectPixel = effect.getPixel(x, y);
      output.setPixelRgb(
        x,
        y,
        _clamp255(_mix(basePixel.r, effectPixel.r, clampedAmount)),
        _clamp255(_mix(basePixel.g, effectPixel.g, clampedAmount)),
        _clamp255(_mix(basePixel.b, effectPixel.b, clampedAmount)),
      );
    }
  }

  return output;
}

double _edgeAmount(img.Image source, int x, int y) {
  final center = _luminance(source.getPixel(x, y));
  final right = _luminance(source.getPixelClamped(x + 1, y));
  final down = _luminance(source.getPixelClamped(x, y + 1));
  return ((center - right).abs() + (center - down).abs()).clamp(0.0, 255.0);
}

double _luminance(img.Pixel pixel) {
  return pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
}

int _quantize(num value, int levels) {
  final step = 255.0 / (levels - 1);
  return _clamp255((value / step).round() * step);
}

double _mix(num a, num b, double amount) {
  return a + (b - a) * amount.clamp(0.0, 1.0);
}

double _screen(num a, num b) {
  final clampedA = a.clamp(0, 255);
  final clampedB = b.clamp(0, 255);
  return 255 - ((255 - clampedA) * (255 - clampedB) / 255);
}

int _clamp255(num value) => value.clamp(0, 255).round();
