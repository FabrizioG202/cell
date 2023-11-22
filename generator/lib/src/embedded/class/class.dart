import 'package:analyzer/dart/element/element.dart';
import 'package:cell_generator/src/embedded/base.dart';
import 'package:cell_generator/src/embedded/class/class_field.dart';
import 'package:cell_generator/src/gen.dart';
import 'package:cell_generator/src/indices.dart';
import 'package:cell_generator/src/type_checkers.dart';
import 'package:cell_generator/src/type_delegates/base.dart';
import 'package:cell_generator/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

final class ClassElementData extends ElementData<ClassElement> {
  ClassElementData({
    required super.element,
    required super.annotation,
    required super.typeIndex,
    required this.constructor,
  });

  /// The fields for this class,
  /// which are created after the class is processed
  /// (look at the [populateFields] method)
  final List<ClassFieldData> fields = [];

  /// The constructor for this class
  final ConstructorElement constructor;

  /// The class Display Name
  String get displayName => element.displayName;

  @override
  String generateConversionCode({
    required String writerVariableName,
    required String objectVariableName,
    required String readerVariableName,
    required String bufferEndVariableName,
  }) {
    return '''
    ${_generateEncodingFunction(writerVariableName, objectVariableName)}
    ${_generateDecodingFunction(readerVariableName, bufferEndVariableName)}
    ''';
  }

  String _generateEncodingFunction(
    String writerVariableName,
    String objectVariableName,
  ) {
    final bodyBuffer = StringBuffer();

    for (final field in fields) {
      // The code for adding the field index to the writer
      // we separated this so it can be easier in the future to support different
      // encoding modes for this information (like uint8, uint16, etc.)
      final fieldIndexWritingCode = 'writeVarUint(${field.index})';

      // The code for encoding the field
      // This generates something along the lines of writeString(value)
      final fieldEncodingCode = field.delegate.generateEncodingCode(
        writerVariableName,
        '$objectVariableName.${field.element.name}${field.isNullable ? '!' : ''}',
      );

      // We compose the code for writing the field.
      final fieldWriteCode = field.delegate.joinEncodingStatements(
        writerVariableName,
        fieldIndexWritingCode,
        fieldEncodingCode,
      );

      // If the field is nullable, we add an if statement to check if it is null
      // and if it is not null, we write the field
      if (field.isNullable) {
        bodyBuffer.writeln('''
          // Write the ${field.element.name} field if it is not null.
          if ($objectVariableName.${field.element.name} != null) {
            $fieldWriteCode
          }
        ''');
      } else {
        bodyBuffer.writeln(fieldWriteCode);
      }
    }

    return '''
    void $encodingFunctionName(BytesWriter $writerVariableName, $displayName $objectVariableName,){
      $bodyBuffer
    }
    ''';
  }

  String _generateDecodingFunction(
    String readerVariableName,
    String bufferEndVariableName,
  ) {
    // The list of parameters to deserialzie
    // This creates a list of variables (all nullable) with the same name as the fields
    // of the class
    final parametersBuffer = StringBuffer();
    for (final field in fields) {
      parametersBuffer.writeln(
        '${field.element.type.getDisplayString(withNullability: false)}? ${field.element.name};',
      );
    }

    /// the while and switch statements for reading the fields
    final decodingLoopBuffer = StringBuffer()..write('''
      /// We loop until the end of the buffer.
      final objectBufferEnd = $readerVariableName.position + $bufferEndVariableName;
      while ($readerVariableName.position < objectBufferEnd){

        /// We decode the field index.
        final field = $readerVariableName.readVarUint();
        switch (field) {
    ''');

    /// For each field, we add a case statement
    for (final field in fields) {
      decodingLoopBuffer.writeln('''
        case ${field.index}:
          ${field.delegate.generateDecodingCode(readerVariableName, field.element.name)};
      ''');
    }

    /// We add the default case
    decodingLoopBuffer.writeln('''
        case final other:
          throw UnknownFieldCodeException.id(other);
      }
    }
    ''');

    /// It adds an if with disjunctions for each field
    /// and if the condition is not met, it throws an exception
    final assertConditions = fields
        .where((element) => !element.isNullable)
        .map((e) => '${e.element.name} == null');

    final assertCode = '''
        // Check that all the fields are not null
        // they could be in the case the schema is changed after the data is written
        // If this happens, it is up to the user to handle it
        if (${assertConditions.join(' || ')}){
          throw Exception('One of the following fields is null: ${fields.where((element) => !element.isNullable).map((e) => e.element.name).join(', ')}');
        }
        ''';

    return '''
    $displayName $decodingFunctionName(BytesReader $readerVariableName, int $bufferEndVariableName){
      $parametersBuffer
        $decodingLoopBuffer
        ${assertConditions.isNotEmpty ? assertCode : ''}

        // Rebuild the object
        ${generateConstructorCode()}
    }
    ''';
  }

  /// Generates the constructor for the field
  /// It adds first positional parameters for the fields
  /// and then named parameters for the fields
  ///
  /// If incompatible fields are found, it throws an error
  String generateConstructorCode() {
    final className = element.name;

    // We do this because we need to check that each of the unsettable fields
    // is passed in to the constructor
    final (inConstructorFields, afterConstructorFields) =
        fields.split((f) => f.element.isFinal && f.element.isLate == false);

    // We check that the constructor has only these fields and no others
    // If it has additional fields, we throw an error
    // If it is missing fields, we throw an error
    // If it has the same fields, we continue
    final params = constructor.parameters;
    final paramsNames = params
        .map(
          (e) => e.name,
        )
        .toSet();

    // We now add to the list of inConstructorFields, the ones from afterConstructorFields
    // which are also in the constructor
    afterConstructorFields.moveWhereTo(
      inConstructorFields,
      (e) => paramsNames.contains(
        e.element.name,
      ),
    );

    // We get the names of the required fields
    final requiredFieldsNames =
        inConstructorFields.map((e) => e.element.name).toSet();

    // We check that the constructor has only these fields and no others
    // If it has additional fields, we throw an error
    if (paramsNames.difference(requiredFieldsNames) case final extraFieldsNames
        when extraFieldsNames.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'The constructor for `$className` has additional fields (${extraFieldsNames.join(",")}) which are not annotated with `@Field`',
        element: constructor,
      );
    }

    // If it is missing fields, we throw an error
    if (requiredFieldsNames.difference(paramsNames)
        case final missingFieldsNames when missingFieldsNames.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'The constructor for `$className` is missing fields (${missingFieldsNames.join(",")}) which are annotated with `@Field`',
        element: constructor,
      );
    }

    // We build the constructor
    final constructorBuffer = StringBuffer('$className(');

    // We add the positional parameters
    final positionalParams = constructor.parameters
        .where((p) => p.isPositional)
        .map((e) => e.name)
        .join(',');
    final namedParams = constructor.parameters
        .where((p) => p.isNamed)
        .map((e) => '${e.name}: ${e.name}')
        .join(',');

    constructorBuffer
      // We write the parameters
      ..writeAll(
        [
          if (positionalParams.isNotEmpty) positionalParams,
          if (namedParams.isNotEmpty) namedParams,
        ],
        ',',
      )

      // We close the constructor
      ..write(')');

    // For each of the fields after the constructor, we set them
    for (final field in afterConstructorFields) {
      // If the field has no setter, we throw an error
      if (field.element.setter == null) {
        throw InvalidGenerationSourceError(
          'The field `${field.element.name}` is annotated with `@Field` but it does not have a setter and cannot be set in the constructor.',
          element: field.element,
        );
      }

      constructorBuffer.writeln(
        '''
        ..${field.element.name} = ${field.element.name}
      ''',
      );
    }

    //We close the constructor with
    return 'return $constructorBuffer;';
  }

  /// Finds the constructor for this class
  /// It finds the first constructor annotated with [EmbeddedConstructor]
  /// or the default constructor if no constructor is annotated
  /// If both are null, it throws an error
  /// If there is more than one constructor annotated, it throws an error
  static ConstructorElement findConstructor(ClassElement element) {
    // We get the constructors
    final constructors = element.constructors;

    // We get the constructors annotated with [EmbeddedConstructor]
    final annotatedConstructors = constructors
        .where(
          (element) =>
              kEmbeddedConstructorTypeChecker.hasAnnotationOfExact(element),
        )
        .toList();

    // If there are no annotated constructors, we return the default constructor
    if (annotatedConstructors.isEmpty) {
      return constructors.firstWhere(
        (element) => element.isDefaultConstructor,
        orElse: () => throw InvalidGenerationSourceError(
          'Generator cannot target `${element.name}`, the class `${element.name}` does not have a default constructor.',
          element: element,
        ),
      );
    }

    // If there is more than one annotated constructor, we throw an error
    if (annotatedConstructors.length > 1) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.name}`, the class `${element.name}` has more than one constructor annotated with `@EmbeddedConstructor`.',
        element: element,
      );
    }

    // If there is only one annotated constructor, we return it
    return annotatedConstructors.first;
  }

  /// Populates the [fields] list
  /// It also performs compatibility checks on the fields' annotations
  /// and also assigns an index to each field
  @override
  void populateFields(List<ElementData> embeddedElements) {
    assert(fields.isEmpty, 'Fields already populated');

    // all the fields which are considered for this class
    final allFields = [
      // All the fields of the class
      ...element.accessors,

      // All from supertypes
      ...element.allSupertypes.expand(
        (e) => e.element.accessors,
      ),
    ]
        // If the accessor is a getter
        .where(
          (e) => e.isGetter,
        )

        // We get the variable (I am not sure why this is necessary to be honest)
        .map(
          (e) => e.variable,
        );

    // separate stuff
    // Find a way to get both fields and getters
    final annotatedFields = allFields
        // We assign each field its own annotation.
        .map(
          (e) => (
            field: e,
            annotation: kFieldTypeChecker.firstAnnotationOf(e.nonSynthetic)
          ),
        )

        // We filter out the fields that are not annotated
        .where((e) => e.annotation != null)

        // We decode the annotation
        .map(
          (e) => (
            field: e.field,
            annotation: readFieldAnnotation(e.annotation!),
          ),
        )

        // We convert them to a List to be able to sort them
        .toList()

      // Sort the fields by index (first the ones with a preferred index, then the ones without)
      ..sort(
        (a, b) =>
            (a.annotation.index ?? -1).compareTo(b.annotation.index ?? -1),
      );

    // We loop over the fields and remove the ones which cannot be annotated
    // while we throw an errors if they happen:
    // like -static fields
    if (annotatedFields.where((element) => element.field.isStatic)
        case final staticFields when staticFields.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'The following fields are static and cannot be annotated with `@Field`: ${staticFields.map((e) => e.field.name).join(', ')}',
        element: element,
      );
    }

    // We look into the [Embedded.additionalInheritedElements]
    for (final MapEntry(key: fieldName, value: fieldAnnotation)
        in annotation.additionalInheritedFields.entries) {
      // We first get the field, and if it is not found, we throw an error
      final field = allFields.firstWhereOrNull((e) => e.name == fieldName);
      if (field == null) {
        throw InvalidGenerationSourceError(
          'The field `$fieldName` is not a field of the class `${element.name}`',
          element: element,
        );
      }

      // We add the field and, in case it is already there, we replace the annotation
      // with the one from the [Embedded.additionalInheritedElements]
      annotatedFields
        // Remove it
        ..removeWhere((e) => e.field.name == fieldName)

        // Add it
        ..add(
          (
            field: field,
            annotation: fieldAnnotation,
          ),
        );
    }

    // We remove the fields from the [Embedded.excludeFields]
    for (final fieldName in annotation.ignoreInheritedFields) {
      // We first get the field, and if it is not found, we throw an error
      final field = allFields.firstWhereOrNull((e) => e.name == fieldName);
      if (field == null) {
        throw InvalidGenerationSourceError(
          'The ignored field `$fieldName` is not a field of the class `${element.name}`',
          element: element,
        );
      }

      // We remove the field
      annotatedFields.removeWhere((element) => element.field == field);
    }

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

      // We add the field to the list of fields
      fields.add(
        ClassFieldData(
          element: field,
          annotation: annotation,
          index: index,
          delegate: TypeConversionDelegate.getFor(
            field.type,
            embeddedElements,
            field: field,
            annotation: annotation,
          ),
        ),
      );
    }
  }

  /// Generates the schema
  /// Generates it like this
  /// ```dart
  /// Schema<ClassName>(
  ///   name: 'ClassName',
  ///   writeToBuffer:  $writeClassName
  ///   readFromBuffer: $readClassName,
  ///   type: ClassName,
  /// );
  /// ```
  @override
  String generateSchemaCode() {
    final className = element.name;

    final schemaName = '${className}Schema';
    return '''
      const k$schemaName = EmbeddedSchema<$className>(
        name: '$className',
        writeTo: $encodingFunctionName,
        readFrom: $decodingFunctionName,
        type: $className,
      );
    ''';
  }
}
