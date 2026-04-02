import 'dart:ffi';

import 'model/field_type.dart';
import 'model/geometry.dart';
import 'native/gdal_ogr.dart';

/// An immutable representation of an OGR vector feature.
///
/// Features are materialized from native OGR handles when read.
/// They hold no native resources and do not need to be closed.
class Feature {
  /// The feature ID (FID). May be [OGRNullFID] (-1) if not set.
  final int fid;

  /// Field values keyed by field name.
  ///
  /// Values are typed according to the OGR field type:
  /// - [OgrFieldType.integer] → [int]
  /// - [OgrFieldType.integer64] → [int]
  /// - [OgrFieldType.real] → [double]
  /// - [OgrFieldType.string], [OgrFieldType.date], [OgrFieldType.time],
  ///   [OgrFieldType.dateTime] → [String]
  /// - `null` if the field is not set
  final Map<String, Object?> attributes;

  /// The feature's geometry, or `null` if the feature has no geometry.
  final Geometry? geometry;

  const Feature({
    required this.fid,
    required this.attributes,
    this.geometry,
  });

  /// Reads a feature from a native OGR handle and destroys the handle.
  ///
  /// [fieldDefs] provides the schema to read fields by index.
  /// The native [handle] is destroyed via [OGR_F_Destroy] after reading.
  factory Feature.fromNativeHandle(
    GdalOgr ogr,
    Pointer<Void> handle,
    List<({String name, OgrFieldType type})> fieldDefs,
  ) {
    try {
      final fid = ogr.getFeatureFID(handle);

      // Read attributes
      final attributes = <String, Object?>{};
      for (var i = 0; i < fieldDefs.length; i++) {
        final def = fieldDefs[i];
        if (!ogr.isFieldSetAndNotNull(handle, i)) {
          attributes[def.name] = null;
          continue;
        }
        attributes[def.name] = switch (def.type) {
          OgrFieldType.integer => ogr.getFieldAsInteger(handle, i),
          OgrFieldType.integer64 => ogr.getFieldAsInteger64(handle, i),
          OgrFieldType.real => ogr.getFieldAsDouble(handle, i),
          OgrFieldType.string ||
          OgrFieldType.date ||
          OgrFieldType.time ||
          OgrFieldType.dateTime =>
            ogr.getFieldAsString(handle, i),
          _ => ogr.getFieldAsString(handle, i),
        };
      }

      // Read geometry
      final geomHandle = ogr.getGeometryRef(handle);
      final geometry =
          geomHandle == nullptr ? null : _readGeometry(ogr, geomHandle);

      return Feature(fid: fid, attributes: attributes, geometry: geometry);
    } finally {
      ogr.destroyFeature(handle);
    }
  }

  @override
  String toString() =>
      'Feature(fid: $fid, attributes: $attributes, geometry: $geometry)';
}

/// Recursively reads a geometry from a native OGR handle.
///
/// The handle is borrowed — it must not be freed.
Geometry? _readGeometry(GdalOgr ogr, Pointer<Void> handle) {
  final ogrType = ogr.getGeometryType(handle);
  final type = GeometryType.fromOgr(ogrType);
  if (type == null) return null;

  return switch (type) {
    GeometryType.point => _readPoint(ogr, handle),
    GeometryType.lineString => _readLineString(ogr, handle),
    GeometryType.polygon => _readPolygon(ogr, handle),
    GeometryType.multiPoint => _readMultiPoint(ogr, handle),
    GeometryType.multiLineString => _readMultiLineString(ogr, handle),
    GeometryType.multiPolygon => _readMultiPolygon(ogr, handle),
    GeometryType.geometryCollection => _readGeometryCollection(ogr, handle),
  };
}

Point _readPoint(GdalOgr ogr, Pointer<Void> handle) {
  final x = ogr.getX(handle, 0);
  final y = ogr.getY(handle, 0);
  final z = ogr.getZ(handle, 0);
  // OGR returns 0.0 for Z when it's a 2D point. We check the geometry type
  // to decide whether to include Z.
  final ogrType = ogr.getGeometryType(handle);
  final hasZ = (ogrType & 0x80000000) != 0 || ogrType == 0x80000001;
  return hasZ ? Point(x, y, z) : Point(x, y);
}

LineString _readLineString(GdalOgr ogr, Pointer<Void> handle) {
  final count = ogr.getPointCount(handle);
  final ogrType = ogr.getGeometryType(handle);
  final hasZ = (ogrType & 0x80000000) != 0;
  final points = List.generate(count, (i) {
    final x = ogr.getX(handle, i);
    final y = ogr.getY(handle, i);
    return hasZ ? Point(x, y, ogr.getZ(handle, i)) : Point(x, y);
  });
  return LineString(points);
}

Polygon _readPolygon(GdalOgr ogr, Pointer<Void> handle) {
  final ringCount = ogr.getGeometryCount(handle);
  final rings = List.generate(ringCount, (i) {
    final ringHandle = ogr.getSubGeometry(handle, i);
    return _readLineString(ogr, ringHandle);
  });
  return Polygon(rings);
}

MultiPoint _readMultiPoint(GdalOgr ogr, Pointer<Void> handle) {
  final count = ogr.getGeometryCount(handle);
  final points = List.generate(count, (i) {
    final subHandle = ogr.getSubGeometry(handle, i);
    return _readPoint(ogr, subHandle);
  });
  return MultiPoint(points);
}

MultiLineString _readMultiLineString(GdalOgr ogr, Pointer<Void> handle) {
  final count = ogr.getGeometryCount(handle);
  final lineStrings = List.generate(count, (i) {
    final subHandle = ogr.getSubGeometry(handle, i);
    return _readLineString(ogr, subHandle);
  });
  return MultiLineString(lineStrings);
}

MultiPolygon _readMultiPolygon(GdalOgr ogr, Pointer<Void> handle) {
  final count = ogr.getGeometryCount(handle);
  final polygons = List.generate(count, (i) {
    final subHandle = ogr.getSubGeometry(handle, i);
    return _readPolygon(ogr, subHandle);
  });
  return MultiPolygon(polygons);
}

GeometryCollection _readGeometryCollection(
    GdalOgr ogr, Pointer<Void> handle) {
  final count = ogr.getGeometryCount(handle);
  final geometries = <Geometry>[];
  for (var i = 0; i < count; i++) {
    final subHandle = ogr.getSubGeometry(handle, i);
    final geom = _readGeometry(ogr, subHandle);
    if (geom != null) geometries.add(geom);
  }
  return GeometryCollection(geometries);
}
