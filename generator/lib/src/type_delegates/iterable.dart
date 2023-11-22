import 'package:analyzer/dart/element/type.dart';
import 'package:cell_generator/src/type_delegates/base.dart';
import 'package:cell_generator/src/utils.dart';

final class IterableTypeConversionDelegate extends TypeConversionDelegate {
  IterableTypeConversionDelegate(this.type, this.itemConversionDelegate);

  final TypeConversionDelegate itemConversionDelegate;

  /// We keep track of the type of the iterable
  /// So that we can distinguish between lists and sets.
  final DartType type;

  bool get isList => type.isDartCoreList;
  bool get isSet => type.isDartCoreSet;

  @override
  String toString() =>
      'IterableTypeConversionDelegate(itemConversionDelegate: $itemConversionDelegate)';

  @override
  String generateDecodingCode(
    String readerVariableName,
    String objectVariableName,
  ) {
    const itemVariableName = 'item';
    final itemConversionCode = itemConversionDelegate.generateDecodingCode(
      readerVariableName,
      itemVariableName,
    );

    // the code generated above is something like
    // item = $decodeItem(reader, length);
    // so, we remove the item = part so that we can return the item directly
    final itemCode =
        itemConversionCode.trim().removePrefix('$itemVariableName = ');

    var iterableReadingCode = '''
      $objectVariableName = $readerVariableName.readIterable(
        (reader) => $itemCode,
      )
      ''';

    // We then need to append the code for converting the iterable to a list or a set
    // depending on the type of the iterable
    if (isList) {
      iterableReadingCode += '.toList()';
    } else if (isSet) {
      iterableReadingCode += '.toSet()';
    }

    return iterableReadingCode;
  }

  @override
  String generateEncodingCode(
    String writerVariableName,
    String objectVariableName,
  ) {
    final itemEncodingCode = itemConversionDelegate.generateEncodingCode(
      writerVariableName,
      'item',
    );

    return '''
      writeIterable($objectVariableName, (item) => $itemEncodingCode,)
      ''';
  }
}
