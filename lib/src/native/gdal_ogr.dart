import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'gdal_memory.dart';

// --- Dataset layer access (GDAL 2.0+ unified API) ---

typedef _GetLayerCountC = Int32 Function(Pointer<Void> ds);
typedef _GetLayerCountDart = int Function(Pointer<Void> ds);

typedef _GetLayerC = Pointer<Void> Function(Pointer<Void> ds, Int32 index);
typedef _GetLayerDart = Pointer<Void> Function(Pointer<Void> ds, int index);

typedef _GetLayerByNameC = Pointer<Void> Function(
    Pointer<Void> ds, Pointer<Utf8> name);
typedef _GetLayerByNameDart = Pointer<Void> Function(
    Pointer<Void> ds, Pointer<Utf8> name);

// --- Layer ---

typedef _LGetNameC = Pointer<Utf8> Function(Pointer<Void> layer);
typedef _LGetNameDart = Pointer<Utf8> Function(Pointer<Void> layer);

typedef _LGetFeatureCountC = Int64 Function(Pointer<Void> layer, Int32 force);
typedef _LGetFeatureCountDart = int Function(Pointer<Void> layer, int force);

typedef _LGetFeatureC = Pointer<Void> Function(
    Pointer<Void> layer, Int64 fid);
typedef _LGetFeatureDart = Pointer<Void> Function(
    Pointer<Void> layer, int fid);

typedef _LGetNextFeatureC = Pointer<Void> Function(Pointer<Void> layer);
typedef _LGetNextFeatureDart = Pointer<Void> Function(Pointer<Void> layer);

typedef _LResetReadingC = Void Function(Pointer<Void> layer);
typedef _LResetReadingDart = void Function(Pointer<Void> layer);

typedef _LGetLayerDefnC = Pointer<Void> Function(Pointer<Void> layer);
typedef _LGetLayerDefnDart = Pointer<Void> Function(Pointer<Void> layer);

typedef _LGetSpatialRefC = Pointer<Void> Function(Pointer<Void> layer);
typedef _LGetSpatialRefDart = Pointer<Void> Function(Pointer<Void> layer);

typedef _LGetExtentC = Int32 Function(
    Pointer<Void> layer, Pointer<Double> envelope, Int32 force);
typedef _LGetExtentDart = int Function(
    Pointer<Void> layer, Pointer<Double> envelope, int force);

typedef _LSetSpatialFilterC = Void Function(
    Pointer<Void> layer, Pointer<Void> geom);
typedef _LSetSpatialFilterDart = void Function(
    Pointer<Void> layer, Pointer<Void> geom);

typedef _LSetSpatialFilterRectC = Void Function(
    Pointer<Void> layer, Double minX, Double minY, Double maxX, Double maxY);
typedef _LSetSpatialFilterRectDart = void Function(
    Pointer<Void> layer, double minX, double minY, double maxX, double maxY);

typedef _LSetAttributeFilterC = Int32 Function(
    Pointer<Void> layer, Pointer<Utf8> query);
typedef _LSetAttributeFilterDart = int Function(
    Pointer<Void> layer, Pointer<Utf8> query);

// --- FeatureDefn ---

typedef _FDGetFieldCountC = Int32 Function(Pointer<Void> defn);
typedef _FDGetFieldCountDart = int Function(Pointer<Void> defn);

typedef _FDGetFieldDefnC = Pointer<Void> Function(
    Pointer<Void> defn, Int32 index);
typedef _FDGetFieldDefnDart = Pointer<Void> Function(
    Pointer<Void> defn, int index);

typedef _FDGetGeomTypeC = Int32 Function(Pointer<Void> defn);
typedef _FDGetGeomTypeDart = int Function(Pointer<Void> defn);

// --- FieldDefn ---

typedef _FldGetNameRefC = Pointer<Utf8> Function(Pointer<Void> fieldDefn);
typedef _FldGetNameRefDart = Pointer<Utf8> Function(Pointer<Void> fieldDefn);

typedef _FldGetTypeC = Int32 Function(Pointer<Void> fieldDefn);
typedef _FldGetTypeDart = int Function(Pointer<Void> fieldDefn);

// --- Feature ---

typedef _FGetFIDC = Int64 Function(Pointer<Void> feature);
typedef _FGetFIDDart = int Function(Pointer<Void> feature);

typedef _FGetFieldAsIntegerC = Int32 Function(
    Pointer<Void> feature, Int32 index);
typedef _FGetFieldAsIntegerDart = int Function(
    Pointer<Void> feature, int index);

typedef _FGetFieldAsInteger64C = Int64 Function(
    Pointer<Void> feature, Int32 index);
typedef _FGetFieldAsInteger64Dart = int Function(
    Pointer<Void> feature, int index);

typedef _FGetFieldAsDoubleC = Double Function(
    Pointer<Void> feature, Int32 index);
typedef _FGetFieldAsDoubleDart = double Function(
    Pointer<Void> feature, int index);

typedef _FGetFieldAsStringC = Pointer<Utf8> Function(
    Pointer<Void> feature, Int32 index);
typedef _FGetFieldAsStringDart = Pointer<Utf8> Function(
    Pointer<Void> feature, int index);

typedef _FIsFieldSetAndNotNullC = Int32 Function(
    Pointer<Void> feature, Int32 index);
typedef _FIsFieldSetAndNotNullDart = int Function(
    Pointer<Void> feature, int index);

typedef _FGetGeometryRefC = Pointer<Void> Function(Pointer<Void> feature);
typedef _FGetGeometryRefDart = Pointer<Void> Function(Pointer<Void> feature);

typedef _FDestroyC = Void Function(Pointer<Void> feature);
typedef _FDestroyDart = void Function(Pointer<Void> feature);

// --- Geometry ---

typedef _GGetGeometryTypeC = Int32 Function(Pointer<Void> geom);
typedef _GGetGeometryTypeDart = int Function(Pointer<Void> geom);

typedef _GGetPointCountC = Int32 Function(Pointer<Void> geom);
typedef _GGetPointCountDart = int Function(Pointer<Void> geom);

typedef _GGetXC = Double Function(Pointer<Void> geom, Int32 index);
typedef _GGetXDart = double Function(Pointer<Void> geom, int index);

typedef _GGetYC = Double Function(Pointer<Void> geom, Int32 index);
typedef _GGetYDart = double Function(Pointer<Void> geom, int index);

typedef _GGetZC = Double Function(Pointer<Void> geom, Int32 index);
typedef _GGetZDart = double Function(Pointer<Void> geom, int index);

typedef _GGetGeometryCountC = Int32 Function(Pointer<Void> geom);
typedef _GGetGeometryCountDart = int Function(Pointer<Void> geom);

typedef _GGetGeometryRefC = Pointer<Void> Function(
    Pointer<Void> geom, Int32 index);
typedef _GGetGeometryRefDart = Pointer<Void> Function(
    Pointer<Void> geom, int index);

/// Low-level access to GDAL OGR vector API functions.
///
/// Uses manual [DynamicLibrary.lookupFunction] calls for OGR layer,
/// feature, and geometry access.
class GdalOgr {
  // Dataset layer access
  late final _GetLayerCountDart _getLayerCount;
  late final _GetLayerDart _getLayer;
  late final _GetLayerByNameDart _getLayerByName;

  // Layer
  late final _LGetNameDart _lGetName;
  late final _LGetFeatureCountDart _lGetFeatureCount;
  late final _LGetFeatureDart _lGetFeature;
  late final _LGetNextFeatureDart _lGetNextFeature;
  late final _LResetReadingDart _lResetReading;
  late final _LGetLayerDefnDart _lGetLayerDefn;
  late final _LGetSpatialRefDart _lGetSpatialRef;
  late final _LGetExtentDart _lGetExtent;
  late final _LSetSpatialFilterDart _lSetSpatialFilter;
  late final _LSetSpatialFilterRectDart _lSetSpatialFilterRect;
  late final _LSetAttributeFilterDart _lSetAttributeFilter;

  // FeatureDefn
  late final _FDGetFieldCountDart _fdGetFieldCount;
  late final _FDGetFieldDefnDart _fdGetFieldDefn;
  late final _FDGetGeomTypeDart _fdGetGeomType;

  // FieldDefn
  late final _FldGetNameRefDart _fldGetNameRef;
  late final _FldGetTypeDart _fldGetType;

  // Feature
  late final _FGetFIDDart _fGetFID;
  late final _FGetFieldAsIntegerDart _fGetFieldAsInteger;
  late final _FGetFieldAsInteger64Dart _fGetFieldAsInteger64;
  late final _FGetFieldAsDoubleDart _fGetFieldAsDouble;
  late final _FGetFieldAsStringDart _fGetFieldAsString;
  late final _FIsFieldSetAndNotNullDart _fIsFieldSetAndNotNull;
  late final _FGetGeometryRefDart _fGetGeometryRef;
  late final _FDestroyDart _fDestroy;

  // Geometry
  late final _GGetGeometryTypeDart _gGetGeometryType;
  late final _GGetPointCountDart _gGetPointCount;
  late final _GGetXDart _gGetX;
  late final _GGetYDart _gGetY;
  late final _GGetZDart _gGetZ;
  late final _GGetGeometryCountDart _gGetGeometryCount;
  late final _GGetGeometryRefDart _gGetGeometryRef;

  GdalOgr(DynamicLibrary lib) {
    // Dataset layer access
    _getLayerCount =
        lib.lookupFunction<_GetLayerCountC, _GetLayerCountDart>(
            'GDALDatasetGetLayerCount');
    _getLayer =
        lib.lookupFunction<_GetLayerC, _GetLayerDart>('GDALDatasetGetLayer');
    _getLayerByName =
        lib.lookupFunction<_GetLayerByNameC, _GetLayerByNameDart>(
            'GDALDatasetGetLayerByName');

    // Layer
    _lGetName =
        lib.lookupFunction<_LGetNameC, _LGetNameDart>('OGR_L_GetName');
    _lGetFeatureCount =
        lib.lookupFunction<_LGetFeatureCountC, _LGetFeatureCountDart>(
            'OGR_L_GetFeatureCount');
    _lGetFeature =
        lib.lookupFunction<_LGetFeatureC, _LGetFeatureDart>(
            'OGR_L_GetFeature');
    _lGetNextFeature =
        lib.lookupFunction<_LGetNextFeatureC, _LGetNextFeatureDart>(
            'OGR_L_GetNextFeature');
    _lResetReading =
        lib.lookupFunction<_LResetReadingC, _LResetReadingDart>(
            'OGR_L_ResetReading');
    _lGetLayerDefn =
        lib.lookupFunction<_LGetLayerDefnC, _LGetLayerDefnDart>(
            'OGR_L_GetLayerDefn');
    _lGetSpatialRef =
        lib.lookupFunction<_LGetSpatialRefC, _LGetSpatialRefDart>(
            'OGR_L_GetSpatialRef');
    _lGetExtent =
        lib.lookupFunction<_LGetExtentC, _LGetExtentDart>('OGR_L_GetExtent');
    _lSetSpatialFilter =
        lib.lookupFunction<_LSetSpatialFilterC, _LSetSpatialFilterDart>(
            'OGR_L_SetSpatialFilter');
    _lSetSpatialFilterRect = lib.lookupFunction<_LSetSpatialFilterRectC,
        _LSetSpatialFilterRectDart>('OGR_L_SetSpatialFilterRect');
    _lSetAttributeFilter =
        lib.lookupFunction<_LSetAttributeFilterC, _LSetAttributeFilterDart>(
            'OGR_L_SetAttributeFilter');

    // FeatureDefn
    _fdGetFieldCount =
        lib.lookupFunction<_FDGetFieldCountC, _FDGetFieldCountDart>(
            'OGR_FD_GetFieldCount');
    _fdGetFieldDefn =
        lib.lookupFunction<_FDGetFieldDefnC, _FDGetFieldDefnDart>(
            'OGR_FD_GetFieldDefn');
    _fdGetGeomType =
        lib.lookupFunction<_FDGetGeomTypeC, _FDGetGeomTypeDart>(
            'OGR_FD_GetGeomType');

    // FieldDefn
    _fldGetNameRef =
        lib.lookupFunction<_FldGetNameRefC, _FldGetNameRefDart>(
            'OGR_Fld_GetNameRef');
    _fldGetType =
        lib.lookupFunction<_FldGetTypeC, _FldGetTypeDart>('OGR_Fld_GetType');

    // Feature
    _fGetFID =
        lib.lookupFunction<_FGetFIDC, _FGetFIDDart>('OGR_F_GetFID');
    _fGetFieldAsInteger =
        lib.lookupFunction<_FGetFieldAsIntegerC, _FGetFieldAsIntegerDart>(
            'OGR_F_GetFieldAsInteger');
    _fGetFieldAsInteger64 =
        lib.lookupFunction<_FGetFieldAsInteger64C, _FGetFieldAsInteger64Dart>(
            'OGR_F_GetFieldAsInteger64');
    _fGetFieldAsDouble =
        lib.lookupFunction<_FGetFieldAsDoubleC, _FGetFieldAsDoubleDart>(
            'OGR_F_GetFieldAsDouble');
    _fGetFieldAsString =
        lib.lookupFunction<_FGetFieldAsStringC, _FGetFieldAsStringDart>(
            'OGR_F_GetFieldAsString');
    _fIsFieldSetAndNotNull = lib.lookupFunction<_FIsFieldSetAndNotNullC,
        _FIsFieldSetAndNotNullDart>('OGR_F_IsFieldSetAndNotNull');
    _fGetGeometryRef =
        lib.lookupFunction<_FGetGeometryRefC, _FGetGeometryRefDart>(
            'OGR_F_GetGeometryRef');
    _fDestroy =
        lib.lookupFunction<_FDestroyC, _FDestroyDart>('OGR_F_Destroy');

    // Geometry
    _gGetGeometryType =
        lib.lookupFunction<_GGetGeometryTypeC, _GGetGeometryTypeDart>(
            'OGR_G_GetGeometryType');
    _gGetPointCount =
        lib.lookupFunction<_GGetPointCountC, _GGetPointCountDart>(
            'OGR_G_GetPointCount');
    _gGetX = lib.lookupFunction<_GGetXC, _GGetXDart>('OGR_G_GetX');
    _gGetY = lib.lookupFunction<_GGetYC, _GGetYDart>('OGR_G_GetY');
    _gGetZ = lib.lookupFunction<_GGetZC, _GGetZDart>('OGR_G_GetZ');
    _gGetGeometryCount =
        lib.lookupFunction<_GGetGeometryCountC, _GGetGeometryCountDart>(
            'OGR_G_GetGeometryCount');
    _gGetGeometryRef =
        lib.lookupFunction<_GGetGeometryRefC, _GGetGeometryRefDart>(
            'OGR_G_GetGeometryRef');
  }

  // --- Dataset layer access ---

  /// Returns the number of layers in the dataset.
  int getLayerCount(Pointer<Void> ds) => _getLayerCount(ds);

  /// Returns the layer handle at [index] (0-based). Returns nullptr if invalid.
  Pointer<Void> getLayer(Pointer<Void> ds, int index) =>
      _getLayer(ds, index);

  /// Returns the layer handle with the given [name]. Returns nullptr if not found.
  Pointer<Void> getLayerByName(Pointer<Void> ds, Pointer<Utf8> name) =>
      _getLayerByName(ds, name);

  // --- Layer ---

  /// Returns the layer name. Owned by GDAL — do not free.
  String getLayerName(Pointer<Void> layer) =>
      readNativeString(_lGetName(layer));

  /// Returns the feature count. Pass [force] = 1 to force computation.
  int getFeatureCount(Pointer<Void> layer, {int force = 1}) =>
      _lGetFeatureCount(layer, force);

  /// Returns a feature by FID. Caller owns the returned handle
  /// and must call [destroyFeature]. Returns nullptr if not found.
  Pointer<Void> getFeature(Pointer<Void> layer, int fid) =>
      _lGetFeature(layer, fid);

  /// Returns the next feature in the iteration. Caller owns the returned
  /// handle and must call [destroyFeature]. Returns nullptr at end.
  Pointer<Void> getNextFeature(Pointer<Void> layer) =>
      _lGetNextFeature(layer);

  /// Resets the feature reading cursor to the beginning.
  void resetReading(Pointer<Void> layer) => _lResetReading(layer);

  /// Returns the layer definition handle. Borrowed — do not free.
  Pointer<Void> getLayerDefn(Pointer<Void> layer) => _lGetLayerDefn(layer);

  /// Returns the layer's spatial reference. Borrowed — do not free.
  /// Returns nullptr if no SRS is set.
  Pointer<Void> getLayerSpatialRef(Pointer<Void> layer) =>
      _lGetSpatialRef(layer);

  /// Reads the layer extent into [envelope] (4 doubles: minX, maxX, minY, maxY).
  /// Returns OGRErr (0 = OGRERR_NONE).
  int getExtent(Pointer<Void> layer, Pointer<Double> envelope,
          {int force = 1}) =>
      _lGetExtent(layer, envelope, force);

  /// Sets a spatial filter on the layer. Pass [nullptr] to clear.
  void setSpatialFilter(Pointer<Void> layer, Pointer<Void> geom) =>
      _lSetSpatialFilter(layer, geom);

  /// Sets a spatial filter rectangle on the layer.
  void setSpatialFilterRect(Pointer<Void> layer, double minX, double minY,
          double maxX, double maxY) =>
      _lSetSpatialFilterRect(layer, minX, minY, maxX, maxY);

  /// Sets an attribute filter (SQL WHERE clause) on the layer.
  /// Pass [nullptr] to clear. Returns OGRErr (0 = OGRERR_NONE).
  int setAttributeFilter(Pointer<Void> layer, Pointer<Utf8> query) =>
      _lSetAttributeFilter(layer, query);

  // --- FeatureDefn ---

  /// Returns the number of fields in the feature definition.
  int getFieldCount(Pointer<Void> defn) => _fdGetFieldCount(defn);

  /// Returns the field definition handle at [index]. Borrowed — do not free.
  Pointer<Void> getFieldDefn(Pointer<Void> defn, int index) =>
      _fdGetFieldDefn(defn, index);

  /// Returns the OGRwkbGeometryType of the feature definition as an integer.
  int getGeomType(Pointer<Void> defn) => _fdGetGeomType(defn);

  // --- FieldDefn ---

  /// Returns the field name. Owned by GDAL — do not free.
  String getFieldName(Pointer<Void> fieldDefn) =>
      readNativeString(_fldGetNameRef(fieldDefn));

  /// Returns the OGRFieldType as an integer.
  int getFieldType(Pointer<Void> fieldDefn) => _fldGetType(fieldDefn);

  // --- Feature ---

  /// Returns the feature ID.
  int getFeatureFID(Pointer<Void> feature) => _fGetFID(feature);

  /// Returns a field value as an integer.
  int getFieldAsInteger(Pointer<Void> feature, int index) =>
      _fGetFieldAsInteger(feature, index);

  /// Returns a field value as a 64-bit integer.
  int getFieldAsInteger64(Pointer<Void> feature, int index) =>
      _fGetFieldAsInteger64(feature, index);

  /// Returns a field value as a double.
  double getFieldAsDouble(Pointer<Void> feature, int index) =>
      _fGetFieldAsDouble(feature, index);

  /// Returns a field value as a string. Owned by GDAL — do not free.
  String getFieldAsString(Pointer<Void> feature, int index) =>
      readNativeString(_fGetFieldAsString(feature, index));

  /// Returns 1 if the field at [index] is set and not null, 0 otherwise.
  bool isFieldSetAndNotNull(Pointer<Void> feature, int index) =>
      _fIsFieldSetAndNotNull(feature, index) != 0;

  /// Returns the feature's geometry handle. Borrowed — do not free.
  /// Returns nullptr if no geometry.
  Pointer<Void> getGeometryRef(Pointer<Void> feature) =>
      _fGetGeometryRef(feature);

  /// Destroys a feature handle obtained via [getFeature] or [getNextFeature].
  void destroyFeature(Pointer<Void> feature) => _fDestroy(feature);

  // --- Geometry ---

  /// Returns the OGRwkbGeometryType as an integer.
  int getGeometryType(Pointer<Void> geom) => _gGetGeometryType(geom);

  /// Returns the number of points in a geometry (for linestrings, rings, etc.).
  int getPointCount(Pointer<Void> geom) => _gGetPointCount(geom);

  /// Returns the X coordinate of point [index].
  double getX(Pointer<Void> geom, int index) => _gGetX(geom, index);

  /// Returns the Y coordinate of point [index].
  double getY(Pointer<Void> geom, int index) => _gGetY(geom, index);

  /// Returns the Z coordinate of point [index].
  double getZ(Pointer<Void> geom, int index) => _gGetZ(geom, index);

  /// Returns the number of sub-geometries (for multi-types, polygons, etc.).
  int getGeometryCount(Pointer<Void> geom) => _gGetGeometryCount(geom);

  /// Returns the sub-geometry handle at [index]. Borrowed — do not free.
  Pointer<Void> getSubGeometry(Pointer<Void> geom, int index) =>
      _gGetGeometryRef(geom, index);
}
