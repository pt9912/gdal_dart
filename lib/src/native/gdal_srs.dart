import 'dart:ffi';

import 'package:ffi/ffi.dart';

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

// VSIFree(void*) — for freeing strings allocated by GDAL/OSR.
typedef _CplFreeC = Void Function(Pointer<Void> ptr);
typedef _CplFreeDart = void Function(Pointer<Void> ptr);

/// Low-level access to GDAL OGR Spatial Reference (OSR) API functions.
class GdalSrs {
  late final _NewDart _new;
  late final _DestroyDart _destroy;
  late final _ImportFromEpsgDart _importFromEpsg;
  late final _ExportToWktDart _exportToWkt;
  late final _ExportToWktExDart _exportToWktEx;
  late final _GetAuthorityCodeDart _getAuthorityCode;
  late final _GetAuthorityNameDart _getAuthorityName;
  late final _IsSameDart _isSame;
  late final _CplFreeDart _cplFree;

  GdalSrs(DynamicLibrary lib) {
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

  /// Frees memory allocated by GDAL (e.g., exported WKT strings).
  void cplFree(Pointer<Void> ptr) => _cplFree(ptr);
}
