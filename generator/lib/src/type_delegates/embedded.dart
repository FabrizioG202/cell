import 'package:cell_generator/src/embedded/base.dart';
import 'package:cell_generator/src/embedded/enum/enum.dart';
import 'package:cell_generator/src/type_delegates/base.dart';

final class EmbeddedTypeConversionDelegate extends TypeConversionDelegate {
  EmbeddedTypeConversionDelegate(this.elementData);

  final ElementData elementData;

  /// Wether the embedded type is an enum
  /// We need to know it so that we can decide if we want to encapuslate it
  /// with a length or not since enums are encoded as integers
  bool get isEnum => elementData is EnumElementData;

  @override
  String toString() =>
      'EmbeddedTypeConversionDelegate(elementData: $elementData)';

  @override
  String generateDecodingCode(
    String readerVariableName,
    String objectVariableName,
  ) =>
      '''
      ${(!isEnum) ? 'final length = $readerVariableName.readUint32(); // The length of the bytes encoded by this object' : ''}
      $objectVariableName = ${elementData.decodingFunctionName}($readerVariableName, ${(!isEnum) ? 'length' : -1})
      ''';

  @override
  String generateEncodingCode(
    String writerVariableName,
    String objectVariableName,
  ) {
    final writingCode = '''
        ${elementData.encodingFunctionName}(
          $writerVariableName,
          $objectVariableName,
        )
        ''';

    // In case it is an enum, we do not encapsulate it with a length
    // We add a , at the end so that it is formatted according to the style guide
    if (!isEnum) {
      return 'encapsulateWithUint32Length((writer) => $writingCode)';
    }

    // Return the writing code
    return writingCode;
  }

  /// Joining is different for enums, since we do not encapsulate them with a length
  @override
  String joinEncodingStatements(
    String writerVariableName,
    String fieldIndexWritingCode,
    String fieldEncodingCode,
  ) {
    // In case it is an enum, we do not encapsulate it with a length
    if (isEnum) {
      return '''
        $writerVariableName.$fieldIndexWritingCode;
        $fieldEncodingCode;
      ''';
    }

    // Otherwise, we use the default implementation
    return super.joinEncodingStatements(
      writerVariableName,
      fieldIndexWritingCode,
      fieldEncodingCode,
    );
  }
}
