part of bytes_io;

const _kMaxUint8 = 0xFF;
const _kMaxUint16 = 0xFFFF;
const _kMaxUint32 = 0xFFFFFFFF;

const _kMinInt8 = -0x80;
const _kMaxInt8 = 0x7F;
const _kMinInt16 = -0x8000;
const _kMaxInt16 = 0x7FFF;
const _kMinInt32 = -0x80000000;
const _kMaxInt32 = 0x7FFFFFFF;
const _kMinInt64 = -0x8000000000000000;

/// The maximum value of a Dart integer (2^63 - 1)
const _kMaxDartInt = 0x7FFFFFFFFFFFFFFF;

const _kMinFloat32 = -3.4028234663852886e+38;
const _kMaxFloat32 = 3.4028234663852886e+38;
const _kMinFloat64 = -1.7976931348623157e+308;
const _kMaxFloat64 = 1.7976931348623157e+308;

final class BytesWriter {
  /// Creates a new [BytesWriter] with an initial capacity of [initialCapacity]
  /// If the [initialCapacity] is not specified, it defaults to 1024
  ///
  /// Ideally, the [initialCapacity] should be the size of the data that will be written
  /// to the [BytesWriter]. Extending the capacity is an expensive operation.
  BytesWriter({int initialCapacity = 1024})
      : _buffer = Uint8List(initialCapacity);

  /// The current position of the [BytesWriter]
  int _position = 0;
  int get position => _position;

  /// The underlying buffer.
  /// This is not final as it may be extended if the [BytesWriter] runs out of capacity
  /// The [_position] is used to determine how much of the buffer is actually used
  ///
  /// Look at [_ensureCapacity] to see how the buffer is extended
  Uint8List _buffer;

  /// The [ByteData] view of the [_buffer]
  /// This allows us to write to the buffer with common encodings.
  ByteData _asByteData() => ByteData.sublistView(_buffer);

  /// Returns the bytes that have been written to the [BytesWriter]
  Uint8List get bytes => _buffer.sublist(0, _position);

  /// Ensures that the [ByteData] has enough capacity to write [length] bytes
  /// If the [ByteData] does not have enough capacity, it will be extended to
  /// twice its current capacity.
  ///
  /// This is a relatively expensive operation, so it should be avoided if possible
  @protected
  @pragma('vm:prefer-inline')
  void _ensureCapacity(int length) {
    if (_buffer.length < length) {
      final newBuffer = Uint8List(
        length * 2,
      )..setAll(
          0,
          _buffer,
        );
      _buffer = newBuffer;
    }
  }

  /// Advances the position of the [BytesWriter] by [amount] bytes, without writing anything
  void skip(int amount) {
    _ensureCapacity(_position + amount);
    _position += amount;
  }

  /*
   ####### #       ####### #     # ####### #     # #######    #    ######  #     #
   #       #       #       ##   ## #       ##    #    #      # #   #     #  #   #
   #       #       #       # # # # #       # #   #    #     #   #  #     #   # #
   #####   #       #####   #  #  # #####   #  #  #    #    #     # ######     #
   #       #       #       #     # #       #   # #    #    ####### #   #      #
   #       #       #       #     # #       #    ##    #    #     # #    #     #
   ####### ####### ####### #     # ####### #     #    #    #     # #     #    #

  */

  /// Writes a single byte (Uint8) to the [BytesWriter] at the given position
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between 0 and 255, inclusive, otherwise an [AssertionError] will be thrown
  void writeUint8(int value, [int? position]) {
    assert(
      value >= 0 && value <= _kMaxUint8,
      'Value must be between 0 and 255',
    );
    position ??= _position;

    _ensureCapacity(position + 1);
    _buffer[position] = value;
    _position = position + 1;
  }

  /// Writes a Uint16 to the [BytesWriter] at the given position (Big Endian)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between 0 and 65535, inclusive, otherwise an [AssertionError] will be thrown
  void writeUint16(int value, [int? position]) {
    assert(
      value >= 0 && value <= _kMaxUint16,
      'Value must be between 0 and 65535',
    );
    position ??= _position;

    _ensureCapacity(position + 2);
    _buffer[position] = (value >> 8) & 0xFF;
    _buffer[position + 1] = value & 0xFF;

    _position = position + 2;
  }

  /// Writes a Uint32 to the [BytesWriter] at the given position (Big Endian)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between 0 and 4294967295, inclusive, otherwise an [AssertionError] will be thrown
  void writeUint32(int value, [int? position]) {
    assert(
      value >= 0 && value <= _kMaxUint32,
      'Value must be between 0 and 4294967295',
    );
    position ??= _position;

    _ensureCapacity(position + 4);
    _buffer[position] = (value >> 24) & 0xFF;
    _buffer[position + 1] = (value >> 16) & 0xFF;
    _buffer[position + 2] = (value >> 8) & 0xFF;
    _buffer[position + 3] = value & 0xFF;

    _position = position + 4;
  }

  /// Writes a Uint64 to the [BytesWriter] at the given position (Big Endian)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between 0 and [_kMaxDartInt], inclusive, otherwise an [AssertionError] will be thrown
  void writeUint64(int value, [int? position]) {
    assert(
      value >= 0 && value <= _kMaxDartInt,
      'Value must be between 0 and $_kMaxDartInt',
    );
    position ??= _position;

    _ensureCapacity(position + 8);
    _buffer[position] = (value >> 56) & 0xFF;
    _buffer[position + 1] = (value >> 48) & 0xFF;
    _buffer[position + 2] = (value >> 40) & 0xFF;
    _buffer[position + 3] = (value >> 32) & 0xFF;
    _buffer[position + 4] = (value >> 24) & 0xFF;
    _buffer[position + 5] = (value >> 16) & 0xFF;
    _buffer[position + 6] = (value >> 8) & 0xFF;
    _buffer[position + 7] = value & 0xFF;

    _position = position + 8;
  }

  /// Writes a variable-length integer to the [BytesWriter] at the given position
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between 0 and 18446744073709551615, inclusive, otherwise an [AssertionError] will be thrown
  void writeVarUint(int value, [int? position]) {
    assert(
      value >= 0 && value <= _kMaxDartInt,
      'Value must be between 0 and $_kMaxDartInt',
    );

    position ??= _position;

    // this is needed to handle the parameter_assignment lint rule
    var loopingValue = value;

    // Loop to handle the variable-length aspect of the encoding
    do {
      // Take the last 7 bits of value
      var byte = loopingValue & 0x7F;
      // Shift the value by 7 bits to the right for the next iteration
      loopingValue >>= 7;

      // If there is more data to write, set the MSB to 1
      if (loopingValue != 0) {
        byte |= 0x80;
      }

      // Ensure the buffer has enough space and write the byte
      _ensureCapacity(position! + 1);
      _buffer[position] = byte;
      position++;
    } while (loopingValue != 0);

    _position = position;
  }

  /// Writes a single signed byte (Int8) to the [BytesWriter] at the given position
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between -128 and 127, inclusive, otherwise an [AssertionError] will be thrown
  void writeInt8(int value, [int? position]) {
    assert(
      value >= _kMinInt8 && value <= _kMaxInt8,
      'Value must be between $_kMinInt8 and $_kMaxInt8',
    );
    position ??= _position;

    _ensureCapacity(position + 1);
    _buffer[position] = value & 0xFF;
    _position = position + 1;
  }

  /// Writes a signed Int16 to the [BytesWriter] at the given position (Big Endian)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between -32768 and 32767, inclusive, otherwise an [AssertionError] will be thrown
  void writeInt16(int value, [int? position]) {
    assert(
      value >= _kMinInt16 && value <= _kMaxInt16,
      'Value must be between $_kMinInt16 and $_kMaxInt16',
    );
    position ??= _position;

    _ensureCapacity(position + 2);
    _buffer[position] = (value >> 8) & 0xFF;
    _buffer[position + 1] = value & 0xFF;

    _position = position + 2;
  }

  /// Writes a signed Int32 to the [BytesWriter] at the given position (Big Endian)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between -2147483648 and 2147483647, inclusive, otherwise an [AssertionError] will be thrown
  void writeInt32(int value, [int? position]) {
    assert(
      value >= _kMinInt32 && value <= _kMaxInt32,
      'Value must be between $_kMinInt32 and $_kMaxInt32',
    );
    position ??= _position;

    _ensureCapacity(position + 4);
    _buffer[position] = (value >> 24) & 0xFF;
    _buffer[position + 1] = (value >> 16) & 0xFF;
    _buffer[position + 2] = (value >> 8) & 0xFF;
    _buffer[position + 3] = value & 0xFF;

    _position = position + 4;
  }

  /// Writes a signed Int64 to the [BytesWriter] at the given position (Big Endian)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between -9223372036854775808 and 9223372036854775807, inclusive, otherwise an [AssertionError] will be thrown
  void writeInt64(int value, [int? position]) {
    assert(
      value >= _kMinInt64 && value <= _kMaxDartInt,
      'Value must be between $_kMinInt64 and $_kMaxDartInt',
    );
    position ??= _position;

    _ensureCapacity(position + 8);
    _buffer[position] = (value >> 56) & 0xFF;
    _buffer[position + 1] = (value >> 48) & 0xFF;
    _buffer[position + 2] = (value >> 40) & 0xFF;
    _buffer[position + 3] = (value >> 32) & 0xFF;
    _buffer[position + 4] = (value >> 24) & 0xFF;
    _buffer[position + 5] = (value >> 16) & 0xFF;
    _buffer[position + 6] = (value >> 8) & 0xFF;
    _buffer[position + 7] = value & 0xFF;

    _position = position + 8;
  }

  /// Writes a [double] to the [BytesWriter] at the given position (Big Endian) using the IEEE 754-2008 binary32 format (aka Float32)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between -3.4028234663852886e+38 and 3.4028234663852886e+38, inclusive, otherwise an [AssertionError] will be thrown
  void writeFloat32(double value, [int? position]) {
    assert(
      value >= _kMinFloat32 && value <= _kMaxFloat32,
      'Value must be between -3.4028234663852886e+38 and 3.4028234663852886e+38',
    );
    position ??= _position;

    _ensureCapacity(position + 4);
    _asByteData().setFloat32(position, value);
    _position = position + 4;

    _position = position + 4;
  }

  /// Writes a [double] to the [BytesWriter] at the given position (Big Endian) using the IEEE 754-2008 binary64 format (aka Float64)
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  /// The [value] must be between -1.7976931348623157e+308 and 1.7976931348623157e+308, inclusive, otherwise an [AssertionError] will be thrown
  void writeFloat64(double value, [int? position]) {
    assert(
      value >= _kMinFloat64 && value <= _kMaxFloat64,
      'Value must be between -1.7976931348623157e+308 and 1.7976931348623157e+308',
    );
    position ??= _position;

    _ensureCapacity(position + 8);
    _asByteData().setFloat64(position, value);
    _position = position + 8;
  }

  /// Writes the given [bytes] to the [BytesWriter] at the given position
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  void writeBytes(Uint8List bytes, [int? position]) {
    position ??= _position;

    _ensureCapacity(position + bytes.length);
    _buffer.setAll(position, bytes);
    _position = position + bytes.length;
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

  /// Writes a boolean to the [BytesWriter] at the given position
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  // ignore: avoid_positional_boolean_parameters
  void writeBool(bool value, [int? position]) {
    position ??= _position;

    _ensureCapacity(position + 1);
    _buffer[position] = value ? 1 : 0;
    _position = position + 1;
  }

  /// Writes a string to the [BytesWriter] at the given position  ///
  /// Under the hood the string is encoded as a varuint length followed by the string bytes
  /// The string is encoded as UTF-8
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  void writeString(String value, [int? position]) {
    position ??= _position;

    final bytes = utf8.encode(value);
    writeVarUint(bytes.length, position);
    writeBytes(Uint8List.fromList(bytes), _position);
  }

  /*
   #     # ####### ### #       ### ####### #     #
   #     #    #     #  #        #     #     #   #
   #     #    #     #  #        #     #      # #
   #     #    #     #  #        #     #       #
   #     #    #     #  #        #     #       #
   #     #    #     #  #        #     #       #
    #####     #    ### ####### ###    #       #

  */

  /// Runs the [callback] and register the position before and after the callback is run
  /// Then writes at the beginning of the callback the length of the data written by the callback as a uint32
  void encapsulateWithUint32Length(void Function(BytesWriter writer) callback) {
    // Keep track of the initial position
    final start = _position;
    skip(4);

    // Call the callback
    callback(this);

    // Keep track of the final position
    final end = _position;

    // Write the length of the data written by the callback
    writeUint32(end - start - 4, start);

    // Reset the position to the end of the encapsulation
    _position = end;
  }

  /// Adds a list to the [BytesWriter] at the given position
  /// It first adds the length of the list as a varuint, then writes each element of the list using the [callback]
  /// If the position is not specified, it defaults to the current position of the [BytesWriter]
  void writeIterable<T>(
    List<T> list,
    void Function(T value) callback, [
    int? position,
  ]) {
    position ??= _position;

    // Write the length of the list
    writeVarUint(list.length, position);

    // Write each element of the list
    list.forEach(callback);
  }
}
