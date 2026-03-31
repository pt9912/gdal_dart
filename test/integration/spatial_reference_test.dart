import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

final _tinyPath = '${Directory.current.path}/test/fixtures/tiny.tif';

void main() {
  group(
    'SpatialReference from EPSG',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('creates from EPSG:4326', () {
        final srs = gdal.spatialReferenceFromEpsg(4326);
        try {
          expect(srs.isClosed, isFalse);
          expect(srs.authorityName, 'EPSG');
          expect(srs.authorityCode, '4326');
        } finally {
          srs.close();
        }
      });

      test('creates from EPSG:32632', () {
        final srs = gdal.spatialReferenceFromEpsg(32632);
        try {
          expect(srs.authorityName, 'EPSG');
          expect(srs.authorityCode, '32632');
        } finally {
          srs.close();
        }
      });

      test('toWkt returns WKT1', () {
        final srs = gdal.spatialReferenceFromEpsg(4326);
        try {
          final wkt = srs.toWkt();
          expect(wkt, isNotEmpty);
          expect(wkt, contains('WGS'));
        } finally {
          srs.close();
        }
      });

      test('toWkt2 returns WKT2', () {
        final srs = gdal.spatialReferenceFromEpsg(4326);
        try {
          final wkt2 = srs.toWkt2();
          expect(wkt2, isNotEmpty);
          // WKT2 uses GEOGCRS instead of GEOGCS
          expect(wkt2, contains('GEOGCRS'));
        } finally {
          srs.close();
        }
      });

      test('throws for invalid EPSG code', () {
        expect(
          () => gdal.spatialReferenceFromEpsg(999999),
          throwsA(isA<GdalException>()),
        );
      });
    },
  );

  group(
    'SpatialReference from WKT',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('creates from WKT and reads authority', () {
        // Get WKT from a known EPSG, then reimport.
        final original = gdal.spatialReferenceFromEpsg(4326);
        final wkt = original.toWkt();
        original.close();

        final srs = gdal.spatialReferenceFromWkt(wkt);
        try {
          expect(srs.authorityCode, '4326');
        } finally {
          srs.close();
        }
      });
    },
  );

  group(
    'SpatialReference from dataset',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late GeoTiffDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openGeoTiff(_tinyPath);
      });

      tearDown(() => ds.close());

      test('spatialReference returns EPSG:4326', () {
        final srs = ds.spatialReference;
        try {
          expect(srs.authorityName, 'EPSG');
          expect(srs.authorityCode, '4326');
        } finally {
          srs.close();
        }
      });

      test('spatialReference exports WKT', () {
        final srs = ds.spatialReference;
        try {
          expect(srs.toWkt(), contains('WGS'));
        } finally {
          srs.close();
        }
      });

      test('spatialReference exports WKT2', () {
        final srs = ds.spatialReference;
        try {
          expect(srs.toWkt2(), contains('GEOGCRS'));
        } finally {
          srs.close();
        }
      });
    },
  );

  group(
    'SpatialReference comparison',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('isSame returns true for equivalent CRS', () {
        final a = gdal.spatialReferenceFromEpsg(4326);
        final b = gdal.spatialReferenceFromEpsg(4326);
        try {
          expect(a.isSame(b), isTrue);
        } finally {
          a.close();
          b.close();
        }
      });

      test('isSame returns false for different CRS', () {
        final a = gdal.spatialReferenceFromEpsg(4326);
        final b = gdal.spatialReferenceFromEpsg(32632);
        try {
          expect(a.isSame(b), isFalse);
        } finally {
          a.close();
          b.close();
        }
      });

      test('dataset CRS matches EPSG:4326', () {
        final ds = gdal.openGeoTiff(
            '${Directory.current.path}/test/fixtures/tiny.tif');
        final dsSrs = ds.spatialReference;
        final epsg = gdal.spatialReferenceFromEpsg(4326);
        try {
          expect(dsSrs.isSame(epsg), isTrue);
        } finally {
          dsSrs.close();
          epsg.close();
          ds.close();
        }
      });
    },
  );

  group(
    'SpatialReference lifecycle',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;

      setUp(() => gdal = Gdal());

      test('close is idempotent', () {
        final srs = gdal.spatialReferenceFromEpsg(4326);
        srs.close();
        srs.close(); // no throw
        expect(srs.isClosed, isTrue);
      });

      test('properties throw after close', () {
        final srs = gdal.spatialReferenceFromEpsg(4326);
        srs.close();
        expect(() => srs.authorityName,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => srs.authorityCode,
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => srs.toWkt(),
            throwsA(isA<GdalDatasetClosedException>()));
        expect(() => srs.toWkt2(),
            throwsA(isA<GdalDatasetClosedException>()));
      });

      test('isSame throws after close', () {
        final a = gdal.spatialReferenceFromEpsg(4326);
        final b = gdal.spatialReferenceFromEpsg(4326);
        a.close();
        expect(() => a.isSame(b),
            throwsA(isA<GdalDatasetClosedException>()));
        b.close();
      });
    },
  );
}
