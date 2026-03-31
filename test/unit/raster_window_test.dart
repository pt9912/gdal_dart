import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('RasterWindow', () {
    test('stores all fields', () {
      final w = RasterWindow(xOffset: 1, yOffset: 2, width: 3, height: 4);
      expect(w.xOffset, 1);
      expect(w.yOffset, 2);
      expect(w.width, 3);
      expect(w.height, 4);
    });

    test('equality', () {
      final a = RasterWindow(xOffset: 0, yOffset: 0, width: 4, height: 4);
      final b = RasterWindow(xOffset: 0, yOffset: 0, width: 4, height: 4);
      final c = RasterWindow(xOffset: 1, yOffset: 0, width: 4, height: 4);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('toString contains fields', () {
      final w = RasterWindow(xOffset: 1, yOffset: 2, width: 3, height: 4);
      expect(w.toString(), contains('xOffset: 1'));
      expect(w.toString(), contains('height: 4'));
    });

    test('allows zero offsets', () {
      final w = RasterWindow(xOffset: 0, yOffset: 0, width: 1, height: 1);
      expect(w.xOffset, 0);
      expect(w.yOffset, 0);
    });
  });
}
