# gdal_dart

Dart-FFI-Paket für GeoTIFF-Funktionalität auf Basis von GDAL.

Lesen, Schreiben und Abfragen von GeoTIFF-Dateien aus Dart — typisiert, mit klar gekapselter nativer Schicht.

## Voraussetzungen

GDAL muss als Shared Library auf dem System installiert sein:

| Plattform | Paket / Befehl |
|---|---|
| Debian / Ubuntu | `sudo apt-get install gdal-bin libgdal-dev` |
| macOS (Homebrew) | `brew install gdal` |
| Windows | GDAL-Binaries von [gisinternals.com](https://www.gisinternals.com/) oder OSGeo4W |

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
}
```

Weitere Beispiele:

- [`example/gdal_dart_example.dart`](example/gdal_dart_example.dart) — Lesen, Schreiben, CRS
- [`example/tile_processing_example.dart`](example/tile_processing_example.dart) — Tile-Rendering mit Reprojektion, Colormaps, Elevation

## API-Übersicht

| Klasse | Zweck |
|---|---|
| `Gdal` | Einstiegspunkt — GDAL initialisieren, Dateien öffnen/erzeugen, CRS erstellen |
| `GeoTiffDataset` | Lesezugriff — Dimensionen, Projektion, GeoTransform, Bänder |
| `GeoTiffWriter` | Schreibzugriff — neues GeoTIFF erzeugen, Bänder befüllen |
| `RasterBand` | Pixeldaten lesen — typisiert (`readAsUint8`, `readAsFloat32`, …), Tile-Zugriff, Overviews |
| `SpatialReference` | CRS-Objekt — WKT1/WKT2-Export, EPSG-Code, `isSame()`-Vergleich |
| `GeoTransform` | Affine Transformation (6 Koeffizienten) |
| `RasterDataType` | GDAL-Datentyp-Enum (`byte_`, `uint16`, `float32`, …) |
| `RasterWindow` | Rechteckiger Raster-Ausschnitt |
| `GeoTIFFTileProcessor` | Tile-Rendering mit Triangulations-Reprojektion, Colormaps und Elevation |
| `Triangulation` | Adaptive Triangulation für effiziente Raster-Reprojektion |
| `ColorStop` / `ColorMapName` | Farbmapping mit vordefinierten Colormaps (viridis, terrain, turbo, …) |

### Exceptions

| Typ | Wann |
|---|---|
| `GdalException` | Basis für alle GDAL-Fehler |
| `GdalLibraryLoadException` | Shared Library nicht gefunden |
| `GdalFileException` | Datei kann nicht geöffnet/erzeugt werden (mit `.path`) |
| `GdalIOException` | Lese-/Schreiboperation fehlgeschlagen |
| `GdalDatasetClosedException` | Zugriff auf geschlossene Ressource |

### Ressourcen-Lebensdauer

`GeoTiffDataset`, `GeoTiffWriter` und `SpatialReference` besitzen native Handles.
Jede Instanz **muss** mit `close()` freigegeben werden.
`close()` ist idempotent.
Bei `GeoTiffWriter` ist `close()` Pflicht, da erst dort Daten auf Disk geflusht werden.

## Entwicklung

Für reproduzierbare Checks gibt es ein [`Dockerfile`](Dockerfile) mit folgenden Stages:

```bash
docker build --target analyze .
docker build --target test .
docker build --target coverage --no-cache-filter coverage --progress=plain .
docker build --target coverage-check --no-cache-filter coverage --progress=plain --build-arg COVERAGE_MIN=95 .
docker build --target doc .
docker build --target bindings .
docker build --target publish-check .
```

## CI/CD

GitHub Actions decken ab:

- **CI** (`ci.yml`): Analyse, Test, Docker-Build
- **Publish** (`publish.yml`): Release über Tags im Format `gdal_dart-v*.*.*` auf `pub.dev`

## Weiterführend

- [Architektur](docs/architecture.md) — Schichtenmodell, Designentscheidungen
- [Roadmap](docs/roadmap.md) — Phasen und Meilensteine
