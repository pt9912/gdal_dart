# Roadmap

## Zielbild

Das Projekt soll eine schlanke, stabile Dart-API für GeoTIFF auf Basis von GDAL bereitstellen.
Die erste Priorität ist ein belastbarer Lesepfad über `dart:ffi` und `ffigen`.
Darauf aufbauend folgen Schreiben, mehr Raster-Funktionen und bessere Distribution.

## Leitlinien

- Erst ein kleiner stabiler Kern, dann Funktionsausbau
- Öffentliche API klein halten
- Native Komplexität intern kapseln
- Tests und Fixtures früh etablieren
- GeoTIFF zuerst, generisches Raster später

## Phase 0: Projektgrundlage

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

## Phase 1: Native Basis

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

## Phase 2: GeoTIFF öffnen und Metadaten lesen

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

## Phase 3: Rasterband-Lesen

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

## Phase 3b: Tile-Lesen und COG-Unterstützung

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

## Phase 4: Test- und Fixture-Basis festigen

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

## Phase 5: GeoTIFF schreiben

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

## Phase 5b: Raumbezug und CRS über die OSR-API

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

## Phase 6: API-Härtung

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

## Phase 7: Erweiterte Raster-Funktionen

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

## Phase 8: Distribution und Developer Experience

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

1. Projektgrundgerüst anlegen
2. `ffigen`-Workflow einrichten
3. GDAL laden und initialisieren
4. GeoTIFF öffnen und Metadaten lesen
5. Rasterband-Lesen per `GDALRasterIO`
6. Tile-Lesen und COG-Zugriff
7. Fixtures und Integrationstests ergänzen
8. CRS-Zugriff über OSR-API

## Meilensteine

### M1: Paket bootstrapped

- Projektstruktur vorhanden
- Bindings generierbar
- GDAL-Library ladbar

### M2: Read-only MVP

- GeoTIFF öffnen
- Metadaten lesen
- Banddaten lesen
- Tile-/Block-Lesen und COG-Fernzugriff
- Overview-Zugriff
- Integrationstests vorhanden

### M2b: CRS-Zugriff

- SpatialReference-Modell
- WKT- und Authority-Code-Export
- CRS-Vergleich

### M3: Write support

- GeoTIFF erzeugen
- Pixeldaten schreiben
- Raumbezug setzen

### M4: Erstes öffentlich nutzbares Release

- API dokumentiert
- Beispiele vorhanden
- Plattformhinweise vorhanden
- Kernfunktionalität stabil

## Offene Entscheidungen

- Unterstützte Minimalversion von GDAL
- Umgang mit fehlender Systeminstallation
- Umfang der ersten öffentlichen API
- Nur GeoTIFF oder mittelfristig generisches Raster
- Optionaler `Finalizer` zusätzlich zu explizitem `close()`
