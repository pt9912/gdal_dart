import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

void main() {
  group(
    'GeoTiffWriter',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late Directory tmpDir;

      setUp(() {
        gdal = Gdal();
        tmpDir = Directory.systemTemp.createTempSync('gdal_dart_test_');
      });

      tearDown(() {
        if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      });

      String tmpPath(String name) => '${tmpDir.path}/$name';

      test('creates a Byte GeoTIFF and reads it back', () {
        final path = tmpPath('byte.tif');
        final data = Uint8List.fromList(List.generate(16, (i) => i + 1));

        final writer = gdal.createGeoTiff(path, width: 4, height: 4);
        writer.setGeoTransform(const GeoTransform(
          originX: 10.0,
          pixelWidth: 0.5,
          rotationX: 0.0,
          originY: 50.0,
          rotationY: 0.0,
          pixelHeight: -0.5,
        ));
        writer.setProjection('GEOGCS["WGS 84",'
            'DATUM["WGS_1984",'
            'SPHEROID["WGS 84",6378137,298.257223563]],'
            'PRIMEM["Greenwich",0],'
            'UNIT["degree",0.0174532925199433]]');
        writer.writeAsUint8(1, data);
        writer.setNoData(1, 0.0);
        writer.close();

        // Read back and verify.
        final ds = gdal.openGeoTiff(path);
        try {
          expect(ds.width, 4);
          expect(ds.height, 4);
          expect(ds.bandCount, 1);
          expect(ds.projectionWkt, contains('WGS'));
          expect(ds.geoTransform.originX, 10.0);
          expect(ds.geoTransform.pixelWidth, 0.5);
          expect(ds.band(1).dataType, RasterDataType.byte_);
          expect(ds.band(1).noDataValue, 0.0);
          expect(ds.band(1).readAsUint8(), orderedEquals(data));
        } finally {
          ds.close();
        }
      });

      test('creates a UInt16 multi-band GeoTIFF', () {
        final path = tmpPath('uint16_3band.tif');
        final band1 = Uint16List.fromList(List.generate(9, (i) => 100 + i));
        final band2 = Uint16List.fromList(List.generate(9, (i) => 200 + i));
        final band3 = Uint16List.fromList(List.generate(9, (i) => 300 + i));

        final writer = gdal.createGeoTiff(
          path,
          width: 3,
          height: 3,
          bandCount: 3,
          dataType: RasterDataType.uint16,
        );
        writer.writeAsUint16(1, band1);
        writer.writeAsUint16(2, band2);
        writer.writeAsUint16(3, band3);
        writer.close();

        final ds = gdal.openGeoTiff(path);
        try {
          expect(ds.bandCount, 3);
          expect(ds.band(1).readAsUint16(), orderedEquals(band1));
          expect(ds.band(2).readAsUint16(), orderedEquals(band2));
          expect(ds.band(3).readAsUint16(), orderedEquals(band3));
        } finally {
          ds.close();
        }
      });

      test('creates a Float32 GeoTIFF', () {
        final path = tmpPath('float32.tif');
        final data =
            Float32List.fromList(List.generate(4, (i) => i * 1.5));

        final writer = gdal.createGeoTiff(
          path,
          width: 2,
          height: 2,
          dataType: RasterDataType.float32,
        );
        writer.writeAsFloat32(1, data);
        writer.setNoData(1, -9999.0);
        writer.close();

        final ds = gdal.openGeoTiff(path);
        try {
          expect(ds.band(1).dataType, RasterDataType.float32);
          expect(ds.band(1).noDataValue, -9999.0);
          final read = ds.band(1).readAsFloat32();
          for (var i = 0; i < 4; i++) {
            expect(read[i], closeTo(data[i], 1e-6));
          }
        } finally {
          ds.close();
        }
      });

      test('creates a Float64 GeoTIFF', () {
        final path = tmpPath('float64.tif');
        final data =
            Float64List.fromList(List.generate(4, (i) => i * 0.123456789));

        final writer = gdal.createGeoTiff(
          path,
          width: 2,
          height: 2,
          dataType: RasterDataType.float64,
        );
        writer.writeAsFloat64(1, data);
        writer.close();

        final ds = gdal.openGeoTiff(path);
        try {
          final read = ds.band(1).readAsFloat64();
          for (var i = 0; i < 4; i++) {
            expect(read[i], closeTo(data[i], 1e-12));
          }
        } finally {
          ds.close();
        }
      });

      test('writes a sub-window', () {
        final path = tmpPath('window.tif');

        // Create 4x4, fill with 0, then write 2x2 window.
        final writer = gdal.createGeoTiff(path, width: 4, height: 4);
        writer.writeAsUint8(1, Uint8List(16)); // all zeros
        writer.writeAsUint8(
          1,
          Uint8List.fromList([10, 20, 30, 40]),
          window: const RasterWindow(
              xOffset: 1, yOffset: 1, width: 2, height: 2),
        );
        writer.close();

        final ds = gdal.openGeoTiff(path);
        try {
          final all = ds.band(1).readAsUint8();
          // Row 0: [0,0,0,0], Row 1: [0,10,20,0], Row 2: [0,30,40,0], Row 3: [0,0,0,0]
          expect(all[5], 10); // (1,1)
          expect(all[6], 20); // (2,1)
          expect(all[9], 30); // (1,2)
          expect(all[10], 40); // (2,2)
          expect(all[0], 0); // untouched
        } finally {
          ds.close();
        }
      });

      test('supports GTiff creation options', () {
        final path = tmpPath('compressed.tif');

        final writer = gdal.createGeoTiff(
          path,
          width: 32,
          height: 32,
          options: {'COMPRESS': 'DEFLATE'},
        );
        writer.writeAsUint8(1, Uint8List(32 * 32));
        writer.close();

        // Just verify the file can be opened.
        final ds = gdal.openGeoTiff(path);
        try {
          expect(ds.width, 32);
        } finally {
          ds.close();
        }
      });

      test('close is idempotent', () {
        final path = tmpPath('idempotent.tif');
        final writer = gdal.createGeoTiff(path, width: 2, height: 2);
        writer.writeAsUint8(1, Uint8List(4));
        writer.close();
        writer.close(); // should not throw
        expect(writer.isClosed, isTrue);
      });

      test('throws after close', () {
        final path = tmpPath('closed.tif');
        final writer = gdal.createGeoTiff(path, width: 2, height: 2);
        writer.close();
        expect(
          () => writer.writeAsUint8(1, Uint8List(4)),
          throwsA(isA<GdalDatasetClosedException>()),
        );
        expect(
          () => writer.setGeoTransform(
              GeoTransform.fromList([0, 1, 0, 0, 0, -1])),
          throwsA(isA<GdalDatasetClosedException>()),
        );
        expect(
          () => writer.setProjection(''),
          throwsA(isA<GdalDatasetClosedException>()),
        );
        expect(
          () => writer.setNoData(1, 0.0),
          throwsA(isA<GdalDatasetClosedException>()),
        );
      });

      test('exposes properties', () {
        final path = tmpPath('props.tif');
        final writer = gdal.createGeoTiff(
          path,
          width: 8,
          height: 6,
          bandCount: 2,
          dataType: RasterDataType.uint16,
        );
        try {
          expect(writer.width, 8);
          expect(writer.height, 6);
          expect(writer.bandCount, 2);
          expect(writer.dataType, RasterDataType.uint16);
          expect(writer.isClosed, isFalse);
        } finally {
          writer.close();
        }
      });
    },
  );
}
