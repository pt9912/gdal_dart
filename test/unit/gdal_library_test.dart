import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/native/gdal_library.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

void main() {
  test('throws GdalLibraryLoadException for nonexistent path', () {
    expect(
      () => loadGdalLibrary(path: '/nonexistent/libgdal.so'),
      throwsA(isA<GdalLibraryLoadException>()),
    );
  });

  group(
    'with GDAL available',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      test('loads with default name', () {
        final lib = loadGdalLibrary();
        expect(lib, isNotNull);
      });
    },
  );
}
