/// A single color stop in a color map.
class ColorStop {
  /// Normalized position (0.0–1.0).
  final double value;

  /// RGB color [r, g, b] with values 0–255.
  final (int, int, int) color;

  const ColorStop(this.value, this.color);
}

/// Predefined color map names.
enum ColorMapName { grayscale, viridis, terrain, turbo, rainbow }

/// Predefined color maps.
const Map<ColorMapName, List<ColorStop>> predefinedColormaps = {
  ColorMapName.grayscale: [
    ColorStop(0.0, (0, 0, 0)),
    ColorStop(1.0, (255, 255, 255)),
  ],
  ColorMapName.viridis: [
    ColorStop(0.0, (68, 1, 84)),
    ColorStop(0.25, (59, 82, 139)),
    ColorStop(0.5, (33, 145, 140)),
    ColorStop(0.75, (94, 201, 98)),
    ColorStop(1.0, (253, 231, 37)),
  ],
  ColorMapName.terrain: [
    ColorStop(0.0, (0, 128, 0)),
    ColorStop(0.25, (139, 195, 74)),
    ColorStop(0.5, (255, 235, 59)),
    ColorStop(0.75, (255, 152, 0)),
    ColorStop(1.0, (255, 255, 255)),
  ],
  ColorMapName.turbo: [
    ColorStop(0.0, (48, 18, 59)),
    ColorStop(0.2, (33, 102, 172)),
    ColorStop(0.4, (68, 190, 112)),
    ColorStop(0.6, (253, 231, 37)),
    ColorStop(0.8, (234, 51, 35)),
    ColorStop(1.0, (122, 4, 3)),
  ],
  ColorMapName.rainbow: [
    ColorStop(0.0, (148, 0, 211)),
    ColorStop(0.2, (0, 0, 255)),
    ColorStop(0.4, (0, 255, 0)),
    ColorStop(0.6, (255, 255, 0)),
    ColorStop(0.8, (255, 127, 0)),
    ColorStop(1.0, (255, 0, 0)),
  ],
};

/// Parse a hex color string (e.g. `"#FF0000"` or `"#F00"`) to RGB.
(int, int, int) parseHexColor(String hexColor) {
  var hex = hexColor.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length != 6) return (0, 0, 0);

  final r = int.tryParse(hex.substring(0, 2), radix: 16);
  final g = int.tryParse(hex.substring(2, 4), radix: 16);
  final b = int.tryParse(hex.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return (0, 0, 0);
  return (r, g, b);
}

/// Apply a color map to a normalized value using binary-search interpolation.
///
/// [colorStops] must be sorted by [ColorStop.value].
(int, int, int) applyColorMap(double normalizedValue, List<ColorStop> colorStops) {
  if (colorStops.isEmpty) return (0, 0, 0);
  if (colorStops.length == 1) return colorStops[0].color;

  final v = normalizedValue.clamp(0.0, 1.0);
  if (v <= colorStops.first.value) return colorStops.first.color;
  if (v >= colorStops.last.value) return colorStops.last.color;

  var left = 0;
  var right = colorStops.length - 1;
  while (right - left > 1) {
    final mid = (left + right) ~/ 2;
    if (colorStops[mid].value <= v) {
      left = mid;
    } else {
      right = mid;
    }
  }

  final lower = colorStops[left];
  final upper = colorStops[right];
  final ratio = (v - lower.value) / (upper.value - lower.value);

  final (lr, lg, lb) = lower.color;
  final (ur, ug, ub) = upper.color;
  return (
    (lr + ratio * (ur - lr)).round(),
    (lg + ratio * (ug - lg)).round(),
    (lb + ratio * (ub - lb)).round(),
  );
}

/// Get color stops from a predefined [ColorMapName].
List<ColorStop> getColorStops(ColorMapName name) {
  return predefinedColormaps[name] ?? predefinedColormaps[ColorMapName.grayscale]!;
}
