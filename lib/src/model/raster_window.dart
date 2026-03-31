/// A rectangular sub-region of a raster band.
class RasterWindow {
  /// Pixel offset from the left.
  final int xOffset;

  /// Line offset from the top.
  final int yOffset;

  /// Width in pixels.
  final int width;

  /// Height in lines.
  final int height;

  const RasterWindow({
    required this.xOffset,
    required this.yOffset,
    required this.width,
    required this.height,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RasterWindow &&
          xOffset == other.xOffset &&
          yOffset == other.yOffset &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(xOffset, yOffset, width, height);

  @override
  String toString() =>
      'RasterWindow(xOffset: $xOffset, yOffset: $yOffset, '
      'width: $width, height: $height)';
}
