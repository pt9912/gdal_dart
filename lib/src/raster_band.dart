import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'geotiff_dataset.dart';
import 'model/raster_data_type.dart';
import 'model/raster_window.dart';
import 'native/gdal_api.dart';
import 'native/gdal_errors.dart';

/// A single raster band within a [GeoTiffDataset].
///
/// Does not own the native band handle — it is valid only while the
/// parent dataset is open. Accessing a band after the dataset is closed
/// throws [GdalDatasetClosedException].
class RasterBand {
  final GdalApi _api;
  final Pointer<Void> _handle;
  final GeoTiffDataset _dataset;

  /// The 1-based band index within the parent dataset.
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

  /// Reads the band (or a [window]) as [Uint8List].
  ///
  /// GDAL converts the native data type to `GDT_Byte` if needed.
  Uint8List readAsUint8({RasterWindow? window}) {
    final w = window ?? _fullWindow();
    final count = w.width * w.height;
    final buf = _readRaw(w, RasterDataType.byte_.gdalValue, 1, count);
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
    final buf = _readRaw(w, RasterDataType.uint16.gdalValue, 2, count);
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
    final buf = _readRaw(w, RasterDataType.int16.gdalValue, 2, count);
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
    final buf = _readRaw(w, RasterDataType.float32.gdalValue, 4, count);
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
    final buf = _readRaw(w, RasterDataType.float64.gdalValue, 8, count);
    try {
      return Float64List.fromList(buf.cast<Double>().asTypedList(count));
    } finally {
      calloc.free(buf);
    }
  }

  // --- Internal ---

  Pointer<Void> _readRaw(
      RasterWindow w, int gdalType, int elementSize, int count) {
    _ensureDatasetOpen();
    final buf = calloc<Uint8>(count * elementSize);
    final err = _api.rasterIO(
      _handle,
      0, // GF_Read
      w.xOffset,
      w.yOffset,
      w.width,
      w.height,
      buf.cast<Void>(),
      w.width,
      w.height,
      gdalType,
      0, // default pixel spacing
      0, // default line spacing
    );
    if (err != 0) {
      calloc.free(buf);
      throw GdalException('GDALRasterIO failed (CPLErr: $err)');
    }
    return buf.cast<Void>();
  }

  RasterWindow _fullWindow() => RasterWindow(
        xOffset: 0,
        yOffset: 0,
        width: _dataset.width,
        height: _dataset.height,
      );

  void _ensureDatasetOpen() {
    if (_dataset.isClosed) {
      throw GdalDatasetClosedException(
          'Cannot access band $index — dataset is closed');
    }
  }
}
