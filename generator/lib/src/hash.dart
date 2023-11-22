/// This library contains the logic to handle
/// hashing of type names and fieled names to convert
/// the names to integers in a semi-consistent way
library hash;

/// Hashes a string with a salt, this is used to convert a string to an integer
/// which is used as the id of a type or a field
int hashStringWithSalt(String str, int salt) {
  var hash = 5381 + salt;
  for (var i = 0; i < str.length; i++) {
    hash = ((hash << 5) + hash) + str.codeUnitAt(i); /* hash * 33 + c */
  }
  return hash & 0xFFFFFFFF; // Constrain to 32 bits
}
