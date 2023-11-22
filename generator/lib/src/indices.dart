import 'package:analyzer/dart/element/element.dart';
import 'package:cell_generator/src/hash.dart';
import 'package:source_gen/source_gen.dart';

/// A function to compute unique indices for elements of type [T] where [T] extends [Element].
/// This function is used at different points throughout the script, namely:
/// - computing field indices
/// - computing type indices
/// - computing enum values indices
///
/// The function takes in three parameters:
/// - [element]: The element for which the index is to be computed.
/// - [preferredIndex]: An optional preferred index for the element. If this index is already taken, an error is thrown.
/// - [getDuplicateIndices]: A function that takes an index and returns an iterable of elements that have the same index.
///
/// If [preferredIndex] is provided and is not already taken, it is returned as the index for the element.
/// If [preferredIndex] is not provided or is already taken, the function generates a unique index by hashing the display name of the element with a salt.
/// The salt is incremented until a unique index is found.
///
/// The function returns the computed index.
int computeIndex<T extends Element>(
  T element, {
  required int? preferredIndex,
  required Iterable<T> Function(int index) getDuplicateIndices,
}) {
  if (preferredIndex != null) {
    // We check if the index is already taken and if it is we throw an error letting the user know of the first duplicate
    if (getDuplicateIndices(preferredIndex).firstOrNull case final T item) {
      throw InvalidGenerationSourceError(
        'The index `$preferredIndex` is already taken by ${item.name}',
        element: element,
      );
    }

    // Since the preferred index is not taken, we return it
    return preferredIndex;
  }

  // We generate a hash for the field name
  int index;
  var salt = 0;
  do {
    index = hashStringWithSalt(element.displayName, salt);
    salt++;
  } while (getDuplicateIndices(index).isNotEmpty);

  // We return the index
  // which, at this point we know is unique
  return index;
}
