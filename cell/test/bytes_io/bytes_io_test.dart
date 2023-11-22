import 'dart:math';

import 'package:cell/src/bytes_io/bytes_io.dart';
import 'package:test/test.dart';

void main() {
  group('Bytes IO', () {
    test('Variable-length Unsigned Integer Encoding and Decoding', () {
      // generate 100 random integers between 0 and 2^32
      final ints =
          List<int>.generate(100, (_) => Random().nextInt(pow(2, 32) as int));

      final writer = BytesWriter();
      for (final int_ in ints) {
        writer.writeVarUint(int_);
      }

      final reader = BytesReader(data: writer.bytes);
      for (final int_ in ints) {
        expect(reader.readVarUint(), int_);
      }
    });

    test('String', () {
      const string = 'Hello World 🌍';

      final writer = BytesWriter()..writeString(string);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readString(), string);
    });

    test('Uint8', () {
      const value = 0x12;
      final writer = BytesWriter()..writeUint8(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readUint8(), value);
    });

    test('Uint16', () {
      const value = 0x1234;
      final writer = BytesWriter()..writeUint16(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readUint16(), value);
    });

    test('Uint32', () {
      const value = 0x12345678;
      final writer = BytesWriter()..writeUint32(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readUint32(), value);
    });

    test('Uint64', () {
      // ignore: avoid_js_rounded_ints
      const value = 0x123456789abcdef0;
      final writer = BytesWriter()..writeUint64(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readUint64(), value);
    });

    test('Int8', () {
      const value = -0x12;
      final writer = BytesWriter()..writeInt8(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readInt8(), value);
    });

    test('Int16', () {
      const value = -0x1234;
      final writer = BytesWriter()..writeInt16(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readInt16(), value);
    });

    test('Int32', () {
      const value = -0x12345678;
      final writer = BytesWriter()..writeInt32(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readInt32(), value);
    });

    test('Int64', () {
      // ignore: avoid_js_rounded_ints
      const value = -0x123456789abcdef0;
      final writer = BytesWriter()..writeInt64(value);
      final reader = BytesReader(data: writer.bytes);
      expect(reader.readInt64(), value);
    });
  });
}
