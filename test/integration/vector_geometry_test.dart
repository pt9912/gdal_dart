import 'dart:io';

import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

import '../helpers/gdal_test_helpers.dart';

final _fixturePath =
    '${Directory.current.path}/test/fixtures/mixed_geometries.geojson';

void main() {
  group(
    'Vector geometry types',
    skip: isGdalAvailable ? null : 'GDAL library not available',
    () {
      late Gdal gdal;
      late VectorDataset ds;
      late OgrLayer layer;
      late List<Feature> allFeatures;

      setUp(() {
        gdal = Gdal();
        ds = gdal.openVector(_fixturePath);
        layer = ds.layer(0);
        allFeatures = layer.features.toList();
      });

      tearDown(() => ds.close());

      Feature _byName(String name) =>
          allFeatures.firstWhere((f) => f.attributes['name'] == name);

      test('reads Point geometry', () {
        final f = _byName('point');
        expect(f.geometry, isA<Point>());
        final p = f.geometry! as Point;
        expect(p.x, closeTo(10.0, 0.01));
        expect(p.y, closeTo(50.0, 0.01));
        expect(p.type, GeometryType.point);
      });

      test('reads LineString geometry', () {
        final f = _byName('line');
        expect(f.geometry, isA<LineString>());
        final ls = f.geometry! as LineString;
        expect(ls.points.length, 3);
        expect(ls.points.first.x, closeTo(10.0, 0.01));
        expect(ls.points.last.x, closeTo(12.0, 0.01));
        expect(ls.type, GeometryType.lineString);
      });

      test('reads Polygon geometry', () {
        final f = _byName('polygon');
        expect(f.geometry, isA<Polygon>());
        final poly = f.geometry! as Polygon;
        expect(poly.rings.length, 1);
        expect(poly.exteriorRing.points.length, 5); // closed ring
        expect(poly.interiorRings, isEmpty);
        expect(poly.type, GeometryType.polygon);
      });

      test('reads MultiPoint geometry', () {
        final f = _byName('multipoint');
        expect(f.geometry, isA<MultiPoint>());
        final mp = f.geometry! as MultiPoint;
        expect(mp.points.length, 2);
        expect(mp.type, GeometryType.multiPoint);
      });

      test('reads MultiLineString geometry', () {
        final f = _byName('multiline');
        expect(f.geometry, isA<MultiLineString>());
        final mls = f.geometry! as MultiLineString;
        expect(mls.lineStrings.length, 2);
        expect(mls.lineStrings.first.points.length, 2);
        expect(mls.type, GeometryType.multiLineString);
      });

      test('reads MultiPolygon geometry', () {
        final f = _byName('multipolygon');
        expect(f.geometry, isA<MultiPolygon>());
        final mpoly = f.geometry! as MultiPolygon;
        expect(mpoly.polygons.length, 2);
        expect(mpoly.type, GeometryType.multiPolygon);
      });

      test('reads GeometryCollection', () {
        final f = _byName('collection');
        expect(f.geometry, isA<GeometryCollection>());
        final gc = f.geometry! as GeometryCollection;
        expect(gc.geometries.length, 2);
        expect(gc.geometries[0], isA<Point>());
        expect(gc.geometries[1], isA<LineString>());
        expect(gc.type, GeometryType.geometryCollection);
      });

      test('handles null geometry', () {
        final f = _byName('no_geom');
        expect(f.geometry, isNull);
      });

      test('reads double field values', () {
        final f = _byName('point');
        expect(f.attributes['value'], isA<double>());
        expect(f.attributes['value'], closeTo(1.5, 0.01));
      });

      test('reads integer field values', () {
        final f = _byName('point');
        expect(f.attributes['active'], 1);
      });

      test('reads null field values', () {
        final f = _byName('no_geom');
        expect(f.attributes['value'], isNull);
        expect(f.attributes['active'], isNull);
      });

      test('layerByName returns the correct layer', () {
        final namedLayer = ds.layerByName(layer.name);
        expect(namedLayer.featureCount, layer.featureCount);
        expect(namedLayer.name, layer.name);
      });

      test('layerByName throws for nonexistent layer', () {
        expect(
          () => ds.layerByName('does_not_exist'),
          throwsA(isA<OgrException>()),
        );
      });

      test('feature FID is non-negative', () {
        for (final f in allFeatures) {
          expect(f.fid, greaterThanOrEqualTo(0));
        }
      });

      test('feature(fid) returns same data as iteration', () {
        final first = allFeatures.first;
        final byFid = layer.feature(first.fid);
        expect(byFid.attributes['name'], first.attributes['name']);
      });

      test('Point toString', () {
        final p = const Point(1.0, 2.0);
        expect(p.toString(), 'Point(1.0, 2.0)');
        final pz = const Point(1.0, 2.0, 3.0);
        expect(pz.toString(), 'Point(1.0, 2.0, 3.0)');
      });

      test('Point equality', () {
        expect(const Point(1.0, 2.0), equals(const Point(1.0, 2.0)));
        expect(const Point(1.0, 2.0), isNot(equals(const Point(1.0, 3.0))));
        expect(const Point(1.0, 2.0, 3.0),
            equals(const Point(1.0, 2.0, 3.0)));
      });

      test('geometry toString representations', () {
        expect(_byName('line').geometry.toString(), contains('3 points'));
        expect(_byName('polygon').geometry.toString(), contains('1 rings'));
        expect(_byName('multipoint').geometry.toString(), contains('2 points'));
        expect(_byName('multiline').geometry.toString(),
            contains('2 lineStrings'));
        expect(
            _byName('multipolygon').geometry.toString(), contains('2 polygons'));
        expect(_byName('collection').geometry.toString(),
            contains('2 geometries'));
      });

      test('VectorDataset toString', () {
        expect(ds.toString(), contains('1 layers'));
      });

      test('OgrLayer toString', () {
        expect(layer.toString(), contains('features'));
      });

      test('Feature toString contains fid', () {
        expect(allFeatures.first.toString(), contains('fid'));
      });

      test('GeometryType.fromOgr returns null for unknown type', () {
        expect(GeometryType.fromOgr(999), isNull);
      });

      test('OgrFieldType.fromOgr returns null for unknown type', () {
        expect(OgrFieldType.fromOgr(999), isNull);
      });
    },
  );
}
