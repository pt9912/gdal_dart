import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'model/geo_transform.dart';
import 'native/gdal_api.dart';
import 'native/gdal_errors.dart';
import 'native/gdal_srs.dart';
import 'raster_band.dart';
import 'spatial_reference.dart';

/// A read-only handle to an opened GeoTIFF dataset.
///
/// Obtained via [Gdal.openGeoTiff]. Must be closed after use:
///
/// ```dart
/// final dataset = gdal.openGeoTiff('example.tif');
/// try {
///   print(dataset.width);
///   final band = dataset.band(1);
///   final pixels = band.readAsUint8();
/// } finally {
///   dataset.close();
/// }
/// ```
class GeoTiffDataset {
  final GdalApi _api;
  final GdalSrs _srs;
  final Pointer<Void> _handle;
  bool _closed = false;

  GeoTiffDataset._(this._api, this._srs, this._handle);

  /// Opens a GeoTIFF file as a read-only dataset.
  ///
  /// Throws [GdalException] if the file cannot be opened.
  factory GeoTiffDataset.open(GdalApi api, GdalSrs srs, String path) {
    // GDAL_OF_READONLY | GDAL_OF_RASTER
    const openFlags = 0x00 | 0x02;

    final pathPtr = path.toNativeUtf8(allocator: calloc);
    try {
      final handle = api.openEx(pathPtr, openFlags);
      if (handle == nullptr) {
        throw GdalException('Failed to open GeoTIFF: $path');
      }
      return GeoTiffDataset._(api, srs, handle);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// The native dataset handle. Used internally by [RasterBand].
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
  String get projectionWkt {
    _ensureOpen();
    return _api.getProjectionRef(_handle);
  }

  /// Returns a new [SpatialReference] for this dataset's CRS.
  ///
  /// The returned reference is independently owned and must be closed
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

  /// Returns the [RasterBand] at 1-based [index].
  ///
  /// Throws [GdalException] if the index is out of range.
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
}
