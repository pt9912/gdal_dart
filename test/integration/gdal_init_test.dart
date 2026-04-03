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
    },
  );

  test('throws GdalLibraryLoadException for invalid path', () {
    expect(
      () => Gdal(libraryPath: '/nonexistent/libgdal.so'),
      throwsA(isA<GdalLibraryLoadException>()),
    );
  });
}
