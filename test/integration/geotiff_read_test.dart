import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

/// Path to the 4x4 Byte GeoTIFF with pixel values 1–16.
final _fixturePath = '${Directory.current.path}/test/fixtures/tiny.tif';

void main() {
  group(
    'RasterBand',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_fixturePath);
      });

      tearDown(() => ds.close());

      test('band(1) returns a valid band', () {
        final band = ds.band(1);
        expect(band.index, 1);
      });

      test('dataType is Byte', () {
        expect(ds.band(1).dataType, RasterDataType.byte_);
      });

      test('noDataValue is 0', () {
        expect(ds.band(1).noDataValue, 0.0);
      });

      test('blockSize is positive', () {
        final band = ds.band(1);
        expect(band.blockWidth, greaterThan(0));
        expect(band.blockHeight, greaterThan(0));
      });

      test('readAsUint8 returns all 16 pixels', () {
        final data = ds.band(1).readAsUint8();
        expect(data, isA<Uint8List>());
        expect(data.length, 16);
        expect(data, orderedEquals(List.generate(16, (i) => i + 1)));
      });

      test('readAsUint8 with window reads a sub-region', () {
        // Read the top-left 2x2 window → values [1,2,5,6]
        final data = ds.band(1).readAsUint8(
              window: const RasterWindow(
                  xOffset: 0, yOffset: 0, width: 2, height: 2),
            );
        expect(data.length, 4);
        expect(data, orderedEquals([1, 2, 5, 6]));
      });

      test('readAsUint8 with offset window', () {
        // Read a 2x2 window at offset (2,1) → row1:[3,4] from pixel coords
        // Row 0: [1,2,3,4], Row 1: [5,6,7,8], Row 2: [9,10,11,12]
        // Window at (2,1) 2x2 → [7,8,11,12]
        final data = ds.band(1).readAsUint8(
              window: const RasterWindow(
                  xOffset: 2, yOffset: 1, width: 2, height: 2),
            );
        expect(data, orderedEquals([7, 8, 11, 12]));
      });

      test('readAsUint16 converts Byte to Uint16', () {
        final data = ds.band(1).readAsUint16();
        expect(data, isA<Uint16List>());
        expect(data.length, 16);
        expect(data.first, 1);
        expect(data.last, 16);
      });

      test('readAsFloat32 converts Byte to Float32', () {
        final data = ds.band(1).readAsFloat32();
        expect(data, isA<Float32List>());
        expect(data.length, 16);
        expect(data.first, 1.0);
        expect(data.last, 16.0);
      });

      test('readAsFloat64 converts Byte to Float64', () {
        final data = ds.band(1).readAsFloat64();
        expect(data, isA<Float64List>());
        expect(data.length, 16);
        expect(data.first, 1.0);
        expect(data.last, 16.0);
      });

      test('throws after dataset is closed', () {
        final band = ds.band(1);
        ds.close();
        expect(
            () => band.readAsUint8(),
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('throws for invalid band index', () {
        expect(() => ds.band(99), throwsA(isA<GdalException>()));
      });
    },
  );
}
