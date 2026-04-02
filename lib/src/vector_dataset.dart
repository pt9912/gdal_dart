import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'native/gdal_api.dart';
import 'native/gdal_constants.dart';
import 'native/gdal_errors.dart';
import 'native/gdal_memory.dart';
import 'native/gdal_ogr.dart';
import 'native/gdal_srs.dart';
import 'ogr_layer.dart';

/// A read-only handle to an opened OGR vector dataset.
///
/// Obtained via [Gdal.openVector]. Must be closed after use to release
/// the native GDAL dataset handle:
///
/// ```dart
/// final dataset = gdal.openVector('data.geojson');
/// try {
///   final layer = dataset.layer(0);
///   for (final feature in layer.features) {
///     print(feature.attributes);
///   }
/// } finally {
///   dataset.close();
/// }
/// ```
///
/// Accessing any property or method after [close] throws
/// [GdalDatasetClosedException].
class VectorDataset {
  final GdalApi _api;
  final GdalOgr _ogr;
  final GdalSrs _srs;
  final Pointer<Void> _handle;
  bool _closed = false;

  VectorDataset._(this._api, this._ogr, this._srs, this._handle);

  /// Opens a vector file (GeoJSON, GeoPackage, Shapefile, etc.) as a
  /// read-only dataset.
  ///
  /// Throws [GdalFileException] if the file cannot be opened.
  factory VectorDataset.open(
    GdalApi api,
    GdalOgr ogr,
    GdalSrs srs,
    String path,
  ) {
    final pathPtr = path.toNativeUtf8(allocator: calloc);
    try {
      final handle = api.openEx(pathPtr, gdalOfReadonly | gdalOfVector);
      if (handle == nullptr) {
        throw GdalFileException(
          'Failed to open vector dataset: $path',
          path: path,
        );
      }
      return VectorDataset._(api, ogr, srs, handle);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// The number of layers in the dataset.
  int get layerCount {
    _ensureOpen();
    return _ogr.getLayerCount(_handle);
  }

  /// Returns the [OgrLayer] at the given 0-based [index].
  ///
  /// Throws [OgrException] if the index is out of range.
  OgrLayer layer(int index) {
    _ensureOpen();
    final layerHandle = _ogr.getLayer(_handle, index);
    return OgrLayer.fromDataset(_ogr, _srs, this, layerHandle);
  }

  /// Returns the [OgrLayer] with the given [name].
  ///
  /// Throws [OgrException] if no layer with that name exists.
  OgrLayer layerByName(String name) {
    _ensureOpen();
    final layerHandle = withNativeString(
      name,
      (ptr) => _ogr.getLayerByName(_handle, ptr),
    );
    return OgrLayer.fromDataset(_ogr, _srs, this, layerHandle);
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
      throw GdalDatasetClosedException('Vector dataset is already closed');
    }
  }

  @override
  String toString() => 'VectorDataset($layerCount layers)';
}
