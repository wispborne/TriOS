/// Starsector JSON files frequently include `//` line comments and
/// `/* */` block comments, which are not valid JSON. This strips them
/// before `jsonDecode`. String literals are respected — a `//` inside
/// a string is preserved.
///
/// Pass `stripHashLineComments: true` to additionally strip `#` line
/// comments (through the next newline) outside string literals. Default
/// `false` preserves legacy behavior for every existing caller.
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
