/// Theis library contains the logic to deal
/// with reading object from [DartObject]s
library gen;

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:cell/cell.dart';

/// get the index of an enum's value
int? enumIndexType(DartObject typeField) {
  if (!typeField.isNull) {
    final interfaceType = typeField.type as InterfaceType?;
    if (interfaceType == null) {
      throw ArgumentError.value(
        typeField,
        'typeField',
        'Must be an interface type',
      );
    }

    // Get the enum values
    final enumValues =
        interfaceType.element.fields.where((f) => f.isEnumConstant).toList();

    // Find the index of the matching enum constant.
    for (var i = 0; i < enumValues.length; i++) {
      if (enumValues[i].computeConstantValue() == typeField) return i;
    }
  }

  return null;
}

/// Decodes an annotation object ot a [Embedded] annotaton
/// This is because DartObjects are not evaluated when we run the code
/// generation, so we need to 'parse' the annotation ourselves
/// (or at least that is what I think is happening here.)
Embedded readEmbeddedAnnotation(DartObject annotation) {
  final idField = annotation.getField('id');
  final isCollectionField = annotation.getField('isCollection');
  final additionalInheritedFieldsField =
      annotation.getField('additionalInheritedFields');
  final ignoreInheritedFieldsField =
      annotation.getField('ignoreInheritedFields');

  // If any field is null, the annotation is invalid
  if (idField == null ||
      additionalInheritedFieldsField == null ||
      ignoreInheritedFieldsField == null ||
      isCollectionField == null) {
    throw ArgumentError.value(annotation, 'annotation', 'Invalid annotation');
  }

  // Simple properties
  final id = idField.toIntValue();
  final isCollection = isCollectionField.toBoolValue()!;

  // Read the additional inherited fields
  final additionalInheritedFields =
      additionalInheritedFieldsField.toMapValue()!.map(
            (key, value) => MapEntry(
              key!.toStringValue()!,

              // decode the field from the annotation
              readFieldAnnotation(
                value!,
              ),
            ),
          );

  // Read the ignore inherited fields
  final ignoreInheritedFields = ignoreInheritedFieldsField
      .toSetValue()!
      .map(
        (e) => e.toStringValue()!,
      )
      .toSet();

  // Finish reading the annotation
  return Embedded(
    id: id,
    isCollection: isCollection,
    additionalInheritedFields: additionalInheritedFields,
    ignoreInheritedFields: ignoreInheritedFields,
  );
}

/// Decodes an annotation object ot a [Field] annotaton
/// This is because DartObjects are not evaluated when we run the code
/// generation, so we need to 'parse' the annotation ourselves
/// (or at least that is what I think is happening here.)
Field readFieldAnnotation(DartObject annotation) {
  final indexField = annotation.getField('index');
  final modeField = annotation.getField('mode');

  // If any field is null, the annotation is invalid
  if (indexField == null || modeField == null) {
    throw ArgumentError.value(annotation, 'annotation', 'Invalid annotation');
  }

  // Finish reading the annotation
  final modeIndex = enumIndexType(modeField);
  return Field(
    index: indexField.toIntValue(),
    mode: modeIndex == null ? null : EncodeMode.values[modeIndex],
  );
}
