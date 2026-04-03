/// CRS type, mapped from OSRCRSType.
enum CrsType {
  geographic2D(0),
  geographic3D(1),
  geocentric(2),
  projected(3),
  vertical(4),
  compound(5),
  other(6);

  final int ogrValue;
  const CrsType(this.ogrValue);

  /// Maps an OSRCRSType integer to a [CrsType].
  static CrsType fromOgr(int value) => switch (value) {
        0 => CrsType.geographic2D,
        1 => CrsType.geographic3D,
        2 => CrsType.geocentric,
        3 => CrsType.projected,
        4 => CrsType.vertical,
        5 => CrsType.compound,
        _ => CrsType.other,
      };
}

/// Immutable CRS metadata from the PROJ database.
///
/// Instances are created by [Gdal.getCRSInfo] and cached per isolate.
/// They hold no native resources and do not need to be closed.
class CrsInfo {
  /// Authority name (always uppercase, e.g., `"EPSG"`).
  final String authName;

  /// Authority code (e.g., `"4326"`).
  final String code;

  /// Human-readable name (e.g., `"WGS 84"`).
  final String name;

  /// CRS type (geographic, projected, etc.).
  final CrsType type;

  /// Whether this CRS definition is deprecated.
  final bool deprecated;

  /// Western longitude of the area of use, or `null` if unknown.
  final double? westLon;

  /// Southern latitude of the area of use, or `null` if unknown.
  final double? southLat;

  /// Eastern longitude of the area of use, or `null` if unknown.
  final double? eastLon;

  /// Northern latitude of the area of use, or `null` if unknown.
  final double? northLat;

  /// Name of the area of use (e.g., `"World"`), or `null`.
  final String? areaName;

  /// Projection method name (e.g., `"Transverse Mercator"`), or `null`.
  final String? projectionMethod;

  CrsInfo({
    required String authName,
    required this.code,
    required this.name,
    required this.type,
    required this.deprecated,
    this.westLon,
    this.southLat,
    this.eastLon,
    this.northLat,
    this.areaName,
    this.projectionMethod,
  }) : authName = authName.toUpperCase();

  /// Normalized cache key, e.g., `"EPSG:4326"`.
  String get key => '$authName:$code';

  @override
  String toString() => 'CrsInfo($key, $name)';
}
