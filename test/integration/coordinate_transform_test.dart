import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

void main() {
  group(
    'CoordinateTransform',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('transforms WGS 84 to UTM zone 32', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final ct = gdal.coordinateTransform(wgs84, utm32);
        try {
          // Munich: ~11.58°E, 48.14°N
          final (x, y) = ct.transformPoint(11.58, 48.14);
          // Expected UTM32: ~691000, ~5335000
          expect(x, closeTo(691000, 2000));
          expect(y, closeTo(5335000, 2000));
        } finally {
          ct.close();
          utm32.close();
          wgs84.close();
        }
      });

      test('transforms UTM zone 32 to WGS 84', () {
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final ct = gdal.coordinateTransform(utm32, wgs84);
        try {
          final (lon, lat) = ct.transformPoint(691000, 5334000);
          expect(lon, closeTo(11.58, 0.05));
          expect(lat, closeTo(48.14, 0.05));
        } finally {
          ct.close();
          wgs84.close();
          utm32.close();
        }
      });

      test('transforms multiple points', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final ct = gdal.coordinateTransform(wgs84, utm32);
        try {
          final results = ct.transformPoints(
            [11.0, 12.0, 13.0],
            [48.0, 49.0, 50.0],
          );
          expect(results, hasLength(3));
          for (final (x, y) in results) {
            expect(x, isNonZero);
            expect(y, isNonZero);
          }
        } finally {
          ct.close();
          utm32.close();
          wgs84.close();
        }
      });

      test('transformPoints with empty lists returns empty', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final ct = gdal.coordinateTransform(wgs84, utm32);
        try {
          expect(ct.transformPoints([], []), isEmpty);
        } finally {
          ct.close();
          utm32.close();
          wgs84.close();
        }
      });

      test('transformPoints throws for mismatched lengths', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final ct = gdal.coordinateTransform(wgs84, utm32);
        try {
          expect(
            () => ct.transformPoints([1.0], [1.0, 2.0]),
            throwsA(isA<ArgumentError>()),
          );
        } finally {
          ct.close();
          utm32.close();
          wgs84.close();
        }
      });

      test('roundtrip preserves coordinates', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final forward = gdal.coordinateTransform(wgs84, utm32);
        final inverse = gdal.coordinateTransform(utm32, wgs84);
        try {
          const origLon = 11.58;
          const origLat = 48.14;
          final (utmX, utmY) = forward.transformPoint(origLon, origLat);
          final (lon, lat) = inverse.transformPoint(utmX, utmY);
          expect(lon, closeTo(origLon, 1e-8));
          expect(lat, closeTo(origLat, 1e-8));
        } finally {
          inverse.close();
          forward.close();
          utm32.close();
          wgs84.close();
        }
      });

      test('close is idempotent', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final ct = gdal.coordinateTransform(wgs84, utm32);
        ct.close();
        ct.close(); // no throw
        expect(ct.isClosed, isTrue);
        utm32.close();
        wgs84.close();
      });

      test('transformPoint throws after close', () {
        final wgs84 = gdal.spatialReferenceFromEpsg(4326);
        final utm32 = gdal.spatialReferenceFromEpsg(32632);
        final ct = gdal.coordinateTransform(wgs84, utm32);
        ct.close();
        expect(
          () => ct.transformPoint(11.0, 48.0),
          throwsA(isA<GdalDatasetClosedException>()),
        );
        utm32.close();
        wgs84.close();
      });
    },
  );
}
