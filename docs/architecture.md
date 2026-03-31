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
    raster_band.dart

tool/
  generate_bindings.dart

test/
  geotiff_open_test.dart
  geotiff_metadata_test.dart
  geotiff_read_test.dart
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

Für die erste Version sollte nur Lesen unterstützt werden.
Schreiben kann später analog über Dataset-Erzeugung und `GDALRasterIO` ergänzt werden.

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

## Erweiterungspfad

Nach einer stabilen ersten Version ist diese Reihenfolge sinnvoll:

1. Robustes GeoTIFF-Lesen
2. Fenster- und Band-Lesen mit typisierten Buffern
3. Metadaten, NoData, Blockgrößen
4. Schreiben neuer GeoTIFF-Dateien
5. Mehr GDAL-Treiber
6. Warping, Resampling und fortgeschrittene Rasteroperationen

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
