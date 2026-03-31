import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'model/geo_transform.dart';
import 'model/raster_data_type.dart';
import 'model/raster_window.dart';
import 'native/gdal_api.dart';
import 'native/gdal_constants.dart';
import 'native/gdal_errors.dart';

/// Creates and writes a new GeoTIFF file.
///
/// Obtained via [Gdal.createGeoTiff]. **Must be closed after use** to
/// flush data to disk — data may be lost if [close] is not called:
///
/// ```dart
/// final writer = gdal.createGeoTiff('output.tif', width: 256, height: 256);
/// writer.setGeoTransform(GeoTransform(...));
/// writer.setProjection(wktString);
/// writer.writeAsUint8(1, pixelData);
/// writer.close(); // mandatory — flushes data to disk
/// ```
///
/// Accessing any method after [close] throws [GdalDatasetClosedException].
class GeoTiffWriter {
  final GdalApi _api;
  final Pointer<Void> _handle;
  final int _width;
  final int _height;
  final int _bandCount;
  final RasterDataType _dataType;
  bool _closed = false;

  GeoTiffWriter._(
      this._api, this._handle, this._width, this._height,
      this._bandCount, this._dataType);

  /// Creates a new GeoTIFF file via the GTiff driver.
  ///
  /// Throws [GdalFileException] if creation fails.
  factory GeoTiffWriter.create(
    GdalApi api,
    String path, {
    required int width,
    required int height,
    int bandCount = 1,
    RasterDataType dataType = RasterDataType.byte_,
    Map<String, String> options = const {},
  }) {
    // Get GTiff driver.
    final driverName = 'GTiff'.toNativeUtf8(allocator: calloc);
    Pointer<Void> driver;
    try {
      driver = api.getDriverByName(driverName);
    } finally {
      calloc.free(driverName);
    }
    if (driver == nullptr) {
      throw GdalException('GTiff driver not found');
    }

    // Build creation options (null-terminated string list).
    final optionPtrs = <Pointer<Utf8>>[];
    Pointer<Pointer<Utf8>> optionList = nullptr;
    if (options.isNotEmpty) {
      optionList = calloc<Pointer<Utf8>>(options.length + 1);
      var i = 0;
      for (final entry in options.entries) {
        final ptr =
            '${entry.key}=${entry.value}'.toNativeUtf8(allocator: calloc);
        optionPtrs.add(ptr);
        optionList[i] = ptr;
        i++;
      }
      optionList[options.length] = nullptr;
    }

    final pathPtr = path.toNativeUtf8(allocator: calloc);
    try {
      final handle = api.create(
        driver, pathPtr, width, height, bandCount, dataType.gdalValue,
        optionList,
      );
      if (handle == nullptr) {
        throw GdalFileException(
            'Failed to create GeoTIFF: $path', path: path);
      }
      return GeoTiffWriter._(api, handle, width, height, bandCount, dataType);
    } finally {
      calloc.free(pathPtr);
      for (final ptr in optionPtrs) {
        calloc.free(ptr);
      }
      if (optionList != nullptr) {
        calloc.free(optionList);
      }
    }
  }

  /// Raster width in pixels.
  int get width => _width;

  /// Raster height in pixels.
  int get height => _height;

  /// Number of raster bands.
  int get bandCount => _bandCount;

  /// The data type of this dataset.
  RasterDataType get dataType => _dataType;

  /// Whether this writer has been closed.
  bool get isClosed => _closed;

  // --- Setters ---

  /// Sets the affine GeoTransform.
  void setGeoTransform(GeoTransform transform) {
    _ensureOpen();
    final buf = calloc<Double>(6);
    try {
      final values = transform.toList();
      for (var i = 0; i < 6; i++) {
        buf[i] = values[i];
      }
      final err = _api.setGeoTransform(_handle, buf);
      if (err != 0) {
        throw GdalException('Failed to set GeoTransform (CPLErr: $err)');
      }
    } finally {
      calloc.free(buf);
    }
  }

  /// Sets the projection as a WKT string.
  void setProjection(String wkt) {
    _ensureOpen();
    final ptr = wkt.toNativeUtf8(allocator: calloc);
    try {
      final err = _api.setProjection(_handle, ptr);
      if (err != 0) {
        throw GdalException('Failed to set projection (CPLErr: $err)');
      }
    } finally {
      calloc.free(ptr);
    }
  }

  /// Sets the NoData value for band at 1-based [bandIndex].
  void setNoData(int bandIndex, double value) {
    _ensureOpen();
    final bandHandle = _api.getRasterBand(_handle, bandIndex);
    if (bandHandle == nullptr) {
      throw GdalException('Failed to get band $bandIndex for setNoData');
    }
    final err = _api.setRasterNoDataValue(bandHandle, value);
    if (err != 0) {
      throw GdalException('Failed to set NoData (CPLErr: $err)');
    }
  }

  // --- Getters (read back written metadata) ---

  /// Reads back the GeoTransform that was set on this dataset.
  ///
  /// Throws [GdalException] if no GeoTransform has been set.
  GeoTransform get geoTransform {
    _ensureOpen();
    final buffer = calloc<Double>(6);
    try {
      final err = _api.getGeoTransform(_handle, buffer);
      if (err != 0) {
        throw GdalException('Failed to read GeoTransform (CPLErr: $err)');
      }
      return GeoTransform.fromList(
        List<double>.generate(6, (i) => buffer[i]),
      );
    } finally {
      calloc.free(buffer);
    }
  }

  /// Reads back the projection WKT that was set on this dataset.
  String get projectionWkt {
    _ensureOpen();
    return _api.getProjectionRef(_handle);
  }

  // --- Write operations ---

  /// Writes [Uint8List] data to band [bandIndex] (1-based).
  void writeAsUint8(int bandIndex, Uint8List data, {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.byte_);
  }

  /// Writes [Uint16List] data to band [bandIndex] (1-based).
  void writeAsUint16(int bandIndex, Uint16List data, {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.uint16);
  }

  /// Writes [Int16List] data to band [bandIndex] (1-based).
  void writeAsInt16(int bandIndex, Int16List data, {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.int16);
  }

  /// Writes [Float32List] data to band [bandIndex] (1-based).
  void writeAsFloat32(int bandIndex, Float32List data,
      {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.float32);
  }

  /// Writes [Float64List] data to band [bandIndex] (1-based).
  void writeAsFloat64(int bandIndex, Float64List data,
      {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.float64);
  }

  /// Writes [Uint32List] data to band [bandIndex] (1-based).
  void writeAsUint32(int bandIndex, Uint32List data, {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.uint32);
  }

  /// Writes [Int32List] data to band [bandIndex] (1-based).
  void writeAsInt32(int bandIndex, Int32List data, {RasterWindow? window}) {
    _writeRaw(bandIndex, window ?? _fullWindow(), data.buffer.asUint8List(),
        RasterDataType.int32_);
  }

  /// Closes the writer, flushes data, and releases the native handle.
  ///
  /// **Must be called** to ensure data is written to disk.
  /// Idempotent — calling [close] on an already closed writer is a no-op.
  void close() {
    if (!_closed) {
      _api.flushCache(_handle);
      _api.close(_handle);
      _closed = true;
    }
  }

  // --- Internal ---

  void _writeRaw(
      int bandIndex, RasterWindow w, Uint8List rawBytes, RasterDataType type) {
    _ensureOpen();
    final bandHandle = _api.getRasterBand(_handle, bandIndex);
    if (bandHandle == nullptr) {
      throw GdalException('Failed to get band $bandIndex for writing');
    }
    final buf = calloc<Uint8>(rawBytes.length);
    try {
      buf.asTypedList(rawBytes.length).setAll(0, rawBytes);
      final err = _api.rasterIO(
        bandHandle,
        gfWrite,
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
        throw GdalIOException('GDALRasterIO write failed (CPLErr: $err)');
      }
    } finally {
      calloc.free(buf);
    }
  }

  RasterWindow _fullWindow() => RasterWindow(
        xOffset: 0,
        yOffset: 0,
        width: _width,
        height: _height,
      );

  void _ensureOpen() {
    if (_closed) {
      throw GdalDatasetClosedException('Writer is already closed');
    }
  }
}
