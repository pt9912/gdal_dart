import 'dart:math' as math;

import 'aabb2d.dart';
import 'triangle.dart';

/// Bounding Volume Hierarchy node for fast 2D point-in-triangle queries.
class BVHNode2D {
  final AABB2D bbox;
  final List<Triangle2D> triangles;
  final BVHNode2D? left;
  final BVHNode2D? right;

  BVHNode2D(this.bbox, {this.triangles = const [], this.left, this.right});

  /// Builds a BVH tree from the given [triangles].
  static BVHNode2D build(List<Triangle2D> triangles,
      {int depth = 0, int maxDepth = 10}) {
    if (triangles.length <= 2 || depth >= maxDepth) {
      var bbox = AABB2D.fromTriangle(triangles[0]);
      for (var i = 1; i < triangles.length; i++) {
        bbox = AABB2D.union(bbox, AABB2D.fromTriangle(triangles[i]));
      }
      return BVHNode2D(bbox, triangles: triangles);
    }

    // Compute centroids.
    final centroids = triangles
        .map((t) => Point2D(
              (t.a.x + t.b.x + t.c.x) / 3,
              (t.a.y + t.b.y + t.c.y) / 3,
            ))
        .toList();

    var minX = centroids[0].x, minY = centroids[0].y;
    var maxX = centroids[0].x, maxY = centroids[0].y;
    for (final c in centroids) {
      minX = math.min(minX, c.x);
      minY = math.min(minY, c.y);
      maxX = math.max(maxX, c.x);
      maxY = math.max(maxY, c.y);
    }

    // Split along longest axis.
    final useX = (maxX - minX) > (maxY - minY);

    // Sort indices by centroid along chosen axis.
    final indices = List.generate(triangles.length, (i) => i);
    indices.sort((a, b) => useX
        ? centroids[a].x.compareTo(centroids[b].x)
        : centroids[a].y.compareTo(centroids[b].y));

    final mid = indices.length ~/ 2;
    final leftTris = [for (var i = 0; i < mid; i++) triangles[indices[i]]];
    final rightTris = [
      for (var i = mid; i < indices.length; i++) triangles[indices[i]]
    ];

    final leftNode = BVHNode2D.build(leftTris, depth: depth + 1, maxDepth: maxDepth);
    final rightNode =
        BVHNode2D.build(rightTris, depth: depth + 1, maxDepth: maxDepth);
    final bbox = AABB2D.union(leftNode.bbox, rightNode.bbox);

    return BVHNode2D(bbox, left: leftNode, right: rightNode);
  }

  /// Finds the triangle containing [point], or `null`.
  Triangle2D? findContainingTriangle(Point2D point) {
    if (!bbox.contains(point)) return null;

    if (triangles.isNotEmpty) {
      for (final triangle in triangles) {
        if (pointInTriangle(point, triangle)) return triangle;
      }
      return null;
    }

    return left?.findContainingTriangle(point) ??
        right?.findContainingTriangle(point);
  }

  /// Point-in-triangle test using barycentric coordinates.
  static bool pointInTriangle(Point2D p, Triangle2D triangle) {
    final a = triangle.a, b = triangle.b, c = triangle.c;
    final v0x = c.x - a.x, v0y = c.y - a.y;
    final v1x = b.x - a.x, v1y = b.y - a.y;
    final v2x = p.x - a.x, v2y = p.y - a.y;

    final dot00 = v0x * v0x + v0y * v0y;
    final dot01 = v0x * v1x + v0y * v1y;
    final dot02 = v0x * v2x + v0y * v2y;
    final dot11 = v1x * v1x + v1y * v1y;
    final dot12 = v1x * v2x + v1y * v2y;

    final invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    final u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    final v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    return u >= 0 && v >= 0 && u + v <= 1;
  }

  /// Converts an [ITriangle] to a [Triangle2D] using target coordinates.
  static Triangle2D toTriangle2D(ITriangle triangle) {
    final (a0, a1) = triangle.target.$1;
    final (b0, b1) = triangle.target.$2;
    final (c0, c1) = triangle.target.$3;
    return Triangle2D(
      a: Point2D(a0, a1),
      b: Point2D(b0, b1),
      c: Point2D(c0, c1),
      triangle: triangle,
    );
  }
}
