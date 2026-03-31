import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

/// Path to the tiny 4x4 GeoTIFF test fixture.
final _fixturePath = '${Directory.current.path}/test/fixtures/tiny.tif';

void main() {
  group(
    'GeoTiffDataset',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() {
        gdal = Gdal();
      });

      test('opens and reads dimensions', () {
        final ds = gdal.openGeoTiff(_fixturePath);
        try {
          expect(ds.width, 4);
          expect(ds.height, 4);
        } finally {
          ds.close();
        }
      });

      test('reads band count', () {
        final ds = gdal.openGeoTiff(_fixturePath);
        try {
          expect(ds.bandCount, 1);
        } finally {
          ds.close();
        }
      });

      test('reads projection WKT', () {
        final ds = gdal.openGeoTiff(_fixturePath);
        try {
          expect(ds.projectionWkt, contains('WGS 84'));
        } finally {
          ds.close();
        }
      });

      test('reads GeoTransform', () {
        final ds = gdal.openGeoTiff(_fixturePath);
        try {
          final gt = ds.geoTransform;
          expect(gt.originX, 10.0);
          expect(gt.originY, 50.0);
          expect(gt.pixelWidth, 0.5);
          expect(gt.pixelHeight, -0.5);
          expect(gt.rotationX, 0.0);
          expect(gt.rotationY, 0.0);
        } finally {
          ds.close();
        }
      });

      test('close is idempotent', () {
        final ds = gdal.openGeoTiff(_fixturePath);
        ds.close();
        ds.close(); // should not throw
        expect(ds.isClosed, isTrue);
      });

      test('throws after close', () {
        final ds = gdal.openGeoTiff(_fixturePath);
        ds.close();
        expect(() => ds.width, throwsA(isA<GdalDatasetClosedException>()));
      });

      test('throws for nonexistent file', () {
        expect(
          () => gdal.openGeoTiff('/nonexistent/file.tif'),
          throwsA(isA<GdalException>()),
        );
      });
    },
  );
}
