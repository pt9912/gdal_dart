import 'dart:typed_data';

import 'colormap_utils.dart';
import 'normalization_utils.dart';

/// A band of raster data stored as a flat list of numbers.
///
/// For typed access use the underlying typed list (e.g. [Float32List]).
typedef SampleBand = List<num>;

/// Nearest-neighbor sampling with window-based reading and multi-band support.
///
/// Returns RGBA values (0–255) or `null` if outside bounds.
(int, int, int, int)? sampleNearest(
  double x,
  double y,
  List<SampleBand> rasterBands,
  TypedArrayType arrayType,
  int width,
  int height,
  int offsetX,
  int offsetY, {
  List<ColorStop>? colorStops,
}) {
  final px = x.round() - offsetX;
  final py = y.round() - offsetY;
  if (px < 0 || px >= width || py < 0 || py >= height) return null;

  final idx = py * width + px;
  final bandCount = rasterBands.length;

  if (bandCount == 1) {
    final rawValue = rasterBands[0][idx].toDouble();
    if (colorStops != null) {
      final normalized = normalizeToColorMapRange(rawValue);
      final (r, g, b) = applyColorMap(normalized, colorStops);
      return (r, g, b, 255);
    } else {
      final gray = normalizeValue(rawValue, arrayType);
      return (gray, gray, gray, 255);
    }
  } else if (bandCount == 3) {
    final r = normalizeValue(rasterBands[0][idx].toDouble(), arrayType);
    final g = normalizeValue(rasterBands[1][idx].toDouble(), arrayType);
    final b = normalizeValue(rasterBands[2][idx].toDouble(), arrayType);
    return (r, g, b, 255);
  } else if (bandCount >= 4) {
    final r = normalizeValue(rasterBands[0][idx].toDouble(), arrayType);
    final g = normalizeValue(rasterBands[1][idx].toDouble(), arrayType);
    final b = normalizeValue(rasterBands[2][idx].toDouble(), arrayType);
    final a = normalizeValue(rasterBands[3][idx].toDouble(), arrayType);
    return (r, g, b, a);
  }

  return null;
}

/// Bilinear interpolation with window-based reading and multi-band support.
///
/// Returns RGBA values (0–255) or `null` if outside bounds.
(int, int, int, int)? sampleBilinear(
  double x,
  double y,
  List<SampleBand> rasterBands,
  TypedArrayType arrayType,
  int width,
  int height,
  int offsetX,
  int offsetY, {
  List<ColorStop>? colorStops,
}) {
  final localX = x - offsetX;
  final localY = y - offsetY;
  if (localX < 0 || localX >= width - 1 || localY < 0 || localY >= height - 1) {
    return null;
  }

  final x0 = localX.floor();
  final x1 = localX.ceil();
  final y0 = localY.floor();
  final y1 = localY.ceil();
  final fx = localX - x0;
  final fy = localY - y0;

  final bandCount = rasterBands.length;

  if (bandCount == 1) {
    final band = rasterBands[0];
    final v00 = band[y0 * width + x0].toDouble();
    final v10 = band[y0 * width + x1].toDouble();
    final v01 = band[y1 * width + x0].toDouble();
    final v11 = band[y1 * width + x1].toDouble();

    final v0 = v00 * (1 - fx) + v10 * fx;
    final v1 = v01 * (1 - fx) + v11 * fx;
    final interpolated = v0 * (1 - fy) + v1 * fy;

    if (colorStops != null) {
      final normalized = normalizeToColorMapRange(interpolated);
      final (r, g, b) = applyColorMap(normalized, colorStops);
      return (r, g, b, 255);
    } else {
      final gray = normalizeValue(interpolated, arrayType);
      return (gray, gray, gray, 255);
    }
  } else {
    final bandsToProcess = bandCount < 4 ? bandCount : 4;
    final result = [0, 0, 0, 255];

    for (var bi = 0; bi < bandsToProcess; bi++) {
      final band = rasterBands[bi];
      final v00 = band[y0 * width + x0].toDouble();
      final v10 = band[y0 * width + x1].toDouble();
      final v01 = band[y1 * width + x0].toDouble();
      final v11 = band[y1 * width + x1].toDouble();

      final v0 = v00 * (1 - fx) + v10 * fx;
      final v1 = v01 * (1 - fx) + v11 * fx;
      final interpolated = v0 * (1 - fy) + v1 * fy;

      result[bi] = normalizeValue(interpolated, arrayType);
    }

    return (result[0], result[1], result[2], result[3]);
  }
}
