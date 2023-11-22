part of cell.database;

/// Represents a schema for serializing and deserializing objects of type [ClassType].
/// Instances of this class should not be created directly; they are meant to be
/// generated automatically.
///
/// This schema contains methods for serializing (`writeTo`) and deserializing (`readFrom`)
/// objects, along with metadata like the schema's `name` and the type of object it handles.
final class EmbeddedSchema<ClassType> {
  const EmbeddedSchema({
    required this.name,
    required this.type,
    required this.writeTo,
    required this.readFrom,
  });

  /// The name of the schema, which also determines the name of the associated file.
  final String name;

  /// The type of the class that this schema serializes.
  /// Used to retain type information at runtime.
  final Type type;

  /// A function that serializes an object of type [ClassType] into a [Uint8List].
  /// Requires a [BytesWriter] for writing data and an object of [ClassType] to serialize.
  final void Function(BytesWriter, ClassType) writeTo;

  /// A function that deserializes an object of type [ClassType] from a [Uint8List].
  /// Requires a [BytesReader] for reading data and the length of the data to be read.
  final ClassType Function(BytesReader, int length) readFrom;
}
