import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'gdal_memory.dart';

// Native function typedefs.
typedef _AllRegisterC = Void Function();
typedef _AllRegisterDart = void Function();

typedef _VersionInfoC = Pointer<Utf8> Function(Pointer<Utf8> request);
typedef _VersionInfoDart = Pointer<Utf8> Function(Pointer<Utf8> request);

typedef _GetDriverCountC = Int32 Function();
typedef _GetDriverCountDart = int Function();

/// Low-level access to GDAL C API functions.
///
/// Uses manual [DynamicLibrary.lookupFunction] calls. The generated
/// ffigen bindings in `lib/src/bindings/` are not required for this layer.
class GdalApi {
  late final _AllRegisterDart _allRegister;
  late final _VersionInfoDart _versionInfo;
  late final _GetDriverCountDart _getDriverCount;

  GdalApi(DynamicLibrary lib) {
    _allRegister = lib
        .lookupFunction<_AllRegisterC, _AllRegisterDart>('GDALAllRegister');
    _versionInfo = lib
        .lookupFunction<_VersionInfoC, _VersionInfoDart>('GDALVersionInfo');
    _getDriverCount = lib
        .lookupFunction<_GetDriverCountC, _GetDriverCountDart>(
            'GDALGetDriverCount');
  }

  /// Registers all known GDAL drivers.
  void allRegister() => _allRegister();

  /// Returns GDAL version information for the given [request].
  ///
  /// Common requests: `RELEASE_NAME`, `VERSION_NUM`, `BUILD_INFO`.
  /// The returned C string is owned by GDAL and must not be freed.
  String versionInfo(String request) {
    return withNativeString(request, (ptr) {
      return readNativeString(_versionInfo(ptr));
    });
  }

  /// Returns the number of registered GDAL drivers.
  int getDriverCount() => _getDriverCount();
}
