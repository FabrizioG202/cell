part of bytes_io;

enum EncodeMode {
  /// Integer modes
  int8,
  int16,
  int32,
  int64,
  uint8,
  uint16,
  uint32,
  uint64,
  varuint,

  /// Floating point modes
  float32,
  float64,

  /// DateTimes
  dateTimeMilliseconds,
  dateTimeMicroseconds;
}
