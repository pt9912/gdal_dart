import 'dart:math' as math;

import 'triangle.dart';

/// 2D point.
class Point2D {
  final double x;
  final double y;
  const Point2D(this.x, this.y);
}

/// Affine transformation coefficients.
class AffineTransform {
  final double a, b, c, d, e, f;
  const AffineTransform(this.a, this.b, this.c, this.d, this.e, this.f);
}

/// A triangle in 2D space with source/target mapping and cached transform.
class Triangle2D {
  final Point2D a;
  final Point2D b;
  final Point2D c;
  final ITriangle triangle;
  AffineTransform? transform;

  Triangle2D({
    required this.a,
    required this.b,
    required this.c,
    required this.triangle,
    this.transform,
  });
}

/// Axis-aligned bounding box in 2D.
class AABB2D {
  final Point2D min;
  final Point2D max;

  const AABB2D(this.min, this.max);

  /// Whether [point] lies inside this bounding box (inclusive).
  bool contains(Point2D point) =>
      point.x >= min.x &&
      point.x <= max.x &&
      point.y >= min.y &&
      point.y <= max.y;

  /// Creates an AABB enclosing the given [triangle].
  factory AABB2D.fromTriangle(Triangle2D triangle) {
    final minX = math.min(triangle.a.x, math.min(triangle.b.x, triangle.c.x));
    final minY = math.min(triangle.a.y, math.min(triangle.b.y, triangle.c.y));
    final maxX = math.max(triangle.a.x, math.max(triangle.b.x, triangle.c.x));
    final maxY = math.max(triangle.a.y, math.max(triangle.b.y, triangle.c.y));
    return AABB2D(Point2D(minX, minY), Point2D(maxX, maxY));
  }

  /// Creates an AABB that is the union of [a] and [b].
  factory AABB2D.union(AABB2D a, AABB2D b) => AABB2D(
        Point2D(math.min(a.min.x, b.min.x), math.min(a.min.y, b.min.y)),
        Point2D(math.max(a.max.x, b.max.x), math.max(a.max.y, b.max.y)),
      );
}
