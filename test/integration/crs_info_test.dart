import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

void main() {
  group(
    'getCRSInfo',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() {
        gdal = Gdal();
      });

      test('returns WGS 84 for EPSG:4326', () {
        final info = gdal.getCRSInfo('EPSG:4326');
        expect(info.authName, 'EPSG');
        expect(info.code, '4326');
        expect(info.name, contains('WGS 84'));
        expect(info.type, CrsType.geographic2D);
        expect(info.deprecated, isFalse);
      });

      test('returns projected type for EPSG:32632', () {
        final info = gdal.getCRSInfo('EPSG:32632');
        expect(info.type, CrsType.projected);
        expect(info.name, contains('UTM'));
      });

      test('normalizes lowercase authority', () {
        final info = gdal.getCRSInfo('epsg:4326');
        expect(info.authName, 'EPSG');
        expect(info.code, '4326');
      });

      test('returns identical object on second call (cache hit)', () {
        final info1 = gdal.getCRSInfo('EPSG:4326');
        final info2 = gdal.getCRSInfo('EPSG:4326');
        expect(identical(info1, info2), isTrue);
      });

      test('key getter returns normalized form', () {
        final info = gdal.getCRSInfo('EPSG:4326');
        expect(info.key, 'EPSG:4326');
      });

      test('provides bounding box for EPSG:32632', () {
        final info = gdal.getCRSInfo('EPSG:32632');
        expect(info.westLon, isNotNull);
        expect(info.southLat, isNotNull);
        expect(info.eastLon, isNotNull);
        expect(info.northLat, isNotNull);
      });

      test('throws ArgumentError for missing colon', () {
        expect(
          () => gdal.getCRSInfo('4326'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for missing code', () {
        expect(
          () => gdal.getCRSInfo('EPSG:'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for extra colons', () {
        expect(
          () => gdal.getCRSInfo('EPSG:4326:extra'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for non-numeric EPSG code', () {
        expect(
          () => gdal.getCRSInfo('EPSG:abc'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for unsupported authority', () {
        expect(
          () => gdal.getCRSInfo('CUSTOM:999'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws GdalException for unknown EPSG code', () {
        expect(
          () => gdal.getCRSInfo('EPSG:9999999'),
          throwsA(isA<GdalException>()),
        );
      });
    },
  );
}
