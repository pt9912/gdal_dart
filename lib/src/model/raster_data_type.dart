/// GDAL raster data types.
enum RasterDataType {
  unknown(0, 0),
  byte_(1, 1),
  uint16(2, 2),
  int16(3, 2),
  uint32(4, 4),
  int32_(5, 4),
  float32(6, 4),
  float64(7, 8);

  /// The GDAL `GDALDataType` enum value.
  final int gdalValue;

  /// Size of a single element in bytes.
  final int sizeInBytes;

  const RasterDataType(this.gdalValue, this.sizeInBytes);

  /// Returns the [RasterDataType] for a GDAL enum value.
  ///
  /// Returns [unknown] for unrecognized values.
  static RasterDataType fromGdal(int value) {
    for (final type in values) {
      if (type.gdalValue == value) return type;
    }
    return unknown;
  }
}
