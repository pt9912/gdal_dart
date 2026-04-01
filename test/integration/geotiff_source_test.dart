import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

final _tinyPath = '${Directory.current.path}/test/fixtures/tiny.tif';

void main() {
  group(
    'GeoTiffSource',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('opens and reads basic metadata', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          expect(source.width, 4);
          expect(source.height, 4);
          expect(source.bandCount, 1);
          expect(source.fromProjection, 'EPSG:4326');
        } finally {
          source.close();
        }
      });

      test('sourceBounds are computed from GeoTransform', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          final (west, south, east, north) = source.sourceBounds;
          // tiny.tif is a 4x4 pixel image at EPSG:4326
          expect(west.isFinite, isTrue);
          expect(south.isFinite, isTrue);
          expect(east, greaterThan(west));
          expect(north, greaterThan(south));
        } finally {
          source.close();
        }
      });

      test('wgs84Bounds match sourceBounds for EPSG:4326 data', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          // For a WGS 84 source, WGS 84 bounds should equal source bounds.
          expect(source.wgs84Bounds, equals(source.sourceBounds));
        } finally {
          source.close();
        }
      });

      test('transformToWgs84 is identity for EPSG:4326', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          final (lon, lat) = source.transformToWgs84(11.0, 48.0);
          expect(lon, 11.0);
          expect(lat, 48.0);
        } finally {
          source.close();
        }
      });

      test('resolution is positive', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          expect(source.resolution, greaterThan(0));
        } finally {
          source.close();
        }
      });

      test('geoTransform is populated', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          expect(source.geoTransform.pixelWidth, isNonZero);
          expect(source.geoTransform.pixelHeight, isNonZero);
        } finally {
          source.close();
        }
      });

      test('band() returns a valid RasterBand', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        try {
          final band = source.band(1);
          expect(band.width, source.width);
          expect(band.height, source.height);
        } finally {
          source.close();
        }
      });

      test('nodata override works', () {
        final source = gdal.openGeoTiffSource(_tinyPath, nodata: -9999);
        try {
          expect(source.noDataValue, -9999);
        } finally {
          source.close();
        }
      });

      test('close is idempotent', () {
        final source = gdal.openGeoTiffSource(_tinyPath);
        source.close();
        source.close(); // should not throw
      });
    },
  );

  group(
    'GeoTiffSource with projected data',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('creates UTM file and verifies WGS 84 bounds', () {
        // Create a small GeoTIFF in UTM zone 32 to test reprojection.
        final tmpDir = Directory.systemTemp.createTempSync('gdal_source_test');
        final utmPath = '${tmpDir.path}/utm32.tif';

        try {
          final writer = gdal.createGeoTiff(
            utmPath,
            width: 4,
            height: 4,
          );
          // Munich area in UTM32: ~690000, 5330000
          writer.setGeoTransform(GeoTransform(
            originX: 690000,
            pixelWidth: 1000,
            rotationX: 0,
            originY: 5334000,
            rotationY: 0,
            pixelHeight: -1000,
          ));

          final wgs84 = gdal.spatialReferenceFromEpsg(32632);
          writer.setProjection(wgs84.toWkt());
          wgs84.close();

          writer.close();

          // Now open as GeoTiffSource.
          final source = gdal.openGeoTiffSource(utmPath);
          try {
            expect(source.fromProjection, 'EPSG:32632');

            final (west, south, east, north) = source.wgs84Bounds;
            // Should be somewhere near Munich (~11°E, 48°N).
            expect(west, closeTo(11.5, 1.0));
            expect(east, closeTo(12.0, 1.0));
            expect(south, closeTo(48.0, 0.5));
            expect(north, closeTo(48.2, 0.5));

            // transformToWgs84 should work.
            final (lon, lat) = source.transformToWgs84(691000, 5334000);
            expect(lon, closeTo(11.58, 0.1));
            expect(lat, closeTo(48.14, 0.1));
          } finally {
            source.close();
          }
        } finally {
          tmpDir.deleteSync(recursive: true);
        }
      });
    },
  );
}
