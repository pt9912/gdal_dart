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
}
