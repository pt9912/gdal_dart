import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/processing/geotiff_tile_processor.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

/// 4x4 Byte GeoTIFF, WGS84, origin (10, 50), pixel 0.5°, values 1-16.
final _tinyPath = '${Directory.current.path}/test/fixtures/tiny.tif';

void main() {
  group(
    'GeoTIFFTileProcessor',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;
      late GeoTIFFTileProcessorConfig config;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_tinyPath);

        // Identity projection for testing — source == view projection.
        config = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (10.0, 48.0, 12.0, 50.0),
          sourceRef: (10.0, 48.0),
          resolution: 0.5,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
        );
      });

      tearDown(() => ds.close());

      test('constructor stores config', () {
        final processor = GeoTIFFTileProcessor(config);
        expect(processor.config, same(config));
        expect(processor.globalTriangulation, isNull);
      });

      test('createGlobalTriangulation creates non-null triangulation', () {
        final processor = GeoTIFFTileProcessor(config);
        processor.createGlobalTriangulation();
        expect(processor.globalTriangulation, isNotNull);
        expect(processor.globalTriangulation!.triangles, isNotEmpty);
      });

      test('getTileData returns null for non-intersecting tile', () {
        final processor = GeoTIFFTileProcessor(config);
        processor.createGlobalTriangulation();

        // Tile far from source bounds
        final result = processor.getTileData(const TileDataParams(
          x: 0,
          y: 0,
          z: 1,
          tileSize: 256,
        ));

        expect(result, isNull);
      });

      test('getTileData returns RGBA data for intersecting tile', () {
        // Use a config with Web Mercator-ish bounds that will intersect
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        final result = processor.getTileData(const TileDataParams(
          x: 0,
          y: 0,
          z: 0,
          tileSize: 4,
        ));

        // Should return RGBA data: 4*4*4 = 64 bytes
        expect(result, isNotNull);
        expect(result, isA<Uint8List>());
        expect(result!.length, 4 * 4 * 4);
      });

      test('getTileData works without global triangulation (fallback)', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        // No createGlobalTriangulation() call

        final result = processor.getTileData(const TileDataParams(
          x: 0,
          y: 0,
          z: 0,
          tileSize: 4,
        ));

        expect(result, isNotNull);
        expect(result!.length, 4 * 4 * 4);
      });

      test('getTileData with bilinear resampling', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        final result = processor.getTileData(const TileDataParams(
          x: 0,
          y: 0,
          z: 0,
          tileSize: 4,
          resampleMethod: 'bilinear',
        ));

        expect(result, isNotNull);
        expect(result!.length, 4 * 4 * 4);
      });

      test('getTileData with colorStops', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        final stops = getColorStops(ColorMapName.viridis);
        final result = processor.getTileData(TileDataParams(
          x: 0,
          y: 0,
          z: 0,
          tileSize: 4,
          colorStops: stops,
        ));

        expect(result, isNotNull);
        expect(result!.length, 4 * 4 * 4);
      });

      test('getTileData with devicePixelRatio', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        final result = processor.getTileData(const TileDataParams(
          x: 0,
          y: 0,
          z: 0,
          tileSize: 4,
          devicePixelRatio: 2.0,
        ));

        // sampleSize = ceil(4 * 2.0) = 8
        expect(result, isNotNull);
        expect(result!.length, 8 * 8 * 4);
      });

      test('getElevationData returns null for non-intersecting tile', () {
        final processor = GeoTIFFTileProcessor(config);
        processor.createGlobalTriangulation();

        final result =
            processor.getElevationData(x: 0, y: 0, z: 1, tileSize: 4);
        expect(result, isNull);
      });

      test('getElevationData returns gridSize*gridSize floats', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        final result =
            processor.getElevationData(x: 0, y: 0, z: 0, tileSize: 4);

        // gridSize = tileSize + 1 = 5, so 5*5 = 25 floats
        expect(result, isNotNull);
        expect(result, isA<Float32List>());
        expect(result!.length, 25);
      });

      test('getElevationData without global triangulation (fallback)', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);

        final result =
            processor.getElevationData(x: 0, y: 0, z: 0, tileSize: 4);
        expect(result, isNotNull);
        expect(result!.length, 25);
      });

      test('getElevationData sanitizes noDataValue', () {
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          worldSize: 200.0,
          noDataValue: -9999.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        final result =
            processor.getElevationData(x: 0, y: 0, z: 0, tileSize: 4);
        expect(result, isNotNull);
        // All values should be finite
        for (final v in result!) {
          expect(v.isFinite, isTrue);
        }
      });

      test('overview selection falls back to base when no overviews', () {
        // Config with no overviewDatasets
        final mercConfig = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (coord) => coord,
          transformSourceMapToViewFn: (coord) => coord,
          sourceBounds: (0.0, 0.0, 100.0, 100.0),
          sourceRef: (0.0, 0.0),
          resolution: 25.0,
          imageWidth: ds.width,
          imageHeight: ds.height,
          baseDataset: ds,
          overviewDatasets: [],
          worldSize: 200.0,
        );

        final processor = GeoTIFFTileProcessor(mercConfig);
        processor.createGlobalTriangulation();

        // Should work fine without overviews
        final result = processor.getTileData(const TileDataParams(
          x: 0,
          y: 0,
          z: 0,
          tileSize: 4,
        ));
        expect(result, isNotNull);
      });
    },
  );

  group(
    'GeoTIFFTileProcessorConfig',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_tinyPath);
      });

      tearDown(() => ds.close());

      test('stores all properties', () {
        final config = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (c) => c,
          transformSourceMapToViewFn: (c) => c,
          sourceBounds: (1.0, 2.0, 3.0, 4.0),
          sourceRef: (1.0, 2.0),
          resolution: 0.5,
          imageWidth: 100,
          imageHeight: 200,
          baseDataset: ds,
          noDataValue: -9999.0,
          worldSize: 12345.0,
        );

        expect(config.sourceBounds, (1.0, 2.0, 3.0, 4.0));
        expect(config.sourceRef, (1.0, 2.0));
        expect(config.resolution, 0.5);
        expect(config.imageWidth, 100);
        expect(config.imageHeight, 200);
        expect(config.noDataValue, -9999.0);
        expect(config.worldSize, 12345.0);
        expect(config.overviewDatasets, isEmpty);
      });

      test('default worldSize is Earth circumference', () {
        final config = GeoTIFFTileProcessorConfig(
          transformViewToSourceMapFn: (c) => c,
          transformSourceMapToViewFn: (c) => c,
          sourceBounds: (0.0, 0.0, 1.0, 1.0),
          sourceRef: (0.0, 0.0),
          resolution: 1.0,
          imageWidth: 1,
          imageHeight: 1,
          baseDataset: ds,
        );

        expect(config.worldSize, closeTo(40075016.686, 1));
      });
    },
  );

  group('TileDataParams', () {
    test('stores all properties', () {
      const params = TileDataParams(
        x: 1,
        y: 2,
        z: 3,
        tileSize: 256,
        devicePixelRatio: 2.0,
        resampleMethod: 'bilinear',
      );

      expect(params.x, 1);
      expect(params.y, 2);
      expect(params.z, 3);
      expect(params.tileSize, 256);
      expect(params.devicePixelRatio, 2.0);
      expect(params.resampleMethod, 'bilinear');
      expect(params.colorStops, isNull);
    });

    test('default values', () {
      const params = TileDataParams(x: 0, y: 0, z: 0, tileSize: 256);
      expect(params.devicePixelRatio, 1.0);
      expect(params.resampleMethod, 'near');
      expect(params.colorStops, isNull);
    });
  });
}
