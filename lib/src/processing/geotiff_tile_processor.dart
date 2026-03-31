import 'dart:math' as math;
import 'dart:typed_data';

import '../geotiff_dataset.dart';
import '../model/raster_window.dart';
import 'colormap_utils.dart';
import 'normalization_utils.dart';
import 'sampling_utils.dart';
import 'triangulation.dart';

/// Configuration for [GeoTIFFTileProcessor].
class GeoTIFFTileProcessorConfig {
  /// Transforms a coordinate from view projection to source projection.
  final TransformFunction transformViewToSourceMapFn;

  /// Transforms a coordinate from source projection to view projection.
  final TransformFunction transformSourceMapToViewFn;

  /// Source bounds [west, south, east, north] in source projection.
  final (double, double, double, double) sourceBounds;

  /// Source reference point for pixel alignment.
  final (double, double) sourceRef;

  /// Source pixel resolution.
  final double resolution;

  /// Source image width in pixels.
  final int imageWidth;

  /// Source image height in pixels.
  final int imageHeight;

  /// The base (full resolution) dataset.
  final GeoTiffDataset baseDataset;

  /// Overview datasets, ordered from finest to coarsest.
  final List<GeoTiffDataset> overviewDatasets;

  /// NoData value (pixels with this value are treated as transparent).
  final double? noDataValue;

  /// Earth circumference in meters (Web Mercator default).
  final double worldSize;

  GeoTIFFTileProcessorConfig({
    required this.transformViewToSourceMapFn,
    required this.transformSourceMapToViewFn,
    required this.sourceBounds,
    required this.sourceRef,
    required this.resolution,
    required this.imageWidth,
    required this.imageHeight,
    required this.baseDataset,
    this.overviewDatasets = const [],
    this.noDataValue,
    this.worldSize = 40075016.686,
  });
}

/// Parameters for tile data generation.
class TileDataParams {
  final int x;
  final int y;
  final int z;
  final int tileSize;
  final double devicePixelRatio;
  final String resampleMethod; // 'near' or 'bilinear'
  final List<ColorStop>? colorStops;

  const TileDataParams({
    required this.x,
    required this.y,
    required this.z,
    required this.tileSize,
    this.devicePixelRatio = 1.0,
    this.resampleMethod = 'near',
    this.colorStops,
  });
}

/// Read window in pixel coordinates.
class _ReadWindow {
  final int readXMin, readXMax, readYMin, readYMax;
  final int readWidth, readHeight;
  _ReadWindow(this.readXMin, this.readXMax, this.readYMin, this.readYMax,
      this.readWidth, this.readHeight);
}

/// Processes GeoTIFF tiles with triangulation-based reprojection.
///
/// Ported from the v-map TypeScript implementation. Uses adaptive
/// triangulation to efficiently reproject raster data from arbitrary
/// source projections to the view projection (typically Web Mercator).
class GeoTIFFTileProcessor {
  final GeoTIFFTileProcessorConfig config;
  Triangulation? _globalTriangulation;

  GeoTIFFTileProcessor(this.config);

  /// Creates the global triangulation for the entire GeoTIFF extent.
  ///
  /// Call once before processing tiles to avoid per-tile triangulation.
  void createGlobalTriangulation() {
    final (srcWest, srcSouth, srcEast, srcNorth) = config.sourceBounds;

    final extBounds = calculateBounds(
      null, null,
      (srcWest, srcSouth, srcEast, srcNorth),
      config.transformSourceMapToViewFn,
    );

    final mercatorBounds = (
      extBounds.source.minX, extBounds.source.minY,
      extBounds.source.maxX, extBounds.source.maxY,
    );

    final errorThreshold = config.resolution / 2.0;
    final step = math.min(
      10.0,
      math.max(config.imageWidth, config.imageHeight) / 256.0,
    ).toInt().clamp(1, 10);

    _globalTriangulation = Triangulation(
      config.transformViewToSourceMapFn,
      mercatorBounds,
      errorThreshold: errorThreshold,
      sourceRef: config.sourceRef,
      resolution: config.resolution,
      step: step,
    );

    // Force BVH indexing.
    _globalTriangulation!.findSourceTriangleForTargetPoint((0, 0));
  }

  /// The global triangulation, or `null` if not yet created.
  Triangulation? get globalTriangulation => _globalTriangulation;

  /// Generate RGBA tile data for the given tile coordinates.
  ///
  /// Returns a [Uint8List] of length `sampleSize * sampleSize * 4` (RGBA),
  /// or `null` if the tile does not intersect the source bounds.
  Uint8List? getTileData(TileDataParams params) {
    final viewBounds = _getTileBounds(params.x, params.y, params.z);

    if (!_tileIntersectsSource(viewBounds)) return null;

    final sampleSize = (params.tileSize * params.devicePixelRatio).ceil();

    final triangulation = _globalTriangulation ??
        Triangulation(
          config.transformViewToSourceMapFn,
          viewBounds,
          errorThreshold: 0.5,
        );

    final tileSrcBounds = _calculateTileSourceBounds(viewBounds);
    final (:bestDataset, :ovWidth, :ovHeight) =
        _selectOverview(params.z, params.tileSize);

    final readWindow = _calculateReadWindow(tileSrcBounds, ovWidth, ovHeight);
    if (readWindow == null) return Uint8List(sampleSize * sampleSize * 4);

    final (:rasterBands, :arrayType) =
        _loadRasterData(bestDataset, readWindow);

    return _renderTilePixels(
      sampleSize: sampleSize,
      viewBounds: viewBounds,
      triangulation: triangulation,
      rasterBands: rasterBands,
      arrayType: arrayType,
      readWindow: readWindow,
      ovWidth: ovWidth,
      ovHeight: ovHeight,
      resampleMethod: params.resampleMethod,
      colorStops: params.colorStops,
    );
  }

  /// Get raw elevation values for a tile as [Float32List].
  ///
  /// Returns a `(tileSize+1) * (tileSize+1)` grid suitable for
  /// Martini terrain mesh generation.
  Float32List? getElevationData({
    required int x, required int y, required int z, required int tileSize,
  }) {
    final gridSize = tileSize + 1;
    final viewBounds = _getTileBounds(x, y, z);

    if (!_tileIntersectsSource(viewBounds)) return null;

    final triangulation = _globalTriangulation ??
        Triangulation(config.transformViewToSourceMapFn, viewBounds,
            errorThreshold: 0.5);

    final tileSrcBounds = _calculateTileSourceBounds(viewBounds);
    final (:bestDataset, :ovWidth, :ovHeight) =
        _selectOverview(z, tileSize);

    final readWindow = _calculateReadWindow(tileSrcBounds, ovWidth, ovHeight);
    if (readWindow == null) return Float32List(gridSize * gridSize);

    final (:rasterBands, arrayType: _) =
        _loadRasterData(bestDataset, readWindow);

    final (vW, vS, vE, vN) = viewBounds;
    final (srcWest, srcSouth, srcEast, srcNorth) = config.sourceBounds;
    final srcWidth = srcEast - srcWest;
    final srcHeight = srcNorth - srcSouth;

    final output = Float32List(gridSize * gridSize);
    TriResult? tri;

    for (var py = 0; py < tileSize; py++) {
      for (var px = 0; px < tileSize; px++) {
        final mercX = vW + (px / tileSize) * (vE - vW);
        final mercY = vN - (py / tileSize) * (vN - vS);

        tri = triangulation.findSourceTriangleForTargetPoint(
            (mercX, mercY), tri);

        if (tri != null) {
          final (srcX, srcY) =
              triangulation.applyAffineTransform(mercX, mercY, tri.transform!);

          if (srcX >= srcWest && srcX <= srcEast &&
              srcY >= srcSouth && srcY <= srcNorth) {
            final imgX = ((srcX - srcWest) / srcWidth) * ovWidth;
            final imgY = ((srcNorth - srcY) / srcHeight) * ovHeight;

            final sampleX = imgX.round() - readWindow.readXMin;
            final sampleY = imgY.round() - readWindow.readYMin;

            if (sampleX >= 0 && sampleX < readWindow.readWidth &&
                sampleY >= 0 && sampleY < readWindow.readHeight) {
              final value =
                  rasterBands[0][sampleY * readWindow.readWidth + sampleX]
                      .toDouble();
              output[py * gridSize + px] = _sanitizeElevation(value);
            }
          }
        }
      }
    }

    // Backfill borders for Martini compatibility.
    for (var row = 0; row < tileSize; row++) {
      output[row * gridSize + tileSize] = output[row * gridSize + tileSize - 1];
    }
    for (var col = 0; col <= tileSize; col++) {
      output[tileSize * gridSize + col] =
          output[(tileSize - 1) * gridSize + col];
    }

    return output;
  }

  // --- Private helpers ---

  double _sanitizeElevation(double value) {
    if (!value.isFinite) return 0;
    if (config.noDataValue != null && value == config.noDataValue) return 0;
    return value;
  }

  double _getTileSizeInMeter(int z) => config.worldSize / math.pow(2, z);

  (double, double, double, double) _getTileBounds(int x, int y, int z) {
    final tileSize = _getTileSizeInMeter(z);
    final west = -config.worldSize / 2 + x * tileSize;
    final north = config.worldSize / 2 - y * tileSize;
    return (west, north - tileSize, west + tileSize, north);
  }

  bool _tileIntersectsSource(
      (double, double, double, double) viewBounds) {
    final (vW, vS, vE, vN) = viewBounds;
    final (srcWest, srcSouth, srcEast, srcNorth) = config.sourceBounds;

    final sw = config.transformViewToSourceMapFn((vW, vS));
    final ne = config.transformViewToSourceMapFn((vE, vN));
    final nw = config.transformViewToSourceMapFn((vW, vN));
    final se = config.transformViewToSourceMapFn((vE, vS));

    final tileMinX = _min4(sw.$1, ne.$1, nw.$1, se.$1);
    final tileMaxX = _max4(sw.$1, ne.$1, nw.$1, se.$1);
    final tileMinY = _min4(sw.$2, ne.$2, nw.$2, se.$2);
    final tileMaxY = _max4(sw.$2, ne.$2, nw.$2, se.$2);

    return tileMaxX >= srcWest &&
        tileMinX <= srcEast &&
        tileMaxY >= srcSouth &&
        tileMinY <= srcNorth;
  }

  ({double tileSrcWest, double tileSrcEast,
    double tileSrcSouth, double tileSrcNorth})
  _calculateTileSourceBounds(
      (double, double, double, double) viewBounds) {
    final (vW, vS, vE, vN) = viewBounds;

    final extBounds = calculateBounds(
      config.sourceRef, config.resolution,
      (vW, vS, vE, vN), config.transformViewToSourceMapFn,
    );

    final sw = config.transformViewToSourceMapFn((vW, vS));
    final ne = config.transformViewToSourceMapFn((vE, vN));
    final nw = config.transformViewToSourceMapFn((vW, vN));
    final se = config.transformViewToSourceMapFn((vE, vS));

    return (
      tileSrcWest: _min4(extBounds.source.minX, sw.$1, ne.$1,
          math.min(nw.$1, se.$1)),
      tileSrcEast: _max4(extBounds.source.maxX, sw.$1, ne.$1,
          math.max(nw.$1, se.$1)),
      tileSrcSouth: _min4(extBounds.source.minY, sw.$2, ne.$2,
          math.min(nw.$2, se.$2)),
      tileSrcNorth: _max4(extBounds.source.maxY, sw.$2, ne.$2,
          math.max(nw.$2, se.$2)),
    );
  }

  ({GeoTiffDataset bestDataset, int ovWidth, int ovHeight}) _selectOverview(
      int z, int tileSize) {
    final base = config.baseDataset;
    if (config.overviewDatasets.isEmpty) {
      return (bestDataset: base, ovWidth: base.width, ovHeight: base.height);
    }

    final tileSizeInMeter = _getTileSizeInMeter(z);
    final tileResolution = tileSizeInMeter / tileSize;

    final allDatasets = [base, ...config.overviewDatasets];
    var bestDataset = allDatasets.last;
    var resolution = config.resolution;

    for (final ds in allDatasets) {
      final ratio = tileResolution / (resolution * 2.0);
      if (ratio <= 1.0) {
        bestDataset = ds;
        break;
      }
      resolution *= 2;
    }

    return (
      bestDataset: bestDataset,
      ovWidth: bestDataset.width,
      ovHeight: bestDataset.height,
    );
  }

  _ReadWindow? _calculateReadWindow(
    ({double tileSrcWest, double tileSrcEast,
      double tileSrcSouth, double tileSrcNorth}) tileSrcBounds,
    int ovWidth, int ovHeight,
  ) {
    final (srcWest, srcSouth, srcEast, srcNorth) = config.sourceBounds;
    final srcWidth = srcEast - srcWest;
    final srcHeight = srcNorth - srcSouth;

    final pixelXMin =
        ((tileSrcBounds.tileSrcWest - srcWest) / srcWidth * ovWidth).floor();
    final pixelXMax =
        ((tileSrcBounds.tileSrcEast - srcWest) / srcWidth * ovWidth).ceil();
    final pixelYMin =
        ((srcNorth - tileSrcBounds.tileSrcNorth) / srcHeight * ovHeight).floor();
    final pixelYMax =
        ((srcNorth - tileSrcBounds.tileSrcSouth) / srcHeight * ovHeight).ceil();

    final readXMin = (pixelXMin - 2).clamp(0, ovWidth);
    final readXMax = (pixelXMax + 2).clamp(0, ovWidth);
    final readYMin = (pixelYMin - 2).clamp(0, ovHeight);
    final readYMax = (pixelYMax + 2).clamp(0, ovHeight);

    final readWidth = readXMax - readXMin;
    final readHeight = readYMax - readYMin;
    if (readWidth <= 0 || readHeight <= 0) return null;

    return _ReadWindow(
        readXMin, readXMax, readYMin, readYMax, readWidth, readHeight);
  }

  ({List<SampleBand> rasterBands, TypedArrayType arrayType}) _loadRasterData(
    GeoTiffDataset dataset, _ReadWindow rw,
  ) {
    final window = RasterWindow(
      xOffset: rw.readXMin,
      yOffset: rw.readYMin,
      width: rw.readWidth,
      height: rw.readHeight,
    );

    final bandCount = dataset.bandCount;
    final bands = <SampleBand>[];
    TypedArrayType? arrayType;

    for (var i = 1; i <= bandCount; i++) {
      final band = dataset.band(i);
      final dt = band.dataType;

      // Determine array type from first band.
      arrayType ??= switch (dt.gdalValue) {
        1 => TypedArrayType.uint8,
        2 => TypedArrayType.uint16,
        3 => TypedArrayType.int16,
        4 => TypedArrayType.uint32,
        5 => TypedArrayType.int32,
        6 => TypedArrayType.float32,
        7 => TypedArrayType.float64,
        _ => TypedArrayType.uint8,
      };

      // Read as float64 for uniform handling; callers normalise anyway.
      final data = band.readAsFloat64(window: window);
      bands.add(data);
    }

    return (rasterBands: bands, arrayType: arrayType ?? TypedArrayType.uint8);
  }

  Uint8List _renderTilePixels({
    required int sampleSize,
    required (double, double, double, double) viewBounds,
    required Triangulation triangulation,
    required List<SampleBand> rasterBands,
    required TypedArrayType arrayType,
    required _ReadWindow readWindow,
    required int ovWidth,
    required int ovHeight,
    required String resampleMethod,
    List<ColorStop>? colorStops,
  }) {
    final (vW, vS, vE, vN) = viewBounds;
    final (srcWest, srcSouth, srcEast, srcNorth) = config.sourceBounds;
    final srcWidth = srcEast - srcWest;
    final srcHeight = srcNorth - srcSouth;

    final outputData = Uint8List(sampleSize * sampleSize * 4);
    TriResult? tri;

    for (var py = 0; py < sampleSize; py++) {
      for (var px = 0; px < sampleSize; px++) {
        final idx = (py * sampleSize + px) * 4;
        final mercX = vW + (px / sampleSize) * (vE - vW);
        final mercY = vN - (py / sampleSize) * (vN - vS);

        tri = triangulation.findSourceTriangleForTargetPoint(
            (mercX, mercY), tri);

        if (tri == null) continue;

        final (srcX, srcY) =
            triangulation.applyAffineTransform(mercX, mercY, tri.transform!);

        if (srcX < srcWest || srcX > srcEast ||
            srcY < srcSouth || srcY > srcNorth) {
          continue;
        }

        final imgX = ((srcX - srcWest) / srcWidth) * ovWidth;
        final imgY = ((srcNorth - srcY) / srcHeight) * ovHeight;

        final rgba = resampleMethod == 'near'
            ? sampleNearest(
                imgX, imgY, rasterBands, arrayType,
                readWindow.readWidth, readWindow.readHeight,
                readWindow.readXMin, readWindow.readYMin,
                colorStops: colorStops)
            : sampleBilinear(
                imgX, imgY, rasterBands, arrayType,
                readWindow.readWidth, readWindow.readHeight,
                readWindow.readXMin, readWindow.readYMin,
                colorStops: colorStops);

        if (rgba != null) {
          final (r, g, b, a) = rgba;
          outputData[idx] = r;
          outputData[idx + 1] = g;
          outputData[idx + 2] = b;
          outputData[idx + 3] = a;
        }
      }
    }

    return outputData;
  }

  static double _min4(double a, double b, double c, double d) =>
      math.min(a, math.min(b, math.min(c, d)));
  static double _max4(double a, double b, double c, double d) =>
      math.max(a, math.max(b, math.max(c, d)));
}
