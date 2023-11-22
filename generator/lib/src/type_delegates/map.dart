import 'package:cell_generator/src/type_delegates/base.dart';

final class MapTypeConversionDelegate extends TypeConversionDelegate {
  MapTypeConversionDelegate(
    this.keyConversionDelegate,
    this.valueConversionDelegate,
  );

  final TypeConversionDelegate keyConversionDelegate;
  final TypeConversionDelegate valueConversionDelegate;

  @override
  String toString() =>
      'MapTypeConversionDelegate(keyConversionDelegate: $keyConversionDelegate, valueConversionDelegate: $valueConversionDelegate)';

  @override
  String generateDecodingCode(
    String readerVariableName,
    String objectVariableName,
  ) {
    return '';
  }

  @override
  String generateEncodingCode(
    String writerVariableName,
    String objectVariableName,
  ) {
    throw UnimplementedError();
  }
}
