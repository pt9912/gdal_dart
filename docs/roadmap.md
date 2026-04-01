# Roadmap

## Zielbild

Das Projekt stellt eine schlanke, stabile Dart-API für GeoTIFF auf Basis von GDAL bereit.
Es deckt Lesen, Schreiben, CRS-Handling, Koordinatentransformation und Tile-Processing ab.

## Leitlinien

- Erst ein kleiner stabiler Kern, dann Funktionsausbau
- Öffentliche API klein halten
- Native Komplexität intern kapseln
- Tests und Fixtures früh etablieren
- GeoTIFF zuerst, generisches Raster später

## Phase 0: Projektgrundlage ✓

Ziel:
Ein lauffähiges Dart-Paket mit klarer Struktur und reproduzierbarer Binding-Generierung.

Umfang:

- `pubspec.yaml` anlegen
- `ffigen` als Dev-Dependency aufnehmen
- `ffigen.yaml` definieren
- Verzeichnisstruktur aus `docs/architecture.md` anlegen
- Skript oder Workflow zur Binding-Generierung anlegen
- Dockerfile für reproduzierbare Analyse-, Test- und Doku-Läufe anlegen

Ergebnis:

- Paket lässt sich lokal aufsetzen
- Bindings können reproduzierbar generiert werden

## Phase 1: Native Basis ✓

Ziel:
Die GDAL-Bibliothek zuverlässig laden und eine minimale native Brücke bereitstellen.

Umfang:

- `DynamicLibrary`-Lader implementieren
- Plattformabhängige Library-Namen kapseln
- Optionalen expliziten Library-Pfad unterstützen
- `GDALAllRegister` anbinden
- Grundlegende Fehlerbehandlung für fehlende Library und ungültige Handles implementieren

Ergebnis:

- GDAL kann aus Dart initialisiert werden
- Fehler bei fehlender Laufzeitumgebung sind klar diagnostizierbar

## Phase 2: GeoTIFF öffnen und Metadaten lesen ✓

Ziel:
GeoTIFF-Dateien sicher öffnen und zentrale Dataset-Informationen auslesen.

Umfang:

- `Gdal.openGeoTiff(...)`
- `GeoTiffDataset` mit `close()`
- Breite, Höhe und Bandanzahl
- Projektion und GeoTransform
- Basis-Metadaten als Dart-Strukturen

Ergebnis:

- Erste nutzbare End-to-End-Funktionalität für reale GeoTIFF-Dateien

## Phase 3: Rasterband-Lesen ✓

Ziel:
Typisierte Pixelzugriffe für ganze Bänder und Fenster bereitstellen.

Umfang:

- `RasterBand`-Abstraktion
- Datentyp und NoData lesen
- Blockgrößen lesen
- `GDALRasterIO` für ganze Bänder
- `GDALRasterIO` für Fenster
- Rückgabe als typisierte Dart-Listen

Ergebnis:

- Praktisch nutzbarer Lesekern für Analyse- und Anzeige-Use-Cases

## Phase 3b: Tile-Lesen und COG-Unterstützung ✓

Ziel:
Kachelbasiertes Lesen und Zugriff auf Cloud Optimized GeoTIFF (COG) ermöglichen.

Umfang:

- Tile-/Block-basiertes Lesen über `GDALRasterIO` mit Fenstergrößen passend zur Blockgröße
- Fernzugriff auf COGs via GDALs virtuelle Dateisysteme (`/vsicurl/`, `/vsis3/`, `/vsigs/`, `/vsiaz/`)
- Overview-Anzahl lesen (`GDALGetOverviewCount`)
- Overview-Band abrufen (`GDALGetOverview`)
- Overview-Daten lesen über bestehende `RasterBand`-Leseoperationen

Ergebnis:

- GeoTIFFs können kachelweise statt nur als Ganzes gelesen werden
- Remote-gehostete COGs sind über Pfad-Konvention nutzbar
- Overviews ermöglichen effizienten Mehrskalenzugriff

## Phase 4: Test- und Fixture-Basis festigen ✓

Ziel:
Die FFI-Schicht gegen Regressionen absichern.

Umfang:

- Kleine GeoTIFF-Fixtures ins Repository aufnehmen
- Pure-Dart-Tests für Modelle und Fehlerpfade
- Integrationstests für Library-Loading und Dataset-Zugriff
- Raster-Lesetests mit bekannten Pixelwerten
- Sauberes Überspringen von Tests ohne lokale GDAL-Installation

Ergebnis:

- Änderungen an Bindings und FFI-Schicht sind sicherer

## Phase 5: GeoTIFF schreiben ✓

Ziel:
Neue GeoTIFF-Dateien aus Dart erzeugen und befüllen.

Umfang:

- Dataset-Erzeugung über GDAL-Treiber
- Banddaten schreiben
- GeoTransform setzen
- Projektion setzen
- NoData und einfache Erstellungsoptionen unterstützen

Ergebnis:

- Das Paket kann nicht nur lesen, sondern auch neue GeoTIFFs erzeugen

## Phase 5b: Raumbezug und CRS über die OSR-API ✓

Ziel:
Koordinatenreferenzsysteme aus GeoTIFF-Datasets strukturiert auslesen und in verschiedenen Formaten exportieren.

Umfang:

- `SpatialReference`-Modell in der `model/`-Schicht einführen
- CRS aus Dataset-WKT importieren (`OSRImportFromWkt`)
- Export als WKT1 (`OSRExportToWkt`) und WKT2 (`OSRExportToWktEx`)
- Authority-Code und -Name auslesen (`OSRGetAuthorityCode`, `OSRGetAuthorityName`)
- CRS-Vergleich (`OSRIsSame`)
- `ogr_srs_api.h` in `ffigen.yaml` aufnehmen
- Native Brücke (`gdal_srs.dart`) für OSR-Funktionen anlegen
- Lifecycle: OSR-Handle über `close()` oder bei Dataset-Schließung freigeben

Ergebnis:

- CRS-Informationen sind als typisiertes Dart-Objekt verfügbar statt nur als WKT-String
- Authority-Codes (z.B. `EPSG:4326`) sind direkt abrufbar
- Grundlage für spätere Koordinatentransformation

Referenz: [GDAL OGR Spatial Reference Tutorial](https://gdal.org/en/stable/tutorials/osr_api_tut.html)

## Phase 6: API-Härtung ✓

Ziel:
Die öffentliche API stabilisieren und für Nutzung durch andere Pakete vorbereiten.

Umfang:

- API-Namen und Typen bereinigen
- Exception-Hierarchie schärfen
- Ressourcenlebensdauer dokumentieren
- Beispiele und Minimal-Guides ergänzen
- Breaking-Change-Risiken reduzieren

Ergebnis:

- Eine belastbare öffentliche API für erste Releases

## Phase 7: Erweiterte Raster-Funktionen ✓

Ziel:
Nützliche Raster-Funktionen ergänzen, ohne die API unnötig aufzublähen.

Umfang:

- Mehr Datentypen und komfortable Konvertierungen
- Mehrband-Lesehilfen
- Subsets und Resampling-Optionen
- Erweiterte Metadatenzugriffe
- Optionale generische Raster-Unterstützung über GeoTIFF hinaus

Ergebnis:

- Das Paket deckt mehr praktische GDAL-Raster-Workflows ab

## Phase 7b: Tile-Processing und Reprojektion ✓

Ziel:
Triangulationsbasierte Tile-Erzeugung mit Reprojektion für Web-Mapping-Use-Cases bereitstellen.

Umfang:

- Adaptive Triangulation für effiziente Raster-Reprojektion (portiert aus v-map)
- BVH-Index für schnelle Point-in-Triangle-Queries
- Nearest-Neighbor- und bilineare Interpolation
- Wert-Normalisierung für verschiedene Datentypen (Uint8–Float64)
- Vordefinierte Colormaps (viridis, terrain, turbo, rainbow, grayscale)
- `GeoTIFFTileProcessor` für RGBA-Tile-Rendering und Elevation-Daten
- Overview-Auswahl nach Zoom-Level
- Martini-kompatible Elevation-Ausgabe

Ergebnis:

- GeoTIFF-Daten können kachelweise reprojiziert und für Web-Mapping aufbereitet werden
- Elevation-Daten stehen für Terrain-Mesh-Erzeugung bereit
- Colormaps ermöglichen flexible Visualisierung von Einband-Daten

## Phase 8: Koordinatentransformation und GeoTiffSource ✓

Ziel:
Koordinatentransformation zwischen CRS und eine Convenience-Klasse für GeoTIFF-Quellen mit vorberechneten WGS 84 Bounds bereitstellen.

Umfang:

- FFI-Bindings für `OCTNewCoordinateTransformation`, `OCTTransform`, `OCTDestroyCoordinateTransformation`
- FFI-Binding für `OSRSetAxisMappingStrategy` mit automatischem `OAMS_TRADITIONAL_GIS_ORDER`
- `CoordinateTransform`-Klasse mit `transformPoint()` und `transformPoints()`
- `GeoTiffSource`-Klasse: bündelt Dataset, WGS 84 Bounds, Quell-Bounds, Projektion, Koordinatentransformation
- Factory-Methoden `Gdal.coordinateTransform()` und `Gdal.openGeoTiffSource()`
- Portierung der Kernfunktionalität von v-map `geotiff-source.ts` nach Dart

Ergebnis:

- Koordinaten können zwischen beliebigen CRS transformiert werden
- GeoTIFF-Metadaten und WGS 84 Bounds stehen als fertiges Objekt bereit
- Achsenreihenfolge ist konsistent (lon/lat statt lat/lon bei GDAL 3.x)

## Phase 9: Distribution und Developer Experience

Ziel:
Installation, Build und Nutzung auf allen Zielplattformen vereinfachen.

Umfang:

- Plattformdoku für Linux, macOS und Windows
- Hinweise zu GDAL-Installation und Suchpfaden
- Docker-basierte Developer- und CI-Workflows dokumentieren
- Beispielprojekte
- CI für Tests und statische Checks
- Entscheidung über reine Systeminstallation oder spätere gebündelte Binaries

Ergebnis:

- Das Paket ist einfacher installierbar und wartbarer

## Kurzfristige Prioritäten

Alle bisherigen Prioritäten sind umgesetzt:

1. ~~Projektgrundgerüst anlegen~~ ✓
2. ~~`ffigen`-Workflow einrichten~~ ✓
3. ~~GDAL laden und initialisieren~~ ✓
4. ~~GeoTIFF öffnen und Metadaten lesen~~ ✓
5. ~~Rasterband-Lesen per `GDALRasterIO`~~ ✓
6. ~~Tile-Lesen und COG-Zugriff~~ ✓
7. ~~Fixtures und Integrationstests ergänzen~~ ✓
8. ~~CRS-Zugriff über OSR-API~~ ✓
9. ~~Tile-Processing und Reprojektion~~ ✓
10. ~~Koordinatentransformation und GeoTiffSource~~ ✓

Nächste Prioritäten:

- Warping und Resampling über GDAL
- Async-/Isolate-basierte Parallelität
- Distribution und Developer Experience

## Meilensteine

### M1: Paket bootstrapped ✓

- Projektstruktur vorhanden
- Bindings generierbar
- GDAL-Library ladbar

### M2: Read-only MVP ✓

- GeoTIFF öffnen
- Metadaten lesen
- Banddaten lesen
- Tile-/Block-Lesen und COG-Fernzugriff
- Overview-Zugriff
- Integrationstests vorhanden

### M2b: CRS-Zugriff ✓

- SpatialReference-Modell
- WKT- und Authority-Code-Export
- CRS-Vergleich

### M3: Write support ✓

- GeoTIFF erzeugen
- Pixeldaten schreiben
- Raumbezug setzen

### M3b: Tile-Processing ✓

- Triangulationsbasierte Reprojektion
- Tile-Rendering mit Colormaps
- Elevation-Daten für Terrain-Meshes

### M3c: Koordinatentransformation ✓

- CoordinateTransform-Klasse (OCT API)
- GeoTiffSource mit WGS 84 Bounds
- Achsenreihenfolge-Fix (OAMS_TRADITIONAL_GIS_ORDER)

### M4: Erstes öffentlich nutzbares Release

- API dokumentiert
- Beispiele vorhanden
- Plattformhinweise vorhanden
- Kernfunktionalität stabil

## Offene Entscheidungen

- Unterstützte Minimalversion von GDAL (aktuell getestet mit 3.8.x)
- Umgang mit fehlender Systeminstallation (gebündelte Binaries vs. reine Systeminstallation)
- Nur GeoTIFF oder mittelfristig generisches Raster
- Optionaler `Finalizer` zusätzlich zu explizitem `close()`
- Async-/Isolate-basierte Parallelität für große Remote-Raster
