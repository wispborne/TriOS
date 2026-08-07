// Tells apart class names that come from a mod from ones that come from
// Starsector itself or from a library the game ships with.
//
// Chipper uses this to decide what to highlight in a log. A crash almost always
// names the mod that caused it somewhere in the stack trace or in the error
// message, and that name is what a reader is looking for.

/// Package prefixes that belong to the game or to a library bundled with it.
/// Taken from the jars in `starsector-core`, plus the Java runtime. Anything
/// that doesn't start with one of these is treated as mod code.
const _gamePackagePrefixes = [
  "com.fs.", // the game
  "sound.", // the game's bundled sound code
  "zzz.", // obfuscated game classes
  "java.",
  "javax.",
  "jdk.",
  "sun.",
  "com.sun.",
  "org.lwjgl.", // lwjgl
  "org.apache.", // log4j
  "org.json.", // json.jar
  "org.codehaus.", // janino
  "de.unkrig.", // janino's compiler backend
  "com.thoughtworks.", // xstream
  "net.java.games.", // jinput
  "com.jcraft.", // jogg and jorbis
  "com.luciad.", // webp-imageio
];

/// Matches a dotted Java name inside a longer piece of text, for example the
/// `Arisza.mms.hullmods.MicrolayerHullmod` in "Problem loading class
/// [Arisza.mms.hullmods.MicrolayerHullmod]".
///
/// Needs at least three parts so that file names like `settings.json` and
/// `starsector.log` don't match. Each part has to start with a letter, so
/// version numbers like `0.98a` don't match either.
final classNameInTextPattern = RegExp(
  r"[a-zA-Z_$][a-zA-Z0-9_$]*(?:\.[a-zA-Z_$][a-zA-Z0-9_$]*){2,}",
);

/// Whether [name] is a class or package name from a mod.
///
/// Returns false for anything that isn't a dotted name at all, so a bare word
/// is never highlighted.
bool isModClassName(String? name) {
  if (name == null) return false;

  // Java 9 and up write the module in front of the class, like
  // "java.base/java.lang.Class". Only the part after the slash is the name.
  final slash = name.lastIndexOf("/");
  final className = slash == -1 ? name : name.substring(slash + 1);

  if (!className.contains(".")) return false;

  return !_gamePackagePrefixes.any(className.startsWith);
}
