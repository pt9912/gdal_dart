import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

final _tinyPath = '${Directory.current.path}/test/fixtures/tiny.tif';
final _multibandPath =
    '${Directory.current.path}/test/fixtures/multiband_uint16.tif';
final _tiledPath = '${Directory.current.path}/test/fixtures/tiled.tif';

void main() {
  group(
    'Int32/Uint32 typed reads',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('readAsUint32 converts Byte to Uint32', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final data = ds.band(1).readAsUint32();
          expect(data, isA<Uint32List>());
          expect(data.length, 16);
          expect(data.first, 1);
          expect(data.last, 16);
        } finally {
          ds.close();
        }
      });

      test('readAsInt32 converts Byte to Int32', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final data = ds.band(1).readAsInt32();
          expect(data, isA<Int32List>());
          expect(data.length, 16);
          expect(data.first, 1);
          expect(data.last, 16);
        } finally {
          ds.close();
        }
      });

      test('writeAsUint32 and readAsUint32 roundtrip', () {
        final tmpDir = Directory.systemTemp.createTempSync('gdal_dart_');
        final path = '${tmpDir.path}/uint32.tif';
        try {
          final data = Uint32List.fromList([100000, 200000, 300000, 400000]);
          final writer = gdal.createGeoTiff(path,
              width: 2, height: 2, dataType: RasterDataType.uint32);
          writer.writeAsUint32(1, data);
          writer.close();

          final ds = gdal.openGeoTiff(path);
          expect(ds.band(1).readAsUint32(), orderedEquals(data));
          ds.close();
        } finally {
          tmpDir.deleteSync(recursive: true);
        }
      });

      test('writeAsInt32 and readAsInt32 roundtrip', () {
        final tmpDir = Directory.systemTemp.createTempSync('gdal_dart_');
        final path = '${tmpDir.path}/int32.tif';
        try {
          final data = Int32List.fromList([-100, 0, 100, 200]);
          final writer = gdal.createGeoTiff(path,
              width: 2, height: 2, dataType: RasterDataType.int32_);
          writer.writeAsInt32(1, data);
          writer.close();

          final ds = gdal.openGeoTiff(path);
          expect(ds.band(1).readAsInt32(), orderedEquals(data));
          ds.close();
        } finally {
          tmpDir.deleteSync(recursive: true);
        }
      });
    },
  );

  group(
    'Multi-band convenience reads',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('readAllBandsAsUint8 returns all bands', () {
        final ds = gdal.openGeoTiff(_multibandPath);
        try {
          final bands = ds.readAllBandsAsUint8();
          expect(bands.length, 3);
          for (final b in bands) {
            expect(b.length, 16);
          }
          // Band 1 starts at 100 (UInt16→Uint8 truncation)
          expect(bands[0].first, 100);
        } finally {
          ds.close();
        }
      });

      test('readAllBandsAsFloat32 returns all bands', () {
        final ds = gdal.openGeoTiff(_multibandPath);
        try {
          final bands = ds.readAllBandsAsFloat32();
          expect(bands.length, 3);
          expect(bands[0].first, 100.0);
          expect(bands[1].first, 200.0);
          expect(bands[2].first, 300.0);
        } finally {
          ds.close();
        }
      });

      test('readAllBandsAsUint8 with window', () {
        final ds = gdal.openGeoTiff(_multibandPath);
        try {
          final bands = ds.readAllBandsAsUint8(
            window: RasterWindow(
                xOffset: 0, yOffset: 0, width: 2, height: 2),
          );
          expect(bands.length, 3);
          for (final b in bands) {
            expect(b.length, 4);
          }
        } finally {
          ds.close();
        }
      });
    },
  );

  group(
    'Resampled reads',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('downsample 32x32 to 8x8', () {
        final ds = gdal.openGeoTiff(_tiledPath);
        try {
          final band = ds.band(1);
          final data = band.readResampledAsUint8(8, 8);
          expect(data.length, 64);
        } finally {
          ds.close();
        }
      });

      test('upsample 4x4 to 8x8', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final data = ds.band(1).readResampledAsUint8(8, 8);
          expect(data.length, 64);
        } finally {
          ds.close();
        }
      });

      test('readResampledAsFloat32', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final data = ds.band(1).readResampledAsFloat32(2, 2);
          expect(data, isA<Float32List>());
          expect(data.length, 4);
        } finally {
          ds.close();
        }
      });

      test('resample with window', () {
        final ds = gdal.openGeoTiff(_tiledPath);
        try {
          final data = ds.band(1).readResampledAsUint8(4, 4,
              window: RasterWindow(
                  xOffset: 0, yOffset: 0, width: 16, height: 16));
          expect(data.length, 16);
        } finally {
          ds.close();
        }
      });
    },
  );

  group(
    'Metadata',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('reads default domain metadata', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final md = ds.metadata();
          expect(md, isA<Map<String, String>>());
          // GeoTIFFs typically have at least AREA_OR_POINT
          expect(md.containsKey('AREA_OR_POINT'), isTrue);
        } finally {
          ds.close();
        }
      });

      test('reads specific metadata item', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final value = ds.metadataItem('AREA_OR_POINT');
          expect(value, isNotNull);
        } finally {
          ds.close();
        }
      });

      test('returns null for missing metadata item', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          expect(ds.metadataItem('NONEXISTENT_KEY'), isNull);
        } finally {
          ds.close();
        }
      });

      test('reads IMAGE_STRUCTURE domain', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final md = ds.metadata(domain: 'IMAGE_STRUCTURE');
          expect(md, isA<Map<String, String>>());
        } finally {
          ds.close();
        }
      });
    },
  );

  group(
    'Band statistics',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('computes exact statistics', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final stats = ds.band(1).computeStatistics();
          // Pixel values 1-16
          expect(stats.min, 1.0);
          expect(stats.max, 16.0);
          expect(stats.mean, closeTo(8.5, 0.01));
          expect(stats.stdDev, greaterThan(0));
        } finally {
          ds.close();
        }
      });

      test('computes approximate statistics', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final stats = ds.band(1).computeStatistics(approximate: true);
          expect(stats.min, lessThanOrEqualTo(1.0));
          expect(stats.max, greaterThanOrEqualTo(16.0));
        } finally {
          ds.close();
        }
      });

      test('toString is useful', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          final stats = ds.band(1).computeStatistics();
          expect(stats.toString(), contains('min:'));
          expect(stats.toString(), contains('max:'));
        } finally {
          ds.close();
        }
      });
    },
  );

  group(
    'Color interpretation',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('single-band returns gray', () {
        final ds = gdal.openGeoTiff(_tinyPath);
        try {
          expect(
              ds.band(1).colorInterpretation, ColorInterpretation.grayIndex);
        } finally {
          ds.close();
        }
      });
    },
  );

  group(
    'Generic open',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('open() works for GeoTIFF', () {
        final ds = gdal.open(_tinyPath);
        try {
          expect(ds.width, 4);
          expect(ds.height, 4);
        } finally {
          ds.close();
        }
      });

      test('open() throws for nonexistent file', () {
        expect(
          () => gdal.open('/nonexistent.tif'),
          throwsA(isA<GdalFileException>()),
        );
      });
    },
  );
}
