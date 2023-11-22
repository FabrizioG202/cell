import 'package:analyzer/dart/element/element.dart';

final class EnumFieldData {
  const EnumFieldData({
    required this.element,
    required this.index,
  });

  final FieldElement element;

  final int index;

  @override
  String toString() => 'EnumFieldData(element: $element, index: $index)';
}
