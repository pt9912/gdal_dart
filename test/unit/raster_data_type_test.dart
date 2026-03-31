import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('RasterDataType', () {
    test('fromGdal maps known values', () {
      expect(RasterDataType.fromGdal(1), RasterDataType.byte_);
      expect(RasterDataType.fromGdal(2), RasterDataType.uint16);
      expect(RasterDataType.fromGdal(3), RasterDataType.int16);
      expect(RasterDataType.fromGdal(6), RasterDataType.float32);
      expect(RasterDataType.fromGdal(7), RasterDataType.float64);
    });

    test('fromGdal returns unknown for unrecognized value', () {
      expect(RasterDataType.fromGdal(99), RasterDataType.unknown);
    });

    test('sizeInBytes is correct', () {
      expect(RasterDataType.byte_.sizeInBytes, 1);
      expect(RasterDataType.uint16.sizeInBytes, 2);
      expect(RasterDataType.int16.sizeInBytes, 2);
      expect(RasterDataType.int32_.sizeInBytes, 4);
      expect(RasterDataType.float32.sizeInBytes, 4);
      expect(RasterDataType.float64.sizeInBytes, 8);
      expect(RasterDataType.unknown.sizeInBytes, 0);
    });
  });
}
