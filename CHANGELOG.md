# Changelog

Alle relevanten Änderungen des Pakets werden hier dokumentiert.

## Unreleased

### Added
- `Gdal` Einstiegspunkt mit `openGeoTiff()`, `createGeoTiff()`,
  `spatialReferenceFromEpsg()`, `spatialReferenceFromWkt()`,
  `versionString`, `versionNumber`, `driverCount`
- `GeoTiffDataset` zum Lesen: `width`, `height`, `bandCount`,
  `projectionWkt`, `geoTransform`, `spatialReference`, `band()`
- `GeoTiffWriter` zum Schreiben: `setGeoTransform()`, `setProjection()`,
  `setNoData()`, `writeAsUint8/Uint16/Int16/Float32/Float64()`,
  Getter `geoTransform`, `projectionWkt`; GTiff-Erstellungsoptionen
- `RasterBand` mit typisierten Leseoperationen (`readAsUint8`, …),
  Tile-Zugriff (`tileWindow`, `readBlock`, `tileCountX/Y`),
  Overview-Support (`overviewCount`, `overview()`), Metadaten
  (`dataType`, `noDataValue`, `blockWidth/Height`, `width`, `height`)
- `SpatialReference` für CRS: `fromWkt`, `fromEpsg`, `toWkt()`,
  `toWkt2()`, `authorityName`, `authorityCode`, `isSame()`
- `GeoTransform` Modell mit `fromList`/`toList`, Gleichheit, `toString`
- `RasterDataType` Enum (`byte_`, `uint16`, `int16`, `uint32`, `int32_`,
  `float32`, `float64`) mit `gdalValue` und `sizeInBytes`
- `RasterWindow` Modell mit Validierung (non-negative Offsets,
  positive Dimensionen)
- Exception-Hierarchie: `GdalException`, `GdalLibraryLoadException`,
  `GdalDatasetClosedException`, `GdalFileException` (mit `.path`),
  `GdalIOException`
- Plattformabhängiger Library-Lader mit `GDAL_LIBRARY_PATH`
  Umgebungsvariable
- Native OSR-Bridge (`GdalSrs`) für Spatial-Reference-Funktionen
- `ffigen.yaml` für GDAL- und OSR-Header
- Multi-Stage-Dockerfile (analyze, test, coverage, doc, bindings,
  publish-check)
- GitHub Actions für CI und pub.dev-Publish
- Testfixtures: `tiny.tif`, `tiled.tif`, `multiband_uint16.tif`,
  `float32.tif`, `not_a_tiff.bin`
- Beispiel: `example/gdal_dart_example.dart`
