import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

/// 32x32 Byte GeoTIFF, 16x16 tiles, 1 overview (16x16).
/// Pixel value = row number (0-31).
final _tiledPath = '${Directory.current.path}/test/fixtures/tiled.tif';

/// 4x4 Byte GeoTIFF (strip-based), pixel values 1-16.
final _tinyPath = '${Directory.current.path}/test/fixtures/tiny.tif';

void main() {
  group(
    'Tile access',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_tiledPath);
      });

      tearDown(() => ds.close());

      test('band has correct dimensions', () {
        final band = ds.band(1);
        expect(band.width, 32);
        expect(band.height, 32);
      });

      test('block size is 16x16', () {
        final band = ds.band(1);
        expect(band.blockWidth, 16);
        expect(band.blockHeight, 16);
      });

      test('tileCount is 2x2', () {
        final band = ds.band(1);
        expect(band.tileCountX, 2);
        expect(band.tileCountY, 2);
      });

      test('tileWindow returns correct coordinates', () {
        final band = ds.band(1);
        final w00 = band.tileWindow(0, 0);
        expect(w00.xOffset, 0);
        expect(w00.yOffset, 0);
        expect(w00.width, 16);
        expect(w00.height, 16);

        final w10 = band.tileWindow(1, 0);
        expect(w10.xOffset, 16);
        expect(w10.yOffset, 0);

        final w01 = band.tileWindow(0, 1);
        expect(w01.xOffset, 0);
        expect(w01.yOffset, 16);
      });

      test('readBlock returns block-sized data', () {
        final band = ds.band(1);
        final block = band.readBlock(0, 0);
        // 16x16 block, Byte type → 256 bytes
        expect(block, isA<Uint8List>());
        expect(block.length, 256);
      });

      test('readBlock tile (0,0) contains row values 0-15', () {
        final band = ds.band(1);
        final block = band.readBlock(0, 0);
        // First row of tile (0,0): all pixels = row 0
        expect(block.sublist(0, 16), everyElement(0));
        // Last row of tile (0,0): all pixels = row 15
        expect(block.sublist(15 * 16, 16 * 16), everyElement(15));
      });

      test('readBlock tile (0,1) contains row values 16-31', () {
        final band = ds.band(1);
        final block = band.readBlock(0, 1);
        // First row of tile (0,1): all pixels = row 16
        expect(block.sublist(0, 16), everyElement(16));
        // Last row of tile (0,1): all pixels = row 31
        expect(block.sublist(15 * 16, 16 * 16), everyElement(31));
      });

      test('readAsUint8 with tileWindow reads same as readBlock', () {
        final band = ds.band(1);
        final blockData = band.readBlock(0, 0);
        final windowData = band.readAsUint8(window: band.tileWindow(0, 0));
        // Both should contain the same pixel values
        expect(windowData.length, 256);
        expect(windowData, orderedEquals(blockData));
      });
    },
  );

  group(
    'Tile access on strip-based file',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_tinyPath);
      });

      tearDown(() => ds.close());

      test('tileCount is 1x1 for small strip file', () {
        final band = ds.band(1);
        // Strip-based file: block = full width × some strip height
        // For a 4x4 file, typically block = 4×4 → 1×1 tile grid
        expect(band.tileCountX, 1);
        expect(band.tileCountY, 1);
      });

      test('readBlock reads the full strip', () {
        final band = ds.band(1);
        final block = band.readBlock(0, 0);
        // Block contains at least the 16 pixel values
        expect(block.length, greaterThanOrEqualTo(16));
        expect(block.sublist(0, 16), orderedEquals(List.generate(16, (i) => i + 1)));
      });
    },
  );

  group(
    'Overview access',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_tiledPath);
      });

      tearDown(() => ds.close());

      test('overviewCount is 1', () {
        expect(ds.band(1).overviewCount, 1);
      });

      test('overview(0) has half the dimensions', () {
        final ov = ds.band(1).overview(0);
        expect(ov.width, 16);
        expect(ov.height, 16);
      });

      test('overview band reads data', () {
        final ov = ds.band(1).overview(0);
        final data = ov.readAsUint8();
        expect(data, isA<Uint8List>());
        expect(data.length, 256); // 16x16
      });

      test('overview preserves data type', () {
        final ov = ds.band(1).overview(0);
        expect(ov.dataType, RasterDataType.byte_);
      });

      test('overview has its own block size', () {
        final ov = ds.band(1).overview(0);
        expect(ov.blockWidth, greaterThan(0));
        expect(ov.blockHeight, greaterThan(0));
      });

      test('overview readAsUint8 with window', () {
        final ov = ds.band(1).overview(0);
        final data = ov.readAsUint8(
          window: const RasterWindow(
              xOffset: 0, yOffset: 0, width: 4, height: 4),
        );
        expect(data.length, 16);
      });

      test('throws for invalid overview index', () {
        expect(
          () => ds.band(1).overview(99),
          throwsA(isA<GdalException>()),
        );
      });

      test('no overviews on tiny file', () {
        final tiny = gdal.openGeoTiff(
            '${Directory.current.path}/test/fixtures/tiny.tif');
        try {
          expect(tiny.band(1).overviewCount, 0);
        } finally {
          tiny.close();
        }
      });
    },
  );
}
