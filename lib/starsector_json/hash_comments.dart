/// Strips `#` comments the way the game does before it parses a JSON file.
///
/// This matches, character for character, the loop in
/// `com.fs.starfarer.loading.LoadingUtils`, which the game runs on the file
/// text before handing it to org.json. The rules, odd ones included:
///
/// - A `#` outside a double-quoted string starts a comment that runs to the end
///   of the line.
/// - Every `"` flips the "inside a string" flag. That includes a `"` inside a
///   comment, and a `"` that was written as `\"`. This step never looks at
///   backslashes, so `"a \" b # c"` loses everything from the `#` onward.
/// - A line break ends the comment and also clears the "inside a string" flag,
///   so as far as this step is concerned a string can never span lines.
/// - `\n` is kept. `\r` is thrown away, so a CRLF file comes out with LF
///   endings.
///
/// Returns the original string unchanged when there was nothing to strip.
///
/// Where the game walks the text one character at a time, this jumps straight
/// from one `#` to the next with [String.indexOf] and strips carriage returns
/// with [String.replaceAll], both of which are far faster than a Dart loop over
/// every character. That works because of two things the rules above imply:
///
/// - Whether a `#` starts a comment depends only on the number of `"`s between
///   it and the start of its line — the flag is cleared at every line break —
///   so the quotes can be counted when a `#` turns up instead of being tracked
///   all along.
/// - A `#` inside a comment changes nothing, and a comment can't be running at
///   the `#`s this loop stops on, because starting a comment skips straight to
///   the end of its line.
String removeHashComments(String text) {
  final length = text.length;
  var hashAt = text.indexOf('#');
  if (hashAt < 0) {
    // With no '#' there can be no comments, so the only possible change is
    // dropping the carriage returns.
    return text.contains('\r') ? text.replaceAll('\r', '') : text;
  }

  // Stays null until we find the first comment, so a file whose only `#`s sit
  // inside strings still comes back without a copy (when it has no '\r's).
  StringBuffer? out;
  // Start of the run of characters we're keeping but haven't written yet.
  var keepFrom = 0;
  // The '\r' positions on either side of the scan, used to find the start of
  // a '#'s line. [crAt] is the next one at or past the scan; [lastCr] is the
  // last one behind it. Rolling these forward visits each '\r' once no matter
  // how many '#'s the file has.
  var lastCr = -1;
  var crAt = text.indexOf('\r');
  if (crAt < 0) crAt = length;

  while (true) {
    while (crAt < hashAt) {
      lastCr = crAt;
      crAt = text.indexOf('\r', crAt + 1);
      if (crAt < 0) crAt = length;
    }

    // Does this '#' start a comment? Only if the number of '"'s since the
    // start of its line is even — the game flips its string flag on every
    // quote and clears it at every line break.
    final lastLf = hashAt == 0 ? -1 : text.lastIndexOf('\n', hashAt - 1);
    final lineStart = (lastLf > lastCr ? lastLf : lastCr) + 1;
    var quotes = 0;
    for (var i = lineStart; i < hashAt; i++) {
      if (text.codeUnitAt(i) == 0x22) quotes++; // 0x22 is '"'
    }

    if (quotes.isEven) {
      // A comment. Write out the span we've been keeping, minus its carriage
      // returns, then skip to the line break — or eat the rest of the file.
      out ??= StringBuffer();
      out.write(text.substring(keepFrom, hashAt).replaceAll('\r', ''));
      var lfAt = text.indexOf('\n', hashAt);
      if (lfAt < 0) lfAt = length;
      final end = lfAt < crAt ? lfAt : crAt;
      if (end == length) return out.toString();
      // A '\n' is kept, so the run we're keeping starts on it. A '\r' is not.
      keepFrom = end == lfAt ? end : end + 1;
      hashAt = end + 1;
    } else {
      // Inside a string as the game sees it, so not a comment.
      hashAt++;
    }

    hashAt = text.indexOf('#', hashAt);
    if (hashAt < 0) break;
  }

  // No more comments; what's left keeps everything but its carriage returns.
  final tail = text.substring(keepFrom);
  if (!tail.contains('\r')) {
    if (out == null) return text;
    out.write(tail);
  } else {
    out ??= StringBuffer();
    out.write(tail.replaceAll('\r', ''));
  }
  return out.toString();
}
