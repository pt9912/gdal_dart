import 'dart:ffi';
import 'dart:io';

/// Whether the GDAL shared library is available on this system.
final bool isGdalAvailable = _checkGdalAvailable();

bool _checkGdalAvailable() {
  final name = Platform.isLinux
      ? 'libgdal.so'
      : Platform.isMacOS
          ? 'libgdal.dylib'
          : Platform.isWindows
              ? 'gdal.dll'
              : '';
  if (name.isEmpty) return false;

  try {
    DynamicLibrary.open(name);
    return true;
  } catch (_) {
    return false;
  }
}
