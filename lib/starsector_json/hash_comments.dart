const int _lineFeed = 0x0A;
const int _carriageReturn = 0x0D;
const int _doubleQuote = 0x22;
const int _hash = 0x23;

/// Strips `#` comments the way the game does before it parses a JSON file.
///
/// This is a line-for-line port of the loop in
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
String removeHashComments(String text) {
  final length = text.length;
  // Stays null until we find the first thing to drop, so a file with no
  // comments and no carriage returns costs one scan and no copying.
  StringBuffer? out;
  var inComment = false;
  var inQuote = false;
  // Start of the run of characters we're keeping but haven't written yet.
  var keepFrom = 0;

  for (var i = 0; i < length; i++) {
    final char = text.codeUnitAt(i);
    if (char == _doubleQuote) inQuote = !inQuote;

    if (char == _lineFeed || char == _carriageReturn) {
      final wasInComment = inComment;
      inComment = false;
      inQuote = false;
      if (char == _lineFeed) {
        // The newline itself is always kept. If a comment was running, the
        // run we're keeping starts here.
        if (wasInComment) keepFrom = i;
      } else {
        out ??= StringBuffer();
        if (!wasInComment) out.write(text.substring(keepFrom, i));
        keepFrom = i + 1;
      }
    } else if (char == _hash && !inQuote && !inComment) {
      out ??= StringBuffer();
      out.write(text.substring(keepFrom, i));
      inComment = true;
    }
    // Anything else either extends the run we're keeping, or sits inside a
    // comment and is skipped because the run already ended.
  }

  if (out == null) return text;
  if (!inComment) out.write(text.substring(keepFrom, length));
  return out.toString();
}
