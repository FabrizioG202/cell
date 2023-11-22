import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:cell/cell.dart';
import 'package:cell_generator/src/type_delegates/base.dart';

/// Data for a field of an embedded class.
final class ClassFieldData {
  const ClassFieldData({
    required this.element,
    required this.annotation,
    required this.index,
    required this.delegate,
  });

  final PropertyInducingElement element;
  bool get isNullable =>
      element.type.nullabilitySuffix != NullabilitySuffix.none;
  final Field annotation;
  final int index;
  final TypeConversionDelegate delegate;

  @override
  String toString() =>
      'ClassFieldData(element: $element, annotation: $annotation, index: $index, delegate: $delegate)';
}
