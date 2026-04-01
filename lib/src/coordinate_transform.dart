import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'native/gdal_errors.dart';
import 'native/gdal_srs.dart';
import 'spatial_reference.dart';

/// Transforms coordinates between two coordinate reference systems.
///
/// Wraps GDAL's OGRCoordinateTransformation (OCT) API.
///
/// Must be closed after use to free the native handle:
///
/// ```dart
/// final wgs84 = gdal.spatialReferenceFromEpsg(4326);
/// final utm32 = gdal.spatialReferenceFromEpsg(32632);
/// final ct = CoordinateTransform(srs, wgs84, utm32);
/// final (x, y) = ct.transformPoint(11.0, 48.0);
/// ct.close();
/// wgs84.close();
/// utm32.close();
/// ```
class CoordinateTransform {
  final GdalSrs _srs;
  Pointer<Void> _handle;
  bool _closed = false;

  /// Creates a coordinate transformation from [source] to [target].
  ///
  /// Throws [GdalException] if the transformation cannot be created
  /// (e.g., incompatible CRS definitions).
  CoordinateTransform(this._srs, SpatialReference source,
      SpatialReference target)
      : _handle = _create(_srs, source, target);

  static Pointer<Void> _create(
      GdalSrs srs, SpatialReference source, SpatialReference target) {
    final handle = srs.newCoordinateTransformation(
        source.nativeHandle, target.nativeHandle);
    if (handle == nullptr) {
      throw GdalException(
          'Failed to create coordinate transformation');
    }
    return handle;
  }

  /// Transforms a single point from the source to the target CRS.
  ///
  /// Returns the transformed `(x, y)` coordinates.
  ///
  /// Throws [GdalException] if the transformation fails.
  (double x, double y) transformPoint(double x, double y) {
    _ensureOpen();
    final xPtr = calloc<Double>(1);
    final yPtr = calloc<Double>(1);
    try {
      xPtr[0] = x;
      yPtr[0] = y;
      final result = _srs.transform(_handle, 1, xPtr, yPtr, nullptr);
      if (result == 0) {
        throw GdalException(
            'Coordinate transformation failed for ($x, $y)');
      }
      return (xPtr[0], yPtr[0]);
    } finally {
      calloc.free(xPtr);
      calloc.free(yPtr);
    }
  }

  /// Transforms multiple points from the source to the target CRS.
  ///
  /// [xs] and [ys] must have the same length. Returns a list of
  /// transformed `(x, y)` pairs.
  ///
  /// Throws [GdalException] if the transformation fails.
  List<(double x, double y)> transformPoints(
      List<double> xs, List<double> ys) {
    _ensureOpen();
    if (xs.length != ys.length) {
      throw ArgumentError('xs and ys must have the same length');
    }
    final count = xs.length;
    if (count == 0) return [];

    final xPtr = calloc<Double>(count);
    final yPtr = calloc<Double>(count);
    try {
      for (var i = 0; i < count; i++) {
        xPtr[i] = xs[i];
        yPtr[i] = ys[i];
      }
      final result = _srs.transform(_handle, count, xPtr, yPtr, nullptr);
      if (result == 0) {
        throw GdalException(
            'Coordinate transformation failed for $count points');
      }
      return List.generate(count, (i) => (xPtr[i], yPtr[i]));
    } finally {
      calloc.free(xPtr);
      calloc.free(yPtr);
    }
  }

  /// Whether this transform has been closed.
  bool get isClosed => _closed;

  /// Destroys the native transformation handle.
  ///
  /// Idempotent.
  void close() {
    if (!_closed) {
      _srs.destroyCoordinateTransformation(_handle);
      _closed = true;
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw GdalDatasetClosedException(
          'CoordinateTransform is already closed');
    }
  }
}
