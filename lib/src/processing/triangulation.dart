import 'aabb2d.dart';
import 'bvh_node2d.dart';
import 'triangle.dart';

/// Function that transforms [x, y] from one projection to another.
typedef TransformFunction = (double, double) Function((double, double) coord);

/// Result of a triangle lookup: the triangle and its cached affine transform.
class TriResult {
  final ITriangle tri;
  final AffineTransform? transform;
  const TriResult(this.tri, this.transform);
}

/// Bounding box with named fields.
class Bounds {
  final double minX, minY, maxX, maxY;
  const Bounds(this.minX, this.minY, this.maxX, this.maxY);
}

/// Calculate bounds by sampling edges of [targetExtent] through [transformFn].
({Bounds source, Bounds target}) calculateBounds(
  (double, double)? sourceRef,
  double? resolution,
  (double, double, double, double) targetExtent,
  TransformFunction transformFn, {
  int step = 10,
}) {
  final (west, south, east, north) = targetExtent;
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  (double, double) minXTarget = (0, 0);
  (double, double) minYTarget = (0, 0);
  (double, double) maxXTarget = (0, 0);
  (double, double) maxYTarget = (0, 0);

  void sampleEdge((double, double) start, (double, double) end, int steps) {
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = start.$1 + (end.$1 - start.$1) * t;
      final y = start.$2 + (end.$2 - start.$2) * t;
      final target = (x, y);
      final (xSrc, ySrc) = transformFn(target);
      if (xSrc < minX) { minX = xSrc; minXTarget = target; }
      if (ySrc < minY) { minY = ySrc; minYTarget = target; }
      if (xSrc > maxX) { maxX = xSrc; maxXTarget = target; }
      if (ySrc > maxY) { maxY = ySrc; maxYTarget = target; }
    }
  }

  sampleEdge((west, north), (east, north), step);
  sampleEdge((east, north), (east, south), step);
  sampleEdge((east, south), (west, south), step);
  sampleEdge((west, south), (west, north), step);

  if (sourceRef != null && resolution != null) {
    final (refX, refY) = sourceRef;
    final minXPix = ((minX - refX) / resolution).floor();
    minX = refX + minXPix * resolution;
    final minYPix = ((minY - refY) / resolution).floor();
    minY = refY + minYPix * resolution;
    final maxXPix = ((maxX - refX) / resolution).ceil();
    maxX = refX + maxXPix * resolution;
    final maxYPix = ((maxY - refY) / resolution).ceil();
    maxY = refY + maxYPix * resolution;
  }

  return (
    source: Bounds(minX, minY, maxX, maxY),
    target: Bounds(minXTarget.$1, minYTarget.$2, maxXTarget.$1, maxYTarget.$2),
  );
}

const _maxSubdivision = 10;

/// Triangulation for raster reprojection.
///
/// Based on the OpenLayers approach: divide the target extent into triangles,
/// transform only vertices with the projection function, then use affine
/// transforms for all pixels within each triangle. This reduces projection
/// calls from ~65k to ~50–200 per tile.
class Triangulation {
  final List<ITriangle> _triangles = [];
  final TransformFunction _transformFn;
  final double _errorThresholdSquared;
  BVHNode2D? _bvh;
  late final Bounds bounds;

  Triangulation(
    this._transformFn,
    (double, double, double, double) targetExtent, {
    double errorThreshold = 0.5,
    (double, double)? sourceRef,
    double? resolution,
    int step = 10,
  }) : _errorThresholdSquared = errorThreshold * errorThreshold {
    final (west, south, east, north) = targetExtent;
    final a = (west, north);
    final b = (east, north);
    final c = (east, south);
    final d = (west, south);

    final extBounds = calculateBounds(
      sourceRef, resolution, targetExtent, _transformFn, step: step,
    );

    final aSrc = (extBounds.source.minX, extBounds.source.maxY);
    final bSrc = (extBounds.source.maxX, extBounds.source.maxY);
    final cSrc = (extBounds.source.maxX, extBounds.source.minY);
    final dSrc = (extBounds.source.minX, extBounds.source.minY);

    bounds = extBounds.source;
    _addQuad(a, b, c, d, aSrc, bSrc, cSrc, dSrc, _maxSubdivision);
  }

  /// All generated triangles.
  List<ITriangle> get triangles => _triangles;

  /// Find the source triangle containing [point] in target space.
  ///
  /// [hint] is a previously found result for spatial coherence caching.
  TriResult? findSourceTriangleForTargetPoint(
    (double, double) point, [TriResult? hint,
  ]) {
    _bvh ??= BVHNode2D.build(_triangles.map(BVHNode2D.toTriangle2D).toList());

    if (hint != null) {
      final p = Point2D(point.$1, point.$2);
      if (BVHNode2D.pointInTriangle(p, BVHNode2D.toTriangle2D(hint.tri))) {
        return hint;
      }
    }

    final p = Point2D(point.$1, point.$2);
    final result = _bvh!.findContainingTriangle(p);
    if (result == null) return null;

    result.transform ??= calculateAffineTransform(result.triangle);
    return TriResult(result.triangle, result.transform);
  }

  /// Calculate affine transformation for a triangle (target → source).
  AffineTransform calculateAffineTransform(ITriangle triangle) {
    final (x0t, y0t) = triangle.target.$1;
    final (x1t, y1t) = triangle.target.$2;
    final (x2t, y2t) = triangle.target.$3;
    final (x0s, y0s) = triangle.source.$1;
    final (x1s, y1s) = triangle.source.$2;
    final (x2s, y2s) = triangle.source.$3;

    final det = (x1t - x0t) * (y2t - y0t) - (x2t - x0t) * (y1t - y0t);
    if (det.abs() < 1e-10) {
      return AffineTransform(1, 0, x0s, 0, 1, y0s);
    }

    final a = ((x1s - x0s) * (y2t - y0t) - (x2s - x0s) * (y1t - y0t)) / det;
    final b = ((x2s - x0s) * (x1t - x0t) - (x1s - x0s) * (x2t - x0t)) / det;
    final c = x0s - a * x0t - b * y0t;
    final d = ((y1s - y0s) * (y2t - y0t) - (y2s - y0s) * (y1t - y0t)) / det;
    final e = ((y2s - y0s) * (x1t - x0t) - (y1s - y0s) * (x2t - x0t)) / det;
    final f = y0s - d * x0t - e * y0t;

    return AffineTransform(a, b, c, d, e, f);
  }

  /// Apply an affine transformation to a point.
  (double, double) applyAffineTransform(
      double x, double y, AffineTransform t) {
    return (t.a * x + t.b * y + t.c, t.d * x + t.e * y + t.f);
  }

  // --- Private ---

  void _addQuad(
    (double, double) a, (double, double) b,
    (double, double) c, (double, double) d,
    (double, double) aSrc, (double, double) bSrc,
    (double, double) cSrc, (double, double) dSrc,
    int maxSubdivision,
  ) {
    var needsSubdivision = false;

    if (maxSubdivision > 0) {
      final abTarget = (_mid(a.$1, b.$1), _mid(a.$2, b.$2));
      final bcTarget = (_mid(b.$1, c.$1), _mid(b.$2, c.$2));
      final cdTarget = (_mid(c.$1, d.$1), _mid(c.$2, d.$2));
      final daTarget = (_mid(d.$1, a.$1), _mid(d.$2, a.$2));

      final abSrc = _transformFn(abTarget);
      final bcSrc = _transformFn(bcTarget);
      final cdSrc = _transformFn(cdTarget);
      final daSrc = _transformFn(daTarget);

      final abExpected = (_mid(aSrc.$1, bSrc.$1), _mid(aSrc.$2, bSrc.$2));
      final bcExpected = (_mid(bSrc.$1, cSrc.$1), _mid(bSrc.$2, cSrc.$2));
      final cdExpected = (_mid(cSrc.$1, dSrc.$1), _mid(cSrc.$2, dSrc.$2));
      final daExpected = (_mid(dSrc.$1, aSrc.$1), _mid(dSrc.$2, aSrc.$2));

      if (_sqError(abSrc, abExpected) > _errorThresholdSquared ||
          _sqError(bcSrc, bcExpected) > _errorThresholdSquared ||
          _sqError(cdSrc, cdExpected) > _errorThresholdSquared ||
          _sqError(daSrc, daExpected) > _errorThresholdSquared) {
        needsSubdivision = true;
      }
    }

    if (needsSubdivision) {
      final eTarget = (
        (a.$1 + b.$1 + c.$1 + d.$1) / 4,
        (a.$2 + b.$2 + c.$2 + d.$2) / 4,
      );
      final eSrc = _transformFn(eTarget);

      final abT = (_mid(a.$1, b.$1), _mid(a.$2, b.$2));
      final bcT = (_mid(b.$1, c.$1), _mid(b.$2, c.$2));
      final cdT = (_mid(c.$1, d.$1), _mid(c.$2, d.$2));
      final daT = (_mid(d.$1, a.$1), _mid(d.$2, a.$2));

      final abS = _transformFn(abT);
      final bcS = _transformFn(bcT);
      final cdS = _transformFn(cdT);
      final daS = _transformFn(daT);

      final next = maxSubdivision - 1;
      _addQuad(a, abT, eTarget, daT, aSrc, abS, eSrc, daS, next);
      _addQuad(abT, b, bcT, eTarget, abS, bSrc, bcS, eSrc, next);
      _addQuad(eTarget, bcT, c, cdT, eSrc, bcS, cSrc, cdS, next);
      _addQuad(daT, eTarget, cdT, d, daS, eSrc, cdS, dSrc, next);
    } else {
      _addTriangle(a, b, d, aSrc, bSrc, dSrc);
      _addTriangle(b, c, d, bSrc, cSrc, dSrc);
    }
  }

  void _addTriangle(
    (double, double) a, (double, double) b, (double, double) c,
    (double, double) aSrc, (double, double) bSrc, (double, double) cSrc,
  ) {
    if (!aSrc.$1.isFinite || !aSrc.$2.isFinite ||
        !bSrc.$1.isFinite || !bSrc.$2.isFinite ||
        !cSrc.$1.isFinite || !cSrc.$2.isFinite) {
      return;
    }
    _triangles.add(ITriangle(
      source: (aSrc, bSrc, cSrc),
      target: (a, b, c),
    ));
  }

  static double _mid(double a, double b) => (a + b) / 2;

  static double _sqError((double, double) actual, (double, double) expected) {
    final dx = actual.$1 - expected.$1;
    final dy = actual.$2 - expected.$2;
    return dx * dx + dy * dy;
  }
}
