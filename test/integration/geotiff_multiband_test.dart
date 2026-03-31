import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

/// 4x4, 3 bands UInt16. Band N has values N*100 .. N*100+15.
final _multibandPath =
    '${Directory.current.path}/test/fixtures/multiband_uint16.tif';

/// 4x4, 1 band Float32. Values 0.0, 0.5, 1.0, ..., 7.5.
final _float32Path = '${Directory.current.path}/test/fixtures/float32.tif';

void main() {
  group(
    'Multi-band UInt16',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_multibandPath);
      });

      tearDown(() => ds.close());

      test('has 3 bands', () {
        expect(ds.bandCount, 3);
      });

      test('all bands are UInt16', () {
        for (var i = 1; i <= 3; i++) {
          expect(ds.band(i).dataType, RasterDataType.uint16);
        }
      });

      test('band 1 readAsUint16 returns values 100-115', () {
        final data = ds.band(1).readAsUint16();
        expect(data, isA<Uint16List>());
        expect(data.length, 16);
        expect(data, orderedEquals(List.generate(16, (i) => 100 + i)));
      });

      test('band 2 readAsUint16 returns values 200-215', () {
        final data = ds.band(2).readAsUint16();
        expect(data, orderedEquals(List.generate(16, (i) => 200 + i)));
      });

      test('band 3 readAsUint16 returns values 300-315', () {
        final data = ds.band(3).readAsUint16();
        expect(data, orderedEquals(List.generate(16, (i) => 300 + i)));
      });

      test('readAsFloat64 converts UInt16 to Float64', () {
        final data = ds.band(1).readAsFloat64();
        expect(data, isA<Float64List>());
        expect(data.first, 100.0);
        expect(data.last, 115.0);
      });

      test('readAsInt16 reads UInt16 data', () {
        final data = ds.band(1).readAsInt16();
        expect(data, isA<Int16List>());
        expect(data.length, 16);
        // UInt16 values 100-115 fit in Int16 range
        expect(data.first, 100);
        expect(data.last, 115);
      });

      test('windowed read across bands', () {
        const window =
            RasterWindow(xOffset: 1, yOffset: 1, width: 2, height: 2);
        // Band 1 row-major: 100..103, 104..107, 108..111, 112..115
        // Window at (1,1) 2x2 → [105,106,109,110]
        final data = ds.band(1).readAsUint16(window: window);
        expect(data, orderedEquals([105, 106, 109, 110]));
      });

      test('noDataValue is 0 on all bands', () {
        for (var i = 1; i <= 3; i++) {
          expect(ds.band(i).noDataValue, 0.0);
        }
      });
    },
  );

  group(
    'Float32 single-band',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_float32Path);
      });

      tearDown(() => ds.close());

      test('dataType is Float32', () {
        expect(ds.band(1).dataType, RasterDataType.float32);
      });

      test('readAsFloat32 returns known values', () {
        final data = ds.band(1).readAsFloat32();
        expect(data, isA<Float32List>());
        expect(data.length, 16);
        expect(data.first, 0.0);
        expect(data[1], closeTo(0.5, 1e-6));
        expect(data.last, closeTo(7.5, 1e-6));
      });

      test('readAsFloat64 preserves float precision', () {
        final data = ds.band(1).readAsFloat64();
        expect(data, isA<Float64List>());
        expect(data[1], closeTo(0.5, 1e-6));
      });

      test('readAsUint8 truncates float values', () {
        final data = ds.band(1).readAsUint8();
        // 0.0→0, 0.5→0, 1.0→1, 1.5→2, ..., 7.5→8 (GDAL rounds)
        expect(data.first, 0);
        expect(data.length, 16);
      });

      test('noDataValue is -9999', () {
        expect(ds.band(1).noDataValue, -9999.0);
      });
    },
  );
}
