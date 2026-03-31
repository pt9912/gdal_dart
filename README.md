# gdal_dart

`gdal_dart` ist ein Dart-FFI-Paket für GeoTIFF-Funktionalität auf Basis von GDAL.
Der Schwerpunkt liegt zunächst auf einem kleinen, stabilen Read-only-Kern für Rasterdaten und Metadaten.

## Status

Das Repository enthält aktuell die Architektur- und Umsetzungsplanung.
Die Implementierung des Pakets wird schrittweise aufgebaut.
Ein vollständiges Dart-Paket-Scaffold mit `pubspec.yaml` ist aktuell noch nicht vorhanden.

- Architektur: [docs/architecture.md](docs/architecture.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## Ziel

Geplant ist eine API auf Basis von:

- `dart:ffi` für den Zugriff auf die GDAL-C-API
- `ffigen` für generierte Low-Level-Bindings

Die erste Ausbaustufe fokussiert:

- GeoTIFF-Dateien öffnen
- Raster-Metadaten lesen
- Banddaten typisiert lesen

## Entwicklung

Für reproduzierbare Checks gibt es ein Multi-Stage-[`Dockerfile`](Dockerfile).
Die vorgesehenen Stages sind:

- `analyze`
- `test`
- `coverage`
- `coverage-check`
- `doc`
- `bindings`
- `publish-check`

Die Stages sind bewusst getrennt:

- `analyze`, `doc` und `publish-check` laufen ohne GDAL- oder Clang-Systempakete
- `test` nutzt eine GDAL-Runtime-Basis
- `coverage` erzeugt einen `lcov`-Report
- `coverage-check` prüft einen Mindestwert über `COVERAGE_MIN`
- `bindings` nutzt die erweiterte Basis mit `clang` und `libclang` für `ffigen`

Die Docker-Stages sind erst nutzbar, sobald das Dart-Paket-Scaffold vorhanden ist.

Beispiele ab diesem Zeitpunkt:

```bash
docker build --target analyze .
docker build --target test .
docker build --target coverage .
docker build --target coverage-check --build-arg COVERAGE_MIN=80 .
docker build --target doc .
docker build --target bindings .
docker build --target publish-check .
```

## CI/CD

GitHub Actions sind für folgende Aufgaben vorgesehen:

- Continuous Integration für Analyse, Test, Coverage-Threshold und Dokumentation
- Publish-Workflow für `pub.dev`

Der Publish-Workflow läuft über Release-Tags im Format `gdal_dart-v*.*.*`.
Vor dem Publish prüft er Tag-Namensschema, `pubspec.yaml`-Version, `CHANGELOG.md` und ob der Tag-Commit auf `main` oder `master` liegt.
