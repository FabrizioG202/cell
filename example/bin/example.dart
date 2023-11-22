import 'dart:io';

import 'package:cell/cell.dart';
import 'package:example/cell_bindings.g.dart';
import 'package:example/classes.dart/person.dart';

Future<void> main() async {
  // the file containing the store / database
  final storeFile = File('data/data.cell');

  // open the file with the schema
  final store = await Store.open(file: storeFile, rowSchema: kPersonSchema);

  // clear the store in case it already exists
  await store.clear();

  // create a list of people
  final people = [
    Person(
      name: 'John',
      age: 20,
      address: 'Somewhere',
      hobby: Hobby.coding,
    ),
    Person(
      name: 'Jane',
      age: 21,
      address: 'Somewhere else',
      hobby: Hobby.reading,
      metadata:
          PersonMetadata(email: 'hello@example.com', phoneNumber: '1234567890'),
    ),
  ];

  // write the people to the store
  await store.addAll(people);

  // read the people from the store
  final readPeople = await store.readAll();

  // print the people
  print(readPeople);
}
