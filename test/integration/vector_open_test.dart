import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

final _fixturePath =
    '${Directory.current.path}/test/fixtures/points.geojson';

void main() {
  group(
    'VectorDataset',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late VectorDataset ds;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openVector(_fixturePath);
      });

      tearDown(() => ds.close());

      test('opens GeoJSON and reports one layer', () {
        expect(ds.layerCount, 1);
      });

      test('layer(0) returns a valid layer', () {
        final layer = ds.layer(0);
        expect(layer.name, isNotEmpty);
      });

      test('featureCount is 2', () {
        final layer = ds.layer(0);
        expect(layer.featureCount, 2);
      });

      test('fieldDefinitions contains name and population', () {
        final layer = ds.layer(0);
        final defs = layer.fieldDefinitions;
        final names = defs.map((d) => d.name).toList();
        expect(names, contains('name'));
        expect(names, contains('population'));
      });

      test('reads feature attributes', () {
        final layer = ds.layer(0);
        final features = layer.features.toList();
        expect(features.length, 2);

        final munich = features.firstWhere(
            (f) => f.attributes['name'] == 'München');
        expect(munich.attributes['population'], 1500000);

        final berlin = features.firstWhere(
            (f) => f.attributes['name'] == 'Berlin');
        expect(berlin.attributes['population'], 3700000);
      });

      test('reads point geometry', () {
        final layer = ds.layer(0);
        final feature = layer.features.first;
        expect(feature.geometry, isA<Point>());
        final point = feature.geometry! as Point;
        // GeoJSON coordinates: [11.58, 48.14] or [13.40, 52.52]
        expect(point.x, anyOf(closeTo(11.58, 0.01), closeTo(13.40, 0.01)));
        expect(point.y, anyOf(closeTo(48.14, 0.01), closeTo(52.52, 0.01)));
      });

      test('feature has consistent geometry for München', () {
        final layer = ds.layer(0);
        final munich = layer.features
            .firstWhere((f) => f.attributes['name'] == 'München');
        final point = munich.geometry! as Point;
        expect(point.x, closeTo(11.58, 0.01));
        expect(point.y, closeTo(48.14, 0.01));
      });

      test('layer geometryType is point', () {
        final layer = ds.layer(0);
        expect(layer.geometryType, GeometryType.point);
      });

      test('layer spatial reference is WGS 84', () {
        final layer = ds.layer(0);
        final srs = layer.spatialReference;
        expect(srs, isNotNull);
        expect(srs!.authorityCode, '4326');
        srs.close();
      });

      test('layer extent covers both cities', () {
        final layer = ds.layer(0);
        final ext = layer.extent;
        expect(ext, isNotNull);
        // München (11.58, 48.14) and Berlin (13.40, 52.52)
        expect(ext!.minX, closeTo(11.58, 0.01));
        expect(ext.maxX, closeTo(13.40, 0.01));
        expect(ext.minY, closeTo(48.14, 0.01));
        expect(ext.maxY, closeTo(52.52, 0.01));
      });

      test('setSpatialFilterRect filters features by bbox', () {
        final layer = ds.layer(0);
        // Only München (11.58, 48.14) — exclude Berlin (13.40, 52.52)
        layer.setSpatialFilterRect(11.0, 47.0, 12.0, 49.0);
        final filtered = layer.features.toList();
        expect(filtered.length, 1);
        expect(filtered.first.attributes['name'], 'München');
        layer.clearSpatialFilter();
        // After clearing, both features should be back
        expect(layer.features.toList().length, 2);
      });

      test('setAttributeFilter filters features by SQL expression', () {
        final layer = ds.layer(0);
        layer.setAttributeFilter('population > 2000000');
        final filtered = layer.features.toList();
        expect(filtered.length, 1);
        expect(filtered.first.attributes['name'], 'Berlin');
        layer.clearAttributeFilter();
        expect(layer.features.toList().length, 2);
      });

      test('setAttributeFilter throws on invalid expression', () {
        final layer = ds.layer(0);
        expect(
          () => layer.setAttributeFilter('INVALID %%% SYNTAX'),
          throwsA(isA<OgrException>()),
        );
      });

      test('featureCount respects active filters', () {
        final layer = ds.layer(0);
        expect(layer.featureCount, 2);
        layer.setAttributeFilter("name = 'Berlin'");
        expect(layer.featureCount, 1);
        layer.clearAttributeFilter();
        expect(layer.featureCount, 2);
      });

      test('throws when opening invalid file', () {
        expect(
          () => gdal.openVector('nonexistent.geojson'),
          throwsA(isA<GdalFileException>()),
        );
      });

      test('throws after dataset is closed', () {
        ds.close();
        expect(
          () => ds.layerCount,
          throwsA(isA<GdalDatasetClosedException>()),
        );
      });

      test('close is idempotent', () {
        ds.close();
        expect(() => ds.close(), returnsNormally);
      });
    },
  );
}
