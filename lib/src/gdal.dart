import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'coordinate_transform.dart';
import 'geotiff_dataset.dart';
import 'geotiff_source.dart';
import 'geotiff_writer.dart';
import 'model/raster_data_type.dart';
import 'native/gdal_api.dart';
import 'native/gdal_library.dart';
import 'native/gdal_ogr.dart';
import 'native/gdal_srs.dart';
import 'spatial_reference.dart';
import 'vector_dataset.dart';

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
  static bool _driversRegistered = false;

  final GdalApi _api;
  final GdalSrs _srs;
  final GdalOgr _ogr;

  /// Creates a new GDAL instance and registers all drivers.
  ///
  /// Driver registration (`GDALAllRegister`) is guarded by a file lock so
  /// that concurrent calls from multiple isolates are serialized. Within the
  /// same isolate, subsequent calls skip registration entirely.
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
        _srs = GdalSrs(lib),
        _ogr = GdalOgr(lib) {
    if (!_driversRegistered) {
      _guardedRegister(_api);
      _driversRegistered = true;
    }
  }

  /// Registers GDAL drivers with cross-isolate thread safety.
  ///
  /// On POSIX systems, uses BSD file locking (`flock`) via FFI to serialize
  /// concurrent `GDALAllRegister` calls. Unlike POSIX `fcntl` locks (used by
  /// Dart's `lockSync`), `flock` locks are per-file-description and block
  /// across threads within the same process.
  static void _guardedRegister(GdalApi api) {
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        _flockGuardedRegister(api);
        return;
      } catch (_) {
        // FFI locking unavailable — fall through to unguarded call.
      }
    }
    api.allRegister();
  }

  static void _flockGuardedRegister(GdalApi api) {
    final libc = DynamicLibrary.process();

    final nativeOpen = libc.lookupFunction<
        Int32 Function(Pointer<Utf8>, Int32, Int32),
        int Function(Pointer<Utf8>, int, int)>('open');
    final nativeFlock = libc.lookupFunction<Int32 Function(Int32, Int32),
        int Function(int, int)>('flock');
    final nativeClose = libc.lookupFunction<Int32 Function(Int32),
        int Function(int)>('close');

    // O_CREAT | O_RDWR — platform-specific values.
    final flags = Platform.isLinux ? 0x42 : 0x0202;
    final pathPtr = '/tmp/.gdal_dart_init.lock'.toNativeUtf8();
    final fd = nativeOpen(pathPtr, flags, 436 /* 0644 */);
    malloc.free(pathPtr);

    if (fd < 0) {
      api.allRegister();
      return;
    }

    nativeFlock(fd, 2 /* LOCK_EX */);
    try {
      api.allRegister();
    } finally {
      nativeFlock(fd, 8 /* LOCK_UN */);
      nativeClose(fd);
    }
  }

  /// The GDAL release name (e.g., `"3.8.4"`).
  String get versionString => _api.versionInfo('RELEASE_NAME');

  /// The GDAL version number as a numeric string (e.g., `"3080400"`).
  String get versionNumber => _api.versionInfo('VERSION_NUM');

  /// The number of registered GDAL drivers.
  int get driverCount => _api.getDriverCount();

  /// Sets a GDAL configuration option (`CPLSetConfigOption`).
  ///
  /// Pass `null` for [value] to unset the option.
  ///
  /// ```dart
  /// gdal.setConfigOption('GDAL_CACHEMAX', '512');
  /// ```
  void setConfigOption(String key, String? value) =>
      _api.setConfigOption(key, value);

  /// Reads a GDAL configuration option (`CPLGetConfigOption`).
  ///
  /// Returns `null` if the option is not set.
  String? getConfigOption(String key) => _api.getConfigOption(key);

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

  /// Creates a [CoordinateTransform] from [source] to [target] CRS.
  ///
  /// The returned transform must be closed by the caller.
  CoordinateTransform coordinateTransform(
      SpatialReference source, SpatialReference target) {
    return CoordinateTransform(_srs, source, target);
  }

  /// Opens a GeoTIFF and returns a [GeoTiffSource] with pre-computed
  /// metadata and WGS 84 bounds.
  ///
  /// Optionally override the [nodata] value.
  ///
  /// The returned source owns the dataset and must be closed after use.
  GeoTiffSource openGeoTiffSource(String path, {double? nodata}) {
    final dataset = open(path);
    return GeoTiffSource.fromDataset(_srs, dataset, nodata: nodata);
  }

  /// Opens a vector file (GeoJSON, GeoPackage, Shapefile, etc.) for reading.
  ///
  /// Throws [GdalFileException] if the file cannot be opened.
  /// The returned [VectorDataset] must be closed after use.
  VectorDataset openVector(String path) {
    return VectorDataset.open(_api, _ogr, _srs, path);
  }
}
