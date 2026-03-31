import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/processing/triangle.dart';
import 'package:test/test.dart';

void main() {
  group('Triangle typedef', () {
    test('can create a Triangle with three coordinate pairs', () {
      const Triangle t = ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0));
      expect(t.$1, (0.0, 0.0));
      expect(t.$2, (1.0, 0.0));
      expect(t.$3, (0.0, 1.0));
    });

    test('supports negative coordinates', () {
      const Triangle t = ((-1.0, -2.0), (3.0, -4.0), (5.0, 6.0));
      expect(t.$1.$1, -1.0);
      expect(t.$1.$2, -2.0);
    });
  });

  group('ITriangle', () {
    test('stores source and target triangles', () {
      const source = ((0.0, 0.0), (10.0, 0.0), (0.0, 10.0));
      const target = ((100.0, 100.0), (200.0, 100.0), (100.0, 200.0));
      final itri = ITriangle(source: source, target: target);

      expect(itri.source, source);
      expect(itri.target, target);
    });

    test('can be constructed as const', () {
      const itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
      );
      expect(itri.source.$1, (0.0, 0.0));
      expect(itri.target.$3, (0.0, 1.0));
    });

    test('source and target can differ', () {
      final itri = ITriangle(
        source: ((0.0, 0.0), (5.0, 0.0), (0.0, 5.0)),
        target: ((10.0, 10.0), (15.0, 10.0), (10.0, 15.0)),
      );
      expect(itri.source.$1, isNot(equals(itri.target.$1)));
    });

    test('handles zero-area (degenerate) triangles', () {
      const itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (2.0, 0.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (2.0, 0.0)),
      );
      // All points are collinear - degenerate but valid data structure
      expect(itri.source.$1.$2, 0.0);
      expect(itri.source.$2.$2, 0.0);
      expect(itri.source.$3.$2, 0.0);
    });

    test('handles very large coordinates', () {
      final itri = ITriangle(
        source: ((1e15, 1e15), (1e15 + 1, 1e15), (1e15, 1e15 + 1)),
        target: ((-1e15, -1e15), (-1e15 + 1, -1e15), (-1e15, -1e15 + 1)),
      );
      expect(itri.source.$1.$1, 1e15);
      expect(itri.target.$1.$1, -1e15);
    });
  });
}
