import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'native/gdal_errors.dart';
import 'native/gdal_srs.dart';

/// A coordinate reference system (CRS) backed by an OGR SpatialReference
/// handle.
///
/// Supports import from WKT or EPSG, export as WKT1/WKT2, authority
/// lookup, and CRS comparison.
///
/// Must be closed after use to free the native handle:
///
/// ```dart
/// final srs = dataset.spatialReference;
/// print(srs.authorityCode); // "4326"
/// print(srs.toWkt2());
/// srs.close();
/// ```
class SpatialReference {
  final GdalSrs _srs;
  Pointer<Void> _handle;
  bool _closed = false;

  SpatialReference._(this._srs, this._handle);

  /// OAMS_TRADITIONAL_GIS_ORDER — ensures (lon/lat) axis order.
  static const int _traditionalGisOrder = 0;

  /// Creates a [SpatialReference] from a WKT string.
  ///
  /// Throws [GdalException] if the WKT cannot be parsed.
  factory SpatialReference.fromWkt(GdalSrs srs, String wkt) {
    final wktPtr = wkt.toNativeUtf8(allocator: calloc);
    try {
      final handle = srs.newSpatialReference(wktPtr);
      if (handle == nullptr) {
        throw GdalException('Failed to create SpatialReference from WKT');
      }
      srs.setAxisMappingStrategy(handle, _traditionalGisOrder);
      return SpatialReference._(srs, handle);
    } finally {
      calloc.free(wktPtr);
    }
  }

  /// Creates a [SpatialReference] from an EPSG code (e.g., 4326).
  ///
  /// Throws [GdalException] if the code is not recognized.
  factory SpatialReference.fromEpsg(GdalSrs srs, int code) {
    final handle = srs.newSpatialReference(nullptr);
    if (handle == nullptr) {
      throw GdalException('Failed to create empty SpatialReference');
    }
    final err = srs.importFromEpsg(handle, code);
    if (err != 0) {
      srs.destroy(handle);
      throw GdalException('Failed to import EPSG:$code (OGRErr: $err)');
    }
    srs.setAxisMappingStrategy(handle, _traditionalGisOrder);
    return SpatialReference._(srs, handle);
  }

  /// The native OSR handle. Used internally.
  Pointer<Void> get nativeHandle {
    _ensureOpen();
    return _handle;
  }

  /// The authority name (e.g., `"EPSG"`), or `null` if unavailable.
  String? get authorityName {
    _ensureOpen();
    return _srs.getAuthorityName(_handle, nullptr);
  }

  /// The authority code (e.g., `"4326"`), or `null` if unavailable.
  String? get authorityCode {
    _ensureOpen();
    return _srs.getAuthorityCode(_handle, nullptr);
  }

  /// Exports the CRS as a WKT1 string.
  String toWkt() {
    _ensureOpen();
    final resultPtr = calloc<Pointer<Utf8>>();
    try {
      final err = _srs.exportToWkt(_handle, resultPtr);
      if (err != 0) {
        throw GdalException('OSRExportToWkt failed (OGRErr: $err)');
      }
      final wkt = resultPtr.value.toDartString();
      _srs.cplFree(resultPtr.value.cast<Void>());
      return wkt;
    } finally {
      calloc.free(resultPtr);
    }
  }

  /// Exports the CRS as a WKT2:2019 string.
  String toWkt2() {
    _ensureOpen();
    final resultPtr = calloc<Pointer<Utf8>>();
    // Build options: ["FORMAT=WKT2_2019", null]
    final optList = calloc<Pointer<Utf8>>(2);
    final optStr = 'FORMAT=WKT2_2019'.toNativeUtf8(allocator: calloc);
    optList[0] = optStr;
    optList[1] = nullptr;
    try {
      final err = _srs.exportToWktEx(_handle, resultPtr, optList);
      if (err != 0) {
        throw GdalException('OSRExportToWktEx failed (OGRErr: $err)');
      }
      final wkt = resultPtr.value.toDartString();
      _srs.cplFree(resultPtr.value.cast<Void>());
      return wkt;
    } finally {
      calloc.free(optStr);
      calloc.free(optList);
      calloc.free(resultPtr);
    }
  }

  /// Returns `true` if this CRS is equivalent to [other].
  bool isSame(SpatialReference other) {
    _ensureOpen();
    other._ensureOpen();
    return _srs.isSame(_handle, other._handle) == 1;
  }

  /// Whether this reference has been closed.
  bool get isClosed => _closed;

  /// Destroys the native OSR handle.
  ///
  /// Idempotent.
  void close() {
    if (!_closed) {
      _srs.destroy(_handle);
      _closed = true;
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw GdalDatasetClosedException('SpatialReference is already closed');
    }
  }
}
