import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('sampleNearest', () {
    group('single band (grayscale)', () {
      test('samples center pixel of uint8 data', () {
        // 3x3 grid, center pixel = 128
        final band = Uint8List.fromList([
          0, 0, 0, //
          0, 128, 0, //
          0, 0, 0, //
        ]);

        final result = sampleNearest(
          1.0, 1.0, [band], TypedArrayType.uint8, 3, 3, 0, 0,
        );

        expect(result, isNotNull);
        expect(result, (128, 128, 128, 255));
      });

      test('returns null when x is out of bounds (left)', () {
        final band = Uint8List.fromList([100, 200]);
        final result = sampleNearest(
          -1.0, 0.0, [band], TypedArrayType.uint8, 2, 1, 0, 0,
        );
        expect(result, isNull);
      });

      test('returns null when x is out of bounds (right)', () {
        final band = Uint8List.fromList([100, 200]);
        final result = sampleNearest(
          2.0, 0.0, [band], TypedArrayType.uint8, 2, 1, 0, 0,
        );
        expect(result, isNull);
      });

      test('returns null when y is out of bounds (top)', () {
        final band = Uint8List.fromList([100, 200]);
        final result = sampleNearest(
          0.0, -1.0, [band], TypedArrayType.uint8, 1, 2, 0, 0,
        );
        expect(result, isNull);
      });

      test('returns null when y is out of bounds (bottom)', () {
        final band = Uint8List.fromList([100, 200]);
        final result = sampleNearest(
          0.0, 2.0, [band], TypedArrayType.uint8, 1, 2, 0, 0,
        );
        expect(result, isNull);
      });

      test('respects offset', () {
        // Band covers pixels at offset (10, 20) with 2x2 window
        final band = Uint8List.fromList([50, 60, 70, 80]);

        // Access pixel at global (10, 20) -> local (0, 0) -> value 50
        final result = sampleNearest(
          10.0, 20.0, [band], TypedArrayType.uint8, 2, 2, 10, 20,
        );
        expect(result, (50, 50, 50, 255));

        // Access pixel at global (11, 21) -> local (1, 1) -> value 80
        final result2 = sampleNearest(
          11.0, 21.0, [band], TypedArrayType.uint8, 2, 2, 10, 20,
        );
        expect(result2, (80, 80, 80, 255));
      });

      test('handles uint16 data', () {
        final band = Uint16List.fromList([32768]); // midpoint
        final result = sampleNearest(
          0.0, 0.0, [band], TypedArrayType.uint16, 1, 1, 0, 0,
        );
        expect(result, isNotNull);
        final (r, g, b, a) = result!;
        expect(r, closeTo(128, 1));
        expect(g, closeTo(128, 1));
        expect(b, closeTo(128, 1));
        expect(a, 255);
      });

      test('handles float32 data', () {
        final band = Float32List.fromList([0.5]);
        final result = sampleNearest(
          0.0, 0.0, [band], TypedArrayType.float32, 1, 1, 0, 0,
        );
        expect(result, isNotNull);
        final (r, _, _, _) = result!;
        expect(r, closeTo(128, 1));
      });

      test('applies colormap when provided', () {
        // Grayscale colormap with value 0.5 should give mid-gray
        final band = Float32List.fromList([0.5]);
        final colorStops = getColorStops(ColorMapName.grayscale);

        final result = sampleNearest(
          0.0, 0.0, [band], TypedArrayType.float32, 1, 1, 0, 0,
          colorStops: colorStops,
        );
        expect(result, isNotNull);
        final (r, g, b, a) = result!;
        expect(r, closeTo(128, 1));
        expect(g, closeTo(128, 1));
        expect(b, closeTo(128, 1));
        expect(a, 255);
      });

      test('applies viridis colormap', () {
        final band = Float32List.fromList([0.0]);
        final colorStops = getColorStops(ColorMapName.viridis);

        final result = sampleNearest(
          0.0, 0.0, [band], TypedArrayType.float32, 1, 1, 0, 0,
          colorStops: colorStops,
        );
        expect(result, isNotNull);
        final (r, g, b, _) = result!;
        // viridis at 0.0 = (68, 1, 84)
        expect(r, 68);
        expect(g, 1);
        expect(b, 84);
      });

      test('rounds coordinate to nearest pixel', () {
        final band = Uint8List.fromList([10, 20, 30]);
        // 0.4 rounds to 0, 0.6 rounds to 1
        final r1 = sampleNearest(
          0.4, 0.0, [band], TypedArrayType.uint8, 3, 1, 0, 0,
        );
        expect(r1, (10, 10, 10, 255));

        final r2 = sampleNearest(
          0.6, 0.0, [band], TypedArrayType.uint8, 3, 1, 0, 0,
        );
        expect(r2, (20, 20, 20, 255));
      });
    });

    group('3 bands (RGB)', () {
      test('samples RGB correctly', () {
        // 1x1 pixel with RGB values
        final r = Uint8List.fromList([200]);
        final g = Uint8List.fromList([100]);
        final b = Uint8List.fromList([50]);

        final result = sampleNearest(
          0.0, 0.0, [r, g, b], TypedArrayType.uint8, 1, 1, 0, 0,
        );
        expect(result, (200, 100, 50, 255));
      });

      test('normalizes uint16 RGB data', () {
        final r = Uint16List.fromList([65535]);
        final g = Uint16List.fromList([32768]);
        final b = Uint16List.fromList([0]);

        final result = sampleNearest(
          0.0, 0.0, [r, g, b], TypedArrayType.uint16, 1, 1, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, 255);
        expect(result.$2, closeTo(128, 1));
        expect(result.$3, 0);
        expect(result.$4, 255);
      });
    });

    group('4 bands (RGBA)', () {
      test('samples RGBA correctly', () {
        final r = Uint8List.fromList([200]);
        final g = Uint8List.fromList([100]);
        final b = Uint8List.fromList([50]);
        final a = Uint8List.fromList([128]);

        final result = sampleNearest(
          0.0, 0.0, [r, g, b, a], TypedArrayType.uint8, 1, 1, 0, 0,
        );
        expect(result, (200, 100, 50, 128));
      });

      test('handles 5+ bands (uses first 4)', () {
        final bands = List.generate(
          5,
          (i) => Uint8List.fromList([i * 50]),
        );

        final result = sampleNearest(
          0.0, 0.0, bands, TypedArrayType.uint8, 1, 1, 0, 0,
        );
        expect(result, isNotNull);
        expect(result, (0, 50, 100, 150));
      });
    });

    group('2 bands', () {
      test('returns null for unsupported 2-band data', () {
        final b1 = Uint8List.fromList([100]);
        final b2 = Uint8List.fromList([200]);

        final result = sampleNearest(
          0.0, 0.0, [b1, b2], TypedArrayType.uint8, 1, 1, 0, 0,
        );
        expect(result, isNull);
      });
    });

    group('boundary values', () {
      test('pixel at (0, 0) with zero offset', () {
        final band = Uint8List.fromList([42]);
        final result = sampleNearest(
          0.0, 0.0, [band], TypedArrayType.uint8, 1, 1, 0, 0,
        );
        expect(result, (42, 42, 42, 255));
      });

      test('pixel at max index', () {
        final band = Uint8List.fromList([10, 20, 30, 40, 50, 60]);
        // 3x2 grid, pixel (2, 1) -> index 5 -> value 60
        final result = sampleNearest(
          2.0, 1.0, [band], TypedArrayType.uint8, 3, 2, 0, 0,
        );
        expect(result, (60, 60, 60, 255));
      });
    });
  });

  group('sampleBilinear', () {
    group('single band (grayscale)', () {
      test('returns exact value at integer coordinates', () {
        // 2x2 grid: uniform value 100
        final band = Uint8List.fromList([100, 100, 100, 100]);

        final result = sampleBilinear(
          0.0, 0.0, [band], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, 100);
      });

      test('interpolates between 4 pixels', () {
        // 2x2 grid:
        // 0   100
        // 0   100
        final band = Uint8List.fromList([0, 100, 0, 100]);

        final result = sampleBilinear(
          0.5, 0.5, [band], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        // Interpolated value should be average: 50
        expect(result!.$1, closeTo(50, 1));
      });

      test('returns null when out of bounds (left)', () {
        final band = Uint8List.fromList([1, 2, 3, 4]);
        final result = sampleBilinear(
          -0.5, 0.0, [band], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNull);
      });

      test('returns null when out of bounds (right edge)', () {
        final band = Uint8List.fromList([1, 2, 3, 4]);
        // At x=1 (width-1), out of bilinear bounds
        final result = sampleBilinear(
          1.0, 0.0, [band], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNull);
      });

      test('returns null when out of bounds (bottom edge)', () {
        final band = Uint8List.fromList([1, 2, 3, 4]);
        final result = sampleBilinear(
          0.0, 1.0, [band], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNull);
      });

      test('respects offset', () {
        final band = Uint8List.fromList([10, 20, 30, 40]);
        // Global (10.0, 20.0) -> local (0.0, 0.0) -> top-left pixel
        final result = sampleBilinear(
          10.0, 20.0, [band], TypedArrayType.uint8, 2, 2, 10, 20,
        );
        expect(result, isNotNull);
        expect(result!.$1, 10);
      });

      test('applies colormap', () {
        // 3x3 grid with center value 0.5
        final band = Float32List.fromList([
          0.5, 0.5, 0.5, //
          0.5, 0.5, 0.5, //
          0.5, 0.5, 0.5, //
        ]);
        final colorStops = getColorStops(ColorMapName.grayscale);

        final result = sampleBilinear(
          1.0, 1.0, [band], TypedArrayType.float32, 3, 3, 0, 0,
          colorStops: colorStops,
        );
        expect(result, isNotNull);
        final (r, g, b, a) = result!;
        expect(r, closeTo(128, 1));
        expect(g, closeTo(128, 1));
        expect(b, closeTo(128, 1));
        expect(a, 255);
      });

      test('grayscale interpolation without colormap', () {
        // 3x3 grid with gradient
        final band = Float32List.fromList([
          0.0, 0.5, 1.0, //
          0.0, 0.5, 1.0, //
          0.0, 0.5, 1.0, //
        ]);

        final result = sampleBilinear(
          0.5, 0.5, [band], TypedArrayType.float32, 3, 3, 0, 0,
        );
        expect(result, isNotNull);
        // Between 0.0 and 0.5 -> 0.25 -> normalizeValue(0.25, float32) -> ~64
        expect(result!.$1, closeTo(64, 1));
      });
    });

    group('multi-band', () {
      test('interpolates RGB bands independently', () {
        // 2x2 grid per band
        final r = Uint8List.fromList([0, 200, 0, 200]);
        final g = Uint8List.fromList([100, 100, 100, 100]);
        final b = Uint8List.fromList([50, 50, 50, 50]);

        final result = sampleBilinear(
          0.5, 0.5, [r, g, b], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, closeTo(100, 1)); // average of 0 and 200
        expect(result.$2, closeTo(100, 1)); // uniform 100
        expect(result.$3, closeTo(50, 1)); // uniform 50
        expect(result.$4, 255); // alpha = 255 for 3-band
      });

      test('interpolates RGBA bands independently', () {
        final r = Uint8List.fromList([255, 255, 255, 255]);
        final g = Uint8List.fromList([0, 0, 0, 0]);
        final b = Uint8List.fromList([128, 128, 128, 128]);
        final a = Uint8List.fromList([200, 200, 200, 200]);

        final result = sampleBilinear(
          0.5, 0.5, [r, g, b, a], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, 255);
        expect(result.$2, 0);
        expect(result.$3, 128);
        expect(result.$4, 200);
      });

      test('handles 5+ bands (uses first 4)', () {
        final bands = List.generate(
          5,
          (_) => Uint8List.fromList([100, 100, 100, 100]),
        );

        final result = sampleBilinear(
          0.5, 0.5, bands, TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, 100);
        expect(result.$2, 100);
        expect(result.$3, 100);
        expect(result.$4, 100);
      });
    });

    group('interpolation correctness', () {
      test('linear gradient horizontally', () {
        // 3x1 row (need at least 2 rows for bilinear)
        // Use 3x2 with same row pattern
        final band = Uint8List.fromList([
          0, 128, 255, //
          0, 128, 255, //
        ]);

        // At x=0.5, between 0 and 128 -> 64
        final r1 = sampleBilinear(
          0.5, 0.0, [band], TypedArrayType.uint8, 3, 2, 0, 0,
        );
        expect(r1, isNotNull);
        expect(r1!.$1, closeTo(64, 1));

        // At x=1.5, between 128 and 255 -> ~192
        final r2 = sampleBilinear(
          1.5, 0.0, [band], TypedArrayType.uint8, 3, 2, 0, 0,
        );
        expect(r2, isNotNull);
        expect(r2!.$1, closeTo(192, 2));
      });

      test('linear gradient vertically', () {
        final band = Uint8List.fromList([
          0, 0, //
          255, 255, //
          255, 255, //
        ]);

        // At y=0.5, between row 0 (0) and row 1 (255) -> ~128
        final result = sampleBilinear(
          0.0, 0.5, [band], TypedArrayType.uint8, 2, 3, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, closeTo(128, 1));
      });

      test('bilinear at corner returns exact value', () {
        final band = Uint8List.fromList([
          10, 20, //
          30, 40, //
        ]);

        // At (0.0, 0.0) -> exact top-left value
        final result = sampleBilinear(
          0.0, 0.0, [band], TypedArrayType.uint8, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        expect(result!.$1, 10);
      });
    });

    group('uint16 bilinear', () {
      test('interpolates uint16 data', () {
        final band = Uint16List.fromList([0, 65535, 0, 65535]);

        final result = sampleBilinear(
          0.5, 0.5, [band], TypedArrayType.uint16, 2, 2, 0, 0,
        );
        expect(result, isNotNull);
        // midpoint of 0 and 65535 = 32768 -> normalized to ~128
        expect(result!.$1, closeTo(128, 1));
      });
    });
  });
}
