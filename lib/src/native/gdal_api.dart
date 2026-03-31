import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'gdal_memory.dart';

// --- Phase 1: Init & info ---

typedef _AllRegisterC = Void Function();
typedef _AllRegisterDart = void Function();

typedef _VersionInfoC = Pointer<Utf8> Function(Pointer<Utf8> request);
typedef _VersionInfoDart = Pointer<Utf8> Function(Pointer<Utf8> request);

typedef _GetDriverCountC = Int32 Function();
typedef _GetDriverCountDart = int Function();

// --- Phase 2: Dataset open/close & metadata ---

typedef _OpenExC = Pointer<Void> Function(
    Pointer<Utf8> filename,
    Uint32 flags,
    Pointer<Pointer<Utf8>> drivers,
    Pointer<Pointer<Utf8>> options,
    Pointer<Pointer<Utf8>> siblings);
typedef _OpenExDart = Pointer<Void> Function(
    Pointer<Utf8> filename,
    int flags,
    Pointer<Pointer<Utf8>> drivers,
    Pointer<Pointer<Utf8>> options,
    Pointer<Pointer<Utf8>> siblings);

typedef _CloseC = Void Function(Pointer<Void> ds);
typedef _CloseDart = void Function(Pointer<Void> ds);

typedef _GetRasterXSizeC = Int32 Function(Pointer<Void> ds);
typedef _GetRasterXSizeDart = int Function(Pointer<Void> ds);

typedef _GetRasterYSizeC = Int32 Function(Pointer<Void> ds);
typedef _GetRasterYSizeDart = int Function(Pointer<Void> ds);

typedef _GetRasterCountC = Int32 Function(Pointer<Void> ds);
typedef _GetRasterCountDart = int Function(Pointer<Void> ds);

typedef _GetProjectionRefC = Pointer<Utf8> Function(Pointer<Void> ds);
typedef _GetProjectionRefDart = Pointer<Utf8> Function(Pointer<Void> ds);

typedef _GetGeoTransformC = Int32 Function(
    Pointer<Void> ds, Pointer<Double> transform);
typedef _GetGeoTransformDart = int Function(
    Pointer<Void> ds, Pointer<Double> transform);

// --- Phase 3: Raster band access ---

typedef _GetRasterBandC = Pointer<Void> Function(
    Pointer<Void> ds, Int32 band);
typedef _GetRasterBandDart = Pointer<Void> Function(
    Pointer<Void> ds, int band);

typedef _GetRasterDataTypeC = Int32 Function(Pointer<Void> band);
typedef _GetRasterDataTypeDart = int Function(Pointer<Void> band);

typedef _GetRasterNoDataValueC = Double Function(
    Pointer<Void> band, Pointer<Int32> success);
typedef _GetRasterNoDataValueDart = double Function(
    Pointer<Void> band, Pointer<Int32> success);

typedef _GetBlockSizeC = Void Function(
    Pointer<Void> band, Pointer<Int32> xSize, Pointer<Int32> ySize);
typedef _GetBlockSizeDart = void Function(
    Pointer<Void> band, Pointer<Int32> xSize, Pointer<Int32> ySize);

typedef _RasterIOC = Int32 Function(
    Pointer<Void> band,
    Int32 rwFlag,
    Int32 xOff,
    Int32 yOff,
    Int32 xSize,
    Int32 ySize,
    Pointer<Void> data,
    Int32 bufXSize,
    Int32 bufYSize,
    Int32 bufType,
    Int32 pixelSpace,
    Int32 lineSpace);
typedef _RasterIODart = int Function(
    Pointer<Void> band,
    int rwFlag,
    int xOff,
    int yOff,
    int xSize,
    int ySize,
    Pointer<Void> data,
    int bufXSize,
    int bufYSize,
    int bufType,
    int pixelSpace,
    int lineSpace);

/// Low-level access to GDAL C API functions.
///
/// Uses manual [DynamicLibrary.lookupFunction] calls. The generated
/// ffigen bindings in `lib/src/bindings/` are not required for this layer.
class GdalApi {
  // Phase 1
  late final _AllRegisterDart _allRegister;
  late final _VersionInfoDart _versionInfo;
  late final _GetDriverCountDart _getDriverCount;

  // Phase 2
  late final _OpenExDart _openEx;
  late final _CloseDart _close;
  late final _GetRasterXSizeDart _getRasterXSize;
  late final _GetRasterYSizeDart _getRasterYSize;
  late final _GetRasterCountDart _getRasterCount;
  late final _GetProjectionRefDart _getProjectionRef;
  late final _GetGeoTransformDart _getGeoTransform;

  // Phase 3
  late final _GetRasterBandDart _getRasterBand;
  late final _GetRasterDataTypeDart _getRasterDataType;
  late final _GetRasterNoDataValueDart _getRasterNoDataValue;
  late final _GetBlockSizeDart _getBlockSize;
  late final _RasterIODart _rasterIO;

  GdalApi(DynamicLibrary lib) {
    // Phase 1
    _allRegister = lib
        .lookupFunction<_AllRegisterC, _AllRegisterDart>('GDALAllRegister');
    _versionInfo = lib
        .lookupFunction<_VersionInfoC, _VersionInfoDart>('GDALVersionInfo');
    _getDriverCount = lib.lookupFunction<_GetDriverCountC, _GetDriverCountDart>(
        'GDALGetDriverCount');

    // Phase 2
    _openEx = lib.lookupFunction<_OpenExC, _OpenExDart>('GDALOpenEx');
    _close = lib.lookupFunction<_CloseC, _CloseDart>('GDALClose');
    _getRasterXSize =
        lib.lookupFunction<_GetRasterXSizeC, _GetRasterXSizeDart>(
            'GDALGetRasterXSize');
    _getRasterYSize =
        lib.lookupFunction<_GetRasterYSizeC, _GetRasterYSizeDart>(
            'GDALGetRasterYSize');
    _getRasterCount =
        lib.lookupFunction<_GetRasterCountC, _GetRasterCountDart>(
            'GDALGetRasterCount');
    _getProjectionRef =
        lib.lookupFunction<_GetProjectionRefC, _GetProjectionRefDart>(
            'GDALGetProjectionRef');
    _getGeoTransform =
        lib.lookupFunction<_GetGeoTransformC, _GetGeoTransformDart>(
            'GDALGetGeoTransform');

    // Phase 3
    _getRasterBand =
        lib.lookupFunction<_GetRasterBandC, _GetRasterBandDart>(
            'GDALGetRasterBand');
    _getRasterDataType =
        lib.lookupFunction<_GetRasterDataTypeC, _GetRasterDataTypeDart>(
            'GDALGetRasterDataType');
    _getRasterNoDataValue =
        lib.lookupFunction<_GetRasterNoDataValueC, _GetRasterNoDataValueDart>(
            'GDALGetRasterNoDataValue');
    _getBlockSize =
        lib.lookupFunction<_GetBlockSizeC, _GetBlockSizeDart>(
            'GDALGetBlockSize');
    _rasterIO =
        lib.lookupFunction<_RasterIOC, _RasterIODart>('GDALRasterIO');
  }

  // --- Phase 1 ---

  /// Registers all known GDAL drivers.
  void allRegister() => _allRegister();

  /// Returns GDAL version information for the given [request].
  ///
  /// Common requests: `RELEASE_NAME`, `VERSION_NUM`, `BUILD_INFO`.
  /// The returned C string is owned by GDAL and must not be freed.
  String versionInfo(String request) {
    return withNativeString(request, (ptr) {
      return readNativeString(_versionInfo(ptr));
    });
  }

  /// Returns the number of registered GDAL drivers.
  int getDriverCount() => _getDriverCount();

  // --- Phase 2 ---

  /// Opens a dataset via GDALOpenEx. Returns a dataset handle or nullptr.
  Pointer<Void> openEx(Pointer<Utf8> filename, int flags) {
    return _openEx(filename, flags, nullptr, nullptr, nullptr);
  }

  /// Closes a dataset handle.
  void close(Pointer<Void> ds) => _close(ds);

  /// Returns the raster width in pixels.
  int getRasterXSize(Pointer<Void> ds) => _getRasterXSize(ds);

  /// Returns the raster height in pixels.
  int getRasterYSize(Pointer<Void> ds) => _getRasterYSize(ds);

  /// Returns the number of raster bands.
  int getRasterCount(Pointer<Void> ds) => _getRasterCount(ds);

  /// Returns the projection as a WKT string. Owned by GDAL.
  String getProjectionRef(Pointer<Void> ds) {
    return readNativeString(_getProjectionRef(ds));
  }

  /// Reads the affine GeoTransform into [buffer] (6 doubles).
  /// Returns a CPLErr code (0 = CE_None).
  int getGeoTransform(Pointer<Void> ds, Pointer<Double> buffer) {
    return _getGeoTransform(ds, buffer);
  }

  // --- Phase 3 ---

  /// Returns a raster band handle (1-based index). Returns nullptr on error.
  Pointer<Void> getRasterBand(Pointer<Void> ds, int band) {
    return _getRasterBand(ds, band);
  }

  /// Returns the GDALDataType enum value for a band.
  int getRasterDataType(Pointer<Void> band) => _getRasterDataType(band);

  /// Returns the NoData value. Sets [success] to 1 if defined.
  double getRasterNoDataValue(Pointer<Void> band, Pointer<Int32> success) {
    return _getRasterNoDataValue(band, success);
  }

  /// Reads the block size into [xSize] and [ySize].
  void getBlockSize(
      Pointer<Void> band, Pointer<Int32> xSize, Pointer<Int32> ySize) {
    _getBlockSize(band, xSize, ySize);
  }

  /// Reads raster data via GDALRasterIO. Returns CPLErr (0 = CE_None).
  int rasterIO(
    Pointer<Void> band,
    int rwFlag,
    int xOff,
    int yOff,
    int xSize,
    int ySize,
    Pointer<Void> data,
    int bufXSize,
    int bufYSize,
    int bufType,
    int pixelSpace,
    int lineSpace,
  ) {
    return _rasterIO(band, rwFlag, xOff, yOff, xSize, ySize, data, bufXSize,
        bufYSize, bufType, pixelSpace, lineSpace);
  }
}
