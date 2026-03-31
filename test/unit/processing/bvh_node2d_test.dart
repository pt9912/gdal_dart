import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/processing/aabb2d.dart';
import 'package:gdal_dart/src/processing/bvh_node2d.dart';
import 'package:gdal_dart/src/processing/triangle.dart';
import 'package:test/test.dart';

/// Helper to create a Triangle2D from three points with a matching ITriangle.
Triangle2D _makeTriangle2D(
  double ax, double ay,
  double bx, double by,
  double cx, double cy,
) {
  final itri = ITriangle(
    source: ((ax, ay), (bx, by), (cx, cy)),
    target: ((ax, ay), (bx, by), (cx, cy)),
  );
  return Triangle2D(
    a: Point2D(ax, ay),
    b: Point2D(bx, by),
    c: Point2D(cx, cy),
    triangle: itri,
  );
}

void main() {
  group('BVHNode2D.pointInTriangle', () {
    final tri = _makeTriangle2D(0, 0, 10, 0, 0, 10);

    test('returns true for point inside triangle', () {
      expect(BVHNode2D.pointInTriangle(const Point2D(2, 2), tri), isTrue);
    });

    test('returns true for point at vertex a', () {
      expect(BVHNode2D.pointInTriangle(const Point2D(0, 0), tri), isTrue);
    });

    test('returns true for point at vertex b', () {
      expect(BVHNode2D.pointInTriangle(const Point2D(10, 0), tri), isTrue);
    });

    test('returns true for point at vertex c', () {
      expect(BVHNode2D.pointInTriangle(const Point2D(0, 10), tri), isTrue);
    });

    test('returns true for point on edge', () {
      expect(BVHNode2D.pointInTriangle(const Point2D(5, 0), tri), isTrue);
      expect(BVHNode2D.pointInTriangle(const Point2D(0, 5), tri), isTrue);
      expect(BVHNode2D.pointInTriangle(const Point2D(5, 5), tri), isTrue);
    });

    test('returns false for point outside triangle', () {
      expect(BVHNode2D.pointInTriangle(const Point2D(6, 6), tri), isFalse);
      expect(BVHNode2D.pointInTriangle(const Point2D(-1, 5), tri), isFalse);
      expect(BVHNode2D.pointInTriangle(const Point2D(5, -1), tri), isFalse);
      expect(BVHNode2D.pointInTriangle(const Point2D(11, 0), tri), isFalse);
    });

    test('returns true for centroid', () {
      final centroid = Point2D(
        (tri.a.x + tri.b.x + tri.c.x) / 3,
        (tri.a.y + tri.b.y + tri.c.y) / 3,
      );
      expect(BVHNode2D.pointInTriangle(centroid, tri), isTrue);
    });

    test('handles right-angle triangle', () {
      final rightTri = _makeTriangle2D(0, 0, 4, 0, 0, 3);
      expect(BVHNode2D.pointInTriangle(const Point2D(1, 1), rightTri), isTrue);
      expect(BVHNode2D.pointInTriangle(const Point2D(3, 2), rightTri), isFalse);
    });
  });

  group('BVHNode2D.toTriangle2D', () {
    test('converts ITriangle to Triangle2D using target coordinates', () {
      final itri = ITriangle(
        source: ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0)),
        target: ((10.0, 20.0), (30.0, 20.0), (10.0, 40.0)),
      );

      final t2d = BVHNode2D.toTriangle2D(itri);

      expect(t2d.a.x, 10.0);
      expect(t2d.a.y, 20.0);
      expect(t2d.b.x, 30.0);
      expect(t2d.b.y, 20.0);
      expect(t2d.c.x, 10.0);
      expect(t2d.c.y, 40.0);
      expect(t2d.triangle, same(itri));
    });
  });

  group('BVHNode2D.build', () {
    test('builds leaf node for 1 triangle', () {
      final triangles = [_makeTriangle2D(0, 0, 10, 0, 0, 10)];
      final bvh = BVHNode2D.build(triangles);

      expect(bvh.triangles, hasLength(1));
      expect(bvh.left, isNull);
      expect(bvh.right, isNull);
      expect(bvh.bbox.contains(const Point2D(5, 5)), isTrue);
    });

    test('builds leaf node for 2 triangles', () {
      final triangles = [
        _makeTriangle2D(0, 0, 5, 0, 0, 5),
        _makeTriangle2D(5, 5, 10, 5, 5, 10),
      ];
      final bvh = BVHNode2D.build(triangles);

      expect(bvh.triangles, hasLength(2));
      expect(bvh.left, isNull);
      expect(bvh.right, isNull);
    });

    test('builds internal node for 3+ triangles', () {
      final triangles = [
        _makeTriangle2D(0, 0, 5, 0, 0, 5),
        _makeTriangle2D(10, 0, 15, 0, 10, 5),
        _makeTriangle2D(20, 0, 25, 0, 20, 5),
      ];
      final bvh = BVHNode2D.build(triangles);

      // Should be an internal node with children
      expect(bvh.left, isNotNull);
      expect(bvh.right, isNotNull);
      expect(bvh.triangles, isEmpty);
    });

    test('respects maxDepth parameter', () {
      final triangles = [
        _makeTriangle2D(0, 0, 5, 0, 0, 5),
        _makeTriangle2D(10, 0, 15, 0, 10, 5),
        _makeTriangle2D(20, 0, 25, 0, 20, 5),
        _makeTriangle2D(30, 0, 35, 0, 30, 5),
      ];
      // maxDepth=0 should create a leaf node regardless of count
      final bvh = BVHNode2D.build(triangles, maxDepth: 0);

      expect(bvh.triangles, hasLength(4));
      expect(bvh.left, isNull);
      expect(bvh.right, isNull);
    });

    test('bbox encloses all triangles', () {
      final triangles = [
        _makeTriangle2D(-10, -20, 0, 0, -5, -5),
        _makeTriangle2D(50, 60, 100, 70, 80, 90),
      ];
      final bvh = BVHNode2D.build(triangles);

      expect(bvh.bbox.min.x, -10);
      expect(bvh.bbox.min.y, -20);
      expect(bvh.bbox.max.x, 100);
      expect(bvh.bbox.max.y, 90);
    });

    test('splits along Y axis when Y extent is larger', () {
      // Triangles spread out more along Y than X
      final triangles = [
        _makeTriangle2D(0, 0, 1, 0, 0, 1),
        _makeTriangle2D(0, 50, 1, 50, 0, 51),
        _makeTriangle2D(0, 100, 1, 100, 0, 101),
      ];
      final bvh = BVHNode2D.build(triangles);
      expect(bvh.left, isNotNull);
      expect(bvh.right, isNotNull);
    });

    test('splits along X axis when X extent is larger', () {
      // Triangles spread out more along X than Y
      final triangles = [
        _makeTriangle2D(0, 0, 1, 0, 0, 1),
        _makeTriangle2D(50, 0, 51, 0, 50, 1),
        _makeTriangle2D(100, 0, 101, 0, 100, 1),
      ];
      final bvh = BVHNode2D.build(triangles);
      expect(bvh.left, isNotNull);
      expect(bvh.right, isNotNull);
    });
  });

  group('BVHNode2D.findContainingTriangle', () {
    test('finds triangle containing a point (single triangle)', () {
      final triangles = [_makeTriangle2D(0, 0, 10, 0, 0, 10)];
      final bvh = BVHNode2D.build(triangles);

      final result = bvh.findContainingTriangle(const Point2D(2, 2));
      expect(result, isNotNull);
      expect(result!.a.x, 0);
    });

    test('returns null for point outside all triangles', () {
      final triangles = [_makeTriangle2D(0, 0, 10, 0, 0, 10)];
      final bvh = BVHNode2D.build(triangles);

      final result = bvh.findContainingTriangle(const Point2D(20, 20));
      expect(result, isNull);
    });

    test('returns null when point is outside bounding box', () {
      final triangles = [_makeTriangle2D(0, 0, 10, 0, 0, 10)];
      final bvh = BVHNode2D.build(triangles);

      final result = bvh.findContainingTriangle(const Point2D(-5, -5));
      expect(result, isNull);
    });

    test('returns null when point is in bbox but not in any triangle', () {
      // Create two small triangles that don't fill the bounding box
      final triangles = [
        _makeTriangle2D(0, 0, 2, 0, 0, 2),
        _makeTriangle2D(8, 8, 10, 8, 8, 10),
      ];
      final bvh = BVHNode2D.build(triangles);

      // Point in the middle of the bbox but not in either triangle
      final result = bvh.findContainingTriangle(const Point2D(5, 5));
      expect(result, isNull);
    });

    test('finds correct triangle among many', () {
      // Create a grid of triangles
      final triangles = <Triangle2D>[];
      for (var i = 0; i < 10; i++) {
        final x = i * 10.0;
        triangles.add(_makeTriangle2D(x, 0, x + 10, 0, x, 10));
        triangles.add(_makeTriangle2D(x + 10, 0, x + 10, 10, x, 10));
      }

      final bvh = BVHNode2D.build(triangles);

      // Point in the first triangle
      final r1 = bvh.findContainingTriangle(const Point2D(2, 2));
      expect(r1, isNotNull);

      // Point in a middle triangle
      final r2 = bvh.findContainingTriangle(const Point2D(55, 3));
      expect(r2, isNotNull);

      // Point outside all
      final r3 = bvh.findContainingTriangle(const Point2D(200, 200));
      expect(r3, isNull);
    });

    test('searches left then right child', () {
      // Use enough triangles to create a deep tree
      final triangles = [
        _makeTriangle2D(0, 0, 5, 0, 0, 5),
        _makeTriangle2D(10, 0, 15, 0, 10, 5),
        _makeTriangle2D(20, 0, 25, 0, 20, 5),
      ];
      final bvh = BVHNode2D.build(triangles);

      // Should find in left subtree
      final r1 = bvh.findContainingTriangle(const Point2D(2, 1));
      expect(r1, isNotNull);

      // Should find in right subtree
      final r2 = bvh.findContainingTriangle(const Point2D(22, 1));
      expect(r2, isNotNull);
    });
  });

  group('BVHNode2D constructor', () {
    test('creates node with default empty triangles', () {
      const bbox = AABB2D(Point2D(0, 0), Point2D(10, 10));
      final node = BVHNode2D(bbox);
      expect(node.bbox, same(bbox));
      expect(node.triangles, isEmpty);
      expect(node.left, isNull);
      expect(node.right, isNull);
    });

    test('creates node with children', () {
      const bbox = AABB2D(Point2D(0, 0), Point2D(10, 10));
      const leftBbox = AABB2D(Point2D(0, 0), Point2D(5, 10));
      const rightBbox = AABB2D(Point2D(5, 0), Point2D(10, 10));

      final left = BVHNode2D(leftBbox);
      final right = BVHNode2D(rightBbox);
      final parent = BVHNode2D(bbox, left: left, right: right);

      expect(parent.left, same(left));
      expect(parent.right, same(right));
    });
  });
}
