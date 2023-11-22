import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:cell/cell.dart';
import 'package:cell_generator/src/embedded/base.dart';
import 'package:cell_generator/src/type_checkers.dart';
import 'package:cell_generator/src/type_delegates/dart_core.dart';
import 'package:cell_generator/src/type_delegates/embedded.dart';
import 'package:cell_generator/src/type_delegates/iterable.dart';
import 'package:cell_generator/src/type_delegates/map.dart';
import 'package:cell_generator/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

/// Handles the logic for converting a type to and from bytes
abstract base class TypeConversionDelegate {
  /// Computes the [TypeConversionDelegate] for a type
  static TypeConversionDelegate getFor(
    DartType type,
    List<ElementData> embeddedElements, {
    required PropertyInducingElement field,
    required Field annotation,

    // wether we are considering a type which is not directly annotated
    // for example, this function gets called for the type of a list item,
    // and in such case, we want to tell the user that the problem
    // is not in the list item, but in the list itself
    bool isNested = false,
  }) {
    // An utility function to throw an error
    // If [isNested] is false, it throws an error on the field
    // If [isNested] is true, it throws an error on the field, but telling the user
    // that the problem is in the list item
    InvalidGenerationSourceError getError(
      DartType type,
      Iterable<EncodeMode> supportedModes,
    ) {
      var message =
          'The field `${field.name}` is annotated with `@Property` with mode `${annotation.mode}`';

      // if the supported modes is empty, we tell the user that the type does not support an encode mode
      // and it is always encoded as [type]
      if (supportedModes.isEmpty) {
        message +=
            ' but the field type `${type.getDisplayString(withNullability: false)}` does not support an encode mode and is always encoded as `${type.getDisplayString(withNullability: false)}`';
      }

      // if the supported modes is not empty, we tell the user that the type does not support the encode mode
      // provided in the annotation and that it requires one of the supported modes
      else {
        message +=
            ' but the field type `${type.getDisplayString(withNullability: false)}` does not support the encode mode `${annotation.mode}` and requires one of the supported modes: ${supportedModes.map((e) => e.toString()).join(', ')}';
      }

      return InvalidGenerationSourceError(
        message,
        element: isNested ? field.type.element : field,
      );
    }

    // We first check if it is any of the core types
    // first integers.
    final modeFromAnnotation = annotation.mode;
    if (type.isDartCoreInt) {
      // we check that the [field's encode mode] is compatible with the type or it is null
      if (![null, ...kIntegerEncodeModes].contains(modeFromAnnotation)) {
        throw getError(type, kIntegerEncodeModes);
      }
      // We use either the mode from the annotation or the default mode
      // for this object type (int32)
      return CoreTypeConversionDelegate(
        type,
        mode: modeFromAnnotation ?? EncodeMode.int32,
      );
    }

    // Floating Point
    if (type.isDartCoreDouble) {
      // we check that the [field's encode mode] is compatible with the type
      if (![null, ...kFloatingPointEncodeModes].contains(modeFromAnnotation)) {
        throw getError(type, kFloatingPointEncodeModes);
      }
      // We use either the mode from the annotation or the default mode
      // for this object type (float64)
      return CoreTypeConversionDelegate(
        type,
        mode: modeFromAnnotation ?? EncodeMode.float64,
      );
    }

    // DateTimes
    if (kDateTimeTypeChecker.isAssignableFromType(type)) {
      // we check that the [field's encode mode] is compatible with the type
      if (![null, ...kDateTimeEncodeModes].contains(modeFromAnnotation)) {
        throw getError(type, kDateTimeEncodeModes);
      }
      // We use either the mode from the annotation or the default mode
      // for this object type (dateTimeMilliseconds)
      return CoreTypeConversionDelegate(
        type,
        mode: modeFromAnnotation ?? EncodeMode.dateTimeMilliseconds,
      );
    }

    // Lists (and Sets) are a special case.
    // we use the encode mode as for the element's encode mode.
    if (type.isDartCoreList || type.isDartCoreSet) {
      // We get the type of the elements
      final elementType = type as ParameterizedType;
      final elementArgumentType = elementType.typeArguments.first;

      // We get the delegate for the element type
      // We create the delegate for the iterable type
      return IterableTypeConversionDelegate(
        type,

        // the [getFor] is called with the parameters as this as
        TypeConversionDelegate.getFor(
          elementArgumentType,
          embeddedElements,
          field: field,
          annotation: annotation,
          isNested: true,
        ),
      );
    }

    // From this point onwards, the type must not have a specified encode mode
    // as none of the types below support them.
    if (modeFromAnnotation != null) {
      throw getError(type, []);
    }

    // We check for String and boolean types
    // And in case, we check that the mode is null
    if (type.isDartCoreString || type.isDartCoreBool) {
      return CoreTypeConversionDelegate(type);
    }

    // We check for bytes types
    if (kBytesTypeCheckers.any((e) => e.isAssignableFromType(type))) {
      return CoreTypeConversionDelegate(type);
    }

    // Then we check for if it is a custom supported type
    if (embeddedElements
            .firstWhereOrNull((e) => e.typeChecker.isExactlyType(type))
        case final ElementData customSupportedTypeData) {
      // The element is of supported type [customSupportedTypeData]
      return EmbeddedTypeConversionDelegate(customSupportedTypeData);
    }

    // We check for Maps
    if (type.isDartCoreMap) {
      // We get the type of the keys and values
      final mapType = type as ParameterizedType;
      final keyType = mapType.typeArguments.first;
      final valueType = mapType.typeArguments.last;

      // We create the delegate for the map type
      return MapTypeConversionDelegate(
        TypeConversionDelegate.getFor(
          keyType,
          embeddedElements,
          field: field,
          annotation: annotation,
          isNested: true,
        ),
        TypeConversionDelegate.getFor(
          valueType,
          embeddedElements,
          field: field,
          annotation: annotation,
          isNested: true,
        ),
      );
    }

    // At this point, the type is not supported
    throw InvalidGenerationSourceError(
      'The field `${field.name}` is annotated with `@Field` with mode `${annotation.mode}` but the field type `${type.getDisplayString(withNullability: false)}` is not supported',
      element: field,
    );
  }

  String generateEncodingCode(
    String writerVariableName,
    String objectVariableName,
  );

  String generateDecodingCode(
    String readerVariableName,
    String objectVariableName,
  );

  /// We compose the code for writing the field.
  /// This will produce the following code (for the example of a string field):
  /// writer..writeVarUint(0)..writeString(value);
  /// (Unformatted, as it will be formatted automatically later)
  /// By default, we use a cascade operator to write the field
  /// However, this can be overriden by subclasses to provide a different implementation
  /// See [EmbeddedTypeConversionDelegate] for an example of this.
  String joinEncodingStatements(
    String writerVariableName,
    String fieldIndexWritingCode,
    String fieldEncodingCode,
  ) =>
      [
        fieldIndexWritingCode,
        fieldEncodingCode,
      ].compose(
        prefix: '$writerVariableName..',
        separator: '..',
        suffix: ';',
      );
}
