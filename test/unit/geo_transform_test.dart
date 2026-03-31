import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GeoTransform', () {
    test('stores all coefficients', () {
      final gt = GeoTransform(
        originX: 10.0,
        pixelWidth: 0.5,
        rotationX: 0.0,
        originY: 50.0,
        rotationY: 0.0,
        pixelHeight: -0.5,
      );
      expect(gt.originX, 10.0);
      expect(gt.pixelWidth, 0.5);
      expect(gt.rotationX, 0.0);
      expect(gt.originY, 50.0);
      expect(gt.rotationY, 0.0);
      expect(gt.pixelHeight, -0.5);
    });

    test('fromList requires exactly 6 values', () {
      expect(() => GeoTransform.fromList([1.0, 2.0]), throwsArgumentError);
    });

    test('fromList roundtrips via toList', () {
      final values = [10.0, 0.5, 0.0, 50.0, 0.0, -0.5];
      final gt = GeoTransform.fromList(values);
      expect(gt.toList(), values);
    });

    test('equality and hashCode', () {
      final a = GeoTransform.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
      final b = GeoTransform.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
      final c = GeoTransform.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 7.0]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('toString contains coefficients', () {
      final gt = GeoTransform.fromList([10.0, 0.5, 0.0, 50.0, 0.0, -0.5]);
      expect(gt.toString(), contains('originX: 10.0'));
      expect(gt.toString(), contains('pixelHeight: -0.5'));
    });
  });
}
