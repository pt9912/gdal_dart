# Plan: CRSInfo-Cache via OSRGetCRSInfoListFromDatabase

Umgesetzt in v0.2.4.

## Context

`gdal_dart` cached bisher nur WKT-Strings (`getOrCreateWKT`). CRS-Metadaten
wie Name, Typ, Gueltigkeitsbereich und Projektionsmethode sind nicht abrufbar.
`OSRGetCRSInfoListFromDatabase` liefert diese Daten aus der PROJ-Datenbank.

**Ziel**: `gdal.getCRSInfo("EPSG:4326")` gibt ein immutables `CrsInfo`-Objekt
zurueck — per-Isolate gecached.

## Design

### Scope: Nur EPSG

`getCRSInfo()` unterstuetzt ausschliesslich EPSG-Codes. Andere Authorities
werden mit `ArgumentError` abgelehnt — analog zu `getOrCreateWKT()`.

### Cache-Strategie

`OSRGetCRSInfoListFromDatabase("EPSG", null, &count)` liefert **alle** Eintraege
einer Authority auf einmal (~6000 fuer EPSG). Deshalb:

1. Erster Aufruf laedt **alle** EPSG-Eintraege und cached sie
2. Jeder Folgeaufruf ist ein Map-Lookup
3. Cache: `static final Map<String, CrsInfo>` mit Key `"EPSG:4326"`
4. `authName` wird im `CrsInfo`-Konstruktor auf Uppercase normalisiert

### Dateien

| Datei | Aenderung |
|---|---|
| `lib/src/model/crs_info.dart` | Neues Model: `CrsInfo`, `CrsType` Enum |
| `lib/src/native/gdal_srs.dart` | FFI-Struct `_NativeOSRCRSInfo`, Lazy Lookup, `getCRSInfoList()` |
| `lib/src/gdal.dart` | `getCRSInfo()` mit Validierung und Cache |
| `lib/gdal_dart.dart` | Export `CrsInfo`, `CrsType` |
| `test/integration/crs_info_test.dart` | 12 Tests |

### Designentscheidungen

- **Lazy Symbol-Lookup**: `OSRGetCRSInfoListFromDatabase` wird per `late final`
  aufgeloest, nicht im Konstruktor — GDAL < 3.0 bricht nicht bei Init
- **GdalException bei fehlendem Symbol**: `ArgumentError` aus `lookupFunction`
  wird gefangen und als `GdalException('... requires GDAL >= 3.0')` geworfen
- **finally fuer OSRDestroyCRSInfoList**: Native Liste wird auch bei Exceptions
  waehrend der Materialisierung freigegeben
- **Kein `const` Konstruktor**: `CrsInfo` normalisiert `authName` per
  `toUpperCase()` in der Initializer-List — inkompatibel mit `const`
- **Numerische Validierung**: `EPSG:abc` wird als `ArgumentError` abgelehnt,
  konsistent mit `getOrCreateWKT()`

### Fehler-Uebersicht

| Eingabe | Exception | Meldung |
|---|---|---|
| `"4326"` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `"EPSG"` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `"EPSG:4326:extra"` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `"CUSTOM:999"` | `ArgumentError` | Unsupported authority |
| `"EPSG:abc"` | `ArgumentError` | Invalid EPSG code |
| `"EPSG:9999999"` | `GdalException` | CRS not found |
| `"epsg:4326"` | Erfolg | Case-Normalisierung |
| GDAL < 3.0 | `GdalException` | requires GDAL >= 3.0 |
