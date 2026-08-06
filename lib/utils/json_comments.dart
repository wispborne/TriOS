/// Strips `//` line comments and `/* */` block comments, which the game's own
/// JSON parser has no idea about. String literals are respected, including
/// `\"` escapes, so a `//` inside a string is kept.
///
/// Use this for files the game never reads — `.version` files, and anything
/// TriOS scans on a best-effort basis — where being stricter than the game
/// buys nothing. `parseJsonToMap()` already handles everything the game
/// itself accepts, `#` comments included, so don't reach for this to prepare
/// a file the game loads.
///
/// Pass `stripHashLineComments: true` to also strip `#` line comments outside
/// strings. That is quote-aware in a way the game's own stripper isn't, so it
/// keeps a `#` that follows a `\"` on the same line.
String stripJsonComments(String src, {bool stripHashLineComments = false}) {
  final sb = StringBuffer();
  var i = 0;
  var inString = false;
  var prev = '';
  while (i < src.length) {
    final c = src[i];
    if (inString) {
      sb.write(c);
      if (c == '"' && prev != r'\') inString = false;
      prev = c;
      i++;
      continue;
    }
    if (c == '"') {
      inString = true;
      sb.write(c);
      prev = c;
      i++;
      continue;
    }
    if (c == '/' && i + 1 < src.length) {
      final next = src[i + 1];
      if (next == '/') {
        final nl = src.indexOf('\n', i + 2);
        if (nl == -1) return sb.toString();
        i = nl;
        continue;
      }
      if (next == '*') {
        final end = src.indexOf('*/', i + 2);
        if (end == -1) return sb.toString();
        i = end + 2;
        continue;
      }
    }
    if (stripHashLineComments && c == '#') {
      final nl = src.indexOf('\n', i + 1);
      if (nl == -1) return sb.toString();
      i = nl;
      continue;
    }
    sb.write(c);
    prev = c;
    i++;
  }
  return sb.toString();
}
