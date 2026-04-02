/// OGR field types, mapped from OGRFieldType.
enum OgrFieldType {
  /// 32-bit integer.
  integer(0),

  /// List of 32-bit integers.
  integerList(1),

  /// Double-precision floating point.
  real(2),

  /// List of doubles.
  realList(3),

  /// String (UTF-8).
  string(4),

  /// List of strings.
  stringList(5),

  /// Binary data.
  binary(8),

  /// Date (year/month/day).
  date(9),

  /// Time (hour/minute/second).
  time(10),

  /// Date and time.
  dateTime(11),

  /// 64-bit integer.
  integer64(12),

  /// List of 64-bit integers.
  integer64List(13);

  /// The OGR integer constant for this field type.
  final int ogrValue;

  const OgrFieldType(this.ogrValue);

  /// Maps an OGRFieldType integer to an [OgrFieldType].
  ///
  /// Returns `null` for unsupported or unknown types.
  static OgrFieldType? fromOgr(int value) {
    for (final ft in values) {
      if (ft.ogrValue == value) return ft;
    }
    return null;
  }
}
