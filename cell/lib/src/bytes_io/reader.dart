part of bytes_io;

class BytesReader {
  /// Creates a new [BytesReader] from the given [data]
  /// If [data] is null, an empty buffer is created
  /// This is useful when reading from a larger buffer
  BytesReader({
    Uint8List? data,
    int bufferPosition = 0,
    int offset = 0,
  })  : _offset = offset,
        buffer = data ?? Uint8List(0),
        _bufferPosition = bufferPosition;

  /// The buffer to read from
  Uint8List buffer;
  ByteData _asByteData() => ByteData.view(buffer.buffer);

  /// The length of the buffer
  /// For the number of bytes
  int get length => buffer.length;

  /// The current reading position (in the buffer)
  /// This will always be between 0 and [length]
  int _bufferPosition;

  /// A possible offset to add to the position
  /// This is useful when reading from a larger buffer
  int _offset = 0;

  int get end => _offset + length;

  /// Sets the offset
  int get offset => _offset;
  set offset(int offset) => _offset = offset;

  /// Returns true if the reader contains the [position]
  bool contains(int position) {
    final bufferPosition = position - _offset;
    return bufferPosition >= 0 && bufferPosition < length;
  }

  @pragma('vm:prefer-inline')
  int get position => _bufferPosition + _offset;

  /// Sets the position of the reader (Accounting the offset)
  /// If the position is out of bounds, an exception is thrown
  @pragma('vm:prefer-inline')
  set position(int truePosition) {
    final bufferPosition = truePosition - _offset;
    if (bufferPosition < 0 || bufferPosition > length) {
      throw Exception('Position out of bounds: $bufferPosition');
    }
    _bufferPosition = bufferPosition;
  }

  /// Adds the bytes from [other] to the buffer
  /// While removing the bytes that have already been read
  ///
  /// This cannot currently be called while reading
  /// This means that if you need to read n bytes, you need to chain the remaining bytes before reading
  void append(Uint8List other) {
    buffer = Uint8List.fromList(remaining + other);
    _bufferPosition = 0;
  }

  void prepend(Uint8List other, {bool remainingOnly = false}) {
    buffer = Uint8List.fromList(other + (remainingOnly ? remaining : buffer));
  }

  /// The remaining bytes in the buffer
  int get remainingLength => buffer.length - _bufferPosition;

  @protected
  Uint8List get remaining => buffer.sublist(_bufferPosition);

  /// Advances the position by [n]
  @pragma('vm:prefer-inline')
  void advance(int n) => _bufferPosition += n;

  /*
   ####### #       ####### #     # ####### #     # #######    #    ######  #     #
   #       #       #       ##   ## #       ##    #    #      # #   #     #  #   #
   #       #       #       # # # # #       # #   #    #     #   #  #     #   # #
   #####   #       #####   #  #  # #####   #  #  #    #    #     # ######     #
   #       #       #       #     # #       #   # #    #    ####### #   #      #
   #       #       #       #     # #       #    ##    #    #     # #    #     #
   ####### ####### ####### #     # ####### #     #    #    #     # #     #    #

  */

  /// Reads a single byte from the buffer
  int readUint8() {
    final value = buffer[_bufferPosition];
    advance(1);
    return value;
  }

  /// Reads a Uint16 from the buffer
  int readUint16() {
    final value = (buffer[_bufferPosition] << 8) | buffer[_bufferPosition + 1];
    advance(2);
    return value;
  }

  /// Reads a Uint32 from the buffer
  int readUint32() {
    final value = (buffer[_bufferPosition] << 24) |
        (buffer[_bufferPosition + 1] << 16) |
        (buffer[_bufferPosition + 2] << 8) |
        buffer[_bufferPosition + 3];
    advance(4);
    return value;
  }

  /// Reads a Uint64 from the buffer
  int readUint64() {
    final value = (buffer[_bufferPosition] << 56) |
        (buffer[_bufferPosition + 1] << 48) |
        (buffer[_bufferPosition + 2] << 40) |
        (buffer[_bufferPosition + 3] << 32) |
        (buffer[_bufferPosition + 4] << 24) |
        (buffer[_bufferPosition + 5] << 16) |
        (buffer[_bufferPosition + 6] << 8) |
        buffer[_bufferPosition + 7];
    advance(8);
    return value;
  }

  /// Reads a varuint from the buffer
  int readVarUint() {
    var value = 0;
    var shift = 0;
    while (true) {
      final byte = buffer[_bufferPosition];
      advance(1);

      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return value;
  }

  /// Reads a signed int8 from the buffer
  int readInt8() {
    final value = buffer[_bufferPosition];
    advance(1);
    // If the most significant bit (MSB) is set, treat it as a negative number.
    return (value & 0x80) != 0 ? value | ~0xFF : value;
  }

  /// Reads a signed int16 from the buffer
  int readInt16() {
    final byte1 = buffer[_bufferPosition];
    final byte2 = buffer[_bufferPosition + 1];
    advance(2);
    final value = (byte1 << 8) | byte2;
    return value < 0x8000 ? value : value | ~0xFFFF;
  }

  /// Reads a signed int32 from the buffer
  int readInt32() {
    final byte1 = buffer[_bufferPosition];
    final byte2 = buffer[_bufferPosition + 1];
    final byte3 = buffer[_bufferPosition + 2];
    final byte4 = buffer[_bufferPosition + 3];
    advance(4);
    final value = (byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4;
    return value < 0x80000000 ? value : value | ~0xFFFFFFFF;
  }

  /// Reads a signed int64 from the buffer
  int readInt64() {
    var value = 0;
    for (var i = 0; i < 8; i++) {
      value = (value << 8) | buffer[_bufferPosition + i];
    }
    advance(8);
    // In Dart, the bitwise operations use the least significant 32 bits,
    // so for a 64-bit value, check the 32nd bit instead of the 64th bit.
    return value < 0x80000000 ? value : value - (1 << 64);
  }

  /// Reads a float32 from the buffer
  double readFloat32() {
    final value = _asByteData().getFloat32(_bufferPosition);
    advance(4);
    return value;
  }

  /// Reads a float64 from the buffer
  double readFloat64() {
    final value = _asByteData().getFloat64(_bufferPosition);
    advance(8);
    return value;
  }

  /// Reads at most the next [n] bytes from the buffer
  /// In other words, if there are less than n bytes remaining in the buffer,
  /// only the remaining bytes are returned
  ///
  /// If [exact] is true, an exception is thrown if there are less than n bytes
  /// remaining in the buffer
  Uint8List readBytes(int n, {bool exact = true}) {
    final bytes = buffer.sublist(
      _bufferPosition,
      min(
        _bufferPosition + n,
        buffer.length,
      ),
    );
    advance(bytes.length);

    // If we are expecting an exact number of bytes, throw an exception
    if (exact && bytes.length != n) {
      throw Exception('Expected $n bytes, but only got ${bytes.length}');
    }

    return bytes;
  }

  /*
   ######  ####### ######  ### #     #    #    ####### ### #     # #######
   #     # #       #     #  #  #     #   # #      #     #  #     # #
   #     # #       #     #  #  #     #  #   #     #     #  #     # #
   #     # #####   ######   #  #     # #     #    #     #  #     # #####
   #     # #       #   #    #   #   #  #######    #     #   #   #  #
   #     # #       #    #   #    # #   #     #    #     #    # #   #
   ######  ####### #     # ###    #    #     #    #    ###    #    #######

  */

  /// Reads a boolean from the buffer
  /// Under ht ehood this is just a Uint8
  /// 0 = false
  /// 1 = true
  ///
  /// If the underlying value is not 0 or 1, an exception is thrown
  bool readBool() {
    final value = readUint8();
    if (value == 0) return false;
    if (value == 1) return true;
    throw Exception('Invalid boolean value: $value');
  }

  /// Reads a string from the buffer
  /// Under the hood, the string is encoded as a varint length followed by
  /// the string bytes
  ///
  /// The string is encoded as UTF-8
  String readString() {
    final length = readVarUint();
    final bytes = readBytes(length);
    return utf8.decode(bytes);
  }

  /// Reads an Iterable from the buffer
  /// Under the hood, the list is encoded as a varint length followed by
  /// the list items
  /// It is up to each encoded item to know how to decode itself
  /// and how much to advance the buffer
  Iterable<T> readIterable<T>(T Function(BytesReader) readItem) {
    // Read the length of the list
    final length = readVarUint();

    // Return an Iterable that will read the items from the buffer
    return Iterable.generate(length, (_) => readItem(this));
  }

  @override
  String toString() {
    return 'BytesReader(|$offset -  ($position) - $end|)';
  }
}
