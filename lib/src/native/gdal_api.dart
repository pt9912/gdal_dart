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

// --- Phase 3b: Tile reading & overviews ---

typedef _GetRasterBandXSizeC = Int32 Function(Pointer<Void> band);
typedef _GetRasterBandXSizeDart = int Function(Pointer<Void> band);

typedef _GetRasterBandYSizeC = Int32 Function(Pointer<Void> band);
typedef _GetRasterBandYSizeDart = int Function(Pointer<Void> band);

typedef _ReadBlockC = Int32 Function(
    Pointer<Void> band, Int32 xBlock, Int32 yBlock, Pointer<Void> buf);
typedef _ReadBlockDart = int Function(
    Pointer<Void> band, int xBlock, int yBlock, Pointer<Void> buf);

typedef _GetOverviewCountC = Int32 Function(Pointer<Void> band);
typedef _GetOverviewCountDart = int Function(Pointer<Void> band);

typedef _GetOverviewC = Pointer<Void> Function(
    Pointer<Void> band, Int32 index);
typedef _GetOverviewDart = Pointer<Void> Function(
    Pointer<Void> band, int index);

// --- Phase 5: Dataset creation & writing ---

typedef _GetDriverByNameC = Pointer<Void> Function(Pointer<Utf8> name);
typedef _GetDriverByNameDart = Pointer<Void> Function(Pointer<Utf8> name);

typedef _CreateC = Pointer<Void> Function(
    Pointer<Void> driver,
    Pointer<Utf8> filename,
    Int32 xSize,
    Int32 ySize,
    Int32 bands,
    Int32 eType,
    Pointer<Pointer<Utf8>> options);
typedef _CreateDart = Pointer<Void> Function(
    Pointer<Void> driver,
    Pointer<Utf8> filename,
    int xSize,
    int ySize,
    int bands,
    int eType,
    Pointer<Pointer<Utf8>> options);

typedef _SetGeoTransformC = Int32 Function(
    Pointer<Void> ds, Pointer<Double> transform);
typedef _SetGeoTransformDart = int Function(
    Pointer<Void> ds, Pointer<Double> transform);

typedef _SetProjectionC = Int32 Function(
    Pointer<Void> ds, Pointer<Utf8> wkt);
typedef _SetProjectionDart = int Function(
    Pointer<Void> ds, Pointer<Utf8> wkt);

typedef _SetRasterNoDataValueC = Int32 Function(
    Pointer<Void> band, Double value);
typedef _SetRasterNoDataValueDart = int Function(
    Pointer<Void> band, double value);

typedef _FlushCacheC = Void Function(Pointer<Void> ds);
typedef _FlushCacheDart = void Function(Pointer<Void> ds);

// --- Phase 7: Metadata, statistics, color interpretation ---

typedef _GetMetadataC = Pointer<Pointer<Utf8>> Function(
    Pointer<Void> obj, Pointer<Utf8> domain);
typedef _GetMetadataDart = Pointer<Pointer<Utf8>> Function(
    Pointer<Void> obj, Pointer<Utf8> domain);

typedef _GetMetadataItemC = Pointer<Utf8> Function(
    Pointer<Void> obj, Pointer<Utf8> name, Pointer<Utf8> domain);
typedef _GetMetadataItemDart = Pointer<Utf8> Function(
    Pointer<Void> obj, Pointer<Utf8> name, Pointer<Utf8> domain);

typedef _ComputeRasterStatisticsC = Int32 Function(
    Pointer<Void> band,
    Int32 approxOK,
    Pointer<Double> min,
    Pointer<Double> max,
    Pointer<Double> mean,
    Pointer<Double> stdDev,
    Pointer<Void> progress,
    Pointer<Void> progressData);
typedef _ComputeRasterStatisticsDart = int Function(
    Pointer<Void> band,
    int approxOK,
    Pointer<Double> min,
    Pointer<Double> max,
    Pointer<Double> mean,
    Pointer<Double> stdDev,
    Pointer<Void> progress,
    Pointer<Void> progressData);

typedef _GetRasterColorInterpretationC = Int32 Function(Pointer<Void> band);
typedef _GetRasterColorInterpretationDart = int Function(Pointer<Void> band);

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

  // Phase 7
  late final _GetMetadataDart _getMetadata;
  late final _GetMetadataItemDart _getMetadataItem;
  late final _ComputeRasterStatisticsDart _computeRasterStatistics;
  late final _GetRasterColorInterpretationDart _getColorInterpretation;

  // Phase 5
  late final _GetDriverByNameDart _getDriverByName;
  late final _CreateDart _create;
  late final _SetGeoTransformDart _setGeoTransform;
  late final _SetProjectionDart _setProjection;
  late final _SetRasterNoDataValueDart _setRasterNoDataValue;
  late final _FlushCacheDart _flushCache;

  // Phase 3b
  late final _GetRasterBandXSizeDart _getRasterBandXSize;
  late final _GetRasterBandYSizeDart _getRasterBandYSize;
  late final _ReadBlockDart _readBlock;
  late final _GetOverviewCountDart _getOverviewCount;
  late final _GetOverviewDart _getOverview;

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

    // Phase 3b
    _getRasterBandXSize =
        lib.lookupFunction<_GetRasterBandXSizeC, _GetRasterBandXSizeDart>(
            'GDALGetRasterBandXSize');
    _getRasterBandYSize =
        lib.lookupFunction<_GetRasterBandYSizeC, _GetRasterBandYSizeDart>(
            'GDALGetRasterBandYSize');
    _readBlock =
        lib.lookupFunction<_ReadBlockC, _ReadBlockDart>('GDALReadBlock');
    _getOverviewCount =
        lib.lookupFunction<_GetOverviewCountC, _GetOverviewCountDart>(
            'GDALGetOverviewCount');
    _getOverview =
        lib.lookupFunction<_GetOverviewC, _GetOverviewDart>('GDALGetOverview');

    // Phase 5
    _getDriverByName =
        lib.lookupFunction<_GetDriverByNameC, _GetDriverByNameDart>(
            'GDALGetDriverByName');
    _create = lib.lookupFunction<_CreateC, _CreateDart>('GDALCreate');
    _setGeoTransform =
        lib.lookupFunction<_SetGeoTransformC, _SetGeoTransformDart>(
            'GDALSetGeoTransform');
    _setProjection =
        lib.lookupFunction<_SetProjectionC, _SetProjectionDart>(
            'GDALSetProjection');
    _setRasterNoDataValue = lib.lookupFunction<_SetRasterNoDataValueC,
        _SetRasterNoDataValueDart>('GDALSetRasterNoDataValue');
    _flushCache =
        lib.lookupFunction<_FlushCacheC, _FlushCacheDart>('GDALFlushCache');

    // Phase 7
    _getMetadata =
        lib.lookupFunction<_GetMetadataC, _GetMetadataDart>('GDALGetMetadata');
    _getMetadataItem =
        lib.lookupFunction<_GetMetadataItemC, _GetMetadataItemDart>(
            'GDALGetMetadataItem');
    _computeRasterStatistics = lib.lookupFunction<
        _ComputeRasterStatisticsC,
        _ComputeRasterStatisticsDart>('GDALComputeRasterStatistics');
    _getColorInterpretation = lib.lookupFunction<
        _GetRasterColorInterpretationC,
        _GetRasterColorInterpretationDart>('GDALGetRasterColorInterpretation');
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

  // --- Phase 3b ---

  /// Returns the raster band width in pixels.
  int getRasterBandXSize(Pointer<Void> band) => _getRasterBandXSize(band);

  /// Returns the raster band height in pixels.
  int getRasterBandYSize(Pointer<Void> band) => _getRasterBandYSize(band);

  /// Reads a single block at [xBlock], [yBlock] into [buf].
  /// Returns CPLErr (0 = CE_None).
  int readBlock(Pointer<Void> band, int xBlock, int yBlock, Pointer<Void> buf) {
    return _readBlock(band, xBlock, yBlock, buf);
  }

  /// Returns the number of overview levels.
  int getOverviewCount(Pointer<Void> band) => _getOverviewCount(band);

  /// Returns the overview band handle at [index] (0-based). Nullptr on error.
  Pointer<Void> getOverview(Pointer<Void> band, int index) {
    return _getOverview(band, index);
  }

  // --- Phase 5 ---

  /// Returns a driver handle by name (e.g., `"GTiff"`). Nullptr if not found.
  Pointer<Void> getDriverByName(Pointer<Utf8> name) {
    return _getDriverByName(name);
  }

  /// Creates a new dataset. Returns a dataset handle or nullptr.
  Pointer<Void> create(
    Pointer<Void> driver,
    Pointer<Utf8> filename,
    int xSize,
    int ySize,
    int bands,
    int eType,
    Pointer<Pointer<Utf8>> options,
  ) {
    return _create(driver, filename, xSize, ySize, bands, eType, options);
  }

  /// Sets the affine GeoTransform. Returns CPLErr (0 = CE_None).
  int setGeoTransform(Pointer<Void> ds, Pointer<Double> transform) {
    return _setGeoTransform(ds, transform);
  }

  /// Sets the projection WKT. Returns CPLErr (0 = CE_None).
  int setProjection(Pointer<Void> ds, Pointer<Utf8> wkt) {
    return _setProjection(ds, wkt);
  }

  /// Sets the NoData value on a band. Returns CPLErr (0 = CE_None).
  int setRasterNoDataValue(Pointer<Void> band, double value) {
    return _setRasterNoDataValue(band, value);
  }

  /// Flushes pending writes to disk.
  void flushCache(Pointer<Void> ds) => _flushCache(ds);

  // --- Phase 7 ---

  /// Returns metadata as a null-terminated string list. Owned by GDAL.
  Pointer<Pointer<Utf8>> getMetadata(Pointer<Void> obj, Pointer<Utf8> domain) {
    return _getMetadata(obj, domain);
  }

  /// Returns a single metadata item. Owned by GDAL. Nullptr if missing.
  Pointer<Utf8> getMetadataItem(
      Pointer<Void> obj, Pointer<Utf8> name, Pointer<Utf8> domain) {
    return _getMetadataItem(obj, name, domain);
  }

  /// Computes band statistics. Returns CPLErr (0 = CE_None).
  int computeRasterStatistics(
    Pointer<Void> band,
    int approxOK,
    Pointer<Double> min,
    Pointer<Double> max,
    Pointer<Double> mean,
    Pointer<Double> stdDev,
  ) {
    return _computeRasterStatistics(
        band, approxOK, min, max, mean, stdDev, nullptr, nullptr);
  }

  /// Returns the GDALColorInterp enum value for a band.
  int getColorInterpretation(Pointer<Void> band) =>
      _getColorInterpretation(band);
}
