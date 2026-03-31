import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TypedArrayType enum', () {
    test('has all expected values', () {
      expect(TypedArrayType.values, hasLength(7));
      expect(TypedArrayType.values, contains(TypedArrayType.uint8));
      expect(TypedArrayType.values, contains(TypedArrayType.uint16));
      expect(TypedArrayType.values, contains(TypedArrayType.int16));
      expect(TypedArrayType.values, contains(TypedArrayType.uint32));
      expect(TypedArrayType.values, contains(TypedArrayType.int32));
      expect(TypedArrayType.values, contains(TypedArrayType.float32));
      expect(TypedArrayType.values, contains(TypedArrayType.float64));
    });
  });

  group('normalizeValue', () {
    group('uint8', () {
      test('passes through 0', () {
        expect(normalizeValue(0, TypedArrayType.uint8), 0);
      });

      test('passes through 255', () {
        expect(normalizeValue(255, TypedArrayType.uint8), 255);
      });

      test('passes through middle value', () {
        expect(normalizeValue(128, TypedArrayType.uint8), 128);
      });

      test('clamps negative to 0', () {
        expect(normalizeValue(-10, TypedArrayType.uint8), 0);
      });

      test('clamps above 255', () {
        expect(normalizeValue(300, TypedArrayType.uint8), 255);
      });

      test('rounds fractional values', () {
        expect(normalizeValue(127.4, TypedArrayType.uint8), 127);
        expect(normalizeValue(127.6, TypedArrayType.uint8), 128);
      });
    });

    group('uint16', () {
      test('maps 0 to 0', () {
        expect(normalizeValue(0, TypedArrayType.uint16), 0);
      });

      test('maps 65535 to 255', () {
        expect(normalizeValue(65535, TypedArrayType.uint16), 255);
      });

      test('maps midpoint to ~128', () {
        final result = normalizeValue(32768, TypedArrayType.uint16);
        expect(result, closeTo(128, 1));
      });

      test('clamps negative to 0', () {
        expect(normalizeValue(-100, TypedArrayType.uint16), 0);
      });
    });

    group('int16', () {
      test('maps -32768 to 0', () {
        expect(normalizeValue(-32768, TypedArrayType.int16), 0);
      });

      test('maps 32767 to 255', () {
        expect(normalizeValue(32767, TypedArrayType.int16), 255);
      });

      test('maps 0 to ~128', () {
        final result = normalizeValue(0, TypedArrayType.int16);
        expect(result, closeTo(128, 1));
      });
    });

    group('uint32', () {
      test('maps 0 to 0', () {
        expect(normalizeValue(0, TypedArrayType.uint32), 0);
      });

      test('maps 4294967295 to 255', () {
        expect(normalizeValue(4294967295, TypedArrayType.uint32), 255);
      });

      test('maps midpoint to ~128', () {
        final result = normalizeValue(2147483648, TypedArrayType.uint32);
        expect(result, closeTo(128, 1));
      });
    });

    group('int32', () {
      test('maps -2147483648 to 0', () {
        expect(normalizeValue(-2147483648, TypedArrayType.int32), 0);
      });

      test('maps 2147483647 to 255', () {
        expect(normalizeValue(2147483647, TypedArrayType.int32), 255);
      });

      test('maps 0 to ~128', () {
        final result = normalizeValue(0, TypedArrayType.int32);
        expect(result, closeTo(128, 1));
      });
    });

    group('float32', () {
      test('maps 0.0 to 0', () {
        expect(normalizeValue(0.0, TypedArrayType.float32), 0);
      });

      test('maps 1.0 to 255', () {
        expect(normalizeValue(1.0, TypedArrayType.float32), 255);
      });

      test('maps 0.5 to ~128', () {
        final result = normalizeValue(0.5, TypedArrayType.float32);
        expect(result, closeTo(128, 1));
      });

      test('clamps negative to 0', () {
        expect(normalizeValue(-0.5, TypedArrayType.float32), 0);
      });

      test('clamps above 1 to 255', () {
        expect(normalizeValue(2.0, TypedArrayType.float32), 255);
      });
    });

    group('float64', () {
      test('maps 0.0 to 0', () {
        expect(normalizeValue(0.0, TypedArrayType.float64), 0);
      });

      test('maps 1.0 to 255', () {
        expect(normalizeValue(1.0, TypedArrayType.float64), 255);
      });

      test('maps 0.5 to ~128', () {
        final result = normalizeValue(0.5, TypedArrayType.float64);
        expect(result, closeTo(128, 1));
      });

      test('clamps negative', () {
        expect(normalizeValue(-1.0, TypedArrayType.float64), 0);
      });

      test('clamps above 1', () {
        expect(normalizeValue(5.0, TypedArrayType.float64), 255);
      });
    });
  });

  group('normalizeToColorMapRange', () {
    test('clamps to [0, 1] when no valueRange', () {
      expect(normalizeToColorMapRange(0.5), 0.5);
      expect(normalizeToColorMapRange(-0.5), 0.0);
      expect(normalizeToColorMapRange(1.5), 1.0);
      expect(normalizeToColorMapRange(0.0), 0.0);
      expect(normalizeToColorMapRange(1.0), 1.0);
    });

    test('maps value within range to [0, 1]', () {
      expect(
        normalizeToColorMapRange(50.0, valueRange: (0.0, 100.0)),
        closeTo(0.5, 1e-10),
      );
    });

    test('maps min value to 0', () {
      expect(
        normalizeToColorMapRange(10.0, valueRange: (10.0, 20.0)),
        closeTo(0.0, 1e-10),
      );
    });

    test('maps max value to 1', () {
      expect(
        normalizeToColorMapRange(20.0, valueRange: (10.0, 20.0)),
        closeTo(1.0, 1e-10),
      );
    });

    test('clamps below min to 0', () {
      expect(
        normalizeToColorMapRange(-10.0, valueRange: (0.0, 100.0)),
        0.0,
      );
    });

    test('clamps above max to 1', () {
      expect(
        normalizeToColorMapRange(200.0, valueRange: (0.0, 100.0)),
        1.0,
      );
    });

    test('returns 0.5 when min == max', () {
      expect(normalizeToColorMapRange(5.0, valueRange: (5.0, 5.0)), 0.5);
    });

    test('handles negative ranges', () {
      expect(
        normalizeToColorMapRange(-50.0, valueRange: (-100.0, 0.0)),
        closeTo(0.5, 1e-10),
      );
    });
  });

  group('autoDetectValueRange', () {
    test('returns (0, 1) for empty data', () {
      final result = autoDetectValueRange([]);
      expect(result, (0.0, 1.0));
    });

    test('detects range of simple data', () {
      final data = Float32List.fromList([1.0, 5.0, 3.0, 2.0, 4.0]);
      final result = autoDetectValueRange(data);
      expect(result.$1, 1.0);
      expect(result.$2, 5.0);
    });

    test('handles single element', () {
      final data = Float32List.fromList([42.0]);
      final result = autoDetectValueRange(data);
      // min == max, should return (min, min + 1)
      expect(result, (42.0, 43.0));
    });

    test('ignores non-finite values', () {
      final data = Float64List.fromList([
        double.nan,
        1.0,
        double.infinity,
        5.0,
        double.negativeInfinity,
        3.0,
      ]);
      final result = autoDetectValueRange(data);
      expect(result.$1, 1.0);
      expect(result.$2, 5.0);
    });

    test('returns (0, 1) when all values are non-finite', () {
      final data = Float64List.fromList([
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]);
      final result = autoDetectValueRange(data);
      expect(result, (0.0, 1.0));
    });

    test('handles negative values', () {
      final data = Float64List.fromList([-10.0, -5.0, -1.0]);
      final result = autoDetectValueRange(data);
      expect(result.$1, -10.0);
      expect(result.$2, -1.0);
    });

    test('uses sampling for large data', () {
      // Large dataset with known min/max at sampled positions
      final data = Float64List(10000);
      for (var i = 0; i < data.length; i++) {
        data[i] = 50.0; // fill with middle value
      }
      data[0] = 0.0; // min at start
      data[data.length - 1] = 100.0; // max near end (may be missed by sampling)

      final result = autoDetectValueRange(data, sampleSize: 100);
      // Should find the min at index 0
      expect(result.$1, lessThanOrEqualTo(50.0));
    });

    test('respects custom sampleSize', () {
      final data = Float64List.fromList([1.0, 2.0, 3.0, 4.0, 5.0]);
      // With sampleSize much larger than data, step should be 1
      final result = autoDetectValueRange(data, sampleSize: 10000);
      expect(result.$1, 1.0);
      expect(result.$2, 5.0);
    });

    test('handles all same values', () {
      final data = Float64List.fromList([7.0, 7.0, 7.0, 7.0]);
      final result = autoDetectValueRange(data);
      expect(result, (7.0, 8.0));
    });
  });

  group('isFloatType', () {
    test('returns true for float32', () {
      expect(isFloatType(TypedArrayType.float32), isTrue);
    });

    test('returns true for float64', () {
      expect(isFloatType(TypedArrayType.float64), isTrue);
    });

    test('returns false for uint8', () {
      expect(isFloatType(TypedArrayType.uint8), isFalse);
    });

    test('returns false for uint16', () {
      expect(isFloatType(TypedArrayType.uint16), isFalse);
    });

    test('returns false for int16', () {
      expect(isFloatType(TypedArrayType.int16), isFalse);
    });

    test('returns false for uint32', () {
      expect(isFloatType(TypedArrayType.uint32), isFalse);
    });

    test('returns false for int32', () {
      expect(isFloatType(TypedArrayType.int32), isFalse);
    });
  });

  group('getTypeRange', () {
    test('uint8 range', () {
      expect(getTypeRange(TypedArrayType.uint8), (0, 255));
    });

    test('uint16 range', () {
      expect(getTypeRange(TypedArrayType.uint16), (0, 65535));
    });

    test('int16 range', () {
      expect(getTypeRange(TypedArrayType.int16), (-32768, 32767));
    });

    test('uint32 range', () {
      expect(getTypeRange(TypedArrayType.uint32), (0, 4294967295));
    });

    test('int32 range', () {
      expect(getTypeRange(TypedArrayType.int32), (-2147483648, 2147483647));
    });

    test('float32 range', () {
      expect(getTypeRange(TypedArrayType.float32), (0, 1));
    });

    test('float64 range', () {
      expect(getTypeRange(TypedArrayType.float64), (0, 1));
    });
  });
}
