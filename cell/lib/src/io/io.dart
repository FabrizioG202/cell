import 'dart:io';

/// Removes a chunk from the file that [raf] points to, between [start] (inclusive) and [end] (exclusive) positions.
///
/// The function modifies the file in place and does not close the [raf], which should be managed externally.
///
/// Throws an Exception if start or end positions are invalid or if an error occurs during file modification.
///
/// - Parameters:
///   - [raf]: RandomAccessFile instance pointing to the file to be modified.
///   - [start]: The starting byte position (inclusive) of the chunk to be removed.
///   - [end]: The ending byte position (exclusive) of the chunk to be removed.
Future<void> removeChunkFromFile(
  RandomAccessFile raf,
  int start,
  int end,
) async {
  // Check that the end position is not before the start position.
  if (end < start) {
    throw Exception('End position must be greater than start position.');
  }

  // Get the total file length for validation.
  final fileLength = await raf.length();

  // Validate that start and end positions are within the bounds of the file length.
  if (start < 0 || end > fileLength) {
    throw Exception('Start and end positions must be within the file size.');
  }

  // Buffer size for shifting the file content.
  // Adjust the buffer size based on available memory and expected file sizes.
  // todo: Test different buffer sizes to find the optimal one.
  // maybe set this to as a parameter to the function?
  const bufferSize = 1024;
  var buffer = List<int>.filled(bufferSize, 0);
  int readSize;
  var writePos = start;

  try {
    // Loop to shift the file content from the end position of the chunk to be removed
    // towards the start, effectively overwriting the chunk.
    for (var readPos = end; readPos < fileLength; readPos += bufferSize) {
      final remaining = fileLength - readPos;
      readSize = remaining < bufferSize ? remaining : bufferSize;
      await raf.setPosition(readPos);
      buffer = await raf.read(readSize);
      await raf.setPosition(writePos);
      await raf.writeFrom(buffer, 0, readSize);
      writePos += readSize;
    }

    // Truncate the file from the end of the newly shifted content.
    await raf.truncate(fileLength - (end - start));
  } catch (e) {
    // If there's an error during the file operation, throw an exception.
    throw Exception('An error occurred during file modification: $e');
  }
}
