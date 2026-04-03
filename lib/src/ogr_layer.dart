import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'model/field_type.dart';
import 'model/geometry.dart';
import 'native/gdal_errors.dart';
import 'native/gdal_memory.dart';
import 'native/gdal_ogr.dart';
import 'native/gdal_srs.dart';
import 'ogr_feature.dart';
import 'spatial_reference.dart';
import 'vector_dataset.dart';

/// A single layer within a [VectorDataset].
///
/// Layers hold a borrowed handle to the native OGR layer and are only
/// valid while the parent dataset is open. They are not independently
/// closeable (similar to [RasterBand] for raster datasets).
class OgrLayer {
  final GdalOgr _ogr;
  final GdalSrs _srs;
  final Pointer<Void> _handle;
  final VectorDataset _dataset;

  List<({String name, OgrFieldType type})>? _fieldDefsCache;

  OgrLayer._(this._ogr, this._srs, this._handle, this._dataset);

  /// Creates an [OgrLayer] from a native layer handle.
  ///
  /// Throws [OgrException] if the handle is null.
  factory OgrLayer.fromDataset(
    GdalOgr ogr,
    GdalSrs srs,
    VectorDataset dataset,
    Pointer<Void> handle,
  ) {
    if (handle == nullptr) {
      throw OgrException('Invalid layer handle');
    }
    return OgrLayer._(ogr, srs, handle, dataset);
  }

  void _ensureDatasetOpen() {
    if (_dataset.isClosed) {
      throw GdalDatasetClosedException('Vector dataset is already closed');
    }
  }

  /// The layer name.
  String get name {
    _ensureDatasetOpen();
    return _ogr.getLayerName(_handle);
  }

  /// The geometry type of the layer, or `null` if unknown.
  GeometryType? get geometryType {
    _ensureDatasetOpen();
    final defnHandle = _ogr.getLayerDefn(_handle);
    final ogrType = _ogr.getGeomType(defnHandle);
    return GeometryType.fromOgr(ogrType);
  }

  /// The number of features in the layer.
  ///
  /// Returns -1 if the count cannot be determined without
  /// scanning the entire layer.
  int get featureCount {
    _ensureDatasetOpen();
    return _ogr.getFeatureCount(_handle);
  }

  /// The field definitions (schema) of features in this layer.
  List<({String name, OgrFieldType type})> get fieldDefinitions {
    _ensureDatasetOpen();
    return _fieldDefsCache ??= _readFieldDefinitions();
  }

  List<({String name, OgrFieldType type})> _readFieldDefinitions() {
    final defnHandle = _ogr.getLayerDefn(_handle);
    final count = _ogr.getFieldCount(defnHandle);
    return List.generate(count, (i) {
      final fieldHandle = _ogr.getFieldDefn(defnHandle, i);
      final name = _ogr.getFieldName(fieldHandle);
      final ogrType = _ogr.getFieldType(fieldHandle);
      final type = OgrFieldType.fromOgr(ogrType) ?? OgrFieldType.string;
      return (name: name, type: type);
    });
  }

  /// Returns a single feature by its FID.
  ///
  /// Throws [OgrException] if the feature is not found.
  Feature feature(int fid) {
    _ensureDatasetOpen();
    final handle = _ogr.getFeature(_handle, fid);
    if (handle == nullptr) {
      throw OgrException('Feature with FID $fid not found');
    }
    return Feature.fromNativeHandle(_ogr, handle, fieldDefinitions);
  }

  /// Iterates over all features in the layer.
  ///
  /// Resets the reading cursor before and after iteration.
  /// Each feature is fully materialized as an immutable Dart object.
  Iterable<Feature> get features sync* {
    _ensureDatasetOpen();
    _ogr.resetReading(_handle);
    try {
      while (true) {
        final handle = _ogr.getNextFeature(_handle);
        if (handle == nullptr) break;
        yield Feature.fromNativeHandle(_ogr, handle, fieldDefinitions);
      }
    } finally {
      _ogr.resetReading(_handle);
    }
  }

  /// The layer's spatial reference, or `null` if none is defined.
  ///
  /// The returned [SpatialReference] is an independent copy and must
  /// be closed by the caller.
  SpatialReference? get spatialReference {
    _ensureDatasetOpen();
    final srsHandle = _ogr.getLayerSpatialRef(_handle);
    if (srsHandle == nullptr) return null;

    // The handle is borrowed from GDAL. We export to WKT and re-import
    // to create an independently owned SpatialReference.
    final wktPtr = calloc<Pointer<Utf8>>();
    try {
      final err = _srs.exportToWkt(srsHandle, wktPtr);
      if (err != 0 || wktPtr.value == nullptr) return null;
      final wkt = wktPtr.value.toDartString();
      _srs.cplFree(wktPtr.value.cast<Void>());
      if (wkt.isEmpty) return null;
      return SpatialReference.fromWkt(_srs, wkt);
    } finally {
      calloc.free(wktPtr);
    }
  }

  /// The spatial extent of the layer as `(minX, minY, maxX, maxY)`.
  ///
  /// Returns `null` if the extent cannot be determined.
  ({double minX, double minY, double maxX, double maxY})? get extent {
    _ensureDatasetOpen();
    final envelope = calloc<Double>(4);
    try {
      final err = _ogr.getExtent(_handle, envelope);
      if (err != 0) return null;
      // OGREnvelope layout: MinX, MaxX, MinY, MaxY
      return (
        minX: envelope[0],
        maxX: envelope[1],
        minY: envelope[2],
        maxY: envelope[3],
      );
    } finally {
      calloc.free(envelope);
    }
  }

  /// Sets a spatial filter rectangle on the layer.
  ///
  /// Only features whose geometry intersects the given bounding box
  /// will be returned by [features] and [featureCount].
  ///
  /// The filter is applied server-side by GDAL, so filtered features
  /// are never read across the FFI boundary.
  void setSpatialFilterRect(
      double minX, double minY, double maxX, double maxY) {
    _ensureDatasetOpen();
    _ogr.setSpatialFilterRect(_handle, minX, minY, maxX, maxY);
  }

  /// Clears any spatial filter set on the layer.
  void clearSpatialFilter() {
    _ensureDatasetOpen();
    _ogr.setSpatialFilter(_handle, nullptr);
  }

  /// Sets an attribute filter (SQL WHERE clause) on the layer.
  ///
  /// Only features matching the expression will be returned by
  /// [features] and [featureCount].
  ///
  /// Example:
  /// ```dart
  /// layer.setAttributeFilter("population > 1000000");
  /// for (final f in layer.features) { ... }
  /// layer.clearAttributeFilter();
  /// ```
  ///
  /// Throws [OgrException] if the expression is invalid.
  void setAttributeFilter(String where) {
    _ensureDatasetOpen();
    withNativeString(where, (ptr) {
      final err = _ogr.setAttributeFilter(_handle, ptr);
      if (err != 0) {
        throw OgrException('Invalid attribute filter: $where');
      }
    });
  }

  /// Clears any attribute filter set on the layer.
  void clearAttributeFilter() {
    _ensureDatasetOpen();
    _ogr.setAttributeFilter(_handle, nullptr);
  }

  @override
  String toString() => 'OgrLayer($name, $featureCount features)';
}
