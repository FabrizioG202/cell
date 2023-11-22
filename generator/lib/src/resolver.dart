// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:cell/cell.dart';
import 'package:cell_generator/src/embedded/base.dart';
import 'package:cell_generator/src/embedded/class/class.dart';
import 'package:cell_generator/src/embedded/enum/enum.dart';
import 'package:cell_generator/src/gen.dart';
import 'package:cell_generator/src/indices.dart';
import 'package:cell_generator/src/type_checkers.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class CellResolver extends Builder {
  static const _kGeneratedFileName = 'cell_bindings.g.dart';

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': [_kGeneratedFileName],
    };
  }

  /// Returns a stream of tuples containing elements annotated with [Embedded] and their corresponding annotations.
  /// The elements are either [ClassElement] or [EnumElement], represented as their common superclass [InterfaceElement].
  ///
  /// The function takes a [BuildStep] as a parameter, which it uses to find all assets in the 'lib/**' directory.
  ///
  /// For each asset, it reads the library and checks all elements for the [Embedded] annotation.
  /// If an element is annotated with [Embedded] and is a [ClassElement] or [EnumElement], it is included in the output.
  /// If an element is annotated with [Embedded] but is not a [ClassElement] or [EnumElement], an [InvalidGenerationSourceError] is thrown.
  ///
  /// The output is a stream of tuples. Each tuple contains:
  /// - [element]: The annotated element, cast to [InterfaceElement].
  /// - [annotation]: The [Embedded] annotation of the element, read using [readEmbeddedAnnotation].
  Stream<({InterfaceElement element, Embedded annotation})> getEmbeddedElements(
    BuildStep buildStep,
  ) async* {
    await for (final asset in buildStep.findAssets(Glob('lib/**'))) {
      for (final element in LibraryReader(
        await buildStep.resolver.libraryFor(
          asset,
        ),
      ).allElements) {
        final annotation = kEmbeddedTypeChecker.firstAnnotationOf(element);
        if (annotation != null) {
          // We check if the element is a class or an enum
          if (element is! ClassElement && element is! EnumElement) {
            throw InvalidGenerationSourceError(
              'Only classes and enums can be annotated with @Embedded',
              element: element,
            );
          }

          yield (
            element: element as InterfaceElement,
            annotation: readEmbeddedAnnotation(annotation),
          );
        }
      }
    }
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final buffer = StringBuffer();
    final elements = await getEmbeddedElements(buildStep).toList();
    final elementData = <ElementData>[];

    // We get the files in which the embedded types are defined
    final filesToImport = elements.map((e) => e.element.source.uri).toSet();

    // We sort the elements by wether they have a preferred index or not (null)
    // We do this so that we can compute the indices of the elements with a
    // preferred index first, and then compute the indices of the elements
    // without a preferred index.
    // in this way, we do not consider a generated index with an higher priority
    // than a preferred index
    // In other words, if the user defines an index, we want to make sure
    // that it is not considered a duplicate of an index which was generated
    // by the script (using the hash function)
    elements.sort(
      (a, b) => (b.annotation.id ?? -1).compareTo(a.annotation.id ?? -1),
    );

    // We compute the elementdata for each element
    for (final (:element, :annotation) in elements) {
      final typeIndex = computeIndex(
        element,
        preferredIndex: annotation.id,

        // We get the elements having the same index as the current element
        // We are interested in the element themselves, not the index
        getDuplicateIndices: (index) => elementData
            .where(
              (e) => e.typeIndex == index,
            )
            .map((e) => e.element),
      );

      // We add the element to the list of elements
      switch (element) {
        case ClassElement():
          elementData.add(
            ClassElementData(
              element: element,
              annotation: annotation,
              typeIndex: typeIndex,
              constructor: ClassElementData.findConstructor(element),
            ),
          );
        case EnumElement():
          elementData.add(
            EnumElementData(
              element: element,
              annotation: annotation,
              typeIndex: typeIndex,
            ),
          );
      }
    }

    // We populate the fields for the classes
    for (final element in elementData) {
      element.populateFields(elementData);
    }

    // We write the header and imports
    _writeHeader(buffer);
    _writeImports(buffer, filesToImport);
    _writeTypeIndices(
      buffer,
      elementData,
    );

    // We generate the schema for each element
    for (final element in elementData) {
      buffer.writeln(element.generateSchemaCode());
    }

    // We generate the conversion code for each element
    for (final element in elementData) {
      buffer.write(
        element.generateConversionCode(
          writerVariableName: 'writer',
          objectVariableName: 'object',
          readerVariableName: 'reader',
          bufferEndVariableName: 'bufferEnd',
        ),
      );
    }

    // write the buffer to file and format it
    await _formatAndWrite(
      buildStep,
      buffer.toString(),
    );
  }

  /// Formats the code and writes it to the output
  Future<void> _formatAndWrite(
    BuildStep buildStep,
    String code,
  ) async {
    String? formattedCode;
    try {
      formattedCode = DartFormatter().format(code);
    } catch (_) {}
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        p.join('lib', CellResolver._kGeneratedFileName),
      ),
      formattedCode ?? code,
    );
  }

  /// Writes the header to the output buffer
  void _writeHeader(StringBuffer buffer) {
    // We ignore some lint rules for the generated code
    // in order to avoid the linter complaining about the generated code
    // - public_member_api_docs is ignored because the generated code is not
    // always annotated with documentation
    //
    // - unused_import is ignored because the generated code imports the
    // typed_data package, which may not be used in the project
    // but we have no way of easily knowing that.
    const kIgnoredLintRules = ['public_member_api_docs', 'unused_import'];

    // We write the header
    buffer
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: ${kIgnoredLintRules.join(', ')}')
      ..writeln();
  }

  /// Writes the imports to the output buffer
  /// It imports:
  ///   - the cell package
  ///   - the files for all the classes
  void _writeImports(
    StringBuffer buffer,
    Set<Uri> uris,
  ) {
    buffer
      ..writeln("import 'package:cell/cell.dart';") //cell
      ..writeln("import 'dart:typed_data';"); // for bytes types
    for (final uri in uris) {
      buffer.writeln("import '$uri';");
    }
  }

  /// Writes the code for type indices to the output buffer
  void _writeTypeIndices(
    StringBuffer buffer,
    List<ElementData> elementDatas,
  ) {
    buffer
      ..write('''
          /// The indices for the embedded types
          /// This is used to recognize the type of an embedded object
          /// when decoding it from bytes
          /// They are unique for each embedded type
          ''')
      ..writeln('const kCellTypeIndexes = {');
    for (final element in elementDatas) {
      buffer.writeln('${element.element.name}: ${element.typeIndex},');
    }
    buffer.writeln('};');
  }
}
