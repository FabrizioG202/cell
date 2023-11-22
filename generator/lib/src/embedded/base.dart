import 'package:analyzer/dart/element/element.dart';
import 'package:cell/cell.dart';
import 'package:source_gen/source_gen.dart';

abstract base class ElementData<ElementType extends InterfaceElement> {
  ElementData({
    required this.element,
    required this.annotation,
    required this.typeIndex,
    this.disambiguator,
  }) : typeChecker = TypeChecker.fromStatic(element.thisType);

  final ElementType element;
  final Embedded annotation;
  final int typeIndex;
  final TypeChecker typeChecker;

  /// This is not implemented right now, however may be implemented in the future
  /// to disambiguate between multiple embedded types with the same name.
  final String? disambiguator;

  /// Generates the schema
  String generateSchemaCode();

  /// Populates the fields of the embedded type
  void populateFields(List<ElementData> embeddedElements);

  /// Generates the conversion code for the embedded types.
  /// This is the code that is used to convert the embedded type to and from
  /// bytes.
  String generateConversionCode({
    required String writerVariableName,
    required String objectVariableName,
    required String readerVariableName,
    required String bufferEndVariableName,
  });

  /// The name of the encoding function for this type
  String get encodingFunctionName => '\$encode${element.name}';

  /// The name of the decoding function for this type
  String get decodingFunctionName => '\$decode${element.name}';

  @override
  String toString() {
    return 'ElementData(element: $element, annotation: $annotation, typeIndex: $typeIndex, typeChecker: $typeChecker, disambiguator: $disambiguator)';
  }
}
