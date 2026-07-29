/// Turns markdown into plain text.
///
/// For places that show text as-is instead of rendering it: this takes off the
/// markers people write around their words (`**bold**`, `` `code` ``, headings,
/// links, quotes) and leaves the words behind. Bullet lists keep a leading
/// dash so they still read as a list.
String stripMarkdown(String text) {
  var result = text;

  // Code fences: drop the ``` lines, keep the code.
  result = result.replaceAll(RegExp(r'^[ \t]*```.*$', multiLine: true), '');

  // Images and links: keep the words, drop the address.
  result = result.replaceAllMapped(
    RegExp(r'!?\[([^\]]*)\]\([^)\s]*(?:\s+"[^"]*")?\)'),
    (m) => m.group(1) ?? '',
  );

  // A bare address in angle brackets.
  result = result.replaceAllMapped(
    RegExp(r'<((?:https?|mailto):[^>\s]+)>'),
    (m) => m.group(1) ?? '',
  );

  // Line starts: headings, quotes, and bullet markers.
  result = result.replaceAll(
    RegExp(r'^[ \t]*#{1,6}(?:[ \t]+|$)', multiLine: true),
    '',
  );
  result = result.replaceAll(RegExp(r'[ \t]*#+[ \t]*$', multiLine: true), '');
  result = result.replaceAll(RegExp(r'^[ \t]*>[ \t]?', multiLine: true), '');
  result = result.replaceAllMapped(
    RegExp(r'^([ \t]*)[*+][ \t]+', multiLine: true),
    (m) => '${m.group(1)}- ',
  );

  // A line of only dashes, stars, or underscores is a divider.
  result = result.replaceAll(
    RegExp(r'^[ \t]*(?:[-*_][ \t]*){3,}$', multiLine: true),
    '',
  );

  // Emphasis markers around words.
  result = result.replaceAllMapped(
    RegExp(r'~~(.+?)~~', dotAll: true),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'\*\*\*(.+?)\*\*\*', dotAll: true),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*', dotAll: true),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'\*(?!\s)([^*\n]+?)(?<!\s)\*'),
    (m) => m.group(1) ?? '',
  );
  // Underscores only count between non-word characters, so file_names and
  // mod_ids are left alone.
  result = result.replaceAllMapped(
    RegExp(r'(?<![\w\\])__(.+?)__(?!\w)', dotAll: true),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'(?<![\w\\])_([^_\n]+)_(?!\w)'),
    (m) => m.group(1) ?? '',
  );

  // Backticks around code.
  result = result.replaceAllMapped(
    RegExp(r'`+([^`]+)`+'),
    (m) => m.group(1) ?? '',
  );

  // A backslash in front of a marker meant "show this character".
  result = result.replaceAllMapped(
    RegExp(r'\\([\\`*_{}\[\]()#+\-.!~>|])'),
    (m) => m.group(1) ?? '',
  );

  // Tidy up: no trailing spaces, and no big gaps left by removed lines.
  result = result.replaceAll(RegExp(r'[ \t]+$', multiLine: true), '');
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return result.trim();
}
