import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'model/geo_transform.dart';
import 'model/raster_window.dart';
import 'native/gdal_api.dart';
import 'native/gdal_constants.dart';
import 'native/gdal_errors.dart';
import 'native/gdal_memory.dart';
import 'native/gdal_srs.dart';
import 'raster_band.dart';
import 'spatial_reference.dart';

/// A read-only handle to an opened GeoTIFF dataset.
///
/// Obtained via [Gdal.openGeoTiff]. Must be closed after use to release
/// the native GDAL dataset handle:
///
/// ```dart
/// final dataset = gdal.openGeoTiff('example.tif');
/// try {
///   print('${dataset.width} x ${dataset.height}');
///   final band = dataset.band(1);
///   final pixels = band.readAsUint8();
/// } finally {
///   dataset.close();
/// }
/// ```
///
/// Accessing any property or method after [close] throws
/// [GdalDatasetClosedException].
class GeoTiffDataset {
  final GdalApi _api;
  final GdalSrs _srs;
  final Pointer<Void> _handle;
  bool _closed = false;

  GeoTiffDataset._(this._api, this._srs, this._handle);

  /// Opens a GeoTIFF file as a read-only dataset.
  ///
  /// Throws [GdalFileException] if the file cannot be opened.
  factory GeoTiffDataset.open(GdalApi api, GdalSrs srs, String path) {
    final pathPtr = path.toNativeUtf8(allocator: calloc);
    try {
      final handle =
          api.openEx(pathPtr, gdalOfReadonly | gdalOfRaster);
      if (handle == nullptr) {
        throw GdalFileException('Failed to open GeoTIFF: $path', path: path);
      }
      return GeoTiffDataset._(api, srs, handle);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// The native dataset handle.
  ///
  /// This is an internal implementation detail used by [RasterBand].
  /// It is not part of the public API contract and may be removed in a
  /// future release.
  Pointer<Void> get nativeHandle {
    _ensureOpen();
    return _handle;
  }

  /// Raster width in pixels.
  int get width {
    _ensureOpen();
    return _api.getRasterXSize(_handle);
  }

  /// Raster height in pixels.
  int get height {
    _ensureOpen();
    return _api.getRasterYSize(_handle);
  }

  /// Number of raster bands.
  int get bandCount {
    _ensureOpen();
    return _api.getRasterCount(_handle);
  }

  /// Projection as a WKT string.
  ///
  /// Returns an empty string if no projection is defined.
  String get projectionWkt {
    _ensureOpen();
    return _api.getProjectionRef(_handle);
  }

  /// Returns a new [SpatialReference] for this dataset's CRS.
  ///
  /// The returned reference is independently owned and **must be closed**
  /// by the caller.
  ///
  /// Throws [GdalException] if the dataset has no valid CRS.
  SpatialReference get spatialReference {
    _ensureOpen();
    final wkt = projectionWkt;
    if (wkt.isEmpty) {
      throw GdalException('Dataset has no spatial reference');
    }
    return SpatialReference.fromWkt(_srs, wkt);
  }

  /// Affine GeoTransform coefficients.
  GeoTransform get geoTransform {
    _ensureOpen();
    final buffer = calloc<Double>(6);
    try {
      final err = _api.getGeoTransform(_handle, buffer);
      if (err != 0) {
        throw GdalException('Failed to read GeoTransform (CPLErr: $err)');
      }
      return GeoTransform.fromList(
        List<double>.generate(6, (i) => buffer[i]),
      );
    } finally {
      calloc.free(buffer);
    }
  }

  /// Returns the dataset metadata as key-value pairs.
  ///
  /// The optional [domain] selects a metadata domain (e.g., `"IMAGE_STRUCTURE"`).
  /// Pass `null` or omit for the default domain.
  Map<String, String> metadata({String? domain}) {
    _ensureOpen();
    final domainPtr =
        domain != null ? domain.toNativeUtf8(allocator: calloc) : nullptr;
    try {
      final list = _api.getMetadata(_handle, domainPtr.cast<Utf8>());
      return _parseStringList(list);
    } finally {
      if (domain != null) calloc.free(domainPtr);
    }
  }

  /// Returns a single metadata item, or `null` if not found.
  ///
  /// The optional [domain] selects a metadata domain.
  String? metadataItem(String key, {String? domain}) {
    _ensureOpen();
    final keyPtr = key.toNativeUtf8(allocator: calloc);
    final domainPtr =
        domain != null ? domain.toNativeUtf8(allocator: calloc) : nullptr;
    try {
      final result =
          _api.getMetadataItem(_handle, keyPtr, domainPtr.cast<Utf8>());
      if (result == nullptr) return null;
      return readNativeString(result);
    } finally {
      calloc.free(keyPtr);
      if (domain != null) calloc.free(domainPtr);
    }
  }

  /// Reads all bands as [Uint8List].
  ///
  /// Returns a list of length [bandCount], where index 0 corresponds to
  /// band 1. An optional [window] reads a sub-region.
  List<Uint8List> readAllBandsAsUint8({RasterWindow? window}) {
    _ensureOpen();
    return List.generate(
        bandCount, (i) => band(i + 1).readAsUint8(window: window));
  }

  /// Reads all bands as [Float32List].
  List<Float32List> readAllBandsAsFloat32({RasterWindow? window}) {
    _ensureOpen();
    return List.generate(
        bandCount, (i) => band(i + 1).readAsFloat32(window: window));
  }

  /// Returns the [RasterBand] at the given 1-based [index].
  ///
  /// Band indices start at 1. Throws [GdalException] if the index is
  /// out of range.
  RasterBand band(int index) {
    _ensureOpen();
    return RasterBand.fromDataset(_api, this, index);
  }

  /// Whether this dataset has been closed.
  bool get isClosed => _closed;

  /// Closes the dataset and releases the native handle.
  ///
  /// Idempotent — calling [close] on an already closed dataset is a no-op.
  void close() {
    if (!_closed) {
      _api.close(_handle);
      _closed = true;
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw GdalDatasetClosedException('Dataset is already closed');
    }
  }

  Map<String, String> _parseStringList(Pointer<Pointer<Utf8>> list) {
    final result = <String, String>{};
    if (list == nullptr) return result;
    for (var i = 0; list[i] != nullptr; i++) {
      final entry = list[i].toDartString();
      final eq = entry.indexOf('=');
      if (eq > 0) {
        result[entry.substring(0, eq)] = entry.substring(eq + 1);
      }
    }
    return result;
  }
}
