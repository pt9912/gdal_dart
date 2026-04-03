import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

void main() {
  group(
    'Gdal',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() {
        gdal = Gdal();
      });

      test('reports a non-empty version string', () {
        expect(gdal.versionString, isNotEmpty);
      });

      test('reports a numeric version number', () {
        expect(int.tryParse(gdal.versionNumber), isNotNull);
      });

      test('has registered drivers', () {
        expect(gdal.driverCount, greaterThan(0));
      });

      test('setConfigOption and getConfigOption round-trip', () {
        gdal.setConfigOption('GDAL_DART_TEST_KEY', '42');
        expect(gdal.getConfigOption('GDAL_DART_TEST_KEY'), '42');
        // Unset
        gdal.setConfigOption('GDAL_DART_TEST_KEY', null);
        expect(gdal.getConfigOption('GDAL_DART_TEST_KEY'), isNull);
      });

      test('getConfigOption returns null for unset key', () {
        expect(gdal.getConfigOption('GDAL_DART_NONEXISTENT_KEY'), isNull);
      });

      group('getOrCreateWKT', () {
        test('returns valid WKT for EPSG:4326', () {
          final wkt = gdal.getOrCreateWKT('EPSG:4326');
          expect(wkt, contains('GEOGCS'));
        });

        test('returns cached result on second call', () {
          final wkt1 = gdal.getOrCreateWKT('EPSG:32632');
          final wkt2 = gdal.getOrCreateWKT('EPSG:32632');
          expect(identical(wkt1, wkt2), isTrue);
        });

        test('cached WKT creates valid SpatialReference', () {
          final wkt = gdal.getOrCreateWKT('EPSG:4326');
          final srs = gdal.spatialReferenceFromWkt(wkt);
          expect(srs.authorityCode, '4326');
          srs.close();
        });

        test('throws on invalid format', () {
          expect(() => gdal.getOrCreateWKT('4326'),
              throwsA(isA<ArgumentError>()));
        });

        test('throws on unsupported authority', () {
          expect(() => gdal.getOrCreateWKT('CUSTOM:999'),
              throwsA(isA<ArgumentError>()));
        });

        test('throws on invalid EPSG code', () {
          expect(() => gdal.getOrCreateWKT('EPSG:abc'),
              throwsA(isA<ArgumentError>()));
        });
      });
    },
  );

  test('throws GdalLibraryLoadException for invalid path', () {
    expect(
      () => Gdal(libraryPath: '/nonexistent/libgdal.so'),
      throwsA(isA<GdalLibraryLoadException>()),
    );
  });
}
