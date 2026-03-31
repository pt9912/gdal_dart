import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GdalException', () {
    test('stores message', () {
      final e = GdalException('test error');
      expect(e.message, 'test error');
    });

    test('toString includes type and message', () {
      final e = GdalException('something failed');
      expect(e.toString(), 'GdalException: something failed');
    });
  });

  group('GdalLibraryLoadException', () {
    test('is a GdalException', () {
      expect(GdalLibraryLoadException('x'), isA<GdalException>());
    });

    test('toString includes type', () {
      final e = GdalLibraryLoadException('not found');
      expect(e.toString(), 'GdalLibraryLoadException: not found');
    });
  });

  group('GdalDatasetClosedException', () {
    test('is a GdalException', () {
      expect(GdalDatasetClosedException('x'), isA<GdalException>());
    });

    test('toString includes type', () {
      final e = GdalDatasetClosedException('already closed');
      expect(e.toString(), 'GdalDatasetClosedException: already closed');
    });
  });

  group('GdalFileException', () {
    test('is a GdalException', () {
      expect(GdalFileException('x'), isA<GdalException>());
    });

    test('stores optional path', () {
      final e = GdalFileException('not found', path: '/some/file.tif');
      expect(e.path, '/some/file.tif');
      expect(e.message, 'not found');
    });

    test('path is null when not provided', () {
      final e = GdalFileException('error');
      expect(e.path, isNull);
    });

    test('toString includes type', () {
      final e = GdalFileException('fail');
      expect(e.toString(), 'GdalFileException: fail');
    });
  });

  group('GdalIOException', () {
    test('is a GdalException', () {
      expect(GdalIOException('x'), isA<GdalException>());
    });

    test('toString includes type', () {
      final e = GdalIOException('read failed');
      expect(e.toString(), 'GdalIOException: read failed');
    });
  });
}
