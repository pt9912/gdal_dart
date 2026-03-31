import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/processing/aabb2d.dart';
import 'package:gdal_dart/src/processing/triangulation.dart';
import 'package:test/test.dart';

void main() {
  group('Bounds', () {
    test('stores all four coordinates', () {
      const b = Bounds(1, 2, 3, 4);
      expect(b.minX, 1);
      expect(b.minY, 2);
      expect(b.maxX, 3);
      expect(b.maxY, 4);
    });

    test('supports negative coordinates', () {
      const b = Bounds(-10, -20, -5, -1);
      expect(b.minX, -10);
      expect(b.maxY, -1);
    });
  });

  group('TriResult', () {
    test('stores triangle and transform', () {
      const itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
      );
      const transform = AffineTransform(1, 0, 0, 0, 1, 0);
      const result = TriResult(itri, transform);

      expect(result.tri, itri);
      expect(result.transform, transform);
    });

    test('allows null transform', () {
      const itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
      );
      const result = TriResult(itri, null);
      expect(result.transform, isNull);
    });
  });

  group('calculateBounds', () {
    // Identity transform: no coordinate change
    (double, double) identity((double, double) coord) => coord;

    test('computes bounds for identity transform', () {
      final result = calculateBounds(
        null, null,
        (0.0, 0.0, 100.0, 100.0),
        identity,
      );

      expect(result.source.minX, closeTo(0.0, 1e-6));
      expect(result.source.minY, closeTo(0.0, 1e-6));
      expect(result.source.maxX, closeTo(100.0, 1e-6));
      expect(result.source.maxY, closeTo(100.0, 1e-6));
    });

    test('computes bounds with scaling transform', () {
      (double, double) scale2x((double, double) coord) =>
          (coord.$1 * 2, coord.$2 * 2);

      final result = calculateBounds(
        null, null,
        (0.0, 0.0, 10.0, 10.0),
        scale2x,
      );

      expect(result.source.minX, closeTo(0.0, 1e-6));
      expect(result.source.minY, closeTo(0.0, 1e-6));
      expect(result.source.maxX, closeTo(20.0, 1e-6));
      expect(result.source.maxY, closeTo(20.0, 1e-6));
    });

    test('computes bounds with translation transform', () {
      (double, double) translate((double, double) coord) =>
          (coord.$1 + 100, coord.$2 + 200);

      final result = calculateBounds(
        null, null,
        (0.0, 0.0, 10.0, 10.0),
        translate,
      );

      expect(result.source.minX, closeTo(100.0, 1e-6));
      expect(result.source.minY, closeTo(200.0, 1e-6));
      expect(result.source.maxX, closeTo(110.0, 1e-6));
      expect(result.source.maxY, closeTo(210.0, 1e-6));
    });

    test('snaps to source grid when sourceRef and resolution provided', () {
      final result = calculateBounds(
        (0.0, 0.0), 10.0,
        (0.0, 0.0, 100.0, 100.0),
        identity,
      );

      // Values should be multiples of resolution (10.0)
      expect(result.source.minX % 10, closeTo(0.0, 1e-6));
      expect(result.source.minY % 10, closeTo(0.0, 1e-6));
      expect(result.source.maxX % 10, closeTo(0.0, 1e-6));
      expect(result.source.maxY % 10, closeTo(0.0, 1e-6));
    });

    test('snaps to grid correctly for non-aligned reference point', () {
      final result = calculateBounds(
        (5.0, 5.0), 10.0,
        (0.0, 0.0, 100.0, 100.0),
        identity,
      );

      // Should be snapped relative to reference point (5, 5) at resolution 10
      final minXOffset = (result.source.minX - 5.0) % 10.0;
      expect(minXOffset.abs(), closeTo(0.0, 1e-6));
    });

    test('uses custom step for edge sampling', () {
      var callCount = 0;
      (double, double) countingIdentity((double, double) coord) {
        callCount++;
        return coord;
      }

      calculateBounds(
        null, null,
        (0.0, 0.0, 100.0, 100.0),
        countingIdentity,
        step: 5,
      );

      // 4 edges * (5 + 1) = 24 samples
      expect(callCount, 24);
    });

    test('handles negative extent', () {
      final result = calculateBounds(
        null, null,
        (-100.0, -100.0, -50.0, -50.0),
        identity,
      );

      expect(result.source.minX, closeTo(-100.0, 1e-6));
      expect(result.source.maxX, closeTo(-50.0, 1e-6));
    });

    test('target bounds track which target coords produced min/max', () {
      // With identity, the target that produces minX should be west edge
      final result = calculateBounds(
        null, null,
        (10.0, 20.0, 30.0, 40.0),
        identity,
      );

      // target bounds record the target coordinates that produced min/max source
      expect(result.target.minX, closeTo(10.0, 1e-6));
      expect(result.target.maxX, closeTo(30.0, 1e-6));
    });
  });

  group('Triangulation', () {
    // Identity transform: target == source
    (double, double) identity((double, double) coord) => coord;

    test('creates triangles for a simple extent with identity transform', () {
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      expect(t.triangles, isNotEmpty);
      // Identity transform -> no subdivision needed -> exactly 2 triangles
      expect(t.triangles.length, 2);
    });

    test('triangles have valid source and target coordinates', () {
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      for (final tri in t.triangles) {
        // With identity, source and target should be close
        expect(tri.source.$1.$1.isFinite, isTrue);
        expect(tri.source.$1.$2.isFinite, isTrue);
        expect(tri.target.$1.$1.isFinite, isTrue);
        expect(tri.target.$1.$2.isFinite, isTrue);
      }
    });

    test('bounds are set correctly', () {
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      expect(t.bounds.minX, closeTo(0.0, 1e-6));
      expect(t.bounds.minY, closeTo(0.0, 1e-6));
      expect(t.bounds.maxX, closeTo(100.0, 1e-6));
      expect(t.bounds.maxY, closeTo(100.0, 1e-6));
    });

    test('subdivides when transform introduces error', () {
      // Non-linear transform that will cause subdivision
      (double, double) nonLinear((double, double) coord) {
        final (x, y) = coord;
        return (x + x * x * 0.01, y + y * y * 0.01);
      }

      final t = Triangulation(
        nonLinear,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.1,
      );

      // Non-linear transform should produce more triangles due to subdivision
      expect(t.triangles.length, greaterThan(2));
    });

    test('respects sourceRef and resolution for grid alignment', () {
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
        sourceRef: (0.0, 0.0),
        resolution: 10.0,
      );

      // Bounds should be snapped
      expect(t.bounds.minX % 10, closeTo(0.0, 1e-6));
      expect(t.bounds.maxX % 10, closeTo(0.0, 1e-6));
    });

    test('filters out triangles with non-finite source coordinates', () {
      (double, double) sometimesInfinite((double, double) coord) {
        final (x, y) = coord;
        if (x > 90 && y > 90) return (double.infinity, double.infinity);
        return (x, y);
      }

      final t = Triangulation(
        sometimesInfinite,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      // All triangles should have finite coordinates
      for (final tri in t.triangles) {
        expect(tri.source.$1.$1.isFinite, isTrue);
        expect(tri.source.$1.$2.isFinite, isTrue);
        expect(tri.source.$2.$1.isFinite, isTrue);
        expect(tri.source.$2.$2.isFinite, isTrue);
        expect(tri.source.$3.$1.isFinite, isTrue);
        expect(tri.source.$3.$2.isFinite, isTrue);
      }
    });
  });

  group('Triangulation.calculateAffineTransform', () {
    late Triangulation t;

    setUp(() {
      (double, double) identity((double, double) coord) => coord;
      t = Triangulation(identity, (0.0, 0.0, 10.0, 10.0));
    });

    test('identity mapping returns identity-like transform', () {
      const itri = ITriangle(
        source: ((0.0, 0.0), (10.0, 0.0), (0.0, 10.0)),
        target: ((0.0, 0.0), (10.0, 0.0), (0.0, 10.0)),
      );

      final transform = t.calculateAffineTransform(itri);

      // a ~= 1, b ~= 0, c ~= 0 (x transform)
      expect(transform.a, closeTo(1.0, 1e-10));
      expect(transform.b, closeTo(0.0, 1e-10));
      expect(transform.c, closeTo(0.0, 1e-10));
      // d ~= 0, e ~= 1, f ~= 0 (y transform)
      expect(transform.d, closeTo(0.0, 1e-10));
      expect(transform.e, closeTo(1.0, 1e-10));
      expect(transform.f, closeTo(0.0, 1e-10));
    });

    test('scaling mapping: source = 2x target', () {
      const itri = ITriangle(
        source: ((0.0, 0.0), (20.0, 0.0), (0.0, 20.0)),
        target: ((0.0, 0.0), (10.0, 0.0), (0.0, 10.0)),
      );

      final transform = t.calculateAffineTransform(itri);

      // Should scale by 2x
      expect(transform.a, closeTo(2.0, 1e-10));
      expect(transform.e, closeTo(2.0, 1e-10));
    });

    test('translation mapping: source = target + offset', () {
      const itri = ITriangle(
        source: ((100.0, 200.0), (110.0, 200.0), (100.0, 210.0)),
        target: ((0.0, 0.0), (10.0, 0.0), (0.0, 10.0)),
      );

      final transform = t.calculateAffineTransform(itri);

      expect(transform.a, closeTo(1.0, 1e-10));
      expect(transform.c, closeTo(100.0, 1e-10));
      expect(transform.e, closeTo(1.0, 1e-10));
      expect(transform.f, closeTo(200.0, 1e-10));
    });

    test('degenerate triangle returns fallback transform', () {
      // All collinear target points -> determinant near zero
      const itri = ITriangle(
        source: ((0.0, 0.0), (10.0, 0.0), (20.0, 0.0)),
        target: ((0.0, 0.0), (10.0, 0.0), (20.0, 0.0)),
      );

      final transform = t.calculateAffineTransform(itri);

      // Fallback: identity with translation to first source point
      expect(transform.a, 1.0);
      expect(transform.b, 0.0);
      expect(transform.c, 0.0); // x0s
      expect(transform.d, 0.0);
      expect(transform.e, 1.0);
      expect(transform.f, 0.0); // y0s
    });
  });

  group('Triangulation.applyAffineTransform', () {
    late Triangulation t;

    setUp(() {
      (double, double) identity((double, double) coord) => coord;
      t = Triangulation(identity, (0.0, 0.0, 10.0, 10.0));
    });

    test('identity transform returns same point', () {
      const transform = AffineTransform(1, 0, 0, 0, 1, 0);
      final (rx, ry) = t.applyAffineTransform(5.0, 7.0, transform);
      expect(rx, closeTo(5.0, 1e-10));
      expect(ry, closeTo(7.0, 1e-10));
    });

    test('scaling transform doubles coordinates', () {
      const transform = AffineTransform(2, 0, 0, 0, 2, 0);
      final (rx, ry) = t.applyAffineTransform(3.0, 4.0, transform);
      expect(rx, closeTo(6.0, 1e-10));
      expect(ry, closeTo(8.0, 1e-10));
    });

    test('translation transform adds offset', () {
      const transform = AffineTransform(1, 0, 10, 0, 1, 20);
      final (rx, ry) = t.applyAffineTransform(5.0, 7.0, transform);
      expect(rx, closeTo(15.0, 1e-10));
      expect(ry, closeTo(27.0, 1e-10));
    });

    test('full affine: ax + by + c, dx + ey + f', () {
      const transform = AffineTransform(2, 3, 1, 4, 5, 2);
      final (rx, ry) = t.applyAffineTransform(1.0, 1.0, transform);
      // rx = 2*1 + 3*1 + 1 = 6
      // ry = 4*1 + 5*1 + 2 = 11
      expect(rx, closeTo(6.0, 1e-10));
      expect(ry, closeTo(11.0, 1e-10));
    });

    test('transform at origin', () {
      const transform = AffineTransform(2, 3, 10, 4, 5, 20);
      final (rx, ry) = t.applyAffineTransform(0.0, 0.0, transform);
      expect(rx, closeTo(10.0, 1e-10));
      expect(ry, closeTo(20.0, 1e-10));
    });
  });

  group('Triangulation.findSourceTriangleForTargetPoint', () {
    test('finds triangle for point inside extent', () {
      (double, double) identity((double, double) coord) => coord;
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final result = t.findSourceTriangleForTargetPoint((50.0, 50.0));
      expect(result, isNotNull);
      expect(result!.tri, isNotNull);
      expect(result.transform, isNotNull);
    });

    test('returns null for point outside extent', () {
      (double, double) identity((double, double) coord) => coord;
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final result = t.findSourceTriangleForTargetPoint((500.0, 500.0));
      expect(result, isNull);
    });

    test('uses hint for spatial coherence when hint is valid', () {
      (double, double) identity((double, double) coord) => coord;
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final first = t.findSourceTriangleForTargetPoint((50.0, 50.0));
      expect(first, isNotNull);

      // Use hint - nearby point should reuse the same triangle
      final second =
          t.findSourceTriangleForTargetPoint((50.1, 50.1), first);
      expect(second, isNotNull);
    });

    test('ignores hint when point is not in hint triangle', () {
      (double, double) identity((double, double) coord) => coord;
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final first = t.findSourceTriangleForTargetPoint((10.0, 90.0));
      expect(first, isNotNull);

      // Far away point - hint triangle won't contain it
      final second =
          t.findSourceTriangleForTargetPoint((90.0, 10.0), first);
      expect(second, isNotNull);
    });

    test('caches affine transform on triangle', () {
      (double, double) identity((double, double) coord) => coord;
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final result = t.findSourceTriangleForTargetPoint((50.0, 50.0));
      expect(result, isNotNull);
      expect(result!.transform, isNotNull);
    });
  });

  group('Triangulation roundtrip with affine transform', () {
    test('identity: transform recovers original point', () {
      (double, double) identity((double, double) coord) => coord;
      final t = Triangulation(
        identity,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final point = (50.0, 50.0);
      final result = t.findSourceTriangleForTargetPoint(point);
      expect(result, isNotNull);

      final (srcX, srcY) =
          t.applyAffineTransform(point.$1, point.$2, result!.transform!);

      // With identity transform, source == target
      expect(srcX, closeTo(point.$1, 1.0));
      expect(srcY, closeTo(point.$2, 1.0));
    });

    test('linear: scale + translate recovers correct source', () {
      // Target->Source: multiply by 2 and add 1000
      (double, double) scale((double, double) coord) =>
          (coord.$1 * 2 + 1000, coord.$2 * 2 + 1000);

      final t = Triangulation(
        scale,
        (0.0, 0.0, 100.0, 100.0),
        errorThreshold: 0.5,
      );

      final point = (50.0, 50.0);
      final result = t.findSourceTriangleForTargetPoint(point);
      expect(result, isNotNull);

      final (srcX, srcY) =
          t.applyAffineTransform(point.$1, point.$2, result!.transform!);

      // Expected: 50*2+1000 = 1100
      expect(srcX, closeTo(1100.0, 2.0));
      expect(srcY, closeTo(1100.0, 2.0));
    });
  });
}
