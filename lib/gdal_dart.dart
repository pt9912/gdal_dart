/// Dart FFI package for GeoTIFF functionality based on GDAL.
library;

export 'src/gdal.dart' show Gdal;
export 'src/geotiff_dataset.dart' show GeoTiffDataset;
export 'src/geotiff_writer.dart' show GeoTiffWriter;
export 'src/model/band_statistics.dart' show BandStatistics;
export 'src/model/color_interpretation.dart' show ColorInterpretation;
export 'src/model/geo_transform.dart' show GeoTransform;
export 'src/model/raster_data_type.dart' show RasterDataType;
export 'src/model/raster_window.dart' show RasterWindow;
export 'src/native/gdal_errors.dart'
    show
        GdalException,
        GdalLibraryLoadException,
        GdalDatasetClosedException,
        GdalFileException,
        GdalIOException;
export 'src/raster_band.dart' show RasterBand;
export 'src/spatial_reference.dart' show SpatialReference;
