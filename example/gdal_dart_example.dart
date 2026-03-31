/// Minimal example demonstrating gdal_dart usage.
///
/// Requires GDAL to be installed on the system.
/// Run with: dart run example/gdal_dart_example.dart
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:gdal_dart/gdal_dart.dart';

void main() {
  final gdal = Gdal();
  print('GDAL ${gdal.versionString} — ${gdal.driverCount} drivers');

  // --- Read a GeoTIFF ---
  _readExample(gdal);

  // --- Write a GeoTIFF ---
  _writeExample(gdal);
}

void _readExample(Gdal gdal) {
  print('\n--- Reading ---');
  final dataset = gdal.openGeoTiff('test/fixtures/tiny.tif');
  try {
    print('Size: ${dataset.width} x ${dataset.height}');
    print('Bands: ${dataset.bandCount}');
    print('GeoTransform: ${dataset.geoTransform}');

    // CRS info
    final srs = dataset.spatialReference;
    print('CRS: ${srs.authorityName}:${srs.authorityCode}');
    srs.close();

    // Read pixel data
    final band = dataset.band(1);
    print('Data type: ${band.dataType}');
    print('Pixels: ${band.readAsUint8()}');
  } finally {
    dataset.close();
  }
}

void _writeExample(Gdal gdal) {
  print('\n--- Writing ---');
  final path = '${Directory.systemTemp.path}/gdal_dart_example.tif';

  final writer = gdal.createGeoTiff(
    path,
    width: 4,
    height: 4,
    dataType: RasterDataType.byte_,
  );
  writer.setGeoTransform(const GeoTransform(
    originX: 10.0,
    pixelWidth: 0.5,
    rotationX: 0.0,
    originY: 50.0,
    rotationY: 0.0,
    pixelHeight: -0.5,
  ));

  final srs = gdal.spatialReferenceFromEpsg(4326);
  writer.setProjection(srs.toWkt());
  srs.close();

  writer.writeAsUint8(1, Uint8List.fromList(List.generate(16, (i) => i)));
  writer.close();
  print('Written to $path');

  // Verify
  final ds = gdal.openGeoTiff(path);
  print('Readback: ${ds.band(1).readAsUint8()}');
  ds.close();
  File(path).deleteSync();
}
