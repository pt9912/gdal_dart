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
export 'src/processing/aabb2d.dart' show Point2D, AffineTransform, AABB2D;
export 'src/processing/bvh_node2d.dart' show BVHNode2D;
export 'src/processing/colormap_utils.dart'
    show ColorStop, ColorMapName, predefinedColormaps, applyColorMap, getColorStops, parseHexColor;
export 'src/processing/geotiff_tile_processor.dart'
    show GeoTIFFTileProcessor, GeoTIFFTileProcessorConfig, TileDataParams;
export 'src/processing/normalization_utils.dart'
    show TypedArrayType, normalizeValue, normalizeToColorMapRange, autoDetectValueRange, isFloatType, getTypeRange;
export 'src/processing/sampling_utils.dart' show SampleBand, sampleNearest, sampleBilinear;
export 'src/processing/triangle.dart' show ITriangle;
export 'src/processing/triangulation.dart'
    show Triangulation, TransformFunction, TriResult, Bounds, calculateBounds;
export 'src/raster_band.dart' show RasterBand;
export 'src/spatial_reference.dart' show SpatialReference;
