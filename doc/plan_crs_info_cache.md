# Plan: CRSInfo-Cache via OSRGetCRSInfoListFromDatabase

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
3. Cache: `static final Map<String, CrsInfo> _crsInfoCache = {}`
   Key-Format: `"EPSG:4326"` (normalisiert, immer Uppercase Authority)
4. Zusaetzlich: `static bool _crsInfoLoaded = false`

### Dateien

#### 1. Neues Model: `lib/src/model/crs_info.dart`

```dart
enum CrsType {
  geographic2D(0),
  geographic3D(1),
  geocentric(2),
  projected(3),
  vertical(4),
  compound(5),
  other(6);

  final int ogrValue;
  const CrsType(this.ogrValue);
  static CrsType fromOgr(int value) => ...;
}

class CrsInfo {
  final String authName;     // immer Uppercase, z.B. "EPSG"
  final String code;         // z.B. "4326"
  final String name;         // z.B. "WGS 84"
  final CrsType type;
  final bool deprecated;
  // Bounding Box (null wenn bboxValid == false)
  final double? westLon;
  final double? southLat;
  final double? eastLon;
  final double? northLat;
  final String? areaName;             // z.B. "World"
  final String? projectionMethod;     // z.B. "Transverse Mercator"

  CrsInfo({ required String authName, ... })
      : authName = authName.toUpperCase(), ...;

  /// Normalisierter Cache-Key, z.B. `"EPSG:4326"`.
  /// authName ist im Konstruktor auf Uppercase normalisiert.
  String get key => '$authName:$code';

  @override
  String toString() => 'CrsInfo($key, $name)';
}
```

**Normalisierung**: Der `CrsInfo`-Konstruktor normalisiert `authName`
auf Uppercase (`authName: authName.toUpperCase()`). Damit ist
`CrsInfo.key` immer konsistent — unabhaengig davon, was die native
Schicht liefert.

#### 2. FFI-Bindings: `lib/src/native/gdal_srs.dart`

**Lazy Lookup** — NICHT im Konstruktor, sondern beim ersten Aufruf.
Grund: `OSRGetCRSInfoListFromDatabase` existiert erst ab GDAL 3.0.
Wuerde das Symbol eager im `GdalSrs`-Konstruktor aufgeloest, bricht
die gesamte Paket-Initialisierung auf aelteren GDAL-Versionen, auch
wenn `getCRSInfo()` nie aufgerufen wird.

```dart
// DynamicLibrary als Feld speichern (bisher nicht noetig)
final DynamicLibrary _lib;

// Lazy — erst bei Bedarf aufloesen
late final _getCRSInfoList = _lib.lookupFunction<...>('OSRGetCRSInfoListFromDatabase');
late final _destroyCRSInfoList = _lib.lookupFunction<...>('OSRDestroyCRSInfoList');
```

**Fehlerbehandlung bei fehlendem Symbol**: Der rohe `ArgumentError`
aus `lookupFunction` wird in `getCRSInfoList()` gefangen und als
`GdalException` mit klarer Meldung weitergeworfen:

```dart
List<CrsInfo> getCRSInfoList(String authName) {
  // Lazy lookup kann ArgumentError werfen wenn Symbol fehlt
  final getCRSInfoListFn;
  final destroyCRSInfoListFn;
  try {
    getCRSInfoListFn = _getCRSInfoList;
    destroyCRSInfoListFn = _destroyCRSInfoList;
  } on ArgumentError {
    throw GdalException(
      'OSRGetCRSInfoListFromDatabase not available — '
      'requires GDAL >= 3.0');
  }
  // ... rest der Implementierung
}
```

Erste FFI-Struct-Definition im Codebase:

```dart
final class _NativeOSRCRSInfo extends Struct {
  external Pointer<Utf8> pszAuthName;
  external Pointer<Utf8> pszCode;
  external Pointer<Utf8> pszName;
  @Int32() external int eType;
  @Int32() external int bDeprecated;
  @Int32() external int bBboxValid;
  @Double() external double dfWestLongitudeDeg;
  @Double() external double dfSouthLatitudeDeg;
  @Double() external double dfEastLongitudeDeg;
  @Double() external double dfNorthLatitudeDeg;
  external Pointer<Utf8> pszAreaName;
  external Pointer<Utf8> pszProjectionMethodName;
}
```

Vollstaendige `getCRSInfoList` mit `finally`-Garantie:

```dart
List<CrsInfo> getCRSInfoList(String authName) {
  final getCRSInfoListFn;
  final destroyCRSInfoListFn;
  try {
    getCRSInfoListFn = _getCRSInfoList;
    destroyCRSInfoListFn = _destroyCRSInfoList;
  } on ArgumentError {
    throw GdalException(
      'OSRGetCRSInfoListFromDatabase not available — '
      'requires GDAL >= 3.0');
  }

  final countPtr = calloc<Int32>();
  Pointer<Pointer<_NativeOSRCRSInfo>> list = nullptr;
  try {
    list = withNativeString(authName, (namePtr) {
      return getCRSInfoListFn(namePtr, nullptr, countPtr);
    });
    final count = countPtr.value;
    return [
      for (int i = 0; i < count; i++)
        _materializeCrsInfo(list[i].ref),
    ];
  } finally {
    calloc.free(countPtr);
    if (list != nullptr) destroyCRSInfoListFn(list);
  }
}
```

#### 3. Cache + API: `lib/src/gdal.dart`

Eingabevalidierung konsistent mit `getOrCreateWKT()`:

```dart
static final Map<String, CrsInfo> _crsInfoCache = {};
static bool _crsInfoLoaded = false;

CrsInfo getCRSInfo(String key) {
  // 1. Formatvalidierung: genau "AUTHORITY:CODE"
  final parts = key.split(':');
  if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
    throw ArgumentError('Expected "AUTHORITY:CODE" format, got "$key"');
  }
  final authority = parts[0].toUpperCase();
  final code = parts[1];

  // 2. Nur EPSG unterstuetzt
  if (authority != 'EPSG') {
    throw ArgumentError('Unsupported authority "$authority" — '
        'only EPSG is supported');
  }

  // 3. Numerische Validierung (konsistent mit getOrCreateWKT)
  if (int.tryParse(code) == null) {
    throw ArgumentError('Invalid EPSG code "$code"');
  }

  // 4. Normalisierten Key verwenden
  final normalizedKey = '$authority:$code';

  // 5. Cache-Hit?
  final cached = _crsInfoCache[normalizedKey];
  if (cached != null) return cached;

  // 6. Noch nicht geladen → komplett laden
  if (!_crsInfoLoaded) {
    final list = _srs.getCRSInfoList('EPSG');
    for (final info in list) {
      _crsInfoCache[info.key] = info;
    }
    _crsInfoLoaded = true;
  }

  // 7. Lookup mit normalisiertem Key
  final result = _crsInfoCache[normalizedKey];
  if (result == null) {
    throw GdalException('CRS not found: $normalizedKey');
  }
  return result;
}
```

### Fehler-Uebersicht

| Eingabe | Exception | Meldung |
|---|---|---|
| `"4326"` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `"EPSG"` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `"EPSG:4326:extra"` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `""` | `ArgumentError` | Expected "AUTHORITY:CODE" format |
| `"CUSTOM:999"` | `ArgumentError` | Unsupported authority |
| `"EPSG:abc"` | `ArgumentError` | Invalid EPSG code |
| `"EPSG:9999999"` | `GdalException` | CRS not found |
| `"epsg:4326"` | Erfolg | Case-Normalisierung |
| GDAL < 3.0 | `GdalException` | requires GDAL >= 3.0 |

#### 4. Export: `lib/gdal_dart.dart`

Neue Exports: `CrsInfo`, `CrsType`

#### 5. Tests: `test/integration/crs_info_test.dart`

- `getCRSInfo("EPSG:4326")` → name `"WGS 84"`, type `geographic2D`
- `getCRSInfo("EPSG:32632")` → type `projected`
- `getCRSInfo("epsg:4326")` → funktioniert (Case-Normalisierung)
- Zweiter Aufruf → `identical()` (Cache-Hit, selbes Objekt)
- `getCRSInfo("4326")` → `ArgumentError`
- `getCRSInfo("EPSG")` → `ArgumentError`
- `getCRSInfo("EPSG:4326:extra")` → `ArgumentError`
- `getCRSInfo("EPSG:abc")` → `ArgumentError`
- `getCRSInfo("CUSTOM:999")` → `ArgumentError`
- `getCRSInfo("EPSG:9999999")` → `GdalException`

## Verifikation

```bash
docker build --target analyze --progress=plain .
docker build --target test --no-cache-filter test --progress=plain .
docker build --target coverage-check --no-cache-filter coverage \
  --progress=plain --build-arg COVERAGE_MIN=95 .
```
