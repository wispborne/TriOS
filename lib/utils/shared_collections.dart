/// Keeps one copy of each distinct list instead of thousands of equal ones.
///
/// Game data is full of short lists drawn from a small vocabulary: a ship's
/// `hints` and `tags`, its built-in hullmods and wings, a weapon's render
/// hints. There are thousands of ships and weapons and only a few hundred
/// distinct lists between them, but the parser builds a fresh list — and a
/// fresh backing array — for every one.
///
/// The pool never shrinks, so this is only for values drawn from a small,
/// repeating vocabulary. Do not put anything unique through it.
///
/// The lists handed back are unmodifiable. Sharing only works if nobody
/// changes one, and an unmodifiable list says so loudly instead of quietly
/// changing every item that shares it.
final Map<String, List<String>> _pool = {};

/// The empty list, shared. Much the commonest case by far.
const List<String> _nothing = [];

/// The shared copy of [value]. Equal lists return the very same object.
List<String>? shareStringList(List<String>? value) {
  if (value == null) return null;
  if (value.isEmpty) return _nothing;

  // A null byte cannot appear in any of this data, so joining on one gives a
  // key that two different lists cannot collide on.
  final key = value.join('\u0000');
  return _pool[key] ??= List<String>.unmodifiable(value);
}
