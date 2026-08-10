/// One shared copy of each short string that mod data produces.
///
/// Parsed mod data repeats the same short strings enormously often — every
/// `.ship`/`.wpn` key, `BALLISTIC`, `SMALL`, tag names — and each occurrence
/// is its own heap object unless something makes them share. On a 460-mod
/// install, pooling collapsed about 90 MB of strings into ~85,000 shared ones.
///
/// The 64-character cutoff: strings longer than that are overwhelmingly unique
/// (sprite paths, description prose, whole tag lists), so pooling them would
/// grow the pool without collapsing anything.
///
/// The pool is never cleared. It costs a few MB, and clearing it would mean a
/// later parse — a mod installed mid-session, a refresh — starts a fresh pool
/// whose strings share nothing with the data already in memory.
///
/// If a parse ever moves to a background isolate ([AppWorker]), that isolate
/// gets its own pool. Sharing still works within each isolate; it just doesn't
/// cross the boundary. That is fine, not a bug: strings sent between isolates
/// are copied anyway, so the receiving side re-pools them when it runs the
/// received data through its own parse or normalize step.
library;

final Map<String, String> _pool = {};

/// Returns the pooled copy of [s], adding [s] to the pool if it's new.
/// Strings longer than 64 characters are returned as-is, unpooled.
String sharedString(String s) {
  if (s.length > 64) return s;
  return _pool[s] ??= s;
}
