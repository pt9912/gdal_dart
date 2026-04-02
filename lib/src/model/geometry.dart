/// OGR geometry types, mapped from OGRwkbGeometryType.
enum GeometryType {
  point,
  lineString,
  polygon,
  multiPoint,
  multiLineString,
  multiPolygon,
  geometryCollection;

  /// Maps an OGRwkbGeometryType integer to a [GeometryType].
  ///
  /// Handles both 2D and 2.5D variants (the Z flag at bit 31 is masked).
  /// Returns `null` for unsupported types.
  static GeometryType? fromOgr(int ogrType) {
    // Mask off the 2.5D flag (0x80000000) to normalize.
    final flat = ogrType & 0x7FFFFFFF;
    return switch (flat) {
      1 => GeometryType.point,
      2 => GeometryType.lineString,
      3 => GeometryType.polygon,
      4 => GeometryType.multiPoint,
      5 => GeometryType.multiLineString,
      6 => GeometryType.multiPolygon,
      7 => GeometryType.geometryCollection,
      _ => null,
    };
  }
}

/// Base class for OGR geometries.
///
/// Geometries are immutable Dart objects with no native handles.
/// They are materialized from native OGR geometry handles when
/// features are read.
sealed class Geometry {
  const Geometry();

  /// The geometry type.
  GeometryType get type;
}

/// A single point in 2D or 3D space.
class Point extends Geometry {
  final double x;
  final double y;
  final double? z;

  const Point(this.x, this.y, [this.z]);

  @override
  GeometryType get type => GeometryType.point;

  @override
  String toString() => z != null ? 'Point($x, $y, $z)' : 'Point($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}

/// An ordered sequence of points forming a line.
class LineString extends Geometry {
  final List<Point> points;

  const LineString(this.points);

  @override
  GeometryType get type => GeometryType.lineString;

  @override
  String toString() => 'LineString(${points.length} points)';
}

/// A polygon with an exterior ring and optional interior rings (holes).
///
/// [rings] has at least one entry. The first ring is the exterior boundary;
/// subsequent rings are holes.
class Polygon extends Geometry {
  final List<LineString> rings;

  const Polygon(this.rings);

  /// The exterior ring.
  LineString get exteriorRing => rings.first;

  /// Interior rings (holes), if any.
  List<LineString> get interiorRings =>
      rings.length > 1 ? rings.sublist(1) : const [];

  @override
  GeometryType get type => GeometryType.polygon;

  @override
  String toString() => 'Polygon(${rings.length} rings)';
}

/// A collection of points.
class MultiPoint extends Geometry {
  final List<Point> points;

  const MultiPoint(this.points);

  @override
  GeometryType get type => GeometryType.multiPoint;

  @override
  String toString() => 'MultiPoint(${points.length} points)';
}

/// A collection of line strings.
class MultiLineString extends Geometry {
  final List<LineString> lineStrings;

  const MultiLineString(this.lineStrings);

  @override
  GeometryType get type => GeometryType.multiLineString;

  @override
  String toString() =>
      'MultiLineString(${lineStrings.length} lineStrings)';
}

/// A collection of polygons.
class MultiPolygon extends Geometry {
  final List<Polygon> polygons;

  const MultiPolygon(this.polygons);

  @override
  GeometryType get type => GeometryType.multiPolygon;

  @override
  String toString() => 'MultiPolygon(${polygons.length} polygons)';
}

/// A heterogeneous collection of geometries.
class GeometryCollection extends Geometry {
  final List<Geometry> geometries;

  const GeometryCollection(this.geometries);

  @override
  GeometryType get type => GeometryType.geometryCollection;

  @override
  String toString() =>
      'GeometryCollection(${geometries.length} geometries)';
}
