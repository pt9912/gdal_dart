import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../model/crs_info.dart';
import 'gdal_errors.dart';
import 'gdal_memory.dart';

// OSRNewSpatialReference(const char*) → OGRSpatialReferenceH
typedef _NewC = Pointer<Void> Function(Pointer<Utf8> wkt);
typedef _NewDart = Pointer<Void> Function(Pointer<Utf8> wkt);

// OSRDestroySpatialReference(OGRSpatialReferenceH)
typedef _DestroyC = Void Function(Pointer<Void> srs);
typedef _DestroyDart = void Function(Pointer<Void> srs);

// OSRImportFromEPSG(OGRSpatialReferenceH, int) → OGRErr
typedef _ImportFromEpsgC = Int32 Function(Pointer<Void> srs, Int32 code);
typedef _ImportFromEpsgDart = int Function(Pointer<Void> srs, int code);

// OSRExportToWkt(OGRSpatialReferenceH, char**) → OGRErr
typedef _ExportToWktC = Int32 Function(
    Pointer<Void> srs, Pointer<Pointer<Utf8>> result);
typedef _ExportToWktDart = int Function(
    Pointer<Void> srs, Pointer<Pointer<Utf8>> result);

// OSRExportToWktEx(OGRSpatialReferenceH, char**, const char* const*) → OGRErr
typedef _ExportToWktExC = Int32 Function(
    Pointer<Void> srs,
    Pointer<Pointer<Utf8>> result,
    Pointer<Pointer<Utf8>> options);
typedef _ExportToWktExDart = int Function(
    Pointer<Void> srs,
    Pointer<Pointer<Utf8>> result,
    Pointer<Pointer<Utf8>> options);

// OSRGetAuthorityCode(OGRSpatialReferenceH, const char*) → const char*
typedef _GetAuthorityCodeC = Pointer<Utf8> Function(
    Pointer<Void> srs, Pointer<Utf8> target);
typedef _GetAuthorityCodeDart = Pointer<Utf8> Function(
    Pointer<Void> srs, Pointer<Utf8> target);

// OSRGetAuthorityName(OGRSpatialReferenceH, const char*) → const char*
typedef _GetAuthorityNameC = Pointer<Utf8> Function(
    Pointer<Void> srs, Pointer<Utf8> target);
typedef _GetAuthorityNameDart = Pointer<Utf8> Function(
    Pointer<Void> srs, Pointer<Utf8> target);

// OSRIsSame(OGRSpatialReferenceH, OGRSpatialReferenceH) → int
typedef _IsSameC = Int32 Function(Pointer<Void> srs1, Pointer<Void> srs2);
typedef _IsSameDart = int Function(Pointer<Void> srs1, Pointer<Void> srs2);

// OSRSetAxisMappingStrategy(OGRSpatialReferenceH, int strategy)
typedef _SetAxisMappingStrategyC = Void Function(
    Pointer<Void> srs, Int32 strategy);
typedef _SetAxisMappingStrategyDart = void Function(
    Pointer<Void> srs, int strategy);

// OCTNewCoordinateTransformation(OGRSpatialReferenceH src, OGRSpatialReferenceH dst)
// → OGRCoordinateTransformationH
typedef _OctNewC = Pointer<Void> Function(
    Pointer<Void> srcSrs, Pointer<Void> dstSrs);
typedef _OctNewDart = Pointer<Void> Function(
    Pointer<Void> srcSrs, Pointer<Void> dstSrs);

// OCTDestroyCoordinateTransformation(OGRCoordinateTransformationH)
typedef _OctDestroyC = Void Function(Pointer<Void> ct);
typedef _OctDestroyDart = void Function(Pointer<Void> ct);

// OCTTransform(OGRCoordinateTransformationH, int count, double* x, double* y, double* z)
// → int (TRUE/FALSE)
typedef _OctTransformC = Int32 Function(Pointer<Void> ct, Int32 count,
    Pointer<Double> x, Pointer<Double> y, Pointer<Double> z);
typedef _OctTransformDart = int Function(Pointer<Void> ct, int count,
    Pointer<Double> x, Pointer<Double> y, Pointer<Double> z);

// VSIFree(void*) — for freeing strings allocated by GDAL/OSR.
typedef _CplFreeC = Void Function(Pointer<Void> ptr);
typedef _CplFreeDart = void Function(Pointer<Void> ptr);

// OSRGetCRSInfoListFromDatabase(const char*, const void*, int*) → OSRCRSInfo**
typedef _GetCRSInfoListC = Pointer<Pointer<_NativeOSRCRSInfo>> Function(
    Pointer<Utf8> authName, Pointer<Void> params, Pointer<Int32> count);
typedef _GetCRSInfoListDart = Pointer<Pointer<_NativeOSRCRSInfo>> Function(
    Pointer<Utf8> authName, Pointer<Void> params, Pointer<Int32> count);

// OSRDestroyCRSInfoList(OSRCRSInfo**)
typedef _DestroyCRSInfoListC = Void Function(
    Pointer<Pointer<_NativeOSRCRSInfo>> list);
typedef _DestroyCRSInfoListDart = void Function(
    Pointer<Pointer<_NativeOSRCRSInfo>> list);

/// Native layout of OSRCRSInfo (GDAL >= 3.0).
final class _NativeOSRCRSInfo extends Struct {
  external Pointer<Utf8> pszAuthName;
  external Pointer<Utf8> pszCode;
  external Pointer<Utf8> pszName;

  @Int32()
  external int eType;

  @Int32()
  external int bDeprecated;

  @Int32()
  external int bBboxValid;

  @Double()
  external double dfWestLongitudeDeg;

  @Double()
  external double dfSouthLatitudeDeg;

  @Double()
  external double dfEastLongitudeDeg;

  @Double()
  external double dfNorthLatitudeDeg;

  external Pointer<Utf8> pszAreaName;
  external Pointer<Utf8> pszProjectionMethodName;
}

/// Low-level access to GDAL OGR Spatial Reference (OSR) API functions.
class GdalSrs {
  final DynamicLibrary _lib;

  late final _NewDart _new;
  late final _DestroyDart _destroy;
  late final _ImportFromEpsgDart _importFromEpsg;
  late final _ExportToWktDart _exportToWkt;
  late final _ExportToWktExDart _exportToWktEx;
  late final _GetAuthorityCodeDart _getAuthorityCode;
  late final _GetAuthorityNameDart _getAuthorityName;
  late final _IsSameDart _isSame;
  late final _SetAxisMappingStrategyDart _setAxisMappingStrategy;
  late final _OctNewDart _octNew;
  late final _OctDestroyDart _octDestroy;
  late final _OctTransformDart _octTransform;
  late final _CplFreeDart _cplFree;

  // Lazy lookups for GDAL >= 3.0 symbols (not resolved in constructor).
  late final _GetCRSInfoListDart _getCRSInfoList = _lib
      .lookupFunction<_GetCRSInfoListC, _GetCRSInfoListDart>(
          'OSRGetCRSInfoListFromDatabase');
  late final _DestroyCRSInfoListDart _destroyCRSInfoList = _lib
      .lookupFunction<_DestroyCRSInfoListC, _DestroyCRSInfoListDart>(
          'OSRDestroyCRSInfoList');

  GdalSrs(DynamicLibrary lib) : _lib = lib {
    _new = lib.lookupFunction<_NewC, _NewDart>('OSRNewSpatialReference');
    _destroy = lib
        .lookupFunction<_DestroyC, _DestroyDart>('OSRDestroySpatialReference');
    _importFromEpsg = lib
        .lookupFunction<_ImportFromEpsgC, _ImportFromEpsgDart>(
            'OSRImportFromEPSG');
    _exportToWkt =
        lib.lookupFunction<_ExportToWktC, _ExportToWktDart>('OSRExportToWkt');
    _exportToWktEx = lib
        .lookupFunction<_ExportToWktExC, _ExportToWktExDart>(
            'OSRExportToWktEx');
    _getAuthorityCode = lib
        .lookupFunction<_GetAuthorityCodeC, _GetAuthorityCodeDart>(
            'OSRGetAuthorityCode');
    _getAuthorityName = lib
        .lookupFunction<_GetAuthorityNameC, _GetAuthorityNameDart>(
            'OSRGetAuthorityName');
    _isSame = lib.lookupFunction<_IsSameC, _IsSameDart>('OSRIsSame');
    _setAxisMappingStrategy = lib.lookupFunction<_SetAxisMappingStrategyC,
        _SetAxisMappingStrategyDart>('OSRSetAxisMappingStrategy');
    _octNew = lib.lookupFunction<_OctNewC, _OctNewDart>(
        'OCTNewCoordinateTransformation');
    _octDestroy = lib.lookupFunction<_OctDestroyC, _OctDestroyDart>(
        'OCTDestroyCoordinateTransformation');
    _octTransform =
        lib.lookupFunction<_OctTransformC, _OctTransformDart>('OCTTransform');
    _cplFree = lib.lookupFunction<_CplFreeC, _CplFreeDart>('VSIFree');
  }

  /// Creates a new SRS handle. Pass [nullptr] for empty, or WKT to import.
  Pointer<Void> newSpatialReference(Pointer<Utf8> wkt) => _new(wkt);

  /// Destroys an SRS handle.
  void destroy(Pointer<Void> srs) => _destroy(srs);

  /// Imports an EPSG code into [srs]. Returns OGRErr (0 = OGRERR_NONE).
  int importFromEpsg(Pointer<Void> srs, int code) =>
      _importFromEpsg(srs, code);

  /// Exports [srs] as WKT1. Writes result pointer into [result].
  /// Caller must free the result via [cplFree]. Returns OGRErr.
  int exportToWkt(Pointer<Void> srs, Pointer<Pointer<Utf8>> result) =>
      _exportToWkt(srs, result);

  /// Exports [srs] as WKT with [options] (null-terminated string list).
  /// Returns OGRErr.
  int exportToWktEx(Pointer<Void> srs, Pointer<Pointer<Utf8>> result,
          Pointer<Pointer<Utf8>> options) =>
      _exportToWktEx(srs, result, options);

  /// Returns the authority code (e.g., `"4326"`) for [target] node.
  /// Pass [nullptr] for the root. Returns nullptr if not available.
  String? getAuthorityCode(Pointer<Void> srs, Pointer<Utf8> target) {
    final ptr = _getAuthorityCode(srs, target);
    if (ptr == nullptr) return null;
    return readNativeString(ptr);
  }

  /// Returns the authority name (e.g., `"EPSG"`) for [target] node.
  String? getAuthorityName(Pointer<Void> srs, Pointer<Utf8> target) {
    final ptr = _getAuthorityName(srs, target);
    if (ptr == nullptr) return null;
    return readNativeString(ptr);
  }

  /// Returns 1 if the two SRS are equivalent, 0 otherwise.
  int isSame(Pointer<Void> srs1, Pointer<Void> srs2) =>
      _isSame(srs1, srs2);

  /// Sets the axis mapping strategy on [srs].
  ///
  /// Use `0` for `OAMS_TRADITIONAL_GIS_ORDER` (lon/lat, easting/northing),
  /// `1` for `OAMS_AUTHORITY_COMPLIANT` (GDAL 3.x default).
  void setAxisMappingStrategy(Pointer<Void> srs, int strategy) =>
      _setAxisMappingStrategy(srs, strategy);

  /// Creates a coordinate transformation from [srcSrs] to [dstSrs].
  /// Returns nullptr on failure.
  Pointer<Void> newCoordinateTransformation(
          Pointer<Void> srcSrs, Pointer<Void> dstSrs) =>
      _octNew(srcSrs, dstSrs);

  /// Destroys a coordinate transformation handle.
  void destroyCoordinateTransformation(Pointer<Void> ct) => _octDestroy(ct);

  /// Transforms [count] points in-place. [x], [y], [z] are arrays of doubles.
  /// Pass [nullptr] for [z] if not needed.
  /// Returns 1 (TRUE) on success, 0 (FALSE) on failure.
  int transform(Pointer<Void> ct, int count, Pointer<Double> x,
          Pointer<Double> y, Pointer<Double> z) =>
      _octTransform(ct, count, x, y, z);

  /// Frees memory allocated by GDAL (e.g., exported WKT strings).
  void cplFree(Pointer<Void> ptr) => _cplFree(ptr);

  /// Returns all CRS entries for [authName] from the PROJ database.
  ///
  /// Requires GDAL >= 3.0. Throws [GdalException] if the native
  /// symbols are not available.
  List<CrsInfo> getCRSInfoList(String authName) {
    final _GetCRSInfoListDart getCRSInfoListFn;
    final _DestroyCRSInfoListDart destroyCRSInfoListFn;
    try {
      getCRSInfoListFn = _getCRSInfoList;
      destroyCRSInfoListFn = _destroyCRSInfoList;
    } on ArgumentError {
      throw GdalException(
          'OSRGetCRSInfoListFromDatabase not available — '
          'requires GDAL >= 3.0');
    }

    final countPtr = calloc<Int32>();
    Pointer<Pointer<_NativeOSRCRSInfo>> list = nullptr;
    try {
      list = withNativeString(authName, (namePtr) {
        return getCRSInfoListFn(namePtr, nullptr, countPtr);
      });
      final count = countPtr.value;
      return [
        for (int i = 0; i < count; i++)
          _materializeCrsInfo(list[i].ref),
      ];
    } finally {
      calloc.free(countPtr);
      if (list != nullptr) destroyCRSInfoListFn(list);
    }
  }

  static CrsInfo _materializeCrsInfo(_NativeOSRCRSInfo native) {
    final bboxValid = native.bBboxValid != 0;
    return CrsInfo(
      authName: readNativeString(native.pszAuthName),
      code: readNativeString(native.pszCode),
      name: readNativeString(native.pszName),
      type: CrsType.fromOgr(native.eType),
      deprecated: native.bDeprecated != 0,
      westLon: bboxValid ? native.dfWestLongitudeDeg : null,
      southLat: bboxValid ? native.dfSouthLatitudeDeg : null,
      eastLon: bboxValid ? native.dfEastLongitudeDeg : null,
      northLat: bboxValid ? native.dfNorthLatitudeDeg : null,
      areaName: _readOptionalString(native.pszAreaName),
      projectionMethod: _readOptionalString(native.pszProjectionMethodName),
    );
  }

  static String? _readOptionalString(Pointer<Utf8> ptr) {
    if (ptr == nullptr) return null;
    final s = ptr.toDartString();
    return s.isEmpty ? null : s;
  }
}
