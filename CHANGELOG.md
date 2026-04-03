# Changelog

Alle relevanten Änderungen des Pakets werden hier dokumentiert.

## 0.2.2

### Added
- `Gdal.setConfigOption()` / `Gdal.getConfigOption()` —
  GDAL-Konfigurationsoptionen lesen und setzen
  (via `CPLSetConfigOption` / `CPLGetConfigOption`)

## 0.2.1

### Added
- `OgrLayer.geometryType` — gibt den Geometrie-Typ des Layers zurück
  (via `OGR_FD_GetGeomType`)

### Fixed
- README vollständig auf 0.2.0 aktualisiert: Vektor-Quick-Start,
  API-Übersicht, Beispiele, Exceptions, Ressourcen-Lebensdauer

## 0.2.0

### Added
- **OGR-Vektor-Lesen** — GeoJSON, GeoPackage und Shapefile über eine
  einheitliche API lesen
- `Gdal.openVector()` — Format-agnostischer Einstiegspunkt für
  Vektor-Datasets
- `VectorDataset` — Layer-Zugriff mit `layerCount`, `layer()`,
  `layerByName()`
- `OgrLayer` — Feature-Iteration (lazy via `sync*`), Schema-Zugriff
  (`fieldDefinitions`), Extent, Spatial Reference
- `OgrLayer.setSpatialFilterRect()` / `clearSpatialFilter()` —
  Server-seitige räumliche Filterung über GDAL
- `OgrLayer.setAttributeFilter()` / `clearAttributeFilter()` —
  SQL-WHERE-basierte Attribut-Filterung
- `Feature` — Immutables Dart-Objekt mit `fid`, `attributes` und
  `geometry`
- `Geometry` sealed class mit `Point`, `LineString`, `Polygon`,
  `MultiPoint`, `MultiLineString`, `MultiPolygon`,
  `GeometryCollection`
- `OgrFieldType` Enum für OGR-Feldtypen
- `OgrException` für Vektor-spezifische Fehler
- Native OGR-Brücke (`gdal_ogr.dart`) mit 30 C-API-Funktionen
- `coverage-uncovered` Docker-Stage für per-Datei Uncovered-Lines-Report
- Beispiel: `example/vector_example.dart`
- Test-Fixtures: `points.geojson`, `mixed_geometries.geojson`

## 0.1.0

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
- Beispiele: `example/gdal_dart_example.dart`,
  `example/tile_processing_example.dart`
- Tile-Processing-Modul (`lib/src/processing/`):
  - `GeoTIFFTileProcessor` für RGBA-Tile-Rendering und Elevation-Daten
  - Adaptive Triangulation mit BVH-Index (portiert aus v-map TypeScript)
  - Nearest-Neighbor- und bilineare Interpolation
  - Normalisierung für Uint8–Float64-Datentypen
  - Vordefinierte Colormaps: viridis, terrain, turbo, rainbow, grayscale
  - Martini-kompatible Elevation-Ausgabe
- `CoordinateTransform` für Koordinatentransformation zwischen CRS
  via GDAL OCT API: `transformPoint()`, `transformPoints()`
- `GeoTiffSource` — Convenience-Klasse, die ein GeoTIFF-Dataset mit
  vorberechneten WGS 84 Bounds und Koordinatentransformation bündelt
  (portiert aus v-map TypeScript `geotiff-source.ts`)
- `Gdal.coordinateTransform()` und `Gdal.openGeoTiffSource()` als
  Factory-Methoden
- `OSRSetAxisMappingStrategy`-Binding: `SpatialReference` setzt
  automatisch `OAMS_TRADITIONAL_GIS_ORDER` (lon/lat-Achsenreihenfolge)
