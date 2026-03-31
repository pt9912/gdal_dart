/// Dart FFI package for GeoTIFF functionality based on GDAL.
library;

export 'src/gdal.dart' show Gdal;
export 'src/native/gdal_errors.dart'
    show GdalException, GdalLibraryLoadException, GdalDatasetClosedException;
