/// Keeps one copy of each distinct string instead of thousands of identical
/// ones.
///
/// Parsing game data produces the same short words over and over: every weapon
/// slot in every ship says `TURRET` or `HARDPOINT`, `LARGE` or `SMALL`. Each
/// one arrives from the parser as its own string object, so a big mod list ends
/// up holding a hundred thousand copies of the same dozen words — megabytes of
/// identical text.
///
/// Only worth using for values drawn from a small, repeating vocabulary. Do not
/// use it for text that is different every time, such as file paths or
/// descriptions: the pool never shrinks, so a unique string put in it is kept
/// for the life of the app.
final Map<String, String> _pool = {};

/// The shared copy of [value]. Equal strings return the very same object.
String internString(String value) {
  if (value.isEmpty) return '';
  return _pool[value] ??= value;
}

/// The longest string [internShortString] will share.
///
/// Long enough for field names, ids, tags and enum-ish values; short enough to
/// leave out file paths and descriptions, which are usually different every
/// time and would sit in the pool forever for nothing.
const internShortStringLimit = 24;

/// The shared copy of [value], if it is short enough to be worth sharing.
///
/// For text coming off a decoder, where most values repeat but the occasional
/// long one does not. Anything longer than [internShortStringLimit] is handed
/// straight back and never enters the pool.
String internShortString(String value) {
  if (value.length > internShortStringLimit) return value;
  return internString(value);
}
