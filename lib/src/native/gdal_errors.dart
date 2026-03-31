/// Base exception for all GDAL-related errors.
class GdalException implements Exception {
  final String message;

  GdalException(this.message);

  @override
  String toString() => 'GdalException: $message';
}

/// Thrown when the GDAL shared library cannot be loaded.
class GdalLibraryLoadException extends GdalException {
  GdalLibraryLoadException(super.message);

  @override
  String toString() => 'GdalLibraryLoadException: $message';
}

/// Thrown when an operation is attempted on a closed dataset.
class GdalDatasetClosedException extends GdalException {
  GdalDatasetClosedException(super.message);

  @override
  String toString() => 'GdalDatasetClosedException: $message';
}
