import 'package:analyzer/dart/element/element.dart';
import 'package:cell_generator/src/embedded/base.dart';
import 'package:cell_generator/src/embedded/enum/enum_field.dart';
import 'package:cell_generator/src/gen.dart';
import 'package:cell_generator/src/indices.dart';
import 'package:cell_generator/src/type_checkers.dart';
import 'package:source_gen/source_gen.dart';

final class EnumElementData extends ElementData<EnumElement> {
  EnumElementData({
    required super.element,
    required super.annotation,
    required super.typeIndex,
  });

  final List<EnumFieldData> fields = [];

  /// Gets the index for a particular field
  int indexForField(FieldElement field) {
    final index = fields.indexWhere((e) => e.element == field);
    if (index == -1) {
      throw StateError(
        'The field `${field.name}` is not a field of the enum `${element.name}`',
      );
    }
    return index;
  }

  /// This reads all the fields of the enum and assigns an index to each field
  @override
  void populateFields(List<ElementData> embeddedElements) {
    assert(fields.isEmpty, 'Fields already populated');

    // We get the annotated Fields and their annotations
    final annotatedFields = element.fields
        // We assign each field its own annotation.
        .map(
          (e) => (field: e, annotation: kFieldTypeChecker.firstAnnotationOf(e)),
        )

        // We filter out the fields that are not annotated
        .where((e) => e.annotation != null)

        // We decode the annotation
        .map(
          (e) =>
              (field: e.field, annotation: readFieldAnnotation(e.annotation!)),
        )

        // We convert them to a List to be able to sort them
        .toList()

      // Sort the fields by index (first the ones with a preferred index, then the ones without)
      ..sort(
        (a, b) =>
            (a.annotation.index ?? -1).compareTo(b.annotation.index ?? -1),
      );

    // We compute the index and the conversion delegate for each field
    for (final (:field, :annotation) in annotatedFields) {
      // We compute the index for the field
      final index = computeIndex(
        field,
        preferredIndex: annotation.index,

        // We get the elements having the same index as the current element
        // We are interested in the element themselves, not the index
        getDuplicateIndices: (index) => fields
            .where(
              (e) => e.index == index,
            )
            .map((e) => e.element),
      );

      // Assert that the annotation is placed on an element which is a [FieldElement]
      if (!field.isEnumConstant) {
        throw InvalidGenerationSourceError(
          'The annotation `@Field` in enum can only be placed on enum constants',
          element: field,
        );
      }

      // We add the field to the list of fields
      fields.add(
        EnumFieldData(
          element: field,
          index: index,
        ),
      );
    }
  }

  @override
  String generateConversionCode({
    required String writerVariableName,
    required String objectVariableName,
    required String readerVariableName,
    required String bufferEndVariableName,
  }) {
    // The case for unserialized enum values
    final unserializedFields = element.fields
        .where(
          (e) => e.isEnumConstant,
        )
        .where(
          (element) => !fields.any((e) => e.element == element),
        );

    // the case for unserialized enum values
    // If we have any, we throw an exception
    final value = unserializedFields.isNotEmpty
        ? '''
          , ${unserializedFields.map((e) => '${element.displayName}.${e.name}').join('||')} 
             => throw Exception('The enum value \$object is not serialized')'''
        : '';

    return '''

    /// This is the encoding function for the enum ${element.name}
    void $encodingFunctionName(BytesWriter $writerVariableName, ${element.displayName} $objectVariableName,){
      $writerVariableName.writeVarUint(
        switch ($objectVariableName) {
          ${fields.map((e) => '${element.displayName}.${e.element.name} => ${e.index}').join(',\n')}
          $value,
        },
      );
    }

    /// This is the decoding function for the enum ${element.name}
    ${element.displayName} $decodingFunctionName(BytesReader $readerVariableName, int $bufferEndVariableName){
      final index = $readerVariableName.readVarUint();
      return switch (index) {
        ${fields.map((e) => '${e.index} => ${element.displayName}.${e.element.name},').join('\n')}
        final other => throw InvalidFieldException('Invalid field: \$other') 
      };
    }
    
    ''';
  }

  @override
  String generateSchemaCode() => '';
}
