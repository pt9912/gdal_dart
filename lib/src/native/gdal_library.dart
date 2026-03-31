import 'dart:ffi';
import 'dart:io';

import 'gdal_errors.dart';

/// Loads the GDAL shared library.
///
/// Resolution order:
/// 1. Explicit [path] parameter
/// 2. `GDAL_LIBRARY_PATH` environment variable
/// 3. Platform default name
DynamicLibrary loadGdalLibrary({String? path}) {
  final resolvedPath =
      path ?? Platform.environment['GDAL_LIBRARY_PATH'] ?? _defaultName();

  try {
    return DynamicLibrary.open(resolvedPath);
  } on ArgumentError catch (e) {
    throw GdalLibraryLoadException(
      'Failed to load GDAL library from "$resolvedPath": ${e.message}',
    );
  }
}

String _defaultName() {
  if (Platform.isLinux) return 'libgdal.so';
  if (Platform.isMacOS) return 'libgdal.dylib';
  if (Platform.isWindows) return 'gdal.dll';
  throw GdalLibraryLoadException(
    'Unsupported platform: ${Platform.operatingSystem}',
  );
}
