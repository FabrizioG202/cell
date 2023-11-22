// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: public_member_api_docs, unused_import

import 'package:cell/cell.dart';
import 'dart:typed_data';
import 'package:example/classes.dart/person.dart';

/// The indices for the embedded types
/// This is used to recognize the type of an embedded object
/// when decoding it from bytes
/// They are unique for each embedded type
const kCellTypeIndexes = {
  Person: 3386891548,
  PersonMetadata: 3896143005,
  Hobby: 223637625,
};
const kPersonSchema = EmbeddedSchema<Person>(
  name: 'Person',
  writeTo: $encodePerson,
  readFrom: $decodePerson,
  type: Person,
);

const kPersonMetadataSchema = EmbeddedSchema<PersonMetadata>(
  name: 'PersonMetadata',
  writeTo: $encodePersonMetadata,
  readFrom: $decodePersonMetadata,
  type: PersonMetadata,
);

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

  // Write the hobby field if it is not null.
  if (object.hobby != null) {
    writer.writeVarUint(3);
    $encodeHobby(
      writer,
      object.hobby!,
    );
  }

  // Write the metadata field if it is not null.
  if (object.metadata != null) {
    writer
      ..writeVarUint(4)
      ..encapsulateWithUint32Length((writer) => $encodePersonMetadata(
            writer,
            object.metadata!,
          ));
  }
}

Person $decodePerson(BytesReader reader, int bufferEnd) {
  String? name;
  int? age;
  String? address;
  Hobby? hobby;
  PersonMetadata? metadata;

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
        hobby = $decodeHobby(reader, -1);

      case 4:
        final length = reader
            .readUint32(); // The length of the bytes encoded by this object
        metadata = $decodePersonMetadata(reader, length);

      case final other:
        throw UnknownFieldCodeException.id(other);
    }
  }

  // Check that all the fields are not null
  // they could be in the case the schema is changed after the data is written
  // If this happens, it is up to the user to handle it
  if (name == null) {
    throw Exception('One of the following fields is null: name');
  }

  // Rebuild the object
  return Person(
      name: name, metadata: metadata, address: address, hobby: hobby, age: age);
}

void $encodePersonMetadata(
  BytesWriter writer,
  PersonMetadata object,
) {
  writer
    ..writeVarUint(0)
    ..writeString(object.email);
  writer
    ..writeVarUint(1)
    ..writeString(object.phoneNumber);
}

PersonMetadata $decodePersonMetadata(BytesReader reader, int bufferEnd) {
  String? email;
  String? phoneNumber;

  /// We loop until the end of the buffer.
  final objectBufferEnd = reader.position + bufferEnd;
  while (reader.position < objectBufferEnd) {
    /// We decode the field index.
    final field = reader.readVarUint();
    switch (field) {
      case 0:
        email = reader.readString();

      case 1:
        phoneNumber = reader.readString();

      case final other:
        throw UnknownFieldCodeException.id(other);
    }
  }

  // Check that all the fields are not null
  // they could be in the case the schema is changed after the data is written
  // If this happens, it is up to the user to handle it
  if (email == null || phoneNumber == null) {
    throw Exception('One of the following fields is null: email, phoneNumber');
  }

  // Rebuild the object
  return PersonMetadata(email: email, phoneNumber: phoneNumber);
}

/// This is the encoding function for the enum Hobby
void $encodeHobby(
  BytesWriter writer,
  Hobby object,
) {
  writer.writeVarUint(
    switch (object) {
      Hobby.reading => 69,
      Hobby.writing => 420,
      Hobby.coding => 1337,
    },
  );
}

/// This is the decoding function for the enum Hobby
Hobby $decodeHobby(BytesReader reader, int bufferEnd) {
  final index = reader.readVarUint();
  return switch (index) {
    69 => Hobby.reading,
    420 => Hobby.writing,
    1337 => Hobby.coding,
    final other => throw InvalidFieldException('Invalid field: $other')
  };
}
