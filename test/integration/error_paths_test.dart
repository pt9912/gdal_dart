import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:gdal_dart/src/native/gdal_library.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

final _tinyPath = '${Directory.current.path}/test/fixtures/tiny.tif';
final _invalidPath = '${Directory.current.path}/test/fixtures/not_a_tiff.bin';

void main() {
  // --- Pure Dart error tests (no GDAL required) ---

  group('loadGdalLibrary errors', () {
    test('throws for nonexistent path', () {
      expect(
        () => loadGdalLibrary(path: '/no/such/libgdal.so'),
        throwsA(isA<GdalLibraryLoadException>()),
      );
    });

    test('exception message contains the attempted path', () {
      try {
        loadGdalLibrary(path: '/bad/path.so');
        fail('should throw');
      } on GdalLibraryLoadException catch (e) {
        expect(e.message, contains('/bad/path.so'));
      }
    });
  });

  group('Gdal constructor errors', () {
    test('throws for invalid libraryPath', () {
      expect(
        () => Gdal(libraryPath: '/no/such/lib.so'),
        throwsA(isA<GdalLibraryLoadException>()),
      );
    });
  });

  // --- Integration error tests (GDAL required) ---

  group(
    'File open errors',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('throws GdalFileException for nonexistent file', () {
        expect(
          () => gdal.openGeoTiff('/nonexistent/path/file.tif'),
          throwsA(isA<GdalFileException>()),
        );
      });

      test('throws GdalFileException for invalid file format', () {
        expect(
          () => gdal.openGeoTiff(_invalidPath),
          throwsA(isA<GdalFileException>()),
        );
      });

      test('GdalFileException contains the file path', () {
        try {
          gdal.openGeoTiff('/no/such/file.tif');
          fail('should throw');
        } on GdalFileException catch (e) {
          expect(e.message, contains('/no/such/file.tif'));
          expect(e.path, '/no/such/file.tif');
        }
      });
    },
  );

  group(
    'Dataset lifecycle errors',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('width throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(() => ds.width, throwsA(isA<GdalDatasetClosedException>()));
      });

      test('height throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(() => ds.height, throwsA(isA<GdalDatasetClosedException>()));
      });

      test('bandCount throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(() => ds.bandCount, throwsA(isA<GdalDatasetClosedException>()));
      });

      test('projectionWkt throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(
            () => ds.projectionWkt,
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('geoTransform throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(
            () => ds.geoTransform,
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('band() throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(() => ds.band(1), throwsA(isA<GdalDatasetClosedException>()));
      });

      test('nativeHandle throws after close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        ds.close();
        expect(
            () => ds.nativeHandle,
            throwsA(isA<GdalDatasetClosedException>()));
      });
    },
  );

  group(
    'Band lifecycle errors',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('band properties throw after dataset close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        final band = ds.band(1);
        ds.close();

        expect(() => band.width, throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.height, throwsA(isA<GdalDatasetClosedException>()));
        expect(
            () => band.dataType, throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.noDataValue,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.blockWidth,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.blockHeight,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.tileCountX,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.tileCountY,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.overviewCount,
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('band read methods throw after dataset close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        final band = ds.band(1);
        ds.close();

        expect(() => band.readAsUint8(),
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.readAsUint16(),
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.readAsInt16(),
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.readAsFloat32(),
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.readAsFloat64(),
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => band.readBlock(0, 0),
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('tileWindow throws after dataset close', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        final band = ds.band(1);
        ds.close();
        expect(() => band.tileWindow(0, 0),
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('overview throws after dataset close', () {
        final ds = gdal.openGeoTiff(
            '${Directory.current.path}/test/fixtures/tiled.tif');
        final band = ds.band(1);
        ds.close();
        expect(() => band.overview(0),
            throwsA(isA<GdalDatasetClosedException>()));
      });
    },
  );

  group(
    'Invalid band access',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('band(0) throws', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          expect(() => ds.band(0), throwsA(isA<GdalException>()));
        } finally {
          ds.close();
        }
      });

      test('band(-1) throws', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          expect(() => ds.band(-1), throwsA(isA<GdalException>()));
        } finally {
          ds.close();
        }
      });

      test('band beyond count throws', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          expect(() => ds.band(ds.bandCount + 1),
              throwsA(isA<GdalException>()));
        } finally {
          ds.close();
        }
      });
    },
  );
}
