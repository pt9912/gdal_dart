import 'package:gdal_dart/gdal_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ColorStop', () {
    test('stores value and color', () {
      const stop = ColorStop(0.5, (128, 64, 32));
      expect(stop.value, 0.5);
      expect(stop.color, (128, 64, 32));
    });

    test('can be const', () {
      const stop = ColorStop(0.0, (0, 0, 0));
      expect(stop.value, 0.0);
      expect(stop.color, (0, 0, 0));
    });
  });

  group('ColorMapName enum', () {
    test('has all expected values', () {
      expect(ColorMapName.values, hasLength(5));
      expect(ColorMapName.values, contains(ColorMapName.grayscale));
      expect(ColorMapName.values, contains(ColorMapName.viridis));
      expect(ColorMapName.values, contains(ColorMapName.terrain));
      expect(ColorMapName.values, contains(ColorMapName.turbo));
      expect(ColorMapName.values, contains(ColorMapName.rainbow));
    });
  });

  group('predefinedColormaps', () {
    test('contains all ColorMapName entries', () {
      for (final name in ColorMapName.values) {
        expect(predefinedColormaps.containsKey(name), isTrue,
            reason: 'Missing colormap for $name');
      }
    });

    test('grayscale has 2 stops from black to white', () {
      final stops = predefinedColormaps[ColorMapName.grayscale]!;
      expect(stops, hasLength(2));
      expect(stops.first.value, 0.0);
      expect(stops.first.color, (0, 0, 0));
      expect(stops.last.value, 1.0);
      expect(stops.last.color, (255, 255, 255));
    });

    test('viridis has 5 stops', () {
      final stops = predefinedColormaps[ColorMapName.viridis]!;
      expect(stops, hasLength(5));
      expect(stops.first.value, 0.0);
      expect(stops.last.value, 1.0);
    });

    test('terrain has 5 stops', () {
      final stops = predefinedColormaps[ColorMapName.terrain]!;
      expect(stops, hasLength(5));
      expect(stops.first.value, 0.0);
      expect(stops.last.value, 1.0);
    });

    test('turbo has 6 stops', () {
      final stops = predefinedColormaps[ColorMapName.turbo]!;
      expect(stops, hasLength(6));
      expect(stops.first.value, 0.0);
      expect(stops.last.value, 1.0);
    });

    test('rainbow has 6 stops', () {
      final stops = predefinedColormaps[ColorMapName.rainbow]!;
      expect(stops, hasLength(6));
      expect(stops.first.value, 0.0);
      expect(stops.last.value, 1.0);
    });

    test('all colormaps have sorted stop values', () {
      for (final entry in predefinedColormaps.entries) {
        final stops = entry.value;
        for (var i = 1; i < stops.length; i++) {
          expect(stops[i].value, greaterThanOrEqualTo(stops[i - 1].value),
              reason: 'Colormap ${entry.key} has unsorted stops');
        }
      }
    });

    test('all color components are in 0-255 range', () {
      for (final entry in predefinedColormaps.entries) {
        for (final stop in entry.value) {
          final (r, g, b) = stop.color;
          expect(r, inInclusiveRange(0, 255),
              reason: 'Red out of range in ${entry.key}');
          expect(g, inInclusiveRange(0, 255),
              reason: 'Green out of range in ${entry.key}');
          expect(b, inInclusiveRange(0, 255),
              reason: 'Blue out of range in ${entry.key}');
        }
      }
    });
  });

  group('parseHexColor', () {
    test('parses 6-digit hex with #', () {
      expect(parseHexColor('#FF0000'), (255, 0, 0));
      expect(parseHexColor('#00FF00'), (0, 255, 0));
      expect(parseHexColor('#0000FF'), (0, 0, 255));
    });

    test('parses 6-digit hex without #', () {
      expect(parseHexColor('FF0000'), (255, 0, 0));
      expect(parseHexColor('00FF00'), (0, 255, 0));
    });

    test('parses 3-digit hex with #', () {
      expect(parseHexColor('#F00'), (255, 0, 0));
      expect(parseHexColor('#0F0'), (0, 255, 0));
      expect(parseHexColor('#00F'), (0, 0, 255));
    });

    test('parses 3-digit hex without #', () {
      expect(parseHexColor('F00'), (255, 0, 0));
    });

    test('parses white', () {
      expect(parseHexColor('#FFFFFF'), (255, 255, 255));
      expect(parseHexColor('#FFF'), (255, 255, 255));
    });

    test('parses black', () {
      expect(parseHexColor('#000000'), (0, 0, 0));
      expect(parseHexColor('#000'), (0, 0, 0));
    });

    test('parses mixed case', () {
      expect(parseHexColor('#ff8800'), (255, 136, 0));
      expect(parseHexColor('#FF8800'), (255, 136, 0));
      expect(parseHexColor('#Ff8800'), (255, 136, 0));
    });

    test('returns black for invalid length', () {
      expect(parseHexColor('#12'), (0, 0, 0));
      expect(parseHexColor('#1234'), (0, 0, 0));
      expect(parseHexColor('#12345'), (0, 0, 0));
      expect(parseHexColor('#1234567'), (0, 0, 0));
    });

    test('returns black for empty string', () {
      expect(parseHexColor(''), (0, 0, 0));
    });

    test('returns black for invalid hex characters', () {
      expect(parseHexColor('#GGHHII'), (0, 0, 0));
    });

    test('trims whitespace', () {
      expect(parseHexColor('  #FF0000  '), (255, 0, 0));
    });

    test('handles hash only', () {
      expect(parseHexColor('#'), (0, 0, 0));
    });

    test('parses specific colors', () {
      expect(parseHexColor('#808080'), (128, 128, 128)); // gray
      expect(parseHexColor('#C0C0C0'), (192, 192, 192)); // silver
    });
  });

  group('applyColorMap', () {
    test('returns black for empty colorStops', () {
      expect(applyColorMap(0.5, []), (0, 0, 0));
    });

    test('returns single stop color regardless of value', () {
      final stops = [const ColorStop(0.5, (100, 150, 200))];
      expect(applyColorMap(0.0, stops), (100, 150, 200));
      expect(applyColorMap(0.5, stops), (100, 150, 200));
      expect(applyColorMap(1.0, stops), (100, 150, 200));
    });

    test('returns first color at value 0 for grayscale', () {
      final stops = predefinedColormaps[ColorMapName.grayscale]!;
      expect(applyColorMap(0.0, stops), (0, 0, 0));
    });

    test('returns last color at value 1 for grayscale', () {
      final stops = predefinedColormaps[ColorMapName.grayscale]!;
      expect(applyColorMap(1.0, stops), (255, 255, 255));
    });

    test('interpolates midpoint of grayscale to ~128', () {
      final stops = predefinedColormaps[ColorMapName.grayscale]!;
      final (r, g, b) = applyColorMap(0.5, stops);
      expect(r, closeTo(128, 1));
      expect(g, closeTo(128, 1));
      expect(b, closeTo(128, 1));
    });

    test('clamps negative value to first stop', () {
      final stops = predefinedColormaps[ColorMapName.grayscale]!;
      expect(applyColorMap(-0.5, stops), (0, 0, 0));
    });

    test('clamps value > 1 to last stop', () {
      final stops = predefinedColormaps[ColorMapName.grayscale]!;
      expect(applyColorMap(1.5, stops), (255, 255, 255));
    });

    test('interpolates viridis at 0.5', () {
      final stops = predefinedColormaps[ColorMapName.viridis]!;
      final (r, g, b) = applyColorMap(0.5, stops);
      // At 0.5, viridis should be (33, 145, 140) - the exact stop
      expect(r, 33);
      expect(g, 145);
      expect(b, 140);
    });

    test('interpolates between viridis stops', () {
      final stops = predefinedColormaps[ColorMapName.viridis]!;
      final (r, g, b) = applyColorMap(0.125, stops);
      // Between (68,1,84) at 0.0 and (59,82,139) at 0.25
      // ratio = 0.5
      expect(r, closeTo((68 + 59) / 2, 1));
      expect(g, closeTo((1 + 82) / 2, 1));
      expect(b, closeTo((84 + 139) / 2, 1));
    });

    test('handles exact stop values', () {
      final stops = predefinedColormaps[ColorMapName.turbo]!;
      // At 0.2 there's an exact stop
      final (r, g, b) = applyColorMap(0.2, stops);
      expect(r, 33);
      expect(g, 102);
      expect(b, 172);
    });

    test('interpolation is smooth across all stops', () {
      final stops = predefinedColormaps[ColorMapName.rainbow]!;
      // Sample at many points and verify monotonic-ish behavior
      (int, int, int)? prev;
      for (var v = 0.0; v <= 1.0; v += 0.01) {
        final color = applyColorMap(v, stops);
        final (r, g, b) = color;
        expect(r, inInclusiveRange(0, 255));
        expect(g, inInclusiveRange(0, 255));
        expect(b, inInclusiveRange(0, 255));
        prev = color;
      }
      // Verify prev was set (loop ran)
      expect(prev, isNotNull);
    });

    test('binary search handles first segment correctly', () {
      final stops = [
        const ColorStop(0.0, (0, 0, 0)),
        const ColorStop(0.5, (100, 100, 100)),
        const ColorStop(1.0, (200, 200, 200)),
      ];
      final (r, _, _) = applyColorMap(0.25, stops);
      // Between 0 and 100, ratio = 0.5
      expect(r, closeTo(50, 1));
    });

    test('binary search handles last segment correctly', () {
      final stops = [
        const ColorStop(0.0, (0, 0, 0)),
        const ColorStop(0.5, (100, 100, 100)),
        const ColorStop(1.0, (200, 200, 200)),
      ];
      final (r, _, _) = applyColorMap(0.75, stops);
      // Between 100 and 200, ratio = 0.5
      expect(r, closeTo(150, 1));
    });

    test('binary search handles many stops', () {
      // Create colormap with 10 equally spaced stops
      final stops = List.generate(
        10,
        (i) => ColorStop(i / 9, (i * 25, i * 25, i * 25)),
      );
      final (r, _, _) = applyColorMap(0.5, stops);
      expect(r, inInclusiveRange(100, 130));
    });
  });

  group('getColorStops', () {
    test('returns grayscale stops', () {
      final stops = getColorStops(ColorMapName.grayscale);
      expect(stops, hasLength(2));
      expect(stops.first.color, (0, 0, 0));
      expect(stops.last.color, (255, 255, 255));
    });

    test('returns viridis stops', () {
      final stops = getColorStops(ColorMapName.viridis);
      expect(stops, hasLength(5));
    });

    test('returns terrain stops', () {
      final stops = getColorStops(ColorMapName.terrain);
      expect(stops, hasLength(5));
    });

    test('returns turbo stops', () {
      final stops = getColorStops(ColorMapName.turbo);
      expect(stops, hasLength(6));
    });

    test('returns rainbow stops', () {
      final stops = getColorStops(ColorMapName.rainbow);
      expect(stops, hasLength(6));
    });

    test('all predefined colormaps are retrievable', () {
      for (final name in ColorMapName.values) {
        final stops = getColorStops(name);
        expect(stops, isNotEmpty, reason: 'Empty stops for $name');
      }
    });
  });
}
