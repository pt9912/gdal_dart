/// A pair of triangles mapping source to target coordinates.
///
/// Each triangle is defined by three [x, y] coordinate pairs.
typedef Triangle = (
  (double, double),
  (double, double),
  (double, double),
);

/// A triangle pair linking source and target projection spaces.
class ITriangle {
  final Triangle source;
  final Triangle target;

  const ITriangle({required this.source, required this.target});
}
