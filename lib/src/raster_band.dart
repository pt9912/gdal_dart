import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'geotiff_dataset.dart';
import 'model/band_statistics.dart';
import 'model/color_interpretation.dart';
import 'model/raster_data_type.dart';
import 'model/raster_window.dart';
import 'native/gdal_api.dart';
import 'native/gdal_constants.dart';
import 'native/gdal_errors.dart';

/// A single raster band within a [GeoTiffDataset].
///
/// Does not own the native band handle — it is valid only while the
/// parent dataset is open. Accessing a band after the dataset is closed
/// throws [GdalDatasetClosedException].
///
/// Overview bands obtained via [overview] share the same lifecycle.
class RasterBand {
  final GdalApi _api;
  final Pointer<Void> _handle;
  final GeoTiffDataset _dataset;

  /// The 1-based band index within the parent dataset.
  ///
  /// Band indices in GDAL start at 1, not 0.
  final int index;

  RasterBand._(this._api, this._handle, this._dataset, this.index);

  /// Creates a [RasterBand] for [bandIndex] (1-based) on [dataset].
  factory RasterBand.fromDataset(
      GdalApi api, GeoTiffDataset dataset, int bandIndex) {
    final handle = api.getRasterBand(dataset.nativeHandle, bandIndex);
    if (handle == nullptr) {
      throw GdalException('Failed to get raster band $bandIndex');
    }
    return RasterBand._(api, handle, dataset, bandIndex);
  }

  // --- Dimensions ---

  /// Band width in pixels.
  ///
  /// Equal to the dataset width for main bands, but smaller for overviews.
  int get width {
    _ensureDatasetOpen();
    return _api.getRasterBandXSize(_handle);
  }

  /// Band height in pixels.
  ///
  /// Equal to the dataset height for main bands, but smaller for overviews.
  int get height {
    _ensureDatasetOpen();
    return _api.getRasterBandYSize(_handle);
  }

  // --- Metadata ---

  /// The GDAL data type of this band.
  RasterDataType get dataType {
    _ensureDatasetOpen();
    return RasterDataType.fromGdal(_api.getRasterDataType(_handle));
  }

  /// The NoData value, or `null` if not defined.
  double? get noDataValue {
    _ensureDatasetOpen();
    final success = calloc<Int32>();
    try {
      final value = _api.getRasterNoDataValue(_handle, success);
      return success.value == 1 ? value : null;
    } finally {
      calloc.free(success);
    }
  }

  /// Block width in pixels.
  int get blockWidth {
    _ensureDatasetOpen();
    final x = calloc<Int32>();
    final y = calloc<Int32>();
    try {
      _api.getBlockSize(_handle, x, y);
      return x.value;
    } finally {
      calloc.free(x);
      calloc.free(y);
    }
  }

  /// Block height in pixels.
  int get blockHeight {
    _ensureDatasetOpen();
    final x = calloc<Int32>();
    final y = calloc<Int32>();
    try {
      _api.getBlockSize(_handle, x, y);
      return y.value;
    } finally {
      calloc.free(x);
      calloc.free(y);
    }
  }

  // --- Typed reads (full band or window via GDALRasterIO) ---

  /// Reads the band (or a [window]) as [Uint8List].
  ///
  /// GDAL converts the native data type to `GDT_Byte` if needed.
  Uint8List readAsUint8({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.byte_);
    try {
      return Uint8List.fromList(buf.cast<Uint8>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  /// Reads the band (or a [window]) as [Uint16List].
  Uint16List readAsUint16({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.uint16);
    try {
      return Uint16List.fromList(buf.cast<Uint16>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  /// Reads the band (or a [window]) as [Int16List].
  Int16List readAsInt16({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.int16);
    try {
      return Int16List.fromList(buf.cast<Int16>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  /// Reads the band (or a [window]) as [Float32List].
  Float32List readAsFloat32({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.float32);
    try {
      return Float32List.fromList(buf.cast<Float>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  /// Reads the band (or a [window]) as [Float64List].
  Float64List readAsFloat64({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.float64);
    try {
      return Float64List.fromList(buf.cast<Double>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  /// Reads the band (or a [window]) as [Uint32List].
  Uint32List readAsUint32({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.uint32);
    try {
      return Uint32List.fromList(buf.cast<Uint32>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  /// Reads the band (or a [window]) as [Int32List].
  Int32List readAsInt32({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.int32_);
    try {
      return Int32List.fromList(buf.cast<Int32>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  // --- Resampled reads ---

  /// Reads the band (or a [window]) resampled to [outWidth] x [outHeight].
  ///
  /// GDAL performs the resampling internally via `GDALRasterIO` when the
  /// output buffer size differs from the source window size.
  Uint8List readResampledAsUint8(int outWidth, int outHeight,
      {RasterWindow? window}) {
    return _readResampled(
        window ?? _fullWindow(), outWidth, outHeight, RasterDataType.byte_,
        (buf, count) => Uint8List.fromList(buf.cast<Uint8>().asTypedList(count)));
  }

  /// Reads the band (or a [window]) resampled to [outWidth] x [outHeight]
  /// as [Float32List].
  Float32List readResampledAsFloat32(int outWidth, int outHeight,
      {RasterWindow? window}) {
    return _readResampled(
        window ?? _fullWindow(), outWidth, outHeight, RasterDataType.float32,
        (buf, count) =>
            Float32List.fromList(buf.cast<Float>().asTypedList(count)));
  }

  // --- Statistics ---

  /// Computes exact band statistics.
  ///
  /// Set [approximate] to `true` for faster approximate results.
  BandStatistics computeStatistics({bool approximate = false}) {
    _ensureDatasetOpen();
    final pMin = calloc<Double>();
    final pMax = calloc<Double>();
    final pMean = calloc<Double>();
    final pStdDev = calloc<Double>();
    try {
      final err = _api.computeRasterStatistics(
          _handle, approximate ? 1 : 0, pMin, pMax, pMean, pStdDev);
      if (err != 0) {
        throw GdalException('Failed to compute statistics (CPLErr: $err)');
      }
      return BandStatistics(
        min: pMin.value,
        max: pMax.value,
        mean: pMean.value,
        stdDev: pStdDev.value,
      );
    } finally {
      calloc.free(pMin);
      calloc.free(pMax);
      calloc.free(pMean);
      calloc.free(pStdDev);
    }
  }

  /// The color interpretation of this band (e.g., gray, red, green, blue).
  ColorInterpretation get colorInterpretation {
    _ensureDatasetOpen();
    return ColorInterpretation.fromGdal(_api.getColorInterpretation(_handle));
  }

  // --- Tile / block access ---

  /// Number of tiles in the horizontal direction.
  int get tileCountX {
    _ensureDatasetOpen();
    return (width + blockWidth - 1) ~/ blockWidth;
  }

  /// Number of tiles in the vertical direction.
  int get tileCountY {
    _ensureDatasetOpen();
    return (height + blockHeight - 1) ~/ blockHeight;
  }

  /// Returns the [RasterWindow] for the tile at [xBlock], [yBlock].
  ///
  /// Edge tiles are clamped to the band boundaries and may be smaller
  /// than [blockWidth] / [blockHeight].
  RasterWindow tileWindow(int xBlock, int yBlock) {
    _ensureDatasetOpen();
    final xOff = xBlock * blockWidth;
    final yOff = yBlock * blockHeight;
    final w = width;
    final h = height;
    return RasterWindow(
      xOffset: xOff,
      yOffset: yOff,
      width: (xOff + blockWidth > w) ? w - xOff : blockWidth,
      height: (yOff + blockHeight > h) ? h - yOff : blockHeight,
    );
  }

  /// Reads a single tile at block coordinates [xBlock], [yBlock]
  /// using `GDALReadBlock`.
  ///
  /// Returns raw bytes in the band's native [dataType]. The buffer size
  /// is always `blockWidth * blockHeight * dataType.sizeInBytes`,
  /// even for edge tiles (GDAL pads the block).
  Uint8List readBlock(int xBlock, int yBlock) {
    _ensureDatasetOpen();
    final dt = dataType;
    final bufSize = blockWidth * blockHeight * dt.sizeInBytes;
    final buf = calloc<Uint8>(bufSize);
    try {
      final err = _api.readBlock(_handle, xBlock, yBlock, buf.cast<Void>());
      if (err != 0) {
        throw GdalIOException('GDALReadBlock failed (CPLErr: $err)');
      }
      return Uint8List.fromList(buf.asTypedList(bufSize));
    } finally {
      calloc.free(buf);
    }
  }

  // --- Overviews ---

  /// Number of overview (pyramid) levels available for this band.
  int get overviewCount {
    _ensureDatasetOpen();
    return _api.getOverviewCount(_handle);
  }

  /// Returns the [RasterBand] for overview level [level] (0-based).
  ///
  /// The overview band has its own [width], [height], and [blockWidth] /
  /// [blockHeight], and supports all the same read operations.
  /// Its lifecycle is tied to the parent dataset.
  ///
  /// Throws [GdalException] if [level] is out of range.
  RasterBand overview(int level) {
    _ensureDatasetOpen();
    final handle = _api.getOverview(_handle, level);
    if (handle == nullptr) {
      throw GdalException(
          'Failed to get overview $level for band $index');
    }
    return RasterBand._(_api, handle, _dataset, index);
  }

  // --- Internal ---

  Pointer<Void> _readRaw(RasterWindow w, RasterDataType type) {
    _ensureDatasetOpen();
    final count = w.width * w.height;
    final buf = calloc<Uint8>(count * type.sizeInBytes);
    final err = _api.rasterIO(
      _handle,
      gfRead,
      w.xOffset,
      w.yOffset,
      w.width,
      w.height,
      buf.cast<Void>(),
      w.width,
      w.height,
      type.gdalValue,
      0,
      0,
    );
    if (err != 0) {
      calloc.free(buf);
      throw GdalIOException('GDALRasterIO read failed (CPLErr: $err)');
    }
    return buf.cast<Void>();
  }

  T _readResampled<T>(RasterWindow w, int outWidth, int outHeight,
      RasterDataType type, T Function(Pointer<Void> buf, int count) convert) {
    _ensureDatasetOpen();
    final count = outWidth * outHeight;
    final buf = calloc<Uint8>(count * type.sizeInBytes);
    final err = _api.rasterIO(
      _handle,
      gfRead,
      w.xOffset,
      w.yOffset,
      w.width,
      w.height,
      buf.cast<Void>(),
      outWidth,
      outHeight,
      type.gdalValue,
      0,
      0,
    );
    if (err != 0) {
      calloc.free(buf);
      throw GdalIOException('GDALRasterIO resampled read failed (CPLErr: $err)');
    }
    try {
      return convert(buf.cast<Void>(), count);
    } finally {
      calloc.free(buf);
    }
  }

  RasterWindow _fullWindow() => RasterWindow(
        xOffset: 0,
        yOffset: 0,
        width: width,
        height: height,
      );

  void _ensureDatasetOpen() {
    if (_dataset.isClosed) {
      throw GdalDatasetClosedException(
          'Cannot access band $index — dataset is closed');
    }
  }
}
