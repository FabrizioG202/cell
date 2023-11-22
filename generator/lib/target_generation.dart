// This file contains what we would like the final generated code to look like
// It is used to drive the development of the generator.

// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'package:cell/cell.dart';

@Embedded()
final class Person {
  @EmbeddedConstructor()
  Person({
    required this.name,
    required this.hobbies,
    required this.bytes,
    this.age,
    this.metadata,
  });

  @Field(index: 0)
  final String name;

  @Field(index: 1, mode: EncodeMode.uint16)
  final int? age;

  @Field(index: 2)
  String? address;

  @Field(index: 3)
  final Metadata? metadata;

  @Field(index: 4)
  final Uint8List bytes;

  @Field(index: 5)
  final List<Hobby> hobbies;
}

@Embedded(id: 1)
enum Hobby {
  @Field(index: 0)
  reading,

  @Field(index: 1)
  writing,

  @Field(index: 2)
  coding,

  musicing,
  testing,
}

@Embedded()
final class Metadata {
  @EmbeddedConstructor()
  const Metadata({
    required this.emailAddress,
    this.phoneNumber,
  });

  @Field()
  final String emailAddress;

  @Field()
  final String? phoneNumber;
}

String handleMissingEmailAddress() => 'error@error.net';

/// This is the encoding function for the enum Hobby
void $encodeHobby(
  BytesWriter writer,
  Hobby object,
) {
  writer.writeVarUint(
    switch (object) {
      Hobby.reading => 0,
      Hobby.writing => 1,
      Hobby.coding => 2,
      Hobby.musicing ||
      Hobby.testing =>
        throw Exception('The enum value $object is not serialized'),
    },
  );
}

/// This is the decoding function for the enum Hobby
Hobby $decodeHobby(BytesReader reader, int bufferEnd) {
  final index = reader.readVarUint();
  return switch (index) {
    0 => Hobby.reading,
    1 => Hobby.writing,
    2 => Hobby.coding,
    final other => throw InvalidFieldException('Invalid field: $other')
  };
}

void $encodePerson(
  BytesWriter writer,
  Person object,
) {
  writer
    ..writeVarUint(0)
    ..writeString(object.name);

  // Write the age field if it is not null.
  if (object.age != null) {
    writer
      ..writeVarUint(1)
      ..writeUint16(object.age!);
  }

  // Write the address field if it is not null.
  if (object.address != null) {
    writer
      ..writeVarUint(2)
      ..writeString(object.address!);
  }

  // Write the metadata field if it is not null.
  if (object.metadata != null) {
    writer
      ..writeVarUint(3)
      ..encapsulateWithUint32Length(
        (writer) => $encodeMetadata(
          writer,
          object.metadata!,
        ),
      );
  }

  writer
    ..writeVarUint(4)
    ..writeBytes(object.bytes);

  // Write the hobbies field if it is not null.
  // ignore: cascade_invocations
  writer
    ..writeVarUint(5)
    ..writeIterable(
      object.hobbies,
      (object) => $encodeHobby(
        writer,
        object,
      ),
    );
}

Person $decodePerson(BytesReader reader, int bufferEnd) {
  String? name;
  int? age;
  String? address;
  Metadata? metadata;
  Uint8List? bytes;
  List<Hobby>? hobbies;

  /// We loop until the end of the buffer.
  final objectBufferEnd = reader.position + bufferEnd;
  while (reader.position < objectBufferEnd) {
    /// We decode the field index.
    final field = reader.readVarUint();
    switch (field) {
      case 0:
        name = reader.readString();

      case 1:
        age = reader.readUint16();

      case 2:
        address = reader.readString();

      case 3:
        final length = reader.readUint32(); // The length of encoded bytes}
        metadata = $decodeMetadata(reader, length);

      case 4:
        final length = reader.readUint32(); // The length of encoded bytes
        bytes = reader.readBytes(length);

      case 5:
        hobbies =
            reader.readIterable((r) => $decodeHobby(r, bufferEnd)).toList();

      case final other:
        throw UnknownFieldCodeException.id(other);
    }
  }

  // Check that all the fields are not null
  // they could be in the case the schema is changed after the data is written
  // If this happens, it is up to the user to handle it
  if (name == null || bytes == null || hobbies == null) {
    throw Exception('The following fields are null: name, bytes');
  }

  // Rebuild the object
  return Person(
    name: name,
    age: age,
    bytes: bytes,
    metadata: metadata,
    hobbies: hobbies,
  )..address = address;
}

void $encodeMetadata(
  BytesWriter writer,
  Metadata object,
) {
  writer
    ..writeVarUint(3893365939)
    ..writeString(object.emailAddress);
  // Write the phoneNumber field if it is not null.
  if (object.phoneNumber != null) {
    writer
      ..writeVarUint(196182440)
      ..writeString(object.phoneNumber!);
  }
}

Metadata $decodeMetadata(BytesReader reader, int bufferEnd) {
  String? emailAddress;
  String? phoneNumber;

  /// We loop until the end of the buffer.
  final objectBufferEnd = reader.position + bufferEnd;
  while (reader.position < objectBufferEnd) {
    /// We decode the field index.
    final field = reader.readVarUint();
    switch (field) {
      case 3893365939:
        emailAddress = reader.readString();

      case 196182440:
        phoneNumber = reader.readString();

      case final other:
        throw UnknownFieldCodeException.id(other);
    }
  }

  // Check that all the fields are not null
  // they could be in the case the schema is changed after the data is written
  // If this happens, it is up to the user to handle it
  if (emailAddress == null) {
    throw Exception('The following fields are null: emailAddress');
  }

  // Rebuild the object
  return Metadata(emailAddress: emailAddress, phoneNumber: phoneNumber);
}
