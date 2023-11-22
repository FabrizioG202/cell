part of cell.database;

/// The maximum size that a row can assume.
/// It is 2^32 since we are using 4 bytes to store the size of the row
const kMaxRowSize = 4294967296;

/// A [Store] is a wrapper around a file that allows to read and write data to it.
final class Store<T> {
  Store._(this.file, this._raf, this.rowSchema);

  final File file;
  final EmbeddedSchema<T> rowSchema;
  final RandomAccessFile _raf;

  /// Opens the store
  static Future<Store<T>> open<T>({
    required File file,
    required EmbeddedSchema<T> rowSchema,
  }) async =>
      Store._(file, await file.open(mode: FileMode.append), rowSchema);

  /// Resets the position of the RAF to the start of the file
  Future<void> resetPosition() => _raf.setPosition(0);

  /// Closes the store
  Future<void> close() => _raf.close();

  /// Clears the store
  /// This is done by truncating the file to 0 bytes
  /// This will not delete the file but just clear it
  Future<void> clear() async => _raf.truncate(0);

  /// Removes the row at position
  /// The start position includes the size of the row
  Future<void> removeRow(int startPosition) async {
    throw UnimplementedError();
  }

  /// Reads a single row from the file
  /// Returns null if the end of the file has been reached
  Future<List<T>> readAll({
    int chunkSize = 1024,
    bool resetPosition = true,
  }) async {
    // Create a new reader
    final reader = BytesReader();

    // Iterate over the rows
    return _rawIterateRows(
      reader,
      chunkSize: chunkSize,
      resetPosition: resetPosition,
      autoAdvanceReader: false,
    ).map(
      (data) {
        // Get the bytes for the row
        final (_, rowLength) = data;
        return rowSchema.readFrom(reader, rowLength);
      },
    ).toList();
  }

  @protected
  Stream<(int rowDataStartPosition, int rowLength)> _rawIterateRows(
    BytesReader reader, {
    required int chunkSize,
    required bool resetPosition,
    required bool autoAdvanceReader,
  }) async* {
    // Assert that the chunk size is valid and > 4 (since otherwise we cannot read the size of the row)
    assert(chunkSize > 4, 'Chunk size must be > 4');

    // we reset the position of the RAF if requested
    if (resetPosition) await _raf.setPosition(0);

    // Read an initial chunk of bytes
    reader.append(await _raf.read(chunkSize));

    mainLoop:
    while (true) {
      // We assume to be RF aligned.
      // We first read the size of the row
      // We use exact: false since we want for the other cases in the switch
      // to be possible and no exception to be thrown on these line.
      // We might subsitute this for something similar to a tryReadUint32
      // to simplify the code and use the [BytesReader] throughout the code
      final sizeBytes = reader.readBytes(4, exact: false);

      // depending on the size of the row, we are ona different branch of the code
      switch (sizeBytes.length) {
        // We have reached the end of the file
        case 0:
          break mainLoop;

        // We have a corrupted file
        case < 4:
          throw Exception('Corrupted file!');

        // We have a valid file (it cannot be > 4 since we are reading 4 bytes)
        case 4:
          break;
      }

      // The position at which the row data starts.
      final rowDataStartPosition = reader.position;
      final remaining = reader.remainingLength;
      final trueSize = _readUint32(sizeBytes);

      // This is the size of this row and the bytes for the size of the next row.
      final readSize = trueSize + 4;

      // If we do not have enough bytes to read the row, we read more bytes
      if (remaining < readSize) {
        // we adjust the chunk size to be at least the size of the row
        // So we know for sure that we have enough bytes to read the row
        final adjustedChunkSize = math.max(chunkSize, readSize);

        // Read the bytes of the row
        final bytes = await _raf.read(adjustedChunkSize);

        // Append the bytes to the reader
        reader.append(bytes);
      }

      // We yield the position of the row and its length
      yield (rowDataStartPosition, trueSize);

      // If we are auto advancing the reader, we advance it
      if (autoAdvanceReader) reader.advance(trueSize);
    }
  }

  /// Writes the given data to disk
  Future<void> addAll(
    List<T> rows, {
    int batchSize = 100,
  }) async {
    final n = rows.length;
    try {
      // loop over the data batched in chunks
      //var position = await _raf.length();
      for (var i = 0; i < n; i += batchSize) {
        // Get the current batch
        final batch = rows.sublist(i, math.min(i + batchSize, n));

        // Get the bytes for the data
        final buffer = BytesWriter();

        // loop over the data and write it to the buffer
        for (final item in batch) {
          // Write the data, encapsulating it with the size of the row so that it is possible to read it later and skip the entire row if needed.
          buffer.encapsulateWithUint32Length(
            (writer) => rowSchema.writeTo(writer, item),
          );
        }

        // Write the bytes to the file
        await _raf.writeFrom(buffer.bytes);
      }
    } on Exception {
      rethrow;
    } finally {}
  }
}

/// A new function to read a Uint32 from a [Uint8List]
/// This should be symmetrical to the [BytesWriter.writeUint32] function used to write the
/// size of the row (within [BytesWriter.encapsulateWithUint32Length])
@pragma('vm:prefer-inline')
int _readUint32(Uint8List bytes) {
  assert(
    bytes.length == 4,
    'Position must be less than the length of the bytes',
  );

  return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}
