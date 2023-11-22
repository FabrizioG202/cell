import 'package:analyzer/dart/element/type.dart';
import 'package:cell/cell.dart';
import 'package:cell_generator/src/type_checkers.dart';
import 'package:cell_generator/src/type_delegates/base.dart';

final class CoreTypeConversionDelegate extends TypeConversionDelegate {
  CoreTypeConversionDelegate(this.type, {this.mode});

  final DartType type;
  final EncodeMode? mode;

  @override
  String toString() => 'CoreTypeConversionDelegate(type: $type, mode: $mode)';

  @override
  String generateEncodingCode(
    String writerVariableName,
    String objectVariableName,
  ) {
    switch (mode) {
      case EncodeMode.uint8:
        return 'writeUint8($objectVariableName)';
      case EncodeMode.uint16:
        return 'writeUint16($objectVariableName)';
      case EncodeMode.uint32:
        return 'writeUint32($objectVariableName)';
      case EncodeMode.uint64:
        return 'writeUint64($objectVariableName)';
      case EncodeMode.varuint:
        return 'writeVarUint($objectVariableName)';
      case EncodeMode.int8:
        return 'writeInt8($objectVariableName)';
      case EncodeMode.int16:
        return 'writeInt16($objectVariableName)';
      case EncodeMode.int32:
        return 'writeInt32($objectVariableName)';
      case EncodeMode.int64:
        return 'writeInt64($objectVariableName)';
      case EncodeMode.float32:
        return 'writeFloat32($objectVariableName)';
      case EncodeMode.float64:
        return 'writeFloat64($objectVariableName)';
      case EncodeMode.dateTimeMilliseconds:
        return 'writeUint64($objectVariableName.millisecondsSinceEpoch)';
      case EncodeMode.dateTimeMicroseconds:
        return 'writeUint64($objectVariableName.microsecondsSinceEpoch)';

      // String
      case null when type.isDartCoreString:
        return 'writeString($objectVariableName)';

      // bool
      case null when type.isDartCoreBool:
        return 'writeBool($objectVariableName)';

      // bytes types
      case null
          when kBytesTypeCheckers.any((e) => e.isAssignableFromType(type)):
        return 'writeBytes($objectVariableName)';

      // this should never happen,
      case null:
        throw StateError(
          'Reached unreachable code, report this to the developer.',
        );
    }
  }

  @override
  String generateDecodingCode(
    String readerVariableName,
    String objectVariableName,
  ) {
    switch (mode) {
      case EncodeMode.uint8:
        return '$objectVariableName = $readerVariableName.readUint8()';
      case EncodeMode.uint16:
        return '$objectVariableName = $readerVariableName.readUint16()';
      case EncodeMode.uint32:
        return '$objectVariableName = $readerVariableName.readUint32()';
      case EncodeMode.uint64:
        return '$objectVariableName = $readerVariableName.readUint64()';
      case EncodeMode.int8:
        return '$objectVariableName = $readerVariableName.readInt8()';
      case EncodeMode.int16:
        return '$objectVariableName = $readerVariableName.readInt16()';
      case EncodeMode.int32:
        return '$objectVariableName = $readerVariableName.readInt32()';
      case EncodeMode.varuint:
        return '$objectVariableName = $readerVariableName.readVarUint()';
      case EncodeMode.int64:
        return '$objectVariableName = $readerVariableName.readInt64()';
      case EncodeMode.float32:
        return '$objectVariableName = $readerVariableName.readFloat32()';
      case EncodeMode.float64:
        return '$objectVariableName = $readerVariableName.readFloat64()';
      case EncodeMode.dateTimeMilliseconds:
        return '$objectVariableName = DateTime.fromMillisecondsSinceEpoch($readerVariableName.readUint64())';
      case EncodeMode.dateTimeMicroseconds:
        return '$objectVariableName = DateTime.fromMicrosecondsSinceEpoch($readerVariableName.readUint64())';

      // If the type is a string, we read it as a string
      case null when type.isDartCoreString:
        return '$objectVariableName = $readerVariableName.readString()';

      // If the type is a bool, we read it as a bool
      case null when type.isDartCoreBool:
        return '$objectVariableName = $readerVariableName.readBool()';

      case null
          when kBytesTypeCheckers.any((e) => e.isAssignableFromType(type)):
        return '''
            final length = $readerVariableName.readVarUint(); // The length of encoded bytes
            $objectVariableName = $readerVariableName.readBytes(length)''';

      case null:
    }
    // At this point, the type is not supported
    // this should never happen as we filter beforehand but better safe than sorry
    throw StateError(
      'Reached unreachable code, report this to the developer.',
    );
  }
}
