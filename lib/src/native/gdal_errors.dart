/// Base exception for all GDAL-related errors.
class GdalException implements Exception {
  /// A human-readable description of the error.
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

/// Thrown when an operation is attempted on a closed resource
/// ([GeoTiffDataset], [GeoTiffWriter], or [SpatialReference]).
class GdalDatasetClosedException extends GdalException {
  GdalDatasetClosedException(super.message);

  @override
  String toString() => 'GdalDatasetClosedException: $message';
}

/// Thrown when a file cannot be opened, created, or found.
class GdalFileException extends GdalException {
  /// The file path that caused the error, if available.
  final String? path;

  GdalFileException(super.message, {this.path});

  @override
  String toString() => 'GdalFileException: $message';
}

/// Thrown when a raster read or write operation fails.
class GdalIOException extends GdalException {
  GdalIOException(super.message);

  @override
  String toString() => 'GdalIOException: $message';
}
