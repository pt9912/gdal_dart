# Architektur: GDAL in Dart

## Ziel

Dieses Projekt stellt GeoTIFF- und OGR-Vektor-Funktionalität aus GDAL für Dart bereit.
Es bietet Lesen, Schreiben, CRS-Handling, Koordinatentransformation, Tile-Processing und Vektor-Datenzugriff (GeoJSON, GeoPackage, Shapefile).
Die technische Basis sind:

- `dart:ffi` für den Aufruf der nativen GDAL-C-API
- `ffigen` zur Generierung der Low-Level-Bindings

## Nicht-Ziele für die erste Ausbaustufe

- Keine vollständige Abbildung der gesamten GDAL-API in einer öffentlichen Dart-API
- Keine direkte Veröffentlichung der durch `ffigen` erzeugten Symbole an Paketnutzer
- Kein vollständiger OGR-Vektor-Schreibzugriff (Lesen ist unterstützt)
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

Dateien:

- `lib/src/native/gdal_library.dart`
- `lib/src/native/gdal_api.dart`
- `lib/src/native/gdal_srs.dart`
- `lib/src/native/gdal_ogr.dart`
- `lib/src/native/gdal_errors.dart`
- `lib/src/native/gdal_constants.dart`
- `lib/src/native/gdal_memory.dart`

### 4. Öffentliche Dart-API

Die oberste Schicht stellt die fachliche API bereit.
Sie ist für Paketnutzer idiomatisch und stabil.

Typen:

- `Gdal` — Einstiegspunkt, Initialisierung, Factory-Methoden
- `GeoTiffDataset` — Lesezugriff auf Raster-Datasets
- `GeoTiffWriter` — Schreibzugriff, GeoTIFF-Erzeugung
- `GeoTiffSource` — Convenience-Wrapper mit vorberechneten WGS 84 Bounds
- `RasterBand` — Typisierter Pixel-/Tile-/Overview-Zugriff
- `SpatialReference` — CRS-Objekt (EPSG, WKT1/WKT2, Vergleich)
- `CoordinateTransform` — Koordinatentransformation zwischen CRS
- `GeoTransform` — Affine Transformation (6 Koeffizienten)
- `RasterWindow` — Rechteckiger Raster-Ausschnitt
- `RasterDataType` — GDAL-Datentyp-Enum
- `BandStatistics` — Min/Max/Mean/StdDev
- `ColorInterpretation` — Band-Farbinterpretation
- `GdalException` und Unterklassen
- `VectorDataset` — Lesezugriff auf OGR-Vektor-Datasets (GeoJSON, GeoPackage, Shapefile)
- `OgrLayer` — Layer-Zugriff mit Feature-Iteration
- `Feature` — Immutables Dart-Objekt mit Attributen und Geometrie
- `Geometry` — Sealed-Class-Hierarchie (Point, LineString, Polygon, Multi-Varianten)
- `OgrFieldType` — OGR-Feldtyp-Enum

Dateien:

- `lib/gdal_dart.dart`
- `lib/src/gdal.dart`
- `lib/src/geotiff_dataset.dart`
- `lib/src/geotiff_writer.dart`
- `lib/src/geotiff_source.dart`
- `lib/src/coordinate_transform.dart`
- `lib/src/raster_band.dart`
- `lib/src/spatial_reference.dart`
- `lib/src/vector_dataset.dart`
- `lib/src/ogr_layer.dart`
- `lib/src/ogr_feature.dart`
- `lib/src/model/...`

## Verzeichnisstruktur

```text
doc/
  architecture.md
  roadmap.md

ffigen.yaml

lib/
  gdal_dart.dart
  src/
    bindings/
      gdal_bindings.dart
    native/
      gdal_api.dart
      gdal_srs.dart
      gdal_ogr.dart
      gdal_errors.dart
      gdal_constants.dart
      gdal_library.dart
      gdal_memory.dart
    model/
      band_statistics.dart
      color_interpretation.dart
      field_type.dart
      geo_transform.dart
      geometry.dart
      raster_data_type.dart
      raster_window.dart
    gdal.dart
    geotiff_dataset.dart
    geotiff_writer.dart
    geotiff_source.dart
    vector_dataset.dart
    ogr_layer.dart
    ogr_feature.dart
    coordinate_transform.dart
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

test/
  helpers/
    gdal_test_helpers.dart
  fixtures/
    tiny.tif
    float32.tif
    multiband_uint16.tif
    tiled.tif
    not_a_tiff.bin
    points.geojson
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
    gdal_init_test.dart
    geotiff_open_test.dart
    geotiff_read_test.dart
    geotiff_write_test.dart
    geotiff_multiband_test.dart
    geotiff_source_test.dart
    spatial_reference_test.dart
    coordinate_transform_test.dart
    tile_and_overview_test.dart
    tile_processor_test.dart
    advanced_raster_test.dart
    error_paths_test.dart
    vector_open_test.dart
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

## API-Schnitt

### Einstiegspunkt

```dart
final gdal = Gdal();

// Lesen
final dataset = gdal.openGeoTiff('example.tif');
final band = dataset.band(1);
final pixels = band.readAsUint8();
dataset.close();

// GeoTiffSource mit WGS 84 Bounds
final source = gdal.openGeoTiffSource('dem.tif');
print(source.wgs84Bounds);
source.close();

// Koordinatentransformation
final ct = gdal.coordinateTransform(
  gdal.spatialReferenceFromEpsg(4326),
  gdal.spatialReferenceFromEpsg(32632),
);
final (x, y) = ct.transformPoint(11.58, 48.14);
ct.close();

// Schreiben
final writer = gdal.createGeoTiff('output.tif', width: 256, height: 256);
writer.writeAsUint8(1, Uint8List(256 * 256));
writer.close();
```

### Öffentliche Operationen

`Gdal`

- GDAL initialisieren, Treiber registrieren
- Dateien öffnen (`open`, `openGeoTiff`, `openGeoTiffSource`)
- GeoTIFF erzeugen (`createGeoTiff`)
- CRS erstellen (`spatialReferenceFromEpsg`, `spatialReferenceFromWkt`)
- Koordinatentransformation erzeugen (`coordinateTransform`)
- Versionsinformationen (`versionString`, `versionNumber`, `driverCount`)

`GeoTiffDataset`

- Dimensionen, Bandanzahl, Projektion, GeoTransform, Metadaten
- Rasterbänder abrufen, Bulk-Reads (`readAllBandsAsUint8/Float32`)
- SpatialReference abrufen

`GeoTiffSource`

- Vorberechnete WGS 84 Bounds und Quell-Bounds
- Koordinatentransformation nach WGS 84 (`transformToWgs84`)
- Zugriff auf Dataset, Bänder, GeoTransform, NoData, Resolution

`CoordinateTransform`

- Einzelpunkt-Transformation (`transformPoint`)
- Batch-Transformation (`transformPoints`)

`RasterBand`

- Typisierte Reads (`readAsUint8/Uint16/Int16/Uint32/Int32/Float32/Float64`)
- Resampled Reads, Tile-/Block-Zugriff, Overviews
- Statistiken, NoData, Datentyp, Farbinterpretation

`VectorDataset`

- Vektor-Datei öffnen (GeoJSON, GeoPackage, Shapefile, etc.)
- Layer-Anzahl, Layer nach Index oder Name abrufen

`OgrLayer`

- Layer-Name, Feature-Anzahl, Extent, Spatial Reference
- Feature nach FID oder per Iteration abrufen
- Felddefinitionen (Schema) auslesen

`Feature`

- Immutables Dart-Objekt (keine nativen Handles)
- FID, Attribute als `Map<String, Object?>`, Geometrie

`Geometry` (sealed class)

- Point, LineString, Polygon
- MultiPoint, MultiLineString, MultiPolygon, GeometryCollection

## Native Integrationsstrategie

### Warum die GDAL-C-API

Die C-API ist für FFI stabiler als C++-Bindings:

- einfachere ABI
- besser durch `ffigen` abbildbar
- weniger Build-Komplexität
- plattformübergreifend robuster

Die aktuell angebundenen C-Funktionen:

- `GDALAllRegister`, `GDALVersionInfo`, `GDALGetDriverCount`
- `GDALOpenEx`, `GDALClose`
- `GDALGetRasterXSize`, `GDALGetRasterYSize`, `GDALGetRasterCount`
- `GDALGetProjectionRef`, `GDALGetGeoTransform`
- `GDALGetRasterBand`, `GDALGetRasterDataType`, `GDALGetRasterNoDataValue`
- `GDALGetBlockSize`, `GDALRasterIO`, `GDALReadBlock`
- `GDALGetRasterBandXSize`, `GDALGetRasterBandYSize`
- `GDALGetOverviewCount`, `GDALGetOverview`
- `GDALGetMetadata`, `GDALGetMetadataItem`
- `GDALComputeRasterStatistics`, `GDALGetRasterColorInterpretation`
- `GDALGetDriverByName`, `GDALCreate`, `GDALSetGeoTransform`, `GDALSetProjection`
- `GDALSetRasterNoDataValue`, `GDALFlushCache`
- `OSRNewSpatialReference`, `OSRDestroySpatialReference`, `OSRImportFromEPSG`
- `OSRExportToWkt`, `OSRExportToWktEx`
- `OSRGetAuthorityCode`, `OSRGetAuthorityName`, `OSRIsSame`
- `OSRSetAxisMappingStrategy`
- `OCTNewCoordinateTransformation`, `OCTTransform`, `OCTDestroyCoordinateTransformation`
- `VSIFree`

OGR-Vektor-API (über `gdal_ogr.dart`):

- `GDALDatasetGetLayerCount`, `GDALDatasetGetLayer`, `GDALDatasetGetLayerByName`
- `OGR_L_GetName`, `OGR_L_GetFeatureCount`, `OGR_L_GetFeature`, `OGR_L_GetNextFeature`
- `OGR_L_ResetReading`, `OGR_L_GetLayerDefn`, `OGR_L_GetSpatialRef`, `OGR_L_GetExtent`
- `OGR_FD_GetFieldCount`, `OGR_FD_GetFieldDefn`
- `OGR_Fld_GetNameRef`, `OGR_Fld_GetType`
- `OGR_F_GetFID`, `OGR_F_GetFieldAsInteger`, `OGR_F_GetFieldAsInteger64`
- `OGR_F_GetFieldAsDouble`, `OGR_F_GetFieldAsString`, `OGR_F_IsFieldSetAndNotNull`
- `OGR_F_GetGeometryRef`, `OGR_F_Destroy`
- `OGR_G_GetGeometryType`, `OGR_G_GetPointCount`, `OGR_G_GetX`, `OGR_G_GetY`, `OGR_G_GetZ`
- `OGR_G_GetGeometryCount`, `OGR_G_GetGeometryRef`

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

`GeoTiffWriter`

- besitzt `GDALDatasetH` (Schreibmodus)
- `close()` flusht Daten und gibt das Handle frei

`GeoTiffSource`

- besitzt `GeoTiffDataset`, `CoordinateTransform` und `SpatialReference`-Instanzen
- `close()` gibt alle internen Ressourcen frei

`SpatialReference`

- besitzt `OGRSpatialReferenceH`
- unabhängig vom Dataset — muss separat geschlossen werden

`CoordinateTransform`

- besitzt `OGRCoordinateTransformationH`
- referenziert keine SRS-Handles (nur bei Erstellung benötigt)

`RasterBand`

- besitzt das Band-Handle nicht separat
- lebt logisch nur solange das Dataset offen ist

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

### CRS-Zugriff (implementiert)

Das Projekt bietet vollständigen CRS-Zugriff über die OGR Spatial Reference API (OSR):

```dart
final crs = dataset.spatialReference;
print(crs.authorityName);     // "EPSG"
print(crs.authorityCode);     // "4326"
print(crs.toWkt());           // WKT1
print(crs.toWkt2());          // WKT2:2019
crs.close();
```

### Koordinatentransformation (implementiert)

Koordinatentransformation zwischen CRS erfolgt über die GDAL OCT API:

```dart
final wgs84 = gdal.spatialReferenceFromEpsg(4326);
final utm32 = gdal.spatialReferenceFromEpsg(32632);
final ct = gdal.coordinateTransform(wgs84, utm32);
final (x, y) = ct.transformPoint(11.58, 48.14);
ct.close();
```

### GeoTiffSource (implementiert)

Convenience-Klasse, die Dataset-Metadaten, WGS 84 Bounds und Koordinatentransformation bündelt:

```dart
final source = gdal.openGeoTiffSource('dem.tif');
print(source.fromProjection);   // "EPSG:32632"
print(source.wgs84Bounds);      // (west, south, east, north)
final (lon, lat) = source.transformToWgs84(500000, 5400000);
source.close();
```

### Achsenreihenfolge

Alle `SpatialReference`-Instanzen setzen `OAMS_TRADITIONAL_GIS_ORDER`, damit Koordinaten konsistent in `(lon/lat)` bzw. `(easting/northing)` vorliegen. Das verhindert die GDAL 3.x-Standardreihenfolge `(lat/lon)`.

### Angebundene C-Funktionen (OSR/OCT)

- `OSRNewSpatialReference` — CRS-Objekt erzeugen
- `OSRDestroySpatialReference` — CRS-Objekt freigeben
- `OSRImportFromEPSG` — CRS aus EPSG-Code laden
- `OSRExportToWkt` — Export als WKT1
- `OSRExportToWktEx` — Export als WKT2 mit Formatoptionen
- `OSRGetAuthorityCode` / `OSRGetAuthorityName` — Authority-Code auslesen
- `OSRIsSame` — CRS-Vergleich
- `OSRSetAxisMappingStrategy` — Achsenreihenfolge setzen
- `OCTNewCoordinateTransformation` — Transformation zwischen zwei CRS erzeugen
- `OCTTransform` — Punkte transformieren
- `OCTDestroyCoordinateTransformation` — Transformation freigeben

Referenz: [GDAL OGR Spatial Reference Tutorial](https://gdal.org/en/stable/tutorials/osr_api_tut.html)

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

Umgesetzt:

1. GeoTIFF-Lesen (Dimensionen, Metadaten, GeoTransform, Projektion)
2. Typisierte Band-Reads mit Fenster-Support
3. Tile-/Block-Lesen, COG-Zugriff, Overviews
4. GeoTIFF-Schreiben
5. CRS-Zugriff über OSR-API (EPSG, WKT1/WKT2, Vergleich)
6. Koordinatentransformation (OCT API)
7. GeoTiffSource mit WGS 84 Bounds
8. Triangulationsbasierte Tile-Reprojektion und Rendering
9. OGR-Vektor-Lesen (GeoJSON, GeoPackage, Shapefile)

Mögliche nächste Schritte:

- OGR-Vektor-Schreiben
- Spatial Filter und Attribut-Filter auf Layern
- GeoPackage-Raster-Zugriff
- Warping und Resampling über GDAL
- Mehr GDAL-Treiber (NetCDF, JPEG2000, …)
- Async-/Isolate-basierte Parallelität
- Optionaler `Finalizer` zusätzlich zu explizitem `close()`

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
