import 'dart:ffi';

import 'geotiff_dataset.dart';
import 'geotiff_writer.dart';
import 'model/raster_data_type.dart';
import 'native/gdal_api.dart';
import 'native/gdal_library.dart';
import 'native/gdal_srs.dart';
import 'spatial_reference.dart';

/// Main entry point for GDAL operations.
///
/// Creates a new instance to initialize GDAL and register all drivers.
///
/// ```dart
/// final gdal = Gdal();
/// final dataset = gdal.openGeoTiff('example.tif');
/// print('${dataset.width} x ${dataset.height}');
/// dataset.close();
/// ```
class Gdal {
  final GdalApi _api;
  final GdalSrs _srs;

  /// Creates a new GDAL instance and registers all drivers.
  ///
  /// Optionally provide [libraryPath] to load GDAL from a specific location.
  /// Otherwise, the library is resolved via:
  /// 1. `GDAL_LIBRARY_PATH` environment variable
  /// 2. Platform default (`libgdal.so`, `libgdal.dylib`, or `gdal.dll`)
  ///
  /// Throws [GdalLibraryLoadException] if the library cannot be loaded.
  Gdal({String? libraryPath})
      : this._fromLib(loadGdalLibrary(path: libraryPath));

  Gdal._fromLib(DynamicLibrary lib)
      : _api = GdalApi(lib),
        _srs = GdalSrs(lib) {
    _api.allRegister();
  }

  /// The GDAL release name (e.g., `"3.8.4"`).
  String get versionString => _api.versionInfo('RELEASE_NAME');

  /// The GDAL version number as a numeric string (e.g., `"3080400"`).
  String get versionNumber => _api.versionInfo('VERSION_NUM');

  /// The number of registered GDAL drivers.
  int get driverCount => _api.getDriverCount();

  /// Opens any GDAL-supported raster file for reading.
  ///
  /// Works with GeoTIFF, JPEG, PNG, NetCDF, and all other formats
  /// supported by the installed GDAL drivers.
  ///
  /// Throws [GdalFileException] if the file cannot be opened.
  /// The returned [GeoTiffDataset] must be closed after use.
  GeoTiffDataset open(String path) {
    return GeoTiffDataset.open(_api, _srs, path);
  }

  /// Opens a GeoTIFF file for reading.
  ///
  /// Equivalent to [open] — provided for clarity when the caller
  /// knows the file is a GeoTIFF.
  GeoTiffDataset openGeoTiff(String path) => open(path);

  /// Creates a new GeoTIFF file for writing.
  ///
  /// The [options] map supports GTiff creation options such as
  /// `{'TILED': 'YES', 'COMPRESS': 'LZW'}`.
  ///
  /// The returned [GeoTiffWriter] must be closed after use to flush
  /// data to disk.
  GeoTiffWriter createGeoTiff(
    String path, {
    required int width,
    required int height,
    int bandCount = 1,
    RasterDataType dataType = RasterDataType.byte_,
    Map<String, String> options = const {},
  }) {
    return GeoTiffWriter.create(
      _api,
      path,
      width: width,
      height: height,
      bandCount: bandCount,
      dataType: dataType,
      options: options,
    );
  }

  /// Creates a [SpatialReference] from an EPSG code (e.g., 4326).
  ///
  /// The returned reference must be closed by the caller.
  SpatialReference spatialReferenceFromEpsg(int code) {
    return SpatialReference.fromEpsg(_srs, code);
  }

  /// Creates a [SpatialReference] from a WKT string.
  ///
  /// The returned reference must be closed by the caller.
  SpatialReference spatialReferenceFromWkt(String wkt) {
    return SpatialReference.fromWkt(_srs, wkt);
  }
}
