import 'dart:io';
import 'dart:convert';
import 'package:cell/src/io/io.dart';
import 'package:test/test.dart';

void main() {
  // Temporary directory and test file variables
  final tempDir = Directory.current;
  final testFile = File('${tempDir.path}/test.txt');
  RandomAccessFile raf;

  // Write a known string to the file as ASCII bytes
  setUp(() async {
    const initialContent = 'Hello hello world';
    final List<int> initialContentBytes = ascii.encode(initialContent);

    // Open the file in write mode and write the bytes
    raf = await testFile.open(mode: FileMode.write);
    await raf.writeFrom(initialContentBytes);
    await raf.close();
  });

  // Clean up: delete the temporary file
  tearDown(() async {
    await testFile.delete();
  });
  group('File Chunk Removal', () {
    test('Removes a chunk from a file correctly', () async {
      // Calculate the byte positions of the chunk to remove
      // Since we're using ASCII, each character is one byte
      const chunkToRemove = 'hello ';
      const start = 'Hello'.length; // Fixed position after 'Hello '
      const end = start + chunkToRemove.length;

      // Run the removeChunkFromFile function
      raf = await testFile.open(mode: FileMode.append);
      await removeChunkFromFile(raf, start, end);

      // Read the file content after the operation as bytes and decode
      final newLength = raf.lengthSync(); // Get the new length of the file
      raf.setPositionSync(0); // Set the read position to the start of the file
      final List<int> modifiedContentBytes = await raf.read(newLength);
      await raf.close();
      final modifiedContent = ascii.decode(modifiedContentBytes);

      // Verify the file content
      expect(modifiedContent, equals('Hello world'));
    });
  });
}
