/// Thrown when a file can't be read as JSON.
///
/// Stands in for Java's `org.json.JSONException`. The messages are copied from
/// the Java code, so what a user sees here matches what the game's log would
/// say for the same file.
class StarsectorJsonException implements Exception {
  const StarsectorJsonException(this.message);

  final String message;

  @override
  String toString() => 'StarsectorJsonException: $message';
}
