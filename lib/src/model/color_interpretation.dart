/// GDAL raster band color interpretation.
enum ColorInterpretation {
  undefined(0),
  grayIndex(1),
  paletteIndex(2),
  red(3),
  green(4),
  blue(5),
  alpha(6),
  hue(7),
  saturation(8),
  lightness(9),
  cyan(10),
  magenta(11),
  yellow(12),
  black(13);

  /// The GDAL `GDALColorInterp` enum value.
  final int gdalValue;

  const ColorInterpretation(this.gdalValue);

  /// Returns the [ColorInterpretation] for a GDAL enum value.
  ///
  /// Returns [undefined] for unrecognized values.
  static ColorInterpretation fromGdal(int value) {
    for (final ci in values) {
      if (ci.gdalValue == value) return ci;
    }
    return undefined;
  }
}
