/// Affine transformation coefficients mapping pixel/line coordinates
/// to georeferenced coordinates.
///
/// The transformation is:
/// ```
/// x_geo = originX + pixel * pixelWidth  + line * rotationX
/// y_geo = originY + pixel * rotationY   + line * pixelHeight
/// ```
///
/// For north-up images [rotationX] and [rotationY] are zero, and
/// [pixelHeight] is negative.
class GeoTransform {
  /// X coordinate of the upper-left corner of the upper-left pixel.
  final double originX;

  /// Pixel width in georeferenced units.
  final double pixelWidth;

  /// Row rotation (zero for north-up images).
  final double rotationX;

  /// Y coordinate of the upper-left corner of the upper-left pixel.
  final double originY;

  /// Column rotation (zero for north-up images).
  final double rotationY;

  /// Pixel height in georeferenced units (negative for north-up images).
  final double pixelHeight;

  const GeoTransform({
    required this.originX,
    required this.pixelWidth,
    required this.rotationX,
    required this.originY,
    required this.rotationY,
    required this.pixelHeight,
  });

  /// Creates a [GeoTransform] from a GDAL-style six-element list.
  factory GeoTransform.fromList(List<double> values) {
    if (values.length != 6) {
      throw ArgumentError('GeoTransform requires exactly 6 values');
    }
    return GeoTransform(
      originX: values[0],
      pixelWidth: values[1],
      rotationX: values[2],
      originY: values[3],
      rotationY: values[4],
      pixelHeight: values[5],
    );
  }

  /// Returns the six coefficients as a list in GDAL order.
  List<double> toList() =>
      [originX, pixelWidth, rotationX, originY, rotationY, pixelHeight];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoTransform &&
          originX == other.originX &&
          pixelWidth == other.pixelWidth &&
          rotationX == other.rotationX &&
          originY == other.originY &&
          rotationY == other.rotationY &&
          pixelHeight == other.pixelHeight;

  @override
  int get hashCode => Object.hash(
      originX, pixelWidth, rotationX, originY, rotationY, pixelHeight);

  @override
  String toString() =>
      'GeoTransform(originX: $originX, pixelWidth: $pixelWidth, '
      'rotationX: $rotationX, originY: $originY, '
      'rotationY: $rotationY, pixelHeight: $pixelHeight)';
}
