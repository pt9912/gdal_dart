# gdal_dart

Dart-FFI-Paket für Raster- und Vektor-Geodaten auf Basis von GDAL.

Lesen, Schreiben und Abfragen von GeoTIFF-Dateien sowie Lesen von Vektor-Formaten (GeoJSON, GeoPackage, Shapefile) aus Dart — typisiert, mit klar gekapselter nativer Schicht.

## Voraussetzungen

GDAL muss als Shared Library auf dem System installiert sein:

| Plattform        | Paket / Befehl                                                                   |
| ---------------- | -------------------------------------------------------------------------------- |
| Debian / Ubuntu  | `sudo apt-get install gdal-bin libgdal-dev`                                      |
| macOS (Homebrew) | `brew install gdal`                                                              |
| Windows          | GDAL-Binaries von [gisinternals.com](https://www.gisinternals.com/) oder OSGeo4W |

Alternativ kann der mitgelieferte [`Dockerfile`](Dockerfile) für eine reproduzierbare Umgebung genutzt werden.

Die Library wird automatisch über den Plattform-Standardnamen geladen (`libgdal.so`, `libgdal.dylib`, `gdal.dll`).
Über die Umgebungsvariable `GDAL_LIBRARY_PATH` oder den Parameter `libraryPath` kann ein expliziter Pfad angegeben werden.

## Quick Start

```dart
import 'package:gdal_dart/gdal_dart.dart';

void main() {
  final gdal = Gdal();

  // --- Lesen ---
  final dataset = gdal.openGeoTiff('input.tif');
  print('${dataset.width} x ${dataset.height}, ${dataset.bandCount} Bänder');
  print('CRS: ${dataset.spatialReference.authorityCode}');

  final band = dataset.band(1);
  final pixels = band.readAsUint8();
  print('Erster Pixel: ${pixels[0]}');
  dataset.close();

  // --- Koordinatentransformation ---
  final wgs84 = gdal.spatialReferenceFromEpsg(4326);
  final utm32 = gdal.spatialReferenceFromEpsg(32632);
  final ct = gdal.coordinateTransform(wgs84, utm32);
  final (x, y) = ct.transformPoint(11.58, 48.14);
  print('UTM32: $x, $y');
  ct.close();
  utm32.close();
  wgs84.close();

  // --- GeoTiffSource (Metadaten + WGS 84 Bounds) ---
  final source = gdal.openGeoTiffSource('dem.tif');
  print('CRS: ${source.fromProjection}');
  print('WGS 84 Bounds: ${source.wgs84Bounds}');
  final (lon, lat) = source.transformToWgs84(500000, 5400000);
  print('WGS 84: $lon, $lat');
  source.close();

  // --- Schreiben ---
  final writer = gdal.createGeoTiff('output.tif', width: 256, height: 256);
  writer.setGeoTransform(GeoTransform(
    originX: 10.0, pixelWidth: 0.01, rotationX: 0.0,
    originY: 50.0, rotationY: 0.0, pixelHeight: -0.01,
  ));
  final srs = gdal.spatialReferenceFromEpsg(4326);
  writer.setProjection(srs.toWkt());
  srs.close();
  writer.writeAsUint8(1, Uint8List(256 * 256));
  writer.close(); // Pflicht — schreibt Daten auf Disk

  // --- Vektor-Daten lesen ---
  final ds = gdal.openVector('places.geojson');
  final layer = ds.layer(0);
  print('Layer: ${layer.name}, ${layer.featureCount} Features');

  for (final f in layer.features) {
    final geom = f.geometry as Point;
    print('${f.attributes['name']}: ${geom.x}, ${geom.y}');
  }

  // Räumlicher Filter
  layer.setSpatialFilterRect(11.0, 47.0, 12.0, 49.0);
  for (final f in layer.features) {
    print('Gefiltert: ${f.attributes['name']}');
  }
  layer.clearSpatialFilter();

  // Attribut-Filter
  layer.setAttributeFilter('population > 1000000');
  for (final f in layer.features) {
    print('Großstadt: ${f.attributes['name']}');
  }
  layer.clearAttributeFilter();

  ds.close();
}
```

Weitere Beispiele:

- [`example/gdal_dart_example.dart`](example/gdal_dart_example.dart) — Lesen, Schreiben, CRS
- [`example/tile_processing_example.dart`](example/tile_processing_example.dart) — Tile-Rendering mit Reprojektion, Colormaps, Elevation
- [`example/vector_example.dart`](example/vector_example.dart) — Vektor-Daten lesen mit Iteration, Spatial- und Attribut-Filter

## API-Übersicht

| Klasse                       | Zweck                                                                                     |
| ---------------------------- | ----------------------------------------------------------------------------------------- |
| `Gdal`                       | Einstiegspunkt — GDAL initialisieren, Dateien öffnen/erzeugen, CRS erstellen              |
| `GeoTiffDataset`             | Lesezugriff — Dimensionen, Projektion, GeoTransform, Bänder                               |
| `GeoTiffWriter`              | Schreibzugriff — neues GeoTIFF erzeugen, Bänder befüllen                                  |
| `RasterBand`                 | Pixeldaten lesen — typisiert (`readAsUint8`, `readAsFloat32`, …), Tile-Zugriff, Overviews |
| `SpatialReference`           | CRS-Objekt — WKT1/WKT2-Export, EPSG-Code, `isSame()`-Vergleich                            |
| `CoordinateTransform`        | Koordinatentransformation zwischen CRS — `transformPoint()`, `transformPoints()`          |
| `GeoTiffSource`              | GeoTIFF-Quelle mit vorberechneten WGS 84 Bounds und Koordinatentransformation             |
| `GeoTransform`               | Affine Transformation (6 Koeffizienten)                                                   |
| `RasterDataType`             | GDAL-Datentyp-Enum (`byte_`, `uint16`, `float32`, …)                                      |
| `RasterWindow`               | Rechteckiger Raster-Ausschnitt                                                            |
| `GeoTIFFTileProcessor`       | Tile-Rendering mit Triangulations-Reprojektion, Colormaps und Elevation                   |
| `Triangulation`              | Adaptive Triangulation für effiziente Raster-Reprojektion                                 |
| `ColorStop` / `ColorMapName` | Farbmapping mit vordefinierten Colormaps (viridis, terrain, turbo, …)                     |
| `VectorDataset`              | Vektor-Lesezugriff — Layer-Zugriff (`layerCount`, `layer()`, `layerByName()`)             |
| `OgrLayer`                   | Feature-Iteration, Schema (`fieldDefinitions`), Extent, Spatial/Attribut-Filter           |
| `Feature`                    | Immutables Feature-Objekt — `fid`, `attributes`, `geometry`                               |
| `Geometry`                   | Sealed class — `Point`, `LineString`, `Polygon`, `Multi…`, `GeometryCollection`           |
| `OgrFieldType`               | OGR-Feldtyp-Enum (`integer`, `real`, `string`, `date`, `dateTime`, …)                     |

### Exceptions

| Typ                          | Wann                                                   |
| ---------------------------- | ------------------------------------------------------ |
| `GdalException`              | Basis für alle GDAL-Fehler                             |
| `GdalLibraryLoadException`   | Shared Library nicht gefunden                          |
| `GdalFileException`          | Datei kann nicht geöffnet/erzeugt werden (mit `.path`) |
| `GdalIOException`            | Lese-/Schreiboperation fehlgeschlagen                  |
| `GdalDatasetClosedException` | Zugriff auf geschlossene Ressource                     |
| `OgrException`               | Vektor-Operation fehlgeschlagen (Layer, Feature, Filter) |

### Ressourcen-Lebensdauer

Folgende Klassen besitzen native Handles und **müssen** mit `close()` freigegeben werden:

- `GeoTiffDataset`, `GeoTiffWriter`, `SpatialReference`, `CoordinateTransform`, `GeoTiffSource`, `VectorDataset`
- `close()` ist bei allen idempotent
- `GeoTiffWriter`: `close()` ist Pflicht, da erst dort Daten auf Disk geflusht werden
- `GeoTiffSource.close()`: schließt alle internen Ressourcen (Dataset, Transform, SpatialReferences)

`Feature` und `Geometry` sind reine Dart-Objekte ohne native Handles und brauchen kein `close()`.

## Entwicklung

Für reproduzierbare Checks gibt es ein [`Dockerfile`](Dockerfile) mit folgenden Stages:

```bash
docker build --target analyze .
docker build --target test .
docker build --target coverage --no-cache-filter coverage --progress=plain .

docker build --target coverage-uncovered --no-cache-filter coverage-uncovered  --progress=plain -t gdal_dart:uncov . 
docker run --rm gdal_dart:uncov # uncoverd extrahieren

docker build --target coverage-check --no-cache-filter coverage --progress=plain --build-arg COVERAGE_MIN=95 .
docker build --target doc -t gdal_dart:doc .
docker build --target bindings .
docker build --target publish-check --no-cache-filter publish-check --progress=plain .
```

### API-Dokumentation generieren

```bash
docker build --target doc -t gdal_dart:doc .
docker run --rm gdal_dart:doc | tar -xzf -
```

Die HTML-Dokumentation liegt danach in `doc/api/`.

## CI/CD

GitHub Actions decken ab:

- **CI** (`ci.yml`): Analyse, Test, Docker-Build
- **Publish** (`publish.yml`): Release über Tags im Format `gdal_dart-v*.*.*` auf `pub.dev`

## Weiterführend

- [Architektur](doc/architecture.md) — Schichtenmodell, Designentscheidungen
- [Roadmap](doc/roadmap.md) — Phasen und Meilensteine
