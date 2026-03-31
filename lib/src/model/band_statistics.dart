/// Raster band statistics computed by GDAL.
class BandStatistics {
  /// Minimum pixel value.
  final double min;

  /// Maximum pixel value.
  final double max;

  /// Mean pixel value.
  final double mean;

  /// Standard deviation of pixel values.
  final double stdDev;

  const BandStatistics({
    required this.min,
    required this.max,
    required this.mean,
    required this.stdDev,
  });

  @override
  String toString() =>
      'BandStatistics(min: $min, max: $max, mean: $mean, stdDev: $stdDev)';
}
