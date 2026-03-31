/// Example: Tile processing with triangulation-based reprojection.
///
/// Demonstrates how to use GeoTIFFTileProcessor to generate RGBA tiles
/// and elevation data from a GeoTIFF source.
///
/// Requires GDAL to be installed on the system.
/// Run with: dart run example/tile_processing_example.dart
library;

import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/processing/geotiff_tile_processor.dart';

void main() {
  final gdal = Gdal();
  print('GDAL ${gdal.versionString}\n');

  final dataset = gdal.openGeoTiff('test/fixtures/tiny.tif');
  try {
    _rgbaTileExample(dataset);
    _colormapExample(dataset);
    _elevationExample(dataset);
  } finally {
    dataset.close();
  }
}

/// Helper: create a processor config for the given dataset.
///
/// Uses an identity projection (source == view) for simplicity.
/// In a real application, the transform functions would use proj4
/// to convert between the source CRS and the view CRS (e.g. Web Mercator).
GeoTIFFTileProcessorConfig _makeConfig(GeoTiffDataset dataset) {
  final gt = dataset.geoTransform;
  final west = gt.originX;
  final north = gt.originY;
  final east = west + dataset.width * gt.pixelWidth;
  final south = north + dataset.height * gt.pixelHeight;

  return GeoTIFFTileProcessorConfig(
    // Identity: source projection == view projection.
    // Replace with proj4 callbacks for real reprojection.
    transformViewToSourceMapFn: (coord) => coord,
    transformSourceMapToViewFn: (coord) => coord,
    sourceBounds: (west, south, east, north),
    sourceRef: (west, south),
    resolution: gt.pixelWidth.abs(),
    imageWidth: dataset.width,
    imageHeight: dataset.height,
    baseDataset: dataset,
    // worldSize controls the tile grid. Use a value matching the
    // source extent for identity projection.
    worldSize: (east - west) * 2,
  );
}

/// Generate an RGBA tile with nearest-neighbor sampling.
void _rgbaTileExample(GeoTiffDataset dataset) {
  print('--- RGBA Tile (nearest) ---');

  final config = _makeConfig(dataset);
  final processor = GeoTIFFTileProcessor(config);
  processor.createGlobalTriangulation();

  final rgba = processor.getTileData(const TileDataParams(
    x: 0,
    y: 0,
    z: 0,
    tileSize: 4,
  ));

  if (rgba == null) {
    print('Tile does not intersect source bounds.');
    return;
  }

  print('Tile size: ${rgba.length} bytes (${rgba.length ~/ 4} pixels RGBA)');

  // Print first row of pixels.
  for (var px = 0; px < 4; px++) {
    final i = px * 4;
    print('  pixel($px,0): R=${rgba[i]} G=${rgba[i + 1]} '
        'B=${rgba[i + 2]} A=${rgba[i + 3]}');
  }
  print('');
}

/// Generate a tile with a viridis colormap applied.
void _colormapExample(GeoTiffDataset dataset) {
  print('--- Colormap Tile (viridis, bilinear) ---');

  final config = _makeConfig(dataset);
  final processor = GeoTIFFTileProcessor(config);
  processor.createGlobalTriangulation();

  final stops = getColorStops(ColorMapName.viridis);
  final rgba = processor.getTileData(TileDataParams(
    x: 0,
    y: 0,
    z: 0,
    tileSize: 4,
    resampleMethod: 'bilinear',
    colorStops: stops,
  ));

  if (rgba == null) {
    print('Tile does not intersect source bounds.');
    return;
  }

  print('Tile size: ${rgba.length} bytes');
  for (var px = 0; px < 4; px++) {
    final i = px * 4;
    print('  pixel($px,0): R=${rgba[i]} G=${rgba[i + 1]} '
        'B=${rgba[i + 2]} A=${rgba[i + 3]}');
  }
  print('');
}

/// Generate Martini-compatible elevation data.
void _elevationExample(GeoTiffDataset dataset) {
  print('--- Elevation Data (Martini grid) ---');

  final config = _makeConfig(dataset);
  final processor = GeoTIFFTileProcessor(config);
  processor.createGlobalTriangulation();

  const tileSize = 4;
  final elevation = processor.getElevationData(
    x: 0,
    y: 0,
    z: 0,
    tileSize: tileSize,
  );

  if (elevation == null) {
    print('Tile does not intersect source bounds.');
    return;
  }

  final gridSize = tileSize + 1;
  print('Grid: $gridSize x $gridSize = ${elevation.length} floats');

  // Print the grid.
  for (var row = 0; row < gridSize; row++) {
    final values = <String>[];
    for (var col = 0; col < gridSize; col++) {
      values.add(elevation[row * gridSize + col].toStringAsFixed(1).padLeft(6));
    }
    print('  row $row: ${values.join(' ')}');
  }

  // Clean up temp files if any were created.
  final tmpFile = File('${Directory.systemTemp.path}/tile_proc_example.tif');
  if (tmpFile.existsSync()) tmpFile.deleteSync();
}
