part of cell;

/// A CellException base class.
class CellException implements Exception {
  /// Creates a new CellException.
  const CellException(this.message);

  /// The message of the exception.
  final String message;

  @override
  String toString() => message;
}

/// An exception thrown when a field is missing.
class MissingFieldException extends CellException {
  /// Creates a new MissingFieldException.
  const MissingFieldException(super.message);
}

/// An exception thrown when a field is invalid.
class InvalidFieldException extends CellException {
  /// Creates a new InvalidFieldException.
  const InvalidFieldException(super.message);
}

/// An exception thrown when a field code is not recognized.
class UnknownFieldCodeException extends CellException {
  /// Creates a new UnknownFieldCodeException.
  const UnknownFieldCodeException(super.message);
  const UnknownFieldCodeException.id(int id) : super('Unknown field code: $id');
}
