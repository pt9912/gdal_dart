import 'dart:typed_data';

/// Identifiers for typed array element types.
enum TypedArrayType {
  uint8,
  uint16,
  int16,
  uint32,
  int32,
  float32,
  float64,
}

/// Normalize a raw value to 0–255 range based on [arrayType].
int normalizeValue(double rawValue, TypedArrayType arrayType) {
  switch (arrayType) {
    case TypedArrayType.uint8:
      return rawValue.round().clamp(0, 255);
    case TypedArrayType.uint16:
      return ((rawValue / 65535) * 255).round().clamp(0, 255);
    case TypedArrayType.int16:
      return (((rawValue + 32768) / 65535) * 255).round().clamp(0, 255);
    case TypedArrayType.uint32:
      return ((rawValue / 4294967295) * 255).round().clamp(0, 255);
    case TypedArrayType.int32:
      return (((rawValue + 2147483648) / 4294967295) * 255).round().clamp(0, 255);
    case TypedArrayType.float32:
    case TypedArrayType.float64:
      return (rawValue.clamp(0.0, 1.0) * 255).round();
  }
}

/// Normalize a raw value to 0–1 range for colormap application.
double normalizeToColorMapRange(double rawValue, {(double, double)? valueRange}) {
  if (valueRange == null) {
    return rawValue.clamp(0.0, 1.0);
  }
  final (minVal, maxVal) = valueRange;
  if (maxVal == minVal) return 0.5;
  return ((rawValue - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
}

/// Auto-detect value range from a [Float32List] or [Float64List].
(double, double) autoDetectValueRange(List<double> data, {int sampleSize = 1000}) {
  if (data.isEmpty) return (0.0, 1.0);

  final step = (data.length / sampleSize).floor().clamp(1, data.length);
  var min = double.infinity;
  var max = double.negativeInfinity;

  for (var i = 0; i < data.length; i += step) {
    final value = data[i];
    if (value.isFinite) {
      if (value < min) min = value;
      if (value > max) max = value;
    }
  }

  if (!min.isFinite || !max.isFinite) return (0.0, 1.0);
  if (min == max) return (min, min + 1);
  return (min, max);
}

/// Whether [arrayType] represents floating-point data.
bool isFloatType(TypedArrayType arrayType) =>
    arrayType == TypedArrayType.float32 || arrayType == TypedArrayType.float64;

/// Typical value range for a [TypedArrayType].
(double, double) getTypeRange(TypedArrayType arrayType) {
  switch (arrayType) {
    case TypedArrayType.uint8:
      return (0, 255);
    case TypedArrayType.uint16:
      return (0, 65535);
    case TypedArrayType.int16:
      return (-32768, 32767);
    case TypedArrayType.uint32:
      return (0, 4294967295);
    case TypedArrayType.int32:
      return (-2147483648, 2147483647);
    case TypedArrayType.float32:
    case TypedArrayType.float64:
      return (0, 1);
  }
}
