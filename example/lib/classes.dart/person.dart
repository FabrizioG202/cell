// ignore_for_file: must_be_immutable

import 'package:cell/cell.dart';
import 'package:equatable/equatable.dart';

@Embedded()
final class Person extends Equatable {
  @EmbeddedConstructor()
  Person({
    required this.name,
    this.metadata,
    this.address,
    this.hobby,
    this.age,
  });

  @Field(index: 0)
  final String name;

  @Field(index: 1, mode: EncodeMode.uint16)
  final int? age;

  @Field(index: 2)
  String? address;

  @Field(index: 3)
  final Hobby? hobby;

  @Field(index: 4)
  final PersonMetadata? metadata;

  @override
  List<Object?> get props => [name, age, address, hobby, metadata];

  @override
  String toString() =>
      'Person(name: $name, age: $age, address: $address, hobby: $hobby, metadata: $metadata)';
}

@Embedded()
enum Hobby {
  @Field(index: 69)
  reading,

  @Field(index: 420)
  writing,

  @Field(index: 1337)
  coding,
}

/// A person metadata
@Embedded()
final class PersonMetadata extends Equatable {
  @EmbeddedConstructor()
  PersonMetadata({
    required this.email,
    required this.phoneNumber,
  });

  @Field(index: 0)
  final String email;

  @Field(index: 1)
  final String phoneNumber;

  @override
  List<Object?> get props => [email, phoneNumber];

  @override
  String toString() =>
      'PersonMetadata(email: $email, phoneNumber: $phoneNumber)';
}
