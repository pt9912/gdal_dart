# Architektur: GeoTIFF mit GDAL in Dart

## Ziel

Dieses Projekt stellt GeoTIFF-Funktionalität aus GDAL für Dart bereit.
Der Fokus liegt zunächst auf einem stabilen, kleinen API-Schnitt für Raster-Lesezugriffe, Metadaten und Band-Zugriffe.
Die technische Basis sind:

- `dart:ffi` für den Aufruf der nativen GDAL-C-API
- `ffigen` zur Generierung der Low-Level-Bindings

Schreibzugriffe, Warping und erweiterte Treiberfunktionen sollen erst auf einer stabilen Lese-Architektur aufbauen.

## Nicht-Ziele für die erste Ausbaustufe

- Keine vollständige Abbildung der gesamten GDAL-API in einer öffentlichen Dart-API
- Keine direkte Veröffentlichung der durch `ffigen` erzeugten Symbole an Paketnutzer
- Kein generischer Vektor- oder OGR-Fokus
- Keine komplexe Async- oder Isolate-Architektur im ersten Schritt

## Architekturprinzipien

- Die GDAL-C-API bleibt die native Integrationsgrenze.
- Generierter Code und handgeschriebener Code werden strikt getrennt.
- Die öffentliche Dart-API ist klein, typisiert und GeoTIFF-orientiert.
- Speicherverwaltung wird zentral gekapselt, nicht ad hoc im Fachcode verteilt.
- Fehler aus GDAL werden deterministisch in Dart-Exceptions oder Ergebnisobjekte übersetzt.

## Schichtenmodell

Die Architektur besteht aus vier Schichten:

### 1. Native Bibliothek

Verwendet wird die GDAL Shared Library, typischerweise:

- Linux: `libgdal.so`
- macOS: `libgdal.dylib`
- Windows: `gdal.dll`

Die Anbindung erfolgt gegen die C-API aus `gdal.h` und den zugehörigen Headern.
Für GeoTIFF ist kein separater nativer TIFF-Layer in Dart nötig, weil GDAL den GeoTIFF-Treiber kapselt.

### 2. Generierte FFI-Bindings

`ffigen` erzeugt die rohen Bindings direkt aus GDAL-Headern.
Diese Schicht ist rein mechanisch und enthält:

- `Struct`, `Union`, `Opaque`
- Native Function Signatures
- Konstanten, soweit sinnvoll generierbar

Diese Ebene bleibt intern.
Hier gibt es keine Business-Logik, keine Speicherpolitik und keine benutzerfreundliche API.

Vorgesehene Datei:

- `lib/src/bindings/gdal_bindings.dart`

### 3. Manuelle FFI-Brücke

Über den generierten Bindings liegt eine kleine handgeschriebene Schicht, die native Details bündelt:

- Laden der nativen Bibliothek
- GDAL-Initialisierung
- String-Konvertierungen
- Fehlerabfrage
- Pointer-Lebensdauer
- Hilfsfunktionen für Dataset-, Band- und Buffer-Zugriffe

Diese Schicht kennt die generierten Bindings, aber noch nicht die endgültige Public API.

Vorgesehene Dateien:

- `lib/src/native/gdal_library.dart`
- `lib/src/native/gdal_api.dart`
- `lib/src/native/gdal_errors.dart`
- `lib/src/native/gdal_memory.dart`

### 4. Öffentliche Dart-API

Die oberste Schicht stellt die fachliche API bereit.
Sie soll für Paketnutzer idiomatisch und stabil sein.

Vorgesehene Typen:

- `Gdal`
- `GeoTiffDataset`
- `RasterBand`
- `GeoTransform`
- `RasterWindow`
- `RasterSize`
- `GdalException`

Vorgesehene Dateien:

- `lib/gdal_dart.dart`
- `lib/src/gdal.dart`
- `lib/src/geotiff_dataset.dart`
- `lib/src/raster_band.dart`
- `lib/src/model/...`

## Empfohlene Verzeichnisstruktur

```text
docs/
  architecture.md

ffigen.yaml

lib/
  gdal_dart.dart
  src/
    bindings/
      gdal_bindings.dart
    native/
      gdal_api.dart
      gdal_errors.dart
      gdal_library.dart
      gdal_memory.dart
    model/
      geo_transform.dart
      raster_data_type.dart
      raster_size.dart
      raster_window.dart
    gdal.dart
    geotiff_dataset.dart
    geotiff_writer.dart
    raster_band.dart
    spatial_reference.dart
    processing/
      triangle.dart
      aabb2d.dart
      bvh_node2d.dart
      triangulation.dart
      sampling_utils.dart
      normalization_utils.dart
      colormap_utils.dart
      geotiff_tile_processor.dart

tool/
  generate_bindings.dart

test/
  unit/
    processing/
      triangle_test.dart
      aabb2d_test.dart
      bvh_node2d_test.dart
      triangulation_test.dart
      sampling_utils_test.dart
      normalization_utils_test.dart
      colormap_utils_test.dart
  integration/
    tile_processor_test.dart
```

## Verantwortung der Schichten

### `bindings/`

- Ausschließlich generierter Code
- Keine manuellen Änderungen
- Regenerierbar aus Headern und `ffigen.yaml`

### `native/`

- Besitz der `DynamicLibrary`
- Besitz der globalen GDAL-Initialisierung
- Schutz vor fehlerhafter Pointer-Nutzung
- Umwandlung von C-Strings, Arrays und Fehlercodes

### `model/`

- Kleine, unveränderliche Dart-Datentypen
- Keine Native Pointer
- Keine direkte Kenntnis der GDAL-C-API

### Public API

- Kapselt `Pointer` und `ffi` vollständig
- Liefert saubere fachliche Methoden
- Macht Ressourcenlebensdauer explizit, zum Beispiel mit `close()`

### `processing/`

- Pure-Dart-Logik ohne direkte FFI-Abhängigkeit
- Triangulationsbasierte Raster-Reprojektion (portiert aus v-map TypeScript)
- BVH-Index für schnelle Point-in-Triangle-Lookups
- Sampling-Utilities: Nearest-Neighbor und bilineare Interpolation
- Normalisierung von TypedArray-Werten auf 0–255 bzw. 0–1
- Vordefinierte Colormaps (viridis, terrain, turbo, rainbow, grayscale)
- `GeoTIFFTileProcessor` als Orchestrierungsschicht für Tile-Rendering mit Reprojektion

## Geplanter API-Schnitt

### Einstiegspunkt

```dart
final gdal = Gdal();
final dataset = gdal.openGeoTiff('example.tif');

final width = dataset.width;
final height = dataset.height;
final projection = dataset.projectionWkt;
final transform = dataset.geoTransform;

final band1 = dataset.band(1);
final values = band1.readAsUint16();

dataset.close();
```

### Erste öffentliche Operationen

`Gdal`

- GDAL initialisieren
- GeoTIFF-Datei öffnen
- Optionale Treiber-/Versionsinformationen bereitstellen

`GeoTiffDataset`

- Größe lesen
- Bandanzahl lesen
- Projektion lesen
- GeoTransform lesen
- Metadaten lesen
- Rasterband abrufen
- Ressource schließen

`RasterBand`

- Datentyp lesen
- NoData-Wert lesen
- Blockgröße lesen
- Fenster lesen
- Ganzes Band in typisierte Dart-Collections lesen

## Native Integrationsstrategie

### Warum die GDAL-C-API

Die C-API ist für FFI stabiler als C++-Bindings:

- einfachere ABI
- besser durch `ffigen` abbildbar
- weniger Build-Komplexität
- plattformübergreifend robuster

Deshalb sollten primär Funktionen wie diese genutzt werden:

- `GDALAllRegister`
- `GDALOpenEx`
- `GDALClose`
- `GDALGetRasterXSize`
- `GDALGetRasterYSize`
- `GDALGetRasterCount`
- `GDALGetProjectionRef`
- `GDALGetGeoTransform`
- `GDALGetRasterBand`
- `GDALGetRasterDataType`
- `GDALRasterIO`
- `GDALGetRasterNoDataValue`
- `GDALGetBlockSize`
- `GDALGetOverviewCount`
- `GDALGetOverview`
- `OSRNewSpatialReference`
- `OSRImportFromWkt`
- `OSRExportToWkt`
- `OSRExportToWktEx`
- `OSRGetAuthorityCode`
- `OSRGetAuthorityName`
- `OSRDestroySpatialReference`

## Bibliothekslade-Strategie

Die Library-Namen sollten zentral gekapselt werden.
Die Auflösung kann so aussehen:

1. Optionaler expliziter Pfad per Konstruktor oder Environment Variable
2. Plattform-Defaultname
3. Fehler mit klarer Diagnose, wenn GDAL nicht gefunden wird

Beispiel:

- `GDAL_LIBRARY_PATH=/usr/lib/libgdal.so`

## `ffigen`-Strategie

`ffigen` soll nur die tatsächlich benötigten Header und Symbole einbeziehen.
Das reduziert Generierungsfehler und hält die Bindings lesbarer.

Grundregeln:

- Nur C-Header verwenden
- Möglichst nur benötigte Einträge einbinden
- Makros und problematische C-Konstrukte nur selektiv zulassen
- Generierten Code nie manuell bearbeiten

Beispielhafte Verantwortung von `ffigen.yaml`:

- Header-Pfade definieren
- Einzuschließende Funktionen filtern
- Opaque-Typen und Struct-Mapping konfigurieren
- Ausgabe nach `lib/src/bindings/gdal_bindings.dart`

## Ressourcen- und Speicherverwaltung

FFI scheitert in Dart-Projekten oft nicht an API-Aufrufen, sondern an unklarer Ownership.
Darum gilt:

- Jede native Ressource hat genau einen Dart-Owner.
- Öffentliche Objekte kapseln native Handles vollständig.
- `close()` ist idempotent.
- Nach `close()` sind weitere Aufrufe Fehler.
- Temporäre native Speicherbereiche werden mit `Arena` oder klar begrenzten Allokationen verwaltet.

### Besitzmodell

`Gdal`

- besitzt globale Initialisierung, aber nicht einzelne Datasets

`GeoTiffDataset`

- besitzt `GDALDatasetH`
- schließt das Handle via `GDALClose`

`RasterBand`

- besitzt das Band-Handle nicht separat
- lebt logisch nur solange das Dataset offen ist

Wichtige Konsequenz:

- `RasterBand` darf sein Parent-Dataset referenzieren
- bandbezogene Methoden müssen prüfen, ob das Dataset noch offen ist

## Fehlerbehandlung

GDAL signalisiert Fehler primär über Rückgabewerte und den CPL-Fehlermechanismus.
Die Dart-Schicht soll das in klare Exceptions umwandeln.

Vorgeschlagene Regeln:

- `null` oder ungültige Handles werden sofort als `GdalException` geworfen
- Fehlercodes aus `GDALRasterIO` werden geprüft
- Fehlermeldungen werden möglichst aus GDAL/CPL übernommen
- Öffentliche API liefert keine rohen Integer-Fehlercodes zurück

Beispielhafte Exception-Typen:

- `GdalException`
- `GdalLibraryLoadException`
- `GdalDatasetClosedException`

## Raumbezug und Koordinatenreferenzsystem

### Aktueller Stand

Das Projekt liest die Projektion eines Datasets als WKT-String über `GDALGetProjectionRef`.
Dieser String beschreibt das Koordinatenreferenzsystem (CRS), wird aber nicht weiter interpretiert.

### Erweiterung über die OSR-API

Für weitergehende CRS-Operationen stellt GDAL die OGR Spatial Reference API (OSR) bereit.
Diese ermöglicht unter anderem:

- WKT-Export in verschiedenen Versionen (WKT1, WKT2:2019)
- Export nach PROJ-String und Authority-Codes (z.B. `EPSG:4326`)
- CRS-Erkennung und -Vergleich
- Koordinatentransformation zwischen CRS

Relevante C-Funktionen:

- `OSRNewSpatialReference` — CRS-Objekt erzeugen
- `OSRImportFromWkt` — CRS aus WKT-String laden
- `OSRExportToWkt` — Export als WKT1
- `OSRExportToWktEx` — Export als WKT2 mit Formatoptionen
- `OSRExportToProj4` — Export als PROJ-String
- `OSRGetAuthorityCode` / `OSRGetAuthorityName` — Authority-Code auslesen (z.B. EPSG)
- `OSRIsSame` — CRS-Vergleich
- `OCTNewCoordinateTransformation` — Koordinatentransformation zwischen zwei CRS
- `OSRDestroySpatialReference` — CRS-Objekt freigeben

Referenz: [GDAL OGR Spatial Reference Tutorial](https://gdal.org/en/stable/tutorials/osr_api_tut.html)

### Geplanter API-Schnitt

Die Dart-API sollte CRS-Informationen als eigenes Modellobjekt kapseln:

```dart
final crs = dataset.spatialReference;
print(crs.toWkt());           // WKT2
print(crs.authorityCode);     // "4326"
print(crs.authorityName);     // "EPSG"
```

Das `SpatialReference`-Objekt gehört in die `model/`-Schicht und besitzt intern ein OSR-Handle, das über `close()` oder automatisch bei Dataset-Schließung freigegeben wird.

### Architektonische Konsequenzen

- Die `ffigen.yaml` muss um `ogr_srs_api.h` erweitert werden.
- Die `native/`-Schicht erhält eine neue Datei (z.B. `gdal_srs.dart`) für die OSR-Funktionen.
- Die öffentliche API erhält ein `SpatialReference`-Modell mit WKT-Export, Authority-Codes und CRS-Vergleich.
- Koordinatentransformation ist ein separater Erweiterungsschritt nach dem CRS-Lesezugriff.

## Datentransfer und Rasterlesen

Für GeoTIFF ist `GDALRasterIO` der zentrale Datenpfad.
Die Dart-API sollte typisierte Leseoperationen anbieten statt generischer `Pointer`-Exposition.

Beispiele:

- `readAsUint8()`
- `readAsUint16()`
- `readAsInt16()`
- `readAsFloat32()`
- `read(window: ...)`

Intern übersetzt die API:

- Dart-Zieltyp
- GDAL-Datentyp
- Buffer-Allokation
- Aufruf von `GDALRasterIO`
- Rückgabe als `Uint8List`, `Uint16List`, `Int16List`, `Float32List` oder `Float64List`

### Tile- und Block-basiertes Lesen

GeoTIFF-Dateien können intern in Tiles (Kacheln) oder Strips organisiert sein.
Die Blockgröße ist über `GDALGetBlockSize` abfragbar und bestimmt die natürliche Leseeinheit.

Für effizientes Lesen großer Raster — insbesondere bei Cloud Optimized GeoTIFF (COG) — ist blockweises Lesen über `GDALRasterIO` mit passenden Fenstergrößen der bevorzugte Weg.
Ein zusätzliches `GDALReadBlock` kann für striktes Block-Alignment sinnvoll sein, ist aber für die erste API-Stufe nicht erforderlich.

Die Dart-API sollte Tile-Zugriff über das bestehende Fenster-Lesen abbilden:

```dart
final band = dataset.band(1);
final blockSize = band.blockSize; // z.B. RasterSize(256, 256)
final tile = band.read(window: RasterWindow(x: 256, y: 0, width: 256, height: 256));
```

Für die erste Version sollte nur Lesen unterstützt werden.
Schreiben kann später analog über Dataset-Erzeugung und `GDALRasterIO` ergänzt werden.

## Cloud Optimized GeoTIFF (COG)

### Hintergrund

Cloud Optimized GeoTIFF (COG) ist ein reguläres GeoTIFF mit spezifischer interner Organisation:

- Interne Kachelung (Tiling) statt Strip-Layout
- Eingebettete Overviews (Pyramiden) für Mehrskalenzugriff
- HTTP-Range-Request-freundliche Byte-Anordnung

GDAL unterstützt COG transparent — eine COG-Datei wird mit denselben Funktionen geöffnet und gelesen wie jedes andere GeoTIFF.
Der Unterschied liegt primär im Zugriffspfad (lokal vs. remote) und in der Nutzung von Overviews und Kacheln.

### Fernzugriff über GDAL Virtual Filesystem

Für den Zugriff auf remote gehostete COGs stellt GDAL virtuelle Dateisysteme bereit:

- `/vsicurl/` — HTTP/HTTPS-Zugriff mit Range-Requests
- `/vsis3/` — Amazon S3
- `/vsigs/` — Google Cloud Storage
- `/vsiaz/` — Azure Blob Storage

Aus Sicht der Dart-API ändert sich nur der Dateipfad:

```dart
final dataset = gdal.openGeoTiff('/vsicurl/https://example.com/data.tif');
```

GDAL übernimmt intern das Caching und die Range-Request-Logik.
Die Dart-Schicht muss dafür keine eigene HTTP-Logik implementieren.

### Overviews

COGs enthalten typischerweise Overviews (reduzierte Auflösungsstufen).
GDAL stellt diese über die Band-API bereit:

- `GDALGetOverviewCount` — Anzahl der Overviews eines Bands
- `GDALGetOverview` — Zugriff auf ein Overview-Band

Ein Overview-Band verhält sich wie ein reguläres `RasterBand`, nur mit geringerer Auflösung.
Die Dart-API kann Overviews als zusätzliche Methoden auf `RasterBand` bereitstellen:

```dart
final band = dataset.band(1);
final overviewCount = band.overviewCount;
final overview = band.overview(0); // erstes Overview-Band
final thumbnail = overview.readAsUint8();
```

### Architektonische Konsequenzen

- Die bestehende synchrone API funktioniert auch für COG-Zugriff, weil GDAL die I/O-Komplexität intern kapselt.
- Für große Remote-Raster können synchrone Aufrufe allerdings blockieren. Falls nötig, kann Isolate-basierte Parallelität oberhalb der FFI-Schicht ergänzt werden (siehe Threading-Abschnitt).
- Die `native/`-Schicht muss um Overview-Funktionen erweitert werden, die Public API um Overview-Zugriff auf `RasterBand`.
- Konfiguration der virtuellen Dateisysteme (Credentials, Caching) erfolgt über GDALs eigene Konfigurationsmechanismen (`CPLSetConfigOption`), nicht über die Dart-API.

## Threading und Nebenläufigkeit

Erste Annahme:

- Die Public API ist synchron.
- Ein Dataset-Handle wird nicht parallel aus mehreren Isolates verwendet.

Begründung:

- Dart-Isolates teilen keinen Speicher direkt.
- Native Handles über Isolates hinweg erhöhen Komplexität und Fehlerrisiko.
- Für eine erste stabile FFI-Schicht ist ein synchrones Modell deutlich robuster.

Falls später nötig, kann Parallelität oberhalb der FFI-Schicht ergänzt werden, zum Beispiel durch:

- Dateiprozessierung pro Isolate
- getrennte Dataset-Handles pro Worker

## Plattformannahmen

Das Paket bindet an eine vorhandene GDAL-Installation.
Für die erste Iteration ist das realistischer als GDAL selbst mitzuliefern.

Das bedeutet:

- Linux, macOS und Windows brauchen GDAL zur Laufzeit
- Die Doku muss Installationspfade und Library-Namen beschreiben
- Tests sollten überspringen oder sauber fehlschlagen, wenn GDAL lokal fehlt

Für reproduzierbare lokale Checks und CI kann zusätzlich ein Docker-Workflow verwendet werden.
In diesem Fall stellt der Container die GDAL-Laufzeit und die Header für `ffigen` bereit, statt eine lokale Systeminstallation vorauszusetzen.

## Teststrategie

Die Testpyramide sollte drei Ebenen haben:

### 1. Pure Dart Tests

- Modelltypen
- Exception-Mapping
- Argumentvalidierung

### 2. FFI-Integrationstests

- GDAL-Library laden
- `GDALAllRegister`
- GeoTIFF öffnen
- Metadaten lesen
- kleine Rasterfenster lesen

### 3. Fixture-basierte End-to-End-Tests

- kleine GeoTIFF-Testdateien im Repository
- bekannte Dimensionen, Projektion und Pixelwerte

Wichtige Regel:

- Tests müssen klein und deterministisch sein
- Fixture-Dateien sollten möglichst kompakt bleiben

## Tile-Processing und Reprojektion

### Hintergrund

Für die Darstellung von GeoTIFF-Daten in Web-Mapping-Kontexten (deck.gl, Leaflet, Cesium) müssen Rasterdaten häufig von der Quellprojektion nach Web Mercator reprojiziert und kachelweise bereitgestellt werden.

### Ansatz: Triangulationsbasierte Reprojektion

Statt jeden Pixel einzeln zu projizieren (ca. 65.000 Projektionsaufrufe pro Tile), wird das Zielgebiet adaptiv in Dreiecke unterteilt. Nur die Dreieck-Eckpunkte werden transformiert, und für alle Pixel innerhalb eines Dreiecks wird eine affine Transformation verwendet. Das reduziert die Projektionsaufrufe auf ca. 50–200 pro Tile.

Dieser Ansatz basiert auf dem OpenLayers-Triangulationsverfahren und wurde aus dem v-map TypeScript-Projekt portiert.

### Architektur des Processing-Moduls

Das Modul liegt in `lib/src/processing/` und hat keine direkte FFI-Abhängigkeit. Es verwendet die öffentliche `gdal_dart`-API für Raster-Zugriffe.

```text
processing/
  triangle.dart            → Triangle-Datenstrukturen (Source/Target-Mapping)
  aabb2d.dart              → Axis-Aligned Bounding Box, Point2D, AffineTransform
  bvh_node2d.dart          → Bounding Volume Hierarchy für O(log n) Punkt-Lookups
  triangulation.dart       → Adaptive Triangulation mit Fehlersteuerung
  sampling_utils.dart      → Nearest-Neighbor und bilineare Interpolation
  normalization_utils.dart → Wert-Normalisierung für verschiedene Datentypen
  colormap_utils.dart      → Farbmapping mit vordefinierten Colormaps
  geotiff_tile_processor.dart → Orchestrierung: Tile-Bounds, Overview-Auswahl,
                               Raster-Lesen, Pixel-Rendering, Elevation-Daten
```

### Ablauf der Tile-Erzeugung

1. Tile-Bounds in der Zielprojektion berechnen
2. Prüfen, ob das Tile mit den Quell-Bounds überlappt (Early Exit)
3. Quell-Bounds für das Tile per Koordinatentransformation bestimmen
4. Passendes Overview-Level wählen
5. Pixel-Fenster berechnen und Rasterdaten lesen
6. Pixel per Triangulation reprojizieren und mit Sampling/Colormap rendern

### Elevation-Daten

Der Tile-Processor kann neben RGBA-Tiles auch Höhendaten als `Float32List` liefern, die für die Terrain-Mesh-Erzeugung (z.B. Martini) geeignet sind. Die Ausgabe hat die Größe `(tileSize+1)²` mit backfilled Rändern für Martini-Kompatibilität.

## Erweiterungspfad

Nach einer stabilen ersten Version ist diese Reihenfolge sinnvoll:

1. Robustes GeoTIFF-Lesen
2. Fenster- und Band-Lesen mit typisierten Buffern
3. Metadaten, NoData, Blockgrößen
4. Tile-/Block-basiertes Lesen für effiziente Kachelzugriffe
5. COG-Unterstützung: Fernzugriff via `/vsicurl/` und Overview-Zugriff
6. Schreiben neuer GeoTIFF-Dateien
7. Mehr GDAL-Treiber
8. Triangulationsbasierte Tile-Reprojektion und Rendering
9. Warping, Resampling und fortgeschrittene Rasteroperationen

## Entscheidungen

### Entscheidung 1: GDAL-C-API statt C++

Begründung:

- einfacher für `dart:ffi`
- stabilere ABI
- weniger Tooling-Risiko

### Entscheidung 2: Generierter und manueller Code strikt getrennt

Begründung:

- Updates an GDAL bleiben beherrschbar
- keine manuellen Eingriffe in generierten Code

### Entscheidung 3: Kleine Public API statt 1:1-API-Spiegelung

Begründung:

- Dart-Nutzer brauchen GeoTIFF-Funktionalität, nicht die gesamte GDAL-Oberfläche
- eine kleine API ist stabiler, testbarer und leichter dokumentierbar

### Entscheidung 4: Lesen zuerst, Schreiben später

Begründung:

- geringeres Risiko
- schneller nutzbarer Kern
- saubere Basis für spätere Erweiterung

## Architekturgrenzen

Die Architektur in diesem Dokument legt die Schichten, Zuständigkeiten und zentralen Entscheidungen fest.
Offene Produkt- und Umsetzungsfragen sowie die konkrete Reihenfolge der Arbeit gehören in die Roadmap:

- [roadmap.md](roadmap.md)
