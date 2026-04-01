import 'coordinate_transform.dart';
import 'geotiff_dataset.dart';
import 'model/geo_transform.dart';
import 'native/gdal_errors.dart';
import 'native/gdal_srs.dart';
import 'raster_band.dart';
import 'spatial_reference.dart';

/// Bounding box as `[west, south, east, north]` (minX, minY, maxX, maxY).
typedef Bounds4 = (double west, double south, double east, double north);

/// A loaded GeoTIFF source with pre-computed metadata, bounds, and
/// coordinate transformation to WGS 84.
///
/// This is the Dart equivalent of the TypeScript `GeoTIFFSource` from v-map.
/// Unlike the TS version, projection handling is done natively by GDAL —
/// no manual GeoKey parsing or hardcoded proj4 strings needed.
///
/// ```dart
/// final gdal = Gdal();
/// final source = GeoTiffSource.open(gdal, 'dem.tif');
/// print(source.wgs84Bounds);
/// print(source.transformToWgs84(500000, 5400000));
/// source.close();
/// ```
class GeoTiffSource {
  /// The underlying dataset.
  final GeoTiffDataset dataset;

  /// Raster width in pixels.
  final int width;

  /// Raster height in pixels.
  final int height;

  /// Number of raster bands.
  final int bandCount;

  /// The source CRS identifier (e.g., `"EPSG:4326"`, `"EPSG:32632"`).
  final String fromProjection;

  /// Bounding box in the source CRS.
  final Bounds4 sourceBounds;

  /// Affine geo-transform.
  final GeoTransform geoTransform;

  /// Pixel resolution (X direction) in source CRS units.
  final double resolution;

  /// NoData value of the first band, or `null` if not set.
  final double? noDataValue;

  /// Bounding box in WGS 84 (EPSG:4326).
  final Bounds4 wgs84Bounds;

  final CoordinateTransform? _toWgs84;
  final SpatialReference _sourceSrs;
  final SpatialReference? _wgs84Srs;

  GeoTiffSource._({
    required this.dataset,
    required this.width,
    required this.height,
    required this.bandCount,
    required this.fromProjection,
    required this.sourceBounds,
    required this.geoTransform,
    required this.resolution,
    required this.noDataValue,
    required this.wgs84Bounds,
    required CoordinateTransform? toWgs84,
    required SpatialReference sourceSrs,
    required SpatialReference? wgs84Srs,
  })  : _toWgs84 = toWgs84,
        _sourceSrs = sourceSrs,
        _wgs84Srs = wgs84Srs;

  /// Opens a GeoTIFF and computes source metadata and WGS 84 bounds.
  ///
  /// Optionally override the [nodata] value. If not provided, the value
  /// is read from the first band's metadata.
  ///
  /// Throws [GdalFileException] if the file cannot be opened.
  /// Throws [GdalException] if the dataset has no valid CRS.
  factory GeoTiffSource.fromDataset(
    GdalSrs srs,
    GeoTiffDataset dataset, {
    double? nodata,
  }) {
    final width = dataset.width;
    final height = dataset.height;
    final bandCount = dataset.bandCount;
    final gt = dataset.geoTransform;

    // Source bounds from GeoTransform.
    final minX = gt.originX;
    final maxY = gt.originY;
    final maxX = gt.originX + width * gt.pixelWidth + height * gt.rotationX;
    final minY = gt.originY + width * gt.rotationY + height * gt.pixelHeight;
    final sourceBounds = (minX, minY, maxX, maxY);

    final resolution = gt.pixelWidth;

    // NoData from first band.
    final band = dataset.band(1);
    final noDataValue = nodata ?? band.noDataValue;

    // Source CRS.
    final sourceSrs = dataset.spatialReference;
    final authorityName = sourceSrs.authorityName ?? '';
    final authorityCode = sourceSrs.authorityCode ?? '';
    final fromProjection = authorityCode.isNotEmpty
        ? '$authorityName:$authorityCode'
        : 'UNKNOWN';

    // Check if source is already WGS 84.
    SpatialReference? wgs84Srs;
    CoordinateTransform? toWgs84;
    Bounds4 wgs84Bounds;

    final isWgs84 = fromProjection == 'EPSG:4326';
    if (isWgs84) {
      wgs84Bounds = sourceBounds;
    } else {
      wgs84Srs = SpatialReference.fromEpsg(srs, 4326);
      toWgs84 = CoordinateTransform(srs, sourceSrs, wgs84Srs);

      // Transform all four corners to WGS 84.
      final corners = toWgs84.transformPoints(
        [minX, maxX, maxX, minX],
        [minY, minY, maxY, maxY],
      );

      final lons = corners.map((c) => c.$1).toList();
      final lats = corners.map((c) => c.$2).toList();

      double minVal(List<double> v) => v.reduce((a, b) => a < b ? a : b);
      double maxVal(List<double> v) => v.reduce((a, b) => a > b ? a : b);

      final west = _clampLon(minVal(lons));
      final east = _clampLon(maxVal(lons));
      final south = _clampLat(minVal(lats));
      final north = _clampLat(maxVal(lats));
      wgs84Bounds = (west, south, east, north);
    }

    return GeoTiffSource._(
      dataset: dataset,
      width: width,
      height: height,
      bandCount: bandCount,
      fromProjection: fromProjection,
      sourceBounds: sourceBounds,
      geoTransform: gt,
      resolution: resolution,
      noDataValue: noDataValue,
      wgs84Bounds: wgs84Bounds,
      toWgs84: toWgs84,
      sourceSrs: sourceSrs,
      wgs84Srs: wgs84Srs,
    );
  }

  /// Transforms a coordinate from the source CRS to WGS 84.
  ///
  /// If the source is already WGS 84, returns the input unchanged.
  (double lon, double lat) transformToWgs84(double x, double y) {
    if (_toWgs84 == null) return (x, y);
    return _toWgs84.transformPoint(x, y);
  }

  /// Returns the [RasterBand] at the given 1-based [index].
  RasterBand band(int index) => dataset.band(index);

  /// Closes the source, releasing all native handles.
  ///
  /// Closes the coordinate transformation, spatial references, and the
  /// underlying dataset. Idempotent.
  void close() {
    _toWgs84?.close();
    _wgs84Srs?.close();
    _sourceSrs.close();
    dataset.close();
  }

  static double _clampLon(double lon) =>
      lon.isFinite ? lon.clamp(-180.0, 180.0) : 0.0;

  static double _clampLat(double lat) =>
      lat.isFinite ? lat.clamp(-90.0, 90.0) : 0.0;
}
