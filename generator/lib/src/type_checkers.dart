// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:cell/cell.dart';
import 'package:source_gen/source_gen.dart';

const kFieldTypeChecker = TypeChecker.fromRuntime(Field);
const kEmbeddedTypeChecker = TypeChecker.fromRuntime(Embedded);
const kEmbeddedConstructorTypeChecker =
    TypeChecker.fromRuntime(EmbeddedConstructor);

const kUint8ListTypeChecker = TypeChecker.fromRuntime(Uint8List);
const kByteDataTypeChecker = TypeChecker.fromRuntime(ByteData);
const kByteBufferTypeChecker = TypeChecker.fromRuntime(ByteBuffer);

/// Type checker to support [DateTime]
const kDateTimeTypeChecker = TypeChecker.fromRuntime(DateTime);

/// Types currently recognized as bytes types
const kBytesTypeCheckers = [
  kUint8ListTypeChecker,
  kByteDataTypeChecker,
  kByteBufferTypeChecker,
];

/// Encode Modes that allows for encoding of integers
const kIntegerEncodeModes = {
  EncodeMode.int8,
  EncodeMode.int16,
  EncodeMode.int32,
  EncodeMode.int64,
  EncodeMode.uint8,
  EncodeMode.uint16,
  EncodeMode.uint32,
  EncodeMode.uint64,
  EncodeMode.varuint,
};

/// Encode Modes that allows for encoding of floating point numbers
const kFloatingPointEncodeModes = {
  EncodeMode.float32,
  EncodeMode.float64,
};

/// Encode Modes that allows for encoding of date time
const kDateTimeEncodeModes = {
  EncodeMode.dateTimeMilliseconds,
  EncodeMode.dateTimeMicroseconds,
};
