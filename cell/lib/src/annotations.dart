part of cell;

/// Annotates a class or an enum to be embedded.
@Target({TargetKind.enumType, TargetKind.classType})
final class Embedded {
  const Embedded({
    this.id,
    this.additionalInheritedFields = const {},
    this.ignoreInheritedFields = const {},
    this.isCollection = false,
  }) : assert(
          id == null || (id >= 0 && id <= 4294967295),
          'The id must be in the range of a unsigned 32 bit integer (0 - 4294967295)',
        );

  /// The id of the type.
  /// This is used internally to identify the types in mixed collections.
  ///
  /// If you don't specify an id, the id will be generated from the hash of the type's name.
  /// This means that if you change the name of the type, the id will change as well.
  ///
  /// Internally it is encoded as a 32 bit unsigned integer.
  final int? id;

  /// The additional fields that are inherited from the parent class.
  final Map<String, Field> additionalInheritedFields;

  /// The fields to ignore from the parent class(es)
  final Set<String> ignoreInheritedFields;

  /// Wether this embedded type is a collection
  /// For collections, Cell will generate additional code to support Table files.
  final bool isCollection;

  @override
  String toString() =>
      'Embedded(id: $id, additionalInheritedFields: $additionalInheritedFields, ignoreInheritedFields: $ignoreInheritedFields)';
}

/// Annotates a constructor to be a collection constructor.
/// By default this is not needed as the default constructor is used.
///
/// But if you want to use a named constructor, you need to annotate it with this.
final class EmbeddedConstructor {
  const EmbeddedConstructor();
}

/// Annotates a constructor to be a collection constructor.
const embeddedConstructor = EmbeddedConstructor();

/// Annotates a field to be an Embedded Object's field.
@Target({TargetKind.field, TargetKind.getter})
final class Field {
  const Field({
    this.index,
    this.mode,
    // this.onDecodeError,
  }) : assert(
          index == null || (index >= 0 && index <= 65535),
          'The index must be in the range of a unsigned 16 bit integer (0 - 65535) or -1',
        );

  /// The index of this field
  /// This can be used to specify the order of the fields.
  /// Make sure however that you don't change a property's index after you've
  /// already serialized some data.
  /// Otherwise you'll get an error when trying to deserialize the data.
  ///
  /// The index must be unique for each property in a collection.
  /// Moreover, the index must be in the range of a unsigned 16 bit integer (0 - 65535).
  ///
  /// If null, a hash of the property's name will be used.
  /// Refer to the documentation of [Embedded] for more information.
  final int? index;

  /// By default, each field is encoded using the default encodings which are:
  ///   - bool: 1 byte
  ///   - integer: 4 bytes
  ///   - double: 64 bits (float64)
  ///   - string: a varInt + the length of the string in bytes
  /// The encoding mode of this property
  /// This can be used to control how the property is encoded on the disk.
  ///
  /// Using smaller encoding modes will result in smaller files but will also
  /// limit the range of values that can be stored.
  final EncodeMode? mode;

  @override
  String toString() => 'Field(index: $index, mode: $mode)';
}

@Target({TargetKind.field, TargetKind.getter})
final class HandleConversionErrors<FieldType> {
  const HandleConversionErrors({
    this.onDecodeError,
  });

  /// Handles the case in which the decoding of a field fails.
  /// This can be used to handle errors such as:
  /// - invalid bytes, etc.
  final FieldType Function(Uint8List bytes)? onDecodeError;
}
