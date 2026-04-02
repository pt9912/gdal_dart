/// Example demonstrating OGR vector reading with gdal_dart.
///
/// Requires GDAL to be installed on the system.
/// Run with: dart run example/vector_example.dart
library;

import 'package:gdal_dart/gdal_dart.dart';

void main() {
  final gdal = Gdal();
  print('GDAL ${gdal.versionString}\n');

  final ds = gdal.openVector('test/fixtures/points.geojson');
  try {
    print('Layers: ${ds.layerCount}');

    final layer = ds.layer(0);
    print('Layer: ${layer.name}');
    print('Features: ${layer.featureCount}');
    print('Fields: ${layer.fieldDefinitions.map((d) => '${d.name} (${d.type.name})').join(', ')}');

    // Spatial reference
    final srs = layer.spatialReference;
    if (srs != null) {
      print('CRS: ${srs.authorityName}:${srs.authorityCode}');
      srs.close();
    }

    // Extent
    final ext = layer.extent;
    if (ext != null) {
      print('Extent: ${ext.minX}, ${ext.minY} → ${ext.maxX}, ${ext.maxY}');
    }

    // Iterate all features
    print('\n--- All features ---');
    for (final f in layer.features) {
      final geom = f.geometry as Point;
      print('  ${f.attributes['name']}: ${geom.x}, ${geom.y}'
          ' (pop: ${f.attributes['population']})');
    }

    // Spatial filter: only München area
    print('\n--- Spatial filter (München area) ---');
    layer.setSpatialFilterRect(11.0, 47.0, 12.0, 49.0);
    for (final f in layer.features) {
      print('  ${f.attributes['name']}');
    }
    layer.clearSpatialFilter();

    // Attribute filter
    print('\n--- Attribute filter (population > 2000000) ---');
    layer.setAttributeFilter('population > 2000000');
    for (final f in layer.features) {
      print('  ${f.attributes['name']}: ${f.attributes['population']}');
    }
    layer.clearAttributeFilter();
  } finally {
    ds.close();
  }
}
