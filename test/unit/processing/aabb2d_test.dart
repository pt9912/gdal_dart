import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/processing/aabb2d.dart';
import 'package:gdal_dart/src/processing/triangle.dart';
import 'package:test/test.dart';

void main() {
  group('Point2D', () {
    test('stores x and y', () {
      const p = Point2D(3.5, -7.2);
      expect(p.x, 3.5);
      expect(p.y, -7.2);
    });

    test('supports zero coordinates', () {
      const p = Point2D(0, 0);
      expect(p.x, 0.0);
      expect(p.y, 0.0);
    });

    test('supports very large values', () {
      const p = Point2D(1e18, -1e18);
      expect(p.x, 1e18);
      expect(p.y, -1e18);
    });
  });

  group('AffineTransform', () {
    test('stores all six coefficients', () {
      const t = AffineTransform(1, 2, 3, 4, 5, 6);
      expect(t.a, 1);
      expect(t.b, 2);
      expect(t.c, 3);
      expect(t.d, 4);
      expect(t.e, 5);
      expect(t.f, 6);
    });

    test('can represent identity transform', () {
      const t = AffineTransform(1, 0, 0, 0, 1, 0);
      expect(t.a, 1);
      expect(t.b, 0);
      expect(t.c, 0);
      expect(t.d, 0);
      expect(t.e, 1);
      expect(t.f, 0);
    });

    test('supports negative coefficients', () {
      const t = AffineTransform(-1, -2, -3, -4, -5, -6);
      expect(t.a, -1);
      expect(t.f, -6);
    });
  });

  group('Triangle2D', () {
    test('stores vertices, triangle reference, and optional transform', () {
      final itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
      );
      final t2d = Triangle2D(
        a: const Point2D(0, 0),
        b: const Point2D(1, 0),
        c: const Point2D(0, 1),
        triangle: itri,
      );

      expect(t2d.a.x, 0);
      expect(t2d.b.x, 1);
      expect(t2d.c.y, 1);
      expect(t2d.triangle, same(itri));
      expect(t2d.transform, isNull);
    });

    test('can have a transform assigned', () {
      final itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
      );
      final t2d = Triangle2D(
        a: const Point2D(0, 0),
        b: const Point2D(1, 0),
        c: const Point2D(0, 1),
        triangle: itri,
        transform: const AffineTransform(1, 0, 0, 0, 1, 0),
      );
      expect(t2d.transform, isNotNull);
      expect(t2d.transform!.a, 1);
    });

    test('transform can be set after construction', () {
      final itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
      );
      final t2d = Triangle2D(
        a: const Point2D(0, 0),
        b: const Point2D(1, 0),
        c: const Point2D(0, 1),
        triangle: itri,
      );
      expect(t2d.transform, isNull);
      t2d.transform = const AffineTransform(2, 0, 0, 0, 2, 0);
      expect(t2d.transform!.a, 2);
    });
  });

  group('AABB2D', () {
    test('stores min and max', () {
      const aabb = AABB2D(Point2D(0, 0), Point2D(10, 10));
      expect(aabb.min.x, 0);
      expect(aabb.min.y, 0);
      expect(aabb.max.x, 10);
      expect(aabb.max.y, 10);
    });

    group('contains', () {
      const aabb = AABB2D(Point2D(0, 0), Point2D(10, 10));

      test('returns true for point inside', () {
        expect(aabb.contains(const Point2D(5, 5)), isTrue);
      });

      test('returns true for point on min corner', () {
        expect(aabb.contains(const Point2D(0, 0)), isTrue);
      });

      test('returns true for point on max corner', () {
        expect(aabb.contains(const Point2D(10, 10)), isTrue);
      });

      test('returns true for point on edge', () {
        expect(aabb.contains(const Point2D(5, 0)), isTrue);
        expect(aabb.contains(const Point2D(0, 5)), isTrue);
        expect(aabb.contains(const Point2D(10, 5)), isTrue);
        expect(aabb.contains(const Point2D(5, 10)), isTrue);
      });

      test('returns false for point left of box', () {
        expect(aabb.contains(const Point2D(-1, 5)), isFalse);
      });

      test('returns false for point right of box', () {
        expect(aabb.contains(const Point2D(11, 5)), isFalse);
      });

      test('returns false for point below box', () {
        expect(aabb.contains(const Point2D(5, -1)), isFalse);
      });

      test('returns false for point above box', () {
        expect(aabb.contains(const Point2D(5, 11)), isFalse);
      });

      test('returns false for point outside on both axes', () {
        expect(aabb.contains(const Point2D(-1, -1)), isFalse);
        expect(aabb.contains(const Point2D(11, 11)), isFalse);
      });
    });

    group('fromTriangle', () {
      test('computes tight bounding box', () {
        final itri = ITriangle(
          source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
          target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        );
        final t2d = Triangle2D(
          a: const Point2D(1, 3),
          b: const Point2D(5, 1),
          c: const Point2D(3, 7),
          triangle: itri,
        );
        final aabb = AABB2D.fromTriangle(t2d);
        expect(aabb.min.x, 1);
        expect(aabb.min.y, 1);
        expect(aabb.max.x, 5);
        expect(aabb.max.y, 7);
      });

      test('handles triangle with negative coordinates', () {
        final itri = ITriangle(
          source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
          target: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        );
        final t2d = Triangle2D(
          a: const Point2D(-5, -3),
          b: const Point2D(2, -1),
          c: const Point2D(-1, 4),
          triangle: itri,
        );
        final aabb = AABB2D.fromTriangle(t2d);
        expect(aabb.min.x, -5);
        expect(aabb.min.y, -3);
        expect(aabb.max.x, 2);
        expect(aabb.max.y, 4);
      });

      test('handles degenerate triangle (all same point)', () {
        final itri = ITriangle(
          source: ((0.0, 0.0), (0.0, 0.0), (0.0, 0.0)),
          target: ((0.0, 0.0), (0.0, 0.0), (0.0, 0.0)),
        );
        final t2d = Triangle2D(
          a: const Point2D(3, 3),
          b: const Point2D(3, 3),
          c: const Point2D(3, 3),
          triangle: itri,
        );
        final aabb = AABB2D.fromTriangle(t2d);
        expect(aabb.min.x, 3);
        expect(aabb.max.x, 3);
        expect(aabb.min.y, 3);
        expect(aabb.max.y, 3);
      });

      test('handles collinear triangle', () {
        final itri = ITriangle(
          source: ((0.0, 0.0), (1.0, 0.0), (2.0, 0.0)),
          target: ((0.0, 0.0), (1.0, 0.0), (2.0, 0.0)),
        );
        final t2d = Triangle2D(
          a: const Point2D(0, 0),
          b: const Point2D(5, 0),
          c: const Point2D(10, 0),
          triangle: itri,
        );
        final aabb = AABB2D.fromTriangle(t2d);
        expect(aabb.min.x, 0);
        expect(aabb.max.x, 10);
        expect(aabb.min.y, 0);
        expect(aabb.max.y, 0);
      });
    });

    group('union', () {
      test('computes union of two non-overlapping boxes', () {
        const a = AABB2D(Point2D(0, 0), Point2D(5, 5));
        const b = AABB2D(Point2D(10, 10), Point2D(15, 15));
        final u = AABB2D.union(a, b);
        expect(u.min.x, 0);
        expect(u.min.y, 0);
        expect(u.max.x, 15);
        expect(u.max.y, 15);
      });

      test('computes union of overlapping boxes', () {
        const a = AABB2D(Point2D(0, 0), Point2D(10, 10));
        const b = AABB2D(Point2D(5, 5), Point2D(15, 15));
        final u = AABB2D.union(a, b);
        expect(u.min.x, 0);
        expect(u.min.y, 0);
        expect(u.max.x, 15);
        expect(u.max.y, 15);
      });

      test('computes union where one box contains the other', () {
        const a = AABB2D(Point2D(0, 0), Point2D(20, 20));
        const b = AABB2D(Point2D(5, 5), Point2D(10, 10));
        final u = AABB2D.union(a, b);
        expect(u.min.x, 0);
        expect(u.min.y, 0);
        expect(u.max.x, 20);
        expect(u.max.y, 20);
      });

      test('computes union of identical boxes', () {
        const a = AABB2D(Point2D(3, 3), Point2D(7, 7));
        final u = AABB2D.union(a, a);
        expect(u.min.x, 3);
        expect(u.min.y, 3);
        expect(u.max.x, 7);
        expect(u.max.y, 7);
      });

      test('handles negative coordinates', () {
        const a = AABB2D(Point2D(-10, -10), Point2D(-5, -5));
        const b = AABB2D(Point2D(-3, -3), Point2D(0, 0));
        final u = AABB2D.union(a, b);
        expect(u.min.x, -10);
        expect(u.min.y, -10);
        expect(u.max.x, 0);
        expect(u.max.y, 0);
      });
    });
  });
}
