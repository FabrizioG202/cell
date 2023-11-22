/// An extension on [String] to add a semicolon at the end of the string
/// if it does not have one already
extension StringUtils on String {
  /// Removes the prefix from the string
  /// If the string does not start with the prefix, it returns the string itself
  String removePrefix(String prefix) {
    if (startsWith(prefix)) {
      return substring(prefix.length);
    }
    return this;
  }
}

/// Useful extensions on [Iterable<T>]
extension StringIterableUtils on Iterable<String> {
  /// Joins the elements of the iterable with the given [separator]
  /// and appends with
  String compose({
    String? suffix,
    String? prefix,
    String separator = '',
  }) {
    final buffer = StringBuffer();
    if (prefix != null) buffer.write(prefix);
    buffer.write(join(separator));
    if (suffix != null) buffer.write(suffix);
    return buffer.toString();
  }
}

/// An extension on [Iterable<T>] which splits a list into two based on a predicate
extension IterableUtils<T> on Iterable<T> {
  /// Splits the list into two based on the predicate
  /// The first list contains all the elements for which the predicate is true
  /// The second list contains all the elements for which the predicate is false
  (List<T> first, List<T> second) split(bool Function(T) predicate) {
    final trueList = <T>[];
    final falseList = <T>[];
    for (final element in this) {
      if (predicate(element)) {
        trueList.add(element);
      } else {
        falseList.add(element);
      }
    }
    return (trueList, falseList);
  }
}

/// An extension on [List<T>] that moves from this list all the elements
/// for which the predicate is true to the other list
/// (done using a while loop)
extension ListUtils<T> on List<T> {
  /// Moves from this list all the elements for which the predicate is true
  /// to the other list
  /// (done using a while loop)
  void moveWhereTo(List<T> other, bool Function(T) predicate) {
    var i = 0;
    while (i < length) {
      if (predicate(this[i])) {
        other.add(removeAt(i));
      } else {
        i++;
      }
    }
  }
}
